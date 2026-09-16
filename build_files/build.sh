#!/bin/bash
set -euo pipefail

# Copy system-wide defaults and helper scripts into the image.
cp -avf /ctx/system_files/. /

# Fedora 43 no longer carries Hyprland. This maintained COPR provides current
# Fedora 43/44 builds for both x86_64 and aarch64.
fedora_version="$(. /etc/os-release && printf '%s' "$VERSION_ID")"
copr_url="https://copr.fedorainfracloud.org/coprs/nett00n/hyprland/repo/fedora-${fedora_version}/nett00n-hyprland-fedora-${fedora_version}.repo"
curl --fail --location --silent --show-error "$copr_url" \
  --output /etc/yum.repos.d/_copr_nett00n-hyprland.repo

# Dell's Broadcom ControlVault 3 reader (0a5c:5843) needs the vendor TOD
# module and firmware; Fedora's standard libfprint cannot see this device.
fprint_copr_url="https://copr.fedorainfracloud.org/coprs/grahamwhiteuk/libfprint-tod/repo/fedora-${fedora_version}/grahamwhiteuk-libfprint-tod-fedora-${fedora_version}.repo"
curl --fail --location --silent --show-error "$fprint_copr_url" \
  --output /etc/yum.repos.d/_copr_grahamwhiteuk-libfprint-tod.repo

dnf5 swap -y libfprint libfprint-tod

# Complete, usable first-login environment. KDE remains installed as a safe
# fallback in SDDM.
dnf5 install -y \
  brightnessctl \
  cmake \
  cliphist \
  gcc-c++ \
  golang \
  fuzzel \
  fprintd \
  fprintd-pam \
  libfprint-2-tod1-broadcom \
  libfprint-tod-selinux \
  grim \
  hypridle \
  hyprland \
  hyprland-guiutils \
  hyprlock \
  hyprpaper \
  hyprpolkitagent \
  hyprshutdown \
  hyprshot \
  network-manager-applet \
  ninja-build \
  pavucontrol \
  playerctl \
  quickshell \
  qt6-qtbase-devel \
  qt6-qtdeclarative-devel \
  qt6-qtmultimedia-devel \
  qt6-qtshadertools-devel \
  slurp \
  swaync \
  uwsm \
  waybar \
  wayland-devel \
  wayland-protocols-devel \
  wdisplays \
  wl-clipboard \
  xdg-desktop-portal-hyprland

/ctx/install-ryoku.sh

dnf5 clean all

# Catch missing session, portal, and configuration files during the image build.
test -x /usr/bin/Hyprland
test -x /usr/bin/ryoku-shell
test -x /usr/bin/bazzite-ryoku-first-login
test -x /usr/bin/wdisplays
test -f /usr/lib/systemd/user/ryoku-shell.service
test -f /usr/lib64/libfprint-2-tod.so.1
test -d /usr/lib64/libfprint-2/tod-1
test -f /usr/lib64/libfprint-2/tod-1/libfprint-2-tod-1-broadcom.so
test -f /var/lib/fprint/fw/bcmDeviceFirmwareCitadel_7.bin
test -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
test -x /usr/libexec/xdg-desktop-portal-hyprland
test -f /etc/xdg/hypr/hyprland.lua
test -f /etc/xdg/quickshell/bazzite-ryoku/shell.qml
test -x /usr/bin/bazzite-ryoku-shell
test -x /usr/bin/bazzite-ryoku-theme
test -x /usr/bin/bazzite-ryoku-wallpaper
test -f /etc/xdg/waybar/config.jsonc

# Validate the QML during the image build when Fedora's Qt tooling is present.
if command -v qmllint >/dev/null 2>&1; then
  qmllint /etc/xdg/quickshell/bazzite-ryoku/shell.qml
fi
