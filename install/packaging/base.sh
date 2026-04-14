# Install packages that may pull unwanted recommends (e.g. gdm3)
mapfile -t lock_packages < <(grep -v '^#' "$OMARI_INSTALL/omari-base.lock.packages" | grep -v '^$')
omari-pkg-add --no-recommends "${lock_packages[@]}"

# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMARI_INSTALL/omari-base.packages" | grep -v '^$')
omari-pkg-add "${packages[@]}"
