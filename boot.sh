#!/bin/bash

set -o pipefail

ascii_art='
 ██████╗ ███╗   ███╗ █████╗ ██████╗ ██╗
██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██║
██║   ██║██╔████╔██║███████║██████╔╝██║
██║   ██║██║╚██╔╝██║██╔══██║██╔══██╗██║
╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██║██║
 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
'
clear
echo -e "\n$ascii_art\n"

sudo apt-get update >/dev/null
sudo apt-get install -y git >/dev/null

# Use custom repo if specified, otherwise use default
OMARI_REPO="${OMARI_REPO:-omakasui/omari}"

# Use custom brand if specified, otherwise use default
OMARI_BRAND="${OMARI_BRAND:-Omari}"

echo -e "\nCloning $OMARI_BRAND from: https://github.com/${OMARI_REPO}.git"
rm -rf ~/.local/share/omari
git clone https://github.com/$OMARI_REPO.git ~/.local/share/omari >/dev/null

# Use custom branch if instructed, otherwise default to main
OMARI_REF="${OMARI_REF:-main}"
echo -e "\e[32mUsing branch: $OMARI_REF\e[0m"
cd ~/.local/share/omari
git fetch origin "${OMARI_REF}" && git checkout "${OMARI_REF}"
cd -

# Set channel based on branch (dev branch uses dev channel, everything else uses stable)
if [[ $OMARI_REF == "dev" ]]; then
  export OMARI_CHANNEL=dev
else
  export OMARI_CHANNEL=stable
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omari/install.sh