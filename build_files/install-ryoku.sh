#!/bin/bash
set -euo pipefail

# Pin the upstream desktop so every image build produces the same shell.
ryoku_commit="e76a32d474a467d45e0dc67a46d1c6057d024f5b"
src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT
export GOCACHE=/tmp/ryoku-go-cache
export GOPATH=/tmp/ryoku-go
export HOME=/tmp/ryoku-build-home
mkdir -p "$GOCACHE" "$GOPATH" "$HOME"

curl --fail --location --silent --show-error \
  "https://github.com/Ryoku-dev/ryoku-arch/archive/${ryoku_commit}.tar.gz" \
  | tar -xz --strip-components=1 -C "$src"

# Flatpak exports its application icons outside the normal XDG icon roots.
# Include both the system and per-user export trees when Ryoku builds the dock
# index; otherwise native apps resolve while many Flatpak app tiles are blank.
sed -i '/filepath.Join(home, ".icons"),/a\        "/var/lib/flatpak/exports/share/icons",\
        filepath.Join(home, ".local", "share", "flatpak", "exports", "share", "icons"),' \
  "$src/ryoku/shell/ipc/icons.go"

# Ryoku's geometry assumes its brand and icon fonts. Without them Qt silently
# substitutes wider system faces, making the bar spacing and symbols look wrong.
google_fonts_commit="1ac2012c34919f5fa2675aacf723fa98edb30b5f"
material_icons_commit="40a7a292a79d9394157e1ea24f83d52d5e17c556"
nerd_fonts_version="3.5.1"
font_dir="/usr/share/fonts/ryoku"
install -d "$font_dir" /usr/share/licenses/ryoku-fonts
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/fonts/${google_fonts_commit}/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf" \
  -o "$font_dir/SpaceGrotesk.ttf"
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/fonts/${google_fonts_commit}/ofl/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf" \
  -o "$font_dir/Fraunces.ttf"
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/fonts/${google_fonts_commit}/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf" \
  -o "$font_dir/Inter.ttf"
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/material-design-icons/${material_icons_commit}/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" \
  -o "$font_dir/MaterialSymbolsRounded.ttf"
for family in SpaceMono JetBrainsMono; do
  curl --fail --location --silent --show-error \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v${nerd_fonts_version}/${family}.zip" \
    -o "$src/${family}.zip"
  unzip -q -j "$src/${family}.zip" '*.ttf' -d "$font_dir/$family"
done
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/fonts/${google_fonts_commit}/ofl/spacegrotesk/OFL.txt" \
  -o /usr/share/licenses/ryoku-fonts/OFL-Space-Grotesk.txt
curl --fail --location --silent --show-error \
  "https://raw.githubusercontent.com/google/material-design-icons/${material_icons_commit}/LICENSE" \
  -o /usr/share/licenses/ryoku-fonts/Apache-2.0-Material-Symbols.txt
fc-cache -f

# Native shell controller and wallpaper service.
(cd "$src/ryoku/shell/ipc" && CGO_ENABLED=0 go build -trimpath -mod=vendor -o /usr/bin/ryoku-shell .)
(cd "$src/ryoku/shell/ryogami/daemon" && CGO_ENABLED=0 go build -trimpath -o /usr/bin/ryogami .)
# Settings Hub backend used by the real Ryoku configuration window.
(cd "$src/ryoku/hub/backend" && CGO_ENABLED=0 go build -trimpath -o /usr/bin/ryoku-hub .)
# RyoStore is a separate Quickshell application and Go data backend. Installing
# the shell tree alone does not make the Store launcher or its catalogue work.
(cd "$src/ryoku/apps/ryostore/backend" && CGO_ENABLED=0 go build -trimpath -o /usr/bin/ryostore .)
# The Store and Settings use this for version/compatibility checks and desktop
# maintenance. Build the pinned CLI from the same source as the shell.
(cd "$src/ryoku/cli" && CGO_ENABLED=0 go build -trimpath -mod=vendor -o /usr/bin/ryoku .)

