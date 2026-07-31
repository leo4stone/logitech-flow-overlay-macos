#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
module_cache="${TMPDIR:-/tmp}/inputlinktips-clang-module-cache"

cd "$project_dir"
mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"

swift test \
    --disable-sandbox \
    --scratch-path "$project_dir/.build"
plutil -lint Resources/Info.plist
zsh -n scripts/build_app.sh scripts/build_dmg.sh scripts/check.sh
