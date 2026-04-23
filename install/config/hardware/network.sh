# Write iwd main config - always overwrite to guarantee EnableNetworkConfiguration.
sudo mkdir -p /etc/iwd
sudo tee /etc/iwd/main.conf > /dev/null << 'EOF'
[General]
EnableNetworkConfiguration=true

[Network]
EnableIPv6=true
EOF

sudo mkdir -p /var/lib/iwd

# Migrate wifi credentials from /etc/network/interfaces to iwd PSK profiles.
_write_iwd_profile() {
  local ssid="$1" psk="$2" profile

  if [[ "$ssid" =~ ^[A-Za-z0-9_-]+$ ]]; then
    profile="/var/lib/iwd/${ssid}.psk"
  else
    profile="/var/lib/iwd/=$(printf '%s' "$ssid" | od -A n -t x1 | tr -d ' \n').psk"
  fi

  if [[ "$psk" =~ ^[0-9a-fA-F]{64}$ ]]; then
    printf '[Security]\nPreSharedKey=%s\n\n[Settings]\nAutoConnect=true\n' "$psk"
  else
    printf '[Security]\nPassphrase=%s\n\n[Settings]\nAutoConnect=true\n' "$psk"
  fi | sudo tee "$profile" > /dev/null

  sudo chmod 600 "$profile"
  echo "Migrated: $ssid -> $profile"
}

if [[ -f /etc/network/interfaces ]]; then
  ssid=""; psk=""

  # FIX: Use proper regex for stanza detection
  # In Bash, [[ =~ ]] uses ERE. [^[:space:]] does NOT work as expected!
  # Use explicit check: line starts with non-space and non-# character
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect new stanza: line starts with a letter (not space/tab/#)
    if [[ "$line" =~ ^[a-zA-Z] ]]; then
      [[ -n "$ssid" && -n "$psk" ]] && _write_iwd_profile "$ssid" "$psk"
      ssid=""; psk=""
    fi

    if [[ "$line" =~ ^[[:space:]]+wpa-ssid[[:space:]]+\"([^\"]+)\" ]]; then
      ssid="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+wpa-ssid[[:space:]]+([^[:space:]#]+) ]]; then
      ssid="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+wpa-psk[[:space:]]+([^[:space:]#]+) ]]; then
      psk="${BASH_REMATCH[1]}"
    fi
  done < /etc/network/interfaces

  # Flush final profile
  [[ -n "$ssid" && -n "$psk" ]] && _write_iwd_profile "$ssid" "$psk"
fi

# Remove wifi interfaces from /etc/network/interfaces to prevent conflicts with iwd.
wifi_ifaces=()
for p in /sys/class/net/*/wireless; do
  [[ -d "$p" ]] || continue
  iface="${p%/wireless}"
  iface="${iface##*/}"
  wifi_ifaces+=("$iface")
done

if [[ -f /etc/network/interfaces && ${#wifi_ifaces[@]} -gt 0 ]]; then
  # Single-pass awk: remove all wifi stanzas at once
  awk_script='BEGIN { for(i=1;i<=ARGC;i++) w[ARGV[i]]=1; ARGC=1 }
    /^(allow-hotplug|auto)[[:space:]]/ { if(w[$2]) next }
    /^iface[[:space:]]/ { skip=(w[$2]?1:0); if(skip) next }
    skip && (/^[[:space:]]/ || /^$/) { next }
    { skip=0; print }'

  sudo awk "$awk_script" /etc/network/interfaces "${wifi_ifaces[@]}" | \
    sudo tee /etc/network/interfaces.tmp > /dev/null
  sudo mv /etc/network/interfaces.tmp /etc/network/interfaces
fi

# Disable wpa_supplicant and mask all related services to prevent conflicts with iwd.
sudo systemctl disable wpa_supplicant 2>/dev/null || true
sudo systemctl mask wpa_supplicant

for p in /sys/class/net/*/wireless; do
  [[ -d "$p" ]] || continue
  iface="${p%/wireless}"
  iface="${iface##*/}"
  sudo systemctl mask "wpa_supplicant@${iface}.service" 2>/dev/null || true
done

sudo systemctl unmask iwd
sudo systemctl enable iwd

# systemd-resolved is a separate package on Debian — only enable if installed.
if systemctl cat systemd-resolved &>/dev/null; then
  sudo systemctl unmask systemd-resolved
  sudo systemctl enable systemd-resolved
fi

sudo systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
sudo systemctl mask systemd-networkd-wait-online.service