# Ryogami's upstream daemon launches its wallpaper UI as `quickshell`, while
# Fedora names the same executable `qs`.  Keep the upstream app intact and
# expose the name it requests so the real Ryogami Wallpapers window can start.
if ! command -v quickshell >/dev/null; then
  ln -s /usr/bin/qs /usr/bin/quickshell
fi

# The compiled metaball renderer creates Ryoku's floating frame shapes.
RYOKU_BLOBS_BUILD="$src/build-blobs" \
  "$src/ryoku/shell/plugin/build.sh" /usr/lib/qt6/qml

# Keep the pinned desktop tree intact. The controller uses it as its QML source
# so Bazzite does not need Arch's package layout or per-user generated copies.
install -d /usr/share/ryoku-source
cp -a "$src/ryoku" /usr/share/ryoku-source/
# RYOKU_SHELL_DIR points the running shell at this preserved tree. QML helpers
# consequently look for the compiled controller beside the source; provide the
# deployed binary there so the dock and launcher can build their icon index.
ln -s /usr/bin/ryoku-shell /usr/share/ryoku-source/ryoku/shell/ipc/ryoku-shell

# Bazzite's / mount is the immutable deployment. Report the user's writable
# filesystem in the storage card, which is the meaningful capacity on bootc.
sed -i 's|df -B1 --output=used,size / 2>/dev/null|df -B1 --output=used,size \\\"$HOME\\\" 2>/dev/null|' \
  /usr/share/ryoku-source/ryoku/shell/quickshell/shell/services/StatsFeed.qml
install -d /usr/lib/qt6/qml/Ryoku/Ui /usr/lib/qt6/qml/Ryoku/FrameBars /usr/lib/qt6/qml/Ryoku/PluginKit
cp -a "$src/ryoku/ui/." /usr/lib/qt6/qml/Ryoku/Ui/
cp -a "$src/ryoku/shell/framebars/." /usr/lib/qt6/qml/Ryoku/FrameBars/
cp -a "$src/ryoku/shell/quickshell/plugins/kit/." /usr/lib/qt6/qml/Ryoku/PluginKit/

install -d /etc/xdg/quickshell/ryostore /etc/xdg/xdg-desktop-portal /usr/share/applications /usr/share/icons/hicolor/scalable/apps
cp -a "$src/ryoku/apps/ryostore/quickshell/." /etc/xdg/quickshell/ryostore/
install -Dm644 "$src/ryoku/apps/ryostore/ryostore.desktop" /usr/share/applications/ryostore.desktop
install -Dm644 "$src/ryoku/apps/ryostore/quickshell/logo.svg" /usr/share/icons/hicolor/scalable/apps/ryostore.svg
install -Dm644 "$src/ryoku/hub/ryoku-hub.desktop" /usr/share/applications/ryoku-hub.desktop
install -Dm644 "$src/ryoku/assets/brand/logo.svg" /usr/share/icons/hicolor/scalable/apps/ryoku-hub.svg
install -Dm644 "$src/ryoku/shell/portals/hyprland-portals.conf" /etc/xdg/xdg-desktop-portal/hyprland-portals.conf

# Ship Ryoku's complete Hyprland configuration as the single source of truth.
# The prior hand-written starter config bypassed `settings.lua`, which meant
# Hub changes and wallpaper colours were immediately overwritten by defaults.
install -d /usr/share/ryoku/hyprland-default /usr/lib/systemd/user
cp -a "$src/ryoku/hyprland/." /usr/share/ryoku/hyprland-default/
cp -a "$src/ryoku/shell/systemd/user/." /usr/lib/systemd/user/
# The portable image stores QML in /usr/share/ryoku-source rather than Arch's
# package path.  Keep those two unit overrides after copying upstream's units.
install -Dm644 /ctx/system_files/usr/lib/systemd/user/ryoku-shell.service /usr/lib/systemd/user/ryoku-shell.service
install -Dm644 /ctx/system_files/usr/lib/systemd/user/ryogami.service /usr/lib/systemd/user/ryogami.service

