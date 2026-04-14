# Copy over Omari configs
mkdir -p ~/.config
cp -R ~/.local/share/omari/config/* ~/.config/

# Configure the bash shell using Omari defaults
cp ~/.local/share/omari/default/bashrc ~/.bashrc