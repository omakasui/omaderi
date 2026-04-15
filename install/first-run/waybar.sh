if systemctl --user is-enabled waybar.service &>/dev/null; then
  systemctl --user disable --now waybar.service
fi
