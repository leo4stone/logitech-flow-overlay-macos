# Logitech Flow Overlay 验收清单

发布或交付新构建前必须完成：

1. `swift test` 覆盖左、右、上、下外侧边缘以及多显示器内部接缝。
2. 构建 `.app` 后验证签名、Info.plist 和可执行文件。
3. 启动构建产物，确认主界面自动显示并满足：
   - Dock 与菜单栏都有应用入口；
   - 状态卡片显示当前鼠标或 Options+ 状态；
   - 关闭窗口不会退出应用，通过 Dock 或菜单栏可以重新打开。
4. 分别以中文和非中文首选语言启动应用，确认主界面、菜单和遮罩分别显示
   中文与英文。
5. 确认系统临时目录中的 `LogitechFlowOverlay.log` 同时记录：
   - `optionsPlusRunning=true`
   - `hidPointers`（仅用于诊断，不得作为 Flow 检测前置条件）
6. 使用菜单“预览遮罩”确认所有显示器出现遮罩并在 3 秒后消失。
   - 日志中的 `overlayShown count` 必须等于 `NSScreen.screens.count`。
   - 每个遮罩必须有不同的 `window` 与 `display`，且 `target` 等于 `actual`、`visible=true`。
   - 使用 Quartz 窗口列表确认屏幕上的 Logitech Flow Overlay 遮罩窗口数等于显示器数；仅验证数组数量不算通过。
7. 以最终用户方式双击 DMG，确认 Finder 自动显示图标视图：
   - 应用和 Applications 快捷方式分别位于箭头两侧；
   - 拖拽说明位于箭头附近；
   - 窗口以中英文直接显示“系统设置 → 隐私与安全性 → 仍要打开”；
   - 映像中没有额外安装说明文档。
8. 真实 Flow 往返一次；日志必须出现 `flowCandidate`、`flowAway`、`flowReturned`。

在第 8 项没有真实设备操作证据时，只能声明自动化和启动验证通过，不能声称真实 Flow 已验证。
