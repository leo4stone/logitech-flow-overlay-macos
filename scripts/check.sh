#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
module_cache="${TMPDIR:-/tmp}/logitech-flow-overlay-clang-module-cache"

cd "$project_dir"
mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"

swift test \
    --disable-sandbox \
    --scratch-path "$project_dir/.build"
plutil -lint Resources/Info.plist
zsh -n \
    scripts/build_app.sh \
    scripts/build_dmg.sh \
    scripts/build_icon.sh \
    scripts/check.sh
for swift_script in \
    scripts/render_dmg_background.swift \
    scripts/render_icns.swift
do
    swiftc \
        -module-cache-path "$module_cache" \
        -typecheck \
        "$swift_script"
done