# Keep the showroom wallpaper workflow the user requested: compact picker,
# random wallpaper, then the separate full Ryogami library.
sed -i \
  's|hl.bind(K(mod .. " + W"),         hl.dsp.exec_cmd("ryogami wallpaper ui"))|hl.bind(K(mod .. " + W"),         hl.dsp.exec_cmd("ryoku-shell menu wallpaper"))|' \
  /usr/share/ryoku/hyprland-default/modules/binds.lua
sed -i \
  '/hl.bind(K(mod .. " + SHIFT + W"), hl.dsp.exec_cmd("ryogami wallpaper random"))/a hl.bind(K(mod .. " + ALT + W"),   hl.dsp.exec_cmd("ryogami wallpaper ui"))' \
  /usr/share/ryoku/hyprland-default/modules/binds.lua

# Build the two Ryoku plugin packs against the exact Hyprland ABI in this
# image.  They are optional effects, but the Hub exposes them and the earlier
# image falsely reported the packages as missing because it shipped no plugin
# binaries at all.
plugin_dir=/usr/lib/hyprland/plugins
install -d "$plugin_dir"
hypr_version="$(pkg-config --modversion hyprland)"
plugins_src="$src/hyprland-plugins"
git clone --depth 1 https://github.com/hyprwm/hyprland-plugins.git "$plugins_src"
plugins_commit="$(grep -F "$hypr_version" "$plugins_src/hyprpm.toml" | grep -oE '[0-9a-f]{40}' | sed -n '2p')"
if [[ -n "$plugins_commit" ]]; then
  git -C "$plugins_src" fetch --depth 1 origin "$plugins_commit"
  git -C "$plugins_src" checkout -q "$plugins_commit"
fi
make -C "$plugins_src/hyprbars" all
make -C "$plugins_src/hyprfocus" all
install -Dm755 "$plugins_src/hyprbars/hyprbars.so" "$plugin_dir/hyprbars.so"
install -Dm755 "$plugins_src/hyprfocus/hyprfocus.so" "$plugin_dir/hyprfocus.so"

glass_src="$src/hyprglass"
git clone --depth 1 https://github.com/hyprnux/hyprglass.git "$glass_src"
glass_commit="$(grep -F "$hypr_version" "$glass_src/hyprpm.toml" | grep -oE '[0-9a-f]{40}' | sed -n '2p')"
if [[ -n "$glass_commit" ]]; then
  git -C "$glass_src" fetch --depth 1 origin "$glass_commit"
  git -C "$glass_src" checkout -q "$glass_commit"
fi
make -C "$glass_src"
install -Dm755 "$glass_src/hyprglass.so" "$plugin_dir/hyprglass.so"

install -Dm755 "$src/ryoku/shell/scripts/ryoku-reload-cover" /usr/bin/ryoku-reload-cover
install -Dm755 "$src/ryoku/shell/scripts/ryostage" /usr/bin/ryostage
install -Dm755 "$src/ryoku/shell/scripts/ryoku-eq" /usr/bin/ryoku-eq
install -Dm755 "$src/ryoku/shell/quickshell/plugins/ryoku-plugins-place" /usr/bin/ryoku-plugins-place
for helper in "$src"/ryoku/hyprland/scripts/ryoku-*; do
  install -Dm755 "$helper" "/usr/bin/$(basename "$helper")"
done

