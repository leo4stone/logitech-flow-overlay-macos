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
if grep -R -n -E \
    '启用 Flow 边缘检测|Enable Flow Edge Detection' \
    Sources README.md docs VALIDATION.md
then
    echo "User-facing terminology must use Active Device Detection." >&2
    exit 1
fi
grep -q '启用“当前活动设备检测”' Sources/LogitechFlowOverlay/L10n.swift
grep -q 'Enable Active Device Detection' Sources/LogitechFlowOverlay/L10n.swift
grep -q 'blur.blendingMode = .behindWindow' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'blur.material = .fullScreenUI' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'blur.maskImage = makeGlassMask' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'glassSlider' \
    Sources/LogitechFlowOverlay/MainWindowController.swift
grep -q 'minimumGlassIntensity = 0.0' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'maximumGlassIntensity = 1.0' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'minimumGlassMaskAlpha = 0.60' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'glassResponseExponent = 2.321928094887362' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'defaultTransparency = 0.20' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'defaultGlassIntensity = 0.80' \
    Sources/LogitechFlowOverlay/OverlaySettings.swift
grep -q 'defaultDimOpacity = 0.50' \
    Sources/LogitechFlowOverlay/ReconnectAlertSettings.swift
grep -q 'defaultDuration = 2.0' \
    Sources/LogitechFlowOverlay/ReconnectAlertSettings.swift
grep -q 'defaultRadius = 100.0' \
    Sources/LogitechFlowOverlay/ReconnectAlertSettings.swift
grep -q 'defaultFeather = 0.04' \
    Sources/LogitechFlowOverlay/ReconnectAlertSettings.swift
for reconnect_label in \
    '"变暗程度"' \
    '"持续时间"' \
    '"聚光半径"' \
    '"边缘羽化"'
do
    grep -q "$reconnect_label" Sources/LogitechFlowOverlay/L10n.swift
done
grep -q 'onReconnectAlertSettingsPreviewBegan' \
    Sources/LogitechFlowOverlay/MainWindowController.swift
grep -q 'onReconnectAlertSettingsPreviewEnded' \
    Sources/LogitechFlowOverlay/MainWindowController.swift
grep -q 'showSettingsPreview' \
    Sources/LogitechFlowOverlay/ReconnectAlertController.swift
grep -q 'dismissImage.isTemplate = true' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'dismissButton.imagePosition = .imageOnly' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'dismissButton.contentTintColor = .white' \
    Sources/LogitechFlowOverlay/OverlayController.swift
grep -q 'dismissButton.isBordered = false' \
    Sources/LogitechFlowOverlay/OverlayController.swift
if grep -q 'title: L10n.dismissOverlay' \
    Sources/LogitechFlowOverlay/OverlayController.swift
then
    echo "The overlay dismiss button must be icon-only." >&2
    exit 1
fi
if grep -R -n -E \
    'blur\.alphaValue|blurAlpha|blur\.backgroundFilters|blurSlider|backgroundBlur' \
    Sources Tests
then
    echo "Glass intensity must use the native material mask, not simulated blur." >&2
    exit 1
fi
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
