#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_image="$project_dir/Resources/Artwork/AppIconSource.png"
output_icon="$project_dir/Resources/AppIcon.icns"
module_cache="${TMPDIR:-/tmp}/logitech-flow-overlay-clang-module-cache"
mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"

swift \
    "$project_dir/scripts/render_icns.swift" \
    "$source_image" \
    "$output_icon"
echo "$output_icon"
