# Set XCompose
if [[ -f ~/.XCompose ]]; then
  rm ~/.XCompose
fi

tee ~/.XCompose >/dev/null <<EOF
# Run omari-restart-xcompose to apply changes

# Include fast emoji access
include "%H/.local/share/omari/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$OMARI_USER_NAME"
<Multi_key> <space> <e> : "$OMARI_USER_EMAIL"
EOF

# Refresh XCompose
omari-restart-xcompose