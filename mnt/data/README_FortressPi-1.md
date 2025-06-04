# 🛡️ FortressPi

FortressPi is a secure, modular, self-hosted platform designed for Raspberry Pi. It integrates GPT4Free, diagnostics, watchdogs, and full backup/restore capabilities with a dynamic Flask-based UI.

---

## 📦 Features

- 🔐 Admin Dashboard (`/admin`)
- 🤖 GPT4Free UI (self-contained Docker)
- 💾 USB ISO Flasher
- 🔍 Diagnostics & Monitoring Tools
- 🛡️ Watchdog System
- 🌍 Reverse Proxy + SSL
- ☁️ Auto Backup & Restore
- 🔁 GitHub Webhook Deployment
- 🎨 Switchable Themes: Bloody + Moonlight
- 📊 Upload & Sync Panel
- 🧠 GPT Response Validator

---

## 🚀 Installation (Raspberry Pi)

1. **Transfer the ZIP & Script**
   ```bash
   scp FortressPi_v22_Integrated_FULL.zip install_fortresspi_pi_autodeploy.sh pi@<your-pi-ip>:~
   ```

2. **SSH into Pi & Install**
   ```bash
   ssh pi@<your-pi-ip>
   chmod +x install_fortresspi_pi_autodeploy.sh
   ./install_fortresspi_pi_autodeploy.sh
   ```

3. **Open in Browser**
   ```
   http://<pi-ip>:5000
   ```

---

## 🌍 CI/CD to Fly.io

1. Add `FLY_API_TOKEN` in GitHub Secrets.
2. Push to `main` to auto-deploy.

---

## 🧪 Validation

Run this before each deploy:
```bash
./validate_fortresspi_zip.sh FortressPi_v22_Integrated_FULL.zip
```

---

## 📁 Repo Files

- `FortressPi_v22_Integrated_FULL.zip`
- `install_fortresspi_pi_autodeploy.sh`
- `.github/workflows/fly-deploy.yml`
- `validate_fortresspi_zip.sh`

---

## 📖 Documentation

Full guide inside:
```
FORTRESSPI_DOCUMENTATION.pdf
```

---

MIT License © 2025 – FortressPi Team