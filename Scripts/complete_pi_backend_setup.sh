#!/bin/bash
#
# complete_pi_backend_setup.sh
#
# Fully automated, interactive “Cookbook + Convex + Chef UI” setup for a Raspberry Pi.
# The script:
#   1. Updates/upgrades OS packages (APT)
#   2. Installs Git, Node.js (LTS), npm, Convex CLI, Docker, Chef Infra Client
#   3. Creates and applies a Chef cookbook under /etc/chef for idempotent provisioning
#   4. Clones (or pulls) a user-specified GitHub repo for your Chef + Convex project and builds it
#   5. Prompts for all Convex project details (URL + API keys) and writes a valid .env.local
#   6. Runs `convex login`, pushes the schema, and deploys functions to the cloud
#   7. Serves the static Chef UI via Docker + Nginx
#   8. Optionally installs a systemd service so local Convex functions run at boot
#
# Usage:
#   chmod +x complete_pi_backend_setup.sh
#   sudo ./complete_pi_backend_setup.sh
#
# Everything is logged to: /var/log/complete_pi_backend_setup.log
#

set -e
set -o pipefail

LOGFILE="/var/log/complete_pi_backend_setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo
echo "========================================================"
echo "COMPLETE RASPBERRY PI → Chef+Convex BACKEND SETUP"
echo "========================================================"
echo

#######################################
# Helper Functions
#######################################

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Retry a command up to N times (with 5 s delay)
retry() {
  local -r -i max_attempts="$1"; shift
  local -r cmd="$@"
  local -i attempt_num=1

  until $cmd; do
    if (( attempt_num == max_attempts )); then
      echo "✗ Command '$cmd' failed after $attempt_num attempts." >&2
      exit 1
    else
      echo "⚠️  Command '$cmd' failed. Retrying ($attempt_num/$max_attempts)..." >&2
      sleep 5
      ((attempt_num++))
    fi
  done
}

#######################################
# Determine which user is provisioning
#######################################
if [ -n "$SUDO_USER" ]; then
  PROV_USER="$SUDO_USER"
else
  PROV_USER="$USER"
fi

echo "▶ Provisioning as user: $PROV_USER"
echo

#######################################
# Collect interactive inputs
#######################################

# 1) GitHub Repo URL
read -p "Enter the GitHub repository URL for your Chef+Convex project (e.g. https://github.com/username/FLYSKIPI.git): " GIT_REPO_URL
if [ -z "$GIT_REPO_URL" ]; then
  echo "✗ Repository URL cannot be empty. Exiting."
  exit 1
fi

# 2) Convex Deployment URL
echo
read -p "Enter your Convex Deployment URL (e.g. https://flyskipi.convex.dev): " CONVEX_URL
if [ -z "$CONVEX_URL" ]; then
  echo "✗ Convex Deployment URL cannot be empty. Exiting."
  exit 1
fi

# 3) Convex Read Key
read -p "Enter your Convex Read Key (sk_...): " CONVEX_READ_KEY
if [ -z "$CONVEX_READ_KEY" ]; then
  echo "✗ Convex Read Key cannot be empty. Exiting."
  exit 1
fi

# 4) Convex Write Key
read -p "Enter your Convex Write Key (sk_...): " CONVEX_WRITE_KEY
if [ -z "$CONVEX_WRITE_KEY" ]; then
  echo "✗ Convex Write Key cannot be empty. Exiting."
  exit 1
fi

# 5) Convex Auth (optional)
echo
echo "If you plan to use Convex Auth, enter these; otherwise press Enter to skip."
read -p "Convex Auth Domain (e.g. auth.convex.dev): " CONVEX_AUTH_DOMAIN
read -p "Convex Auth Client ID: " CONVEX_AUTH_CLIENT_ID

# 6) Local-mode for Convex functions
echo
read -p "Do you want to run Convex functions locally on this Pi at boot? [y/N]: " RUN_LOCAL
RUN_LOCAL="${RUN_LOCAL:-N}"

#######################################
# 1) Update & Upgrade APT Packages
#######################################
echo
echo "1) Updating & upgrading APT packages..."
retry 3 apt-get update -y
retry 3 apt-get upgrade -y
echo "✔ APT packages are up to date."
echo

#######################################
# 2) Install Git
#######################################
echo "2) Checking for Git..."
if ! command_exists git; then
  echo "→ Git not found; installing..."
  retry 3 apt-get install -y git
else
  echo "→ Git already installed: $(git --version)"
fi
echo

