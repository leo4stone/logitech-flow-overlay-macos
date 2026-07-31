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
if rg -n \
    '启用 Flow 边缘检测|Enable Flow Edge Detection' \
    Sources README.md docs VALIDATION.md
then
    echo "User-facing terminology must use Active Device Detection." >&2
    exit 1
fi
rg -q '启用“当前活动设备检测”' Sources/LogitechFlowOverlay/L10n.swift
rg -q 'Enable Active Device Detection' Sources/LogitechFlowOverlay/L10n.swift
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
