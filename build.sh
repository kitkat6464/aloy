#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

# Remove Fedora kernel & remove leftover files
dnf -y remove kernel* && rm -r -f /usr/lib/modules/*

# Enable repos    
dnf -y copr enable bieszczaders/kernel-cachyos
dnf -y copr enable bieszczaders/kernel-cachyos-addons

# Install CachyOS kernel & akmods

# create a shims to bypass kernel install triggering dracut/rpm-ostree
# seems to be minimal impact, but allows progress on build
cd /usr/lib/kernel/install.d \
&& mv 05-rpmostree.install 05-rpmostree.install.bak \
&& mv 50-dracut.install 50-dracut.install.bak \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
&& chmod +x  05-rpmostree.install 50-dracut.install

# install kernel
dnf -y install --setopt=install_weak_deps=False \
  kernel-cachyos \
  kernel-cachyos-core \
  kernel-cachyos-devel \
  kernel-cachyos-devel-matched \
  kernel-cachyos-modules \
  akmods

# restore kernel install shim
mv -f 05-rpmostree.install.bak 05-rpmostree.install \
&& mv -f 50-dracut.install.bak 50-dracut.install
cd -

# Install SCX stuff
dnf -y install --setopt=install_weak_deps=False \
  scx-scheds \
  scx-manager

# Install cachyos-settings over zram-generator-defaults
dnf -y swap zram-generator-defaults cachyos-settings

# Disable repos    
dnf -y copr disable bieszczaders/kernel-cachyos
dnf -y copr disable bieszczaders/kernel-cachyos-addons
