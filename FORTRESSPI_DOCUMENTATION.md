# FortressPi Documentation

## Overview
FortressPi is a modular, secure, and portable web-based system for AI tools, dashboards, watchdogs, and system control.

---

## 🚀 Setup Options

### Option 1: APT Installation
```bash
sudo dpkg -i fortresspi-dashboard_2.0_all.deb
sudo dpkg -i fortresspi-diagnostics_1.0_all.deb
```

### Option 2: USB / ISO
Use the provided `.iso` or `auto_deploy_fortresspi.sh` script.

---

## 🔧 Modules Included
- GPT-4Free Web UI
- Admin Dashboard `/admin`
- Metrics & Service Tests
- Watchdog with auto-restart
- Webmin integration
- CLI Diagnostics Tool: `fortresspi`

---

## 🔐 Security Recommendations
- Change admin password on first login
- Configure UFW to expose only required ports
- Use HTTPS for Webmin and Dashboard

---

## 📦 Maintenance & Update
Use CLI:
```bash
fortresspi status
fortresspi check-update
```

To rebuild:
```bash
./fortresspi_local_builder.sh
```

---

## 🧠 FAQ

**Q: How do I reset the dashboard admin password?**  
A: Run `reset_admin.sh` from the dashboard folder.

**Q: Does it work offline?**  
A: Yes, with pre-downloaded `.deb` and `.zip` files.

---

# 📜 Changelog

## v2.0
- Added diagnostics CLI + dashboard tabs
- Integrated AppImage, APT repo, signed `.deb`
- New dark theme (dashboard)

## v1.0
- Initial core module system and deploy scripts
