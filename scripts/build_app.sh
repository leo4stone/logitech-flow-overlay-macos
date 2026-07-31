#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
app_dir="$project_dir/dist/Logitech Flow Overlay.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
module_cache="${TMPDIR:-/tmp}/logitech-flow-overlay-clang-module-cache"

cd "$project_dir"
mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"

swift build \
    --disable-sandbox \
    --scratch-path "$project_dir/.build" \
    -c "$configuration"

binary_path="$(swift build \
    --disable-sandbox \
    --scratch-path "$project_dir/.build" \
    -c "$configuration" \
    --show-bin-path)/LogitechFlowOverlay"

if [[ ! -f "$project_dir/Resources/AppIcon.icns" \
    || "$project_dir/Resources/Artwork/AppIconSource.png" \
        -nt "$project_dir/Resources/AppIcon.icns" ]]; then
    "$project_dir/scripts/build_icon.sh"
fi

mkdir -p "$macos_dir" "$resources_dir"
cp "$binary_path" "$macos_dir/LogitechFlowOverlay"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
cp "$project_dir/Resources/AppIcon.icns" "$resources_dir/AppIcon.icns"

codesign --force --deep --sign - "$app_dir"

echo "$app_dir"
