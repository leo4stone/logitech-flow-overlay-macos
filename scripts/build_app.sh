#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
app_dir="$project_dir/dist/InputLinkTips.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
module_cache="${TMPDIR:-/tmp}/inputlinktips-clang-module-cache"

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
    --show-bin-path)/InputLinkTips"

mkdir -p "$macos_dir"
cp "$binary_path" "$macos_dir/InputLinkTips"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"

codesign --force --deep --sign - "$app_dir"

echo "$app_dir"
