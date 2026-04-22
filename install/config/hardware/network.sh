# Enable iwd's built-in DHCP on wifi interfaces.
# Ethernet remains managed by ifupdown (/etc/network/interfaces).
sudo mkdir -p /etc/iwd
if [[ ! -f /etc/iwd/main.conf ]]; then
  printf '[General]\nEnableNetworkConfiguration=true\n\n[Network]\nEnableIPv6=true\n' \
    | sudo tee /etc/iwd/main.conf > /dev/null
fi

# Migrate saved networks from wpa_supplicant to iwd PSK profiles.
# Runs even when currently on ethernet so wifi is ready at next boot.
WPA_CONF="${WPA_CONF:-/etc/wpa_supplicant/wpa_supplicant.conf}"

if [[ -f "$WPA_CONF" ]]; then
  sudo mkdir -p /var/lib/iwd

  in_block=0; ssid=""; psk=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*network=\{ ]]; then
      in_block=1; ssid=""; psk=""
      continue
    fi

    if (( in_block )); then
      [[ "$line" =~ ^[[:space:]]*ssid=\"(.+)\" ]]          && ssid="${BASH_REMATCH[1]}"
      [[ "$line" =~ ^[[:space:]]*psk=([0-9a-fA-F]{64})$ ]] && psk="${BASH_REMATCH[1]}"
      [[ "$line" =~ ^[[:space:]]*psk=\"(.+)\" ]]           && psk="plain:${BASH_REMATCH[1]}"

      if [[ "$line" =~ ^\} && -n "$ssid" && -n "$psk" ]]; then
        in_block=0
        if [[ "$psk" == plain:* ]]; then
          printf '[Security]\nPassphrase=%s\n\n[Settings]\nAutoConnect=true\n' \
            "${psk#plain:}" | sudo tee "/var/lib/iwd/${ssid}.psk" > /dev/null
        else
          printf '[Security]\nPreSharedKey=%s\n\n[Settings]\nAutoConnect=true\n' \
            "$psk" | sudo tee "/var/lib/iwd/${ssid}.psk" > /dev/null
        fi
        sudo chmod 600 "/var/lib/iwd/${ssid}.psk"
        echo "Migrated: $ssid"
      fi
    fi
  done < "$WPA_CONF"
fi

# Replace wpa_supplicant with iwd
sudo systemctl stop wpa_supplicant 2>/dev/null || true
sudo systemctl disable wpa_supplicant 2>/dev/null || true
sudo systemctl mask wpa_supplicant

# Ensure iwd service will be started
sudo systemctl enable iwd

# Prevent boot timeout waiting for network-online
sudo systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
sudo systemctl mask systemd-networkd-wait-online.service
