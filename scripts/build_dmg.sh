#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
version="$(
    /usr/libexec/PlistBuddy \
        -c 'Print :CFBundleShortVersionString' \
        "$project_dir/Resources/Info.plist"
)"
output_dir="$project_dir/dist"
app_path="$output_dir/InputLinkTips.app"
architecture="$(uname -m)"
dmg_path="$output_dir/InputLinkTips-${version}-${architecture}.dmg"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/InputLinkTips-dmg.XXXXXX")"

cleanup() {
    rm -rf "$staging_dir"
}
trap cleanup EXIT

"$project_dir/scripts/build_app.sh" release

cp -R "$app_path" "$staging_dir/InputLinkTips.app"
cp "$project_dir/Resources/安装说明.txt" "$staging_dir/安装说明.txt"
ln -s /Applications "$staging_dir/Applications"

rm -f "$dmg_path"
hdiutil create \
    -volname "InputLinkTips" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$dmg_path"

hdiutil verify "$dmg_path"
echo "$dmg_path"
