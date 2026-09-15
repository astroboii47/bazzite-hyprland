#!/bin/bash
set -euo pipefail

# Pin the upstream desktop so every image build produces the same shell.
ryoku_commit="e76a32d474a467d45e0dc67a46d1c6057d024f5b"
src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT

curl --fail --location --silent --show-error \
  "https://github.com/Ryoku-dev/ryoku-arch/archive/${ryoku_commit}.tar.gz" \
  | tar -xz --strip-components=1 -C "$src"

# Native shell controller and wallpaper service.
(cd "$src/ryoku/shell/ipc" && CGO_ENABLED=0 go build -trimpath -mod=vendor -o /usr/bin/ryoku-shell .)
(cd "$src/ryoku/shell/ryogami/daemon" && CGO_ENABLED=0 go build -trimpath -o /usr/bin/ryogami .)

# The compiled metaball renderer creates Ryoku's floating frame shapes.
RYOKU_BLOBS_BUILD="$src/build-blobs" \
  "$src/ryoku/shell/plugin/build.sh" /usr/lib/qt6/qml

# Keep the pinned desktop tree intact. The controller uses it as its QML source
# so Bazzite does not need Arch's package layout or per-user generated copies.
install -d /usr/share/ryoku-source
cp -a "$src/ryoku" /usr/share/ryoku-source/
install -d /usr/lib/qt6/qml/Ryoku/Ui /usr/lib/qt6/qml/Ryoku/FrameBars /usr/lib/qt6/qml/Ryoku/PluginKit
cp -a "$src/ryoku/ui/." /usr/lib/qt6/qml/Ryoku/Ui/
cp -a "$src/ryoku/shell/framebars/." /usr/lib/qt6/qml/Ryoku/FrameBars/
cp -a "$src/ryoku/shell/quickshell/plugins/kit/." /usr/lib/qt6/qml/Ryoku/PluginKit/

install -Dm755 "$src/ryoku/shell/scripts/ryoku-reload-cover" /usr/bin/ryoku-reload-cover
install -Dm755 "$src/ryoku/shell/scripts/ryostage" /usr/bin/ryostage
install -Dm755 "$src/ryoku/shell/scripts/ryoku-eq" /usr/bin/ryoku-eq
install -Dm755 "$src/ryoku/shell/quickshell/plugins/ryoku-plugins-place" /usr/bin/ryoku-plugins-place
for helper in "$src"/ryoku/hyprland/scripts/ryoku-*; do
  install -Dm755 "$helper" "/usr/bin/$(basename "$helper")"
done

# Wallpaper picker, stock wallpapers, and the real animated lock surface.
install -d /usr/share/ryogami /usr/share/ryoku/wallpapers /usr/share/ryoku/lockscreen
cp -a "$src/ryoku/shell/ryogami/wall-ui/." /usr/share/ryogami/
cp -a "$src/ryoku/assets/wallpapers/." /usr/share/ryoku/wallpapers/
cp -a "$src/ryoku/lockscreen/qylock/." /usr/share/ryoku/lockscreen/qylock/

test -x /usr/bin/ryoku-shell
test -x /usr/bin/ryogami
test -f /usr/lib/qt6/qml/Ryoku/Blobs/qmldir
test -f /usr/share/ryoku-source/ryoku/shell/quickshell/shell/shell.qml
