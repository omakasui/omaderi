# Install omari SDDM theme
omari-refresh-sddm

# Setup SDDM login service
sudo mkdir -p /etc/sddm.conf.d
if [[ ! -f /etc/sddm.conf.d/theme.conf ]]; then
  cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf
[Theme]
Current=omari
EOF
fi

# Debian 13 ships the greeter as sddm-greeter-qt6, but SDDM looks for sddm-greeter
if [[ ! -e /usr/bin/sddm-greeter ]] && [[ -f /usr/bin/sddm-greeter-qt6 ]]; then
  sudo ln -s /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter
fi

# Don't use chrootable here as --now will cause issues for manual installs
sudo systemctl enable sddm.service