#######################################
# 3) Install Node.js (LTS) & npm
#######################################
echo "3) Checking for Node.js & npm..."
if ! command_exists node || ! command_exists npm; then
  echo "→ Node.js/npm not found; installing Node.js LTS..."
  retry 3 curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  retry 3 apt-get install -y nodejs
else
  echo "→ Node.js is installed: $(node -v) | npm: $(npm -v)"
fi
echo

#######################################
# 4) Install Convex CLI
#######################################
echo "4) Checking for Convex CLI..."
if ! command_exists convex; then
  echo "→ Convex CLI not found; installing via npm..."
  retry 3 npm install -g convex
  echo "→ Convex CLI version: $(convex --version)"
else
  echo "→ Convex CLI already installed: $(convex --version)"
fi
echo

#######################################
# 5) Install Docker
#######################################
echo "5) Checking for Docker..."
if ! command_exists docker; then
  echo "→ Docker not found; installing via convenience script..."
  retry 3 curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  retry 3 bash /tmp/get-docker.sh
  rm /tmp/get-docker.sh
  echo "→ Docker version: $(docker --version)"
else
  echo "→ Docker already installed: $(docker --version)"
fi
echo

#######################################
# 6) Add user to 'docker' group
#######################################
echo "6) Ensuring user '$PROV_USER' is in 'docker' group..."
if id -nG "$PROV_USER" | grep -qw docker; then
  echo "→ '$PROV_USER' is already in 'docker' group."
else
  retry 3 usermod -aG docker "$PROV_USER"
  echo "→ Added '$PROV_USER' to 'docker' group (log out/in required)."
fi
echo

#######################################
# 7) Install Chef Infra Client
#######################################
echo "7) Checking for Chef Infra Client..."
if ! command_exists chef-client; then
  echo "→ Chef Infra Client not found; installing..."
  retry 3 curl -fsSL https://omnitruck.chef.io/install.sh | bash -s -- -P chef
  echo "→ Chef Client version: $(chef-client --version)"
else
  echo "→ Chef Client already installed: $(chef-client --version)"
fi
echo

#######################################
# 8) Create Chef cookbook under /etc/chef
#######################################
CHEF_COOKBOOK_DIR="/etc/chef/cookbooks/pi_dev_environment"
echo "8) Creating Chef cookbook at $CHEF_COOKBOOK_DIR..."
mkdir -p "$CHEF_COOKBOOK_DIR/recipes" "$CHEF_COOKBOOK_DIR/attributes"

# 8a) solo.rb
echo "→ Writing /etc/chef/solo.rb..."
cat <<'EOF' > /etc/chef/solo.rb
cookbook_path ['/etc/chef/cookbooks']
EOF

# 8b) attributes/default.rb
echo "→ Writing attributes/default.rb..."
cat <<EOF > "$CHEF_COOKBOOK_DIR/attributes/default.rb"
default['pi_dev_environment']['user'] = '$PROV_USER'
EOF

# 8c) recipes/default.rb
echo "→ Writing recipes/default.rb..."
cat <<'EOF' > "$CHEF_COOKBOOK_DIR/recipes/default.rb"
#
# Cookbook:: pi_dev_environment
# Recipe:: default
#
# Ensures Git, Node.js, Convex CLI, Docker are installed, and that the user is in the 'docker' group.

# 1) Update apt cache
apt_update 'update_sources' do
  action :update
end

# 2) Upgrade all packages
execute 'upgrade_all_packages' do
  command 'apt-get upgrade -y'
  action :run
end

# 3) Install Git
package 'git' do
  action :install
end

# 4) Install Node.js (LTS) via NodeSource
remote_file '/tmp/nodesource_setup.sh' do
  source 'https://deb.nodesource.com/setup_lts.x'
  mode '0755'
  action :create
end

execute 'run_nodesource_setup' do
  command 'bash /tmp/nodesource_setup.sh'
  action :run
end

package 'nodejs' do
  action :install
end

# 5) Install Convex CLI via npm
npm_package 'convex' do
  action :install
  options '-g'
end

# 6) Install Docker
remote_file '/tmp/get-docker.sh' do
  source 'https://get.docker.com'
  mode '0755'
  action :create
end

execute 'install_docker' do
  command 'bash /tmp/get-docker.sh'
  action :run
end

file '/tmp/get-docker.sh' do
  action :delete
end

# Ensure 'docker' group exists
group 'docker' do
  action :create
  append true
end

# 7) Add the specified user to 'docker' group
user_to_add = node['pi_dev_environment']['user'] || 'pi'

