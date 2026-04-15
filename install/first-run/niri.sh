# Mask the system-provided waybar.service.
# Debian enables it globally (/usr/lib/systemd/user/), so --user disable is not enough
# (systemd warns "enabled in global scope" and still starts it).
# Masking creates ~/.config/systemd/user/waybar.service -> /dev/null which takes
# precedence over the global unit. Niri manages waybar via spawn-sh-at-startup.
systemctl --user mask --now waybar.service