# Portable hardware backends used by the Displays, Graphics, and Performance
# pages in Ryoku Settings. Their probes read Hyprland/sysfs; privileged writes
# remain constrained by Ryoku's narrow polkit rules.
install -Dm755 "$src/system/hardware/display/ryoku-monitor" /usr/bin/ryoku-monitor
install -Dm755 "$src/system/hardware/gpu/ryoku-gpu" /usr/bin/ryoku-gpu
install -Dm755 "$src/system/hardware/gpu/ryoku-gpu-detect" /usr/bin/ryoku-gpu-detect
install -Dm644 "$src/system/hardware/gpu/90-ryoku-gpu.rules" /usr/lib/udev/rules.d/90-ryoku-gpu.rules
install -Dm755 "$src/system/hardware/power/ryoku-power" /usr/bin/ryoku-power
install -Dm644 "$src/system/hardware/power/47-ryoku-power.rules" /usr/share/polkit-1/rules.d/47-ryoku-power.rules

# Wallpaper picker, stock wallpapers, and the real animated lock surface.
install -d /usr/share/ryogami /usr/share/ryoku/wallpapers /usr/share/ryoku/lockscreen
cp -a "$src/ryoku/shell/ryogami/wall-ui/." /usr/share/ryogami/
cp -a "$src/ryoku/assets/wallpapers/." /usr/share/ryoku/wallpapers/
cp -a "$src/ryoku/lockscreen/qylock/." /usr/share/ryoku/lockscreen/qylock/

# Upstream Arch uses a third-party simultaneous password/fingerprint PAM
# module. Fedora provides the supported pam_fprintd module instead. Without
# this substitution qylock displays correctly but every fingerprint PAM
# conversation fails because the requested module does not exist.
sed -i 's/pam_fprintd_grosshack\.so/pam_fprintd.so/g' \
  /usr/share/ryoku/lockscreen/qylock/quickshell-lockscreen/assets/pam/ryoku-lock

test -x /usr/bin/ryoku-shell
test -x /usr/bin/ryogami
test -x /usr/bin/ryoku-hub
test -x /usr/bin/ryostore
test -x /usr/bin/ryoku
test -x /usr/bin/quickshell
test -x /usr/bin/ryoku-monitor
test -x /usr/bin/ryoku-gpu
test -x /usr/bin/ryoku-power
test -f /etc/xdg/quickshell/ryostore/shell.qml
test -f /usr/share/applications/ryostore.desktop
test -f /usr/share/applications/ryoku-hub.desktop
test -f /etc/xdg/xdg-desktop-portal/hyprland-portals.conf
test -f /usr/lib/qt6/qml/Ryoku/Blobs/qmldir
test -f /usr/share/ryoku-source/ryoku/shell/quickshell/shell/shell.qml
test -x /usr/share/ryoku-source/ryoku/shell/ipc/ryoku-shell
grep -Fq 'ryoku-shell menu wallpaper' /usr/share/ryoku/hyprland-default/modules/binds.lua
grep -Fq '/var/lib/flatpak/exports/share/icons' /usr/share/ryoku-source/ryoku/shell/ipc/icons.go
grep -Fq 'df -B1 --output=used,size \"$HOME\"' /usr/share/ryoku-source/ryoku/shell/quickshell/shell/services/StatsFeed.qml
test -f /usr/share/ryoku-source/ryoku/hub/quickshell/shell.qml
grep -q 'pam_fprintd.so' /usr/share/ryoku/lockscreen/qylock/quickshell-lockscreen/assets/pam/ryoku-lock
! grep -q 'pam_fprintd_grosshack.so' /usr/share/ryoku/lockscreen/qylock/quickshell-lockscreen/assets/pam/ryoku-lock
fc-match -f '%{family}' 'Space Grotesk' | grep -q '^Space Grotesk'
fc-match -f '%{family}' 'Fraunces' | grep -q '^Fraunces'
fc-match -f '%{family}' 'Material Symbols Rounded' | grep -q '^Material Symbols Rounded'
fc-match -f '%{family}' 'SpaceMono Nerd Font' | grep -q '^SpaceMono Nerd Font'
fc-match -f '%{family}' 'JetBrainsMono Nerd Font' | grep -q '^JetBrainsMono Nerd Font'