group 'docker' do
  action :modify
  members [user_to_add]
  append true
end
EOF

echo "→ Chef cookbook created."
echo

#######################################
# 9) Run chef-client locally to apply the cookbook
#######################################
echo "9) Running chef-client in local mode..."
chef-client -z -c /etc/chef/solo.rb -o pi_dev_environment
echo "→ Chef converge completed successfully."
echo

#######################################
# 10) Clone or update the specified GitHub repository
#######################################
echo "10) Cloning/updating repository: $GIT_REPO_URL"
cd "/home/$PROV_USER"
REPO_NAME=$(basename -s .git "$GIT_REPO_URL")
if [ -d "$REPO_NAME" ]; then
  echo "→ '$REPO_NAME' exists; pulling latest changes..."
  cd "$REPO_NAME"
  retry 3 git pull
else
  echo "→ Cloning into '$REPO_NAME'..."
  retry 3 git clone "$GIT_REPO_URL"
  cd "$REPO_NAME"
fi
echo "→ Repository ready at $(pwd)"
echo

#######################################
# 11) Install & build Node components (Convex + Chef UI)
#######################################
echo "11) Installing & building Node.js components..."

# Top-level (if package.json exists)
if [ -f "package.json" ]; then
  echo "→ Installing top-level npm dependencies..."
  retry 3 npm install
fi

# Convex backend
if [ -d "convex" ]; then
  echo "→ Installing Convex backend dependencies..."
  cd convex
  retry 3 npm install
  cd ..
else
  echo "⚠️  Warning: 'convex/' directory not found!"
fi

# Chef UI front-end
if [ -d "app" ]; then
  echo "→ Installing Chef UI (React) dependencies..."
  cd app
  retry 3 npm install
  echo "→ Building Chef UI (static)..."
  retry 3 npm run build
  cd ..
else
  echo "⚠️  Warning: 'app/' directory not found!"
fi

echo "→ Node.js components installed & built."
echo

#######################################
# 12) Convex CLI: login, push schema, deploy functions
#######################################
echo "12) Convex CLI: Initiating login (if not already authenticated)..."
convex login || true

echo "→ Pushing Convex schema to cloud..."
retry 3 convex schema:push --config convex/convex.config.ts

echo "→ Deploying Convex functions to cloud..."
retry 3 convex functions:deploy --config convex/convex.config.ts
echo "→ Convex backend is now live on the cloud."
echo

#######################################
# 13) Create or update .env.local with provided Convex values
#######################################
ENV_FILE="/home/$PROV_USER/$REPO_NAME/.env.local"
echo "13) Ensuring .env.local exists at $ENV_FILE..."
if [ ! -f "$ENV_FILE" ]; then
  echo "→ Creating .env.local with your Convex values..."
  cat <<EOF > "$ENV_FILE"
VITE_CONVEX_URL=$CONVEX_URL
CONVEX_READ_KEY=$CONVEX_READ_KEY
CONVEX_WRITE_KEY=$CONVEX_WRITE_KEY
EOF
  # Only add Auth lines if provided
  if [ -n "$CONVEX_AUTH_DOMAIN" ]; then
    cat <<EOF >> "$ENV_FILE"
CONVEX_AUTH_DOMAIN=$CONVEX_AUTH_DOMAIN
CONVEX_AUTH_CLIENT_ID=$CONVEX_AUTH_CLIENT_ID
EOF
  fi
  chown "$PROV_USER":"$PROV_USER" "$ENV_FILE"
  echo "→ .env.local created; please verify its contents."
else
  echo "→ .env.local already exists; updating with provided values..."
  sed -i "s|^VITE_CONVEX_URL=.*|VITE_CONVEX_URL=$CONVEX_URL|" "$ENV_FILE"
  sed -i "s|^CONVEX_READ_KEY=.*|CONVEX_READ_KEY=$CONVEX_READ_KEY|" "$ENV_FILE"
  sed -i "s|^CONVEX_WRITE_KEY=.*|CONVEX_WRITE_KEY=$CONVEX_WRITE_KEY|" "$ENV_FILE"
  if [ -n "$CONVEX_AUTH_DOMAIN" ]; then
    if grep -q "^CONVEX_AUTH_DOMAIN=" "$ENV_FILE"; then
      sed -i "s|^CONVEX_AUTH_DOMAIN=.*|CONVEX_AUTH_DOMAIN=$CONVEX_AUTH_DOMAIN|" "$ENV_FILE"
    else
      echo "CONVEX_AUTH_DOMAIN=$CONVEX_AUTH_DOMAIN" >> "$ENV_FILE"
    fi
    if grep -q "^CONVEX_AUTH_CLIENT_ID=" "$ENV_FILE"; then
      sed -i "s|^CONVEX_AUTH_CLIENT_ID=.*|CONVEX_AUTH_CLIENT_ID=$CONVEX_AUTH_CLIENT_ID|" "$ENV_FILE"
    else
      echo "CONVEX_AUTH_CLIENT_ID=$CONVEX_AUTH_CLIENT_ID" >> "$ENV_FILE"
    fi
  fi
  chown "$PROV_USER":"$PROV_USER" "$ENV_FILE"
  echo "→ .env.local updated."
