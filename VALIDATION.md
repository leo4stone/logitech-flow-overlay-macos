# InputLinkTips 验收清单

发布或交付新构建前必须完成：

1. `swift test` 覆盖左、右、上、下外侧边缘以及多显示器内部接缝。
2. 构建 `.app` 后验证签名、Info.plist 和可执行文件。
3. 启动构建产物，确认系统临时目录中的 `InputLinkTips.log` 同时记录：
   - `optionsPlusRunning=true`
   - `hidPointers`（仅用于诊断，不得作为 Flow 检测前置条件）
4. 使用菜单“预览遮罩”确认所有显示器出现遮罩并在 3 秒后消失。
   - 日志中的 `overlayShown count` 必须等于 `NSScreen.screens.count`。
   - 每个遮罩必须有不同的 `window` 与 `display`，且 `target` 等于 `actual`、`visible=true`。
   - 使用 Quartz 窗口列表确认屏幕上的 InputLinkTips 遮罩窗口数等于显示器数；仅验证数组数量不算通过。
5. 真实 Flow 往返一次；日志必须出现 `flowCandidate`、`flowAway`、`flowReturned`。

在第 5 项没有真实设备操作证据时，只能声明自动化和启动验证通过，不能声称真实 Flow 已验证。
