# Octoix AI Server Setup  
## 2011 MacBook Pro Ubuntu Server "Golden Image"

This script prepares a **2011 MacBook Pro** to run as a **headless Ubuntu AI / home-lab server** with optimized networking, power management, and system performance.

It is designed for **Octoix AI node deployments**, home labs, Kubernetes edge nodes, or lightweight private AI infrastructure.

---

## 🚀 Features

- Interactive **Dual Static IP Configuration**
  - Ethernet (Primary)
  - WiFi (Backup / Failover)
- Headless Server Optimization
  - Disable Sleep / Lid Close Suspend
- 8GB Swap File for low-RAM systems
- Broadcom WiFi Driver auto-load
- IPv6 disabled (ISP timeout mitigation)
- CPU Performance Mode enabled
- Automatic Fan Control via `mbpfan`
- Boot delay mitigation fixes
- Netplan static routing with metrics

---

## 🖥️ Supported Hardware

- MacBook Pro 2011 (13", 15", or 17")
- Broadcom WiFi chipset (BCM4331)
- Ubuntu Server 24.04 LTS (Tested)
- Works best with:
  - 8GB+ RAM
  - SSD storage

---

## ⚙️ What This Script Configures

### Networking
- Static IP Ethernet (primary route)
- Static IP WiFi (secondary optional route)
- Custom gateway
- Google + Cloudflare DNS
- Route metric prioritization (Ethernet `100`, WiFi `600`)

### Power & Stability
- Disables suspend / sleep / hibernate targets via `systemctl`
- Ignores lid close events in `logind.conf`
- Masks `systemd-networkd-wait-online` to prevent network boot hangs

### Performance Optimization
- CPU governor set to **performance** via `cpufrequtils`
- Fan thermal control enabled
- 8GB swap configured for AI/Docker workloads

### Kernel / Driver Fixes
- Broadcom `wl` driver forced at boot via `/etc/modules`
- IPv6 disabled via `sysctl.conf` (common ISP issue workaround)

---

## 📋 Requirements

Before running:

- Fresh Ubuntu Server 24.04 LTS install
- **Ethernet cable plugged in** (Required to fetch the proprietary WiFi driver)
- User with `sudo` privileges
- Internet connectivity

---

## ▶️ Usage

### 1. Transfer the Script to the Server
Since a fresh install on a new SSD won't have the Broadcom drivers yet, use your local network to push the script to the Mac via Ethernet.

Find the temporary DHCP IP of the Mac:
`ip addr show enp2s0f0`

From your main computer, securely copy the file over:
`scp setup_mac_server.sh username@<TEMP_IP>:~/`

### 2. Make the Script Executable
Log into the server and grant execution permissions:
`chmod +x setup_mac_server.sh`

### 3. Run the Installer
Execute the script. You will be prompted to enter your desired static IPs and WiFi credentials before the system configures itself.
`./setup_mac_server.sh`

*Note: The system will automatically reboot upon completion.*

---

## 🛠️ Post-Installation & Troubleshooting

### Clear SSH Fingerprints
Because this installs on a new SSD, the server's cryptographic identity will change. Run this on your main computer to clear the old keys and prevent connection errors:
`ssh-keygen -R <YOUR_ETHERNET_IP>`
`ssh-keygen -R <YOUR_WIFI_IP>`

### Verify System Health
Once rebooted, you can verify the server's thermal status and lid state:

**Check CPU Temperature:**
`cat /sys/class/thermal/thermal_zone0/temp`
*(Divide the output by 1000 to get degrees Celsius).*

**Verify Clamshell Mode (Lid Status):**
`cat /proc/acpi/button/lid/LID0/state`
