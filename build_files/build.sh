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

# Complete, usable first-login environment. KDE remains installed as a safe
# fallback in SDDM.
dnf5 install -y \
  brightnessctl \
  cliphist \
  fuzzel \
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
  playerctl \
  quickshell \
  slurp \
  swaync \
  uwsm \
  waybar \
  wl-clipboard \
  xdg-desktop-portal-hyprland

dnf5 clean all

# Catch missing session, portal, and configuration files during the image build.
test -x /usr/bin/Hyprland
test -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
test -x /usr/libexec/xdg-desktop-portal-hyprland
test -f /etc/xdg/hypr/hyprland.lua
test -f /etc/xdg/quickshell/bazzite-ryoku/shell.qml
test -x /usr/bin/bazzite-ryoku-shell
test -f /etc/xdg/waybar/config.jsonc