fi
echo

#######################################
# 14) Serve Chef UI (static) via Docker + Nginx
#######################################
echo "14) Serving Chef UI via Docker + Nginx..."
UI_DIST="/home/$PROV_USER/$REPO_NAME/app/dist"

if [ -d "$UI_DIST" ]; then
  # Stop existing container if it exists
  if docker ps --format '{{.Names}}' | grep -q chef_ui_nginx; then
    echo "→ Stopping existing 'chef_ui_nginx' container..."
    docker rm -f chef_ui_nginx || true
  fi

  echo "→ Launching Nginx container to serve $UI_DIST on port 80..."
  docker run -d -p 80:80 \
    -v "$UI_DIST":/usr/share/nginx/html:ro \
    --name chef_ui_nginx \
    nginx:alpine

  echo "→ Chef UI is now available at http://<pi-ip>/"
else
  echo "⚠️  ERROR: UI dist directory not found at $UI_DIST"
fi
echo

#######################################
# 15) Optional: Install systemd service for local Convex functions
#######################################
if [[ "$RUN_LOCAL" =~ ^[Yy] ]]; then
  echo "15) Installing systemd service to run Convex functions locally at boot..."
  SERVICE_FILE="/etc/systemd/system/convex-local.service"
  echo "→ Writing systemd unit file at $SERVICE_FILE..."
  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Convex Functions Local Server
After=network.target

[Service]
Type=simple
User=$PROV_USER
WorkingDirectory=/home/$PROV_USER/$REPO_NAME/convex
ExecStart=$(command -v convex) functions:serve --config convex/convex.config.ts
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  echo "→ Reloading systemd daemon..."
  systemctl daemon-reload
  echo "→ Enabling & starting 'convex-local.service'..."
  systemctl enable convex-local.service
  systemctl start convex-local.service
  echo "→ Convex local functions service is active (listening on port 8888)."
else
  echo "15) Skipping installation of local-mode Convex functions service."
fi
echo

#######################################
# 16) Final Summary & Manual Checklist
#######################################
echo "========================================================"
echo "        PI → Chef+Convex SETUP SCRIPT COMPLETED"
echo "========================================================"
echo
echo "Manual steps you still need to do:"
echo
echo "1) Log out and log back in as '$PROV_USER' to apply 'docker' group membership."
echo "   After re-login, confirm with: docker ps"
echo
echo "2) Verify /home/$PROV_USER/$REPO_NAME/.env.local contains correct values:"
echo "   – VITE_CONVEX_URL=$CONVEX_URL"
echo "   – CONVEX_READ_KEY=$CONVEX_READ_KEY"
echo "   – CONVEX_WRITE_KEY=$CONVEX_WRITE_KEY"
if [ -n "$CONVEX_AUTH_DOMAIN" ]; then
  echo "   – CONVEX_AUTH_DOMAIN=$CONVEX_AUTH_DOMAIN"
  echo "   – CONVEX_AUTH_CLIENT_ID=$CONVEX_AUTH_CLIENT_ID"
fi
echo
echo "3) To access the Chef UI in production, open:"
echo "     http://<pi-ip>/"
echo "   (If you opted for local-mode Devtools instead, run 'npm run dev' in this project’s 'app' folder.)"
echo
echo "4) In Chef UI:"
echo "   – Navigate to 'Register Device' (Setup page)."
echo "   – Enter a unique Device ID (e.g. raspberry-001)."
echo "   – Click 'Register Device' to create a document in Convex 'installations' (status = pending)."
echo
echo "5) (Optional) To run installer actions locally, ensure 'convex-local.service' is active:"
echo "     sudo systemctl status convex-local.service"
echo "     sudo journalctl -u convex-local.service -f"
echo "   Then click installer buttons in Chef UI to install packages on this Pi."
echo
echo "========================================================"
echo "Detailed logs: $LOGFILE"
echo "========================================================"
echo

exit 0
