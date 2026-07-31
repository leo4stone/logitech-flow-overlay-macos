#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
version="$(
    /usr/libexec/PlistBuddy \
        -c 'Print :CFBundleShortVersionString' \
        "$project_dir/Resources/Info.plist"
)"
app_name="Logitech Flow Overlay"
volume_name="Logitech Flow Overlay"
output_dir="$project_dir/dist"
app_path="$output_dir/$app_name.app"
architecture="$(uname -m)"
dmg_path="$output_dir/Logitech-Flow-Overlay-${version}-${architecture}.dmg"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/LogitechFlowOverlay-dmg.XXXXXX")"
rw_dmg="$staging_dir/LogitechFlowOverlay-rw.dmg"
module_cache="${TMPDIR:-/tmp}/logitech-flow-overlay-clang-module-cache"
mounted_device=""

cleanup() {
    if [[ -n "$mounted_device" ]]; then
        hdiutil detach "$mounted_device" -quiet || true
    fi
    rm -rf "$staging_dir"
}
trap cleanup EXIT

cd "$project_dir"
mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"
"$project_dir/scripts/build_app.sh" release
swift "$project_dir/scripts/render_dmg_background.swift"

mkdir -p "$staging_dir/root/.background"
cp -R "$app_path" "$staging_dir/root/$app_name.app"
cp \
    "$project_dir/Resources/Artwork/DMGBackground.png" \
    "$staging_dir/root/.background/DMGBackground.png"
ln -s /Applications "$staging_dir/root/Applications"

hdiutil create \
    -volname "$volume_name" \
    -srcfolder "$staging_dir/root" \
    -ov \
    -format UDRW \
    "$rw_dmg" \
    >/dev/null

attach_output="$(
    hdiutil attach \
        -readwrite \
        -noverify \
        -noautoopen \
        "$rw_dmg"
)"
mounted_device="$(
    print -r -- "$attach_output" \
        | awk '/Apple_HFS|Apple_APFS/ { print $1; exit }'
)"
mount_point="$(
    print -r -- "$attach_output" \
        | sed -n 's#^.*\(/Volumes/.*\)$#\1#p' \
        | head -n 1
)"

if [[ -z "$mounted_device" || -z "$mount_point" ]]; then
    echo "Unable to mount writable disk image" >&2
    exit 1
fi

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$volume_name"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set sidebar width of container window to 0
        set the bounds of container window to {120, 120, 1040, 720}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:DMGBackground.png"
        set position of item "$app_name.app" of container window to {220, 270}
        set position of item "Applications" of container window to {700, 270}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$mounted_device" -quiet
mounted_device=""

rm -f "$dmg_path"
hdiutil convert \
    "$rw_dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$dmg_path" \
    >/dev/null

hdiutil verify "$dmg_path"
echo "$dmg_path"
