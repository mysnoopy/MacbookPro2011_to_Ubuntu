#!/bin/bash

# --- OCTOIX AI: 2011 MacBook Pro Ubuntu Server "Golden Image" Setup ---
# Features: Interactive IP config, Headless, Dual-IP, No-Sleep, 8GB Swap, Fan Control

echo "==============================================="
echo "         Server Setup (Interactive IP)         "
echo "==============================================="

# 1. Collect User Input
read -p "Enter Ethernet Static IP (e.g., 10.166.1.40): " eth_ip
read -p "Enter WiFi Static IP (e.g., 10.166.1.41): " wifi_ip
read -p "Enter Gateway/Router IP (e.g., 10.166.1.1): " gateway_ip
read -p "Enter WiFi SSID: " wifi_ssid
read -s -p "Enter WiFi Password: " wifi_pass
echo -e "\n"

# Preview for confirmation
echo "--- Configuration Summary ---"
echo "Ethernet: $eth_ip/24"
echo "WiFi:     $wifi_ip/24"
echo "Gateway:  $gateway_ip"
echo "SSID:     $wifi_ssid"
echo "-----------------------------"
read -p "Does this look correct? (y/n): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Aborting setup."
    exit 1
fi

echo "Starting installation... (Keep Ethernet cable plugged in!)"

# 2. Install Drivers and Power Tools
sudo apt update
sudo apt install -y bcmwl-kernel-source mbpfan cpufrequtils ethtool

# 3. Create 8GB Swap File
echo "Creating 8GB Swap File... this may take a minute."
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1G count=8
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 4. Force Broadcom Driver at Early Boot
if ! grep -q "wl" /etc/modules; then
    echo "wl" | sudo tee -a /etc/modules
fi

# 5. Disable Sleep & Boot Hangs
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo systemctl mask systemd-networkd-wait-online.service

# 6. Configure Lid Switch (Ignore Close Event)
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/#LidSwitchIgnoreInhibit=yes/LidSwitchIgnoreInhibit=no/' /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

# 7. Disable IPv6 (Fixes SF ISP update timeouts)
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 8. Generate Static Netplan with Metrics
echo "Generating /etc/netplan/00-installer-config.yaml..."
sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0f0:
      dhcp4: no
      addresses: [$eth_ip/24]
      routes:
        - to: default
          via: $gateway_ip
          metric: 100
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
  wifis:
    wlp3s0:
      optional: true
      dhcp4: no
      addresses: [$wifi_ip/24]
      access-points:
        "$wifi_ssid":
          password: "$wifi_pass"
EOF

# 9. Optimization (Fan Control & CPU Performance)
sudo systemctl enable mbpfan
sudo systemctl start mbpfan
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils

echo "==============================================="
echo "Setup Complete! Giving the driver 10s to wake up..."
sleep 10
sudo netplan apply
echo "System will reboot in 5 seconds to finalize..."
sleep 5
sudo reboot
