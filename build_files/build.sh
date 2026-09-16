#!/bin/bash
set -euo pipefail

# Copy system-wide defaults and helper scripts into the image.
cp -avf /ctx/system_files/. /

# These were the early hand-built Ryoku imitation. The real upstream shell is
# installed below; do not ship two competing shell implementations.
rm -rf /etc/xdg/quickshell/bazzite-ryoku
rm -f /usr/bin/bazzite-ryoku-shell /usr/bin/bazzite-ryoku-theme /usr/bin/bazzite-ryoku-wallpaper

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
  bluez \
  bluez-tools \
  cava \
  cmake \
  cliphist \
  cairo-devel \
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
  hyprland-devel \
  hyprland-guiutils \
  hyprlock \
  hyprpaper \
  hyprpolkitagent \
  hyprshutdown \
  hyprshot \
  hyprsunset \
  ImageMagick \
  iw \
  jq \
  libqalculate \
  libdrm-devel \
  libinput-devel \
  libxkbcommon-devel \
  matugen \
  network-manager-applet \
  nftables \
  ninja-build \
  pavucontrol \
  pango-devel \
  papirus-icon-theme \
  pciutils \
  playerctl \
  pkgconf-pkg-config \
  pixman-devel \
  qalculate \
  quickshell \
  qt6-qtbase-devel \
  qt6-qtdeclarative-devel \
  qt6-qtmultimedia-devel \
  qt6-qtsvg \
  qt6-qtshadertools-devel \
  slurp \
  tesseract \
  tesseract-langpack-eng \
  uwsm \
  unzip \
  upower \
  wayland-devel \
  wayland-protocols-devel \
  wdisplays \
  wf-recorder \
  wl-clipboard \
  wtype \
  zbar \
  ddcutil \
  xdg-desktop-portal-hyprland

# Ryoku owns the notification server and shell surfaces.  The early image
# installed SwayNotificationCenter and Waybar as fallback UI; either can take
# over a session and produce the oversized, unthemed popups the user saw.
dnf5 remove -y swaync waybar || true

/ctx/install-ryoku.sh

dnf5 clean all

# Catch missing session, portal, and configuration files during the image build.
test -x /usr/bin/Hyprland
test -x /usr/bin/ryoku-shell
test -x /usr/bin/ryostore
test -x /usr/bin/ryoku
test -x /usr/bin/ryoku-volume
test -x /usr/bin/ryoku-monitor
test -x /usr/bin/ryoku-gpu
test -x /usr/bin/ryoku-power
test -x /usr/bin/bazzite-ryoku-first-login
test -x /usr/bin/bazzite-ryoku-repair
test -x /usr/bin/bazzite-display-scale
test -x /usr/bin/bazzite-ryogami
test -f /usr/share/applications/ryoku-wallpapers.desktop
grep -q 'ryoku:wallpaper-menu' /etc/xdg/hypr/hyprland.lua
grep -q 'config.json.example' /usr/bin/bazzite-ryoku-first-login
test -x /usr/bin/powerprofilesctl
test -x /usr/bin/wdisplays
for tool in cava convert ddcutil hyprsunset jq powerprofilesctl qalc tesseract upower wf-recorder wtype zbarimg; do
  printf 'Validating runtime tool: %s\n' "$tool"
  command -v "$tool" >/dev/null
done
test -f /usr/lib/systemd/user/ryoku-shell.service
test -f /usr/lib64/libfprint-2-tod.so.1
test -d /usr/lib64/libfprint-2/tod-1
test -f /usr/lib64/libfprint-2/tod-1/libfprint-2-tod-1-broadcom.so
test -f /var/lib/fprint/fw/bcmDeviceFirmwareCitadel_7.bin
test -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
test -x /usr/libexec/xdg-desktop-portal-hyprland
test -f /etc/xdg/hypr/hyprland.lua
test -f /usr/share/icons/Papirus/index.theme
grep -q '^    lock_cmd = ryoku-shell lock$' /etc/xdg/hypr/hypridle.conf
grep -q '^    before_sleep_cmd = ryoku-shell lock$' /etc/xdg/hypr/hypridle.conf
test ! -e /etc/xdg/quickshell/bazzite-ryoku
test ! -e /usr/bin/bazzite-ryoku-shell
test -f /usr/share/ryoku-source/ryoku/shell/quickshell/shell/shell.qml
test -f /usr/share/ryoku-source/ryoku/hub/quickshell/shell.qml
test -f /etc/xdg/quickshell/ryostore/shell.qml
grep -q '^Exec=.*qs -c ryostore$' /usr/share/applications/ryostore.desktop
grep -q '^Exec=ryoku-shell hub open$' /usr/share/applications/ryoku-hub.desktop
grep -q '^org.freedesktop.impl.portal.ScreenCast=hyprland' /etc/xdg/xdg-desktop-portal/hyprland-portals.conf
test -f /etc/xdg/waybar/config.jsonc
