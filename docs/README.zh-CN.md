# Logitech Flow Overlay for macOS

[English](../README.md)

一个非官方的 macOS 菜单栏工具，让 Logitech Flow 的跨设备切换状态变得
清晰可见。鼠标通过 Flow 离开当前 Mac 时，应用会在所有显示器上显示醒目的
全屏毛玻璃遮罩；鼠标返回后遮罩立即消失。

> 本项目与 Logitech 无隶属或官方合作关系。

## 功能

- 在每块已连接显示器上显示全屏毛玻璃遮罩
- 支持从桌面左、右、上、下四个方向触发 Flow
- 识别多显示器内部接缝，不会把本机跨屏移动误认为 Flow
- Logitech 鼠标输入恢复后立即移除遮罩
- 可选择 0.2、0.4 或 0.8 秒触发延迟
- 菜单栏提供遮罩预览和诊断日志
- 无网络请求、无分析统计

## 运行要求

- macOS 13 或更高版本
- 已运行 Logi Options+ 并配置 Logitech Flow
- 支持 Flow 的 Logitech 鼠标
- 从源码构建时需要 Xcode Command Line Tools

当前 DMG 面向 Apple Silicon Mac。Swift 源码不依赖第三方库。

## 检测原理

Logi Options+ 没有提供稳定的公开 Flow 状态接口。应用在以下条件同时成立时
判断鼠标已经切换：

1. Logi Options+ 正在运行。
2. 指针明确向桌面组合区域的外侧边缘移动。
3. 当前 Mac 在设定的延迟时间内不再收到指针移动。

应用会为每个 `NSScreen` 创建独立、不拦截输入的遮罩窗口。本机显示器之间的
内部接缝不会触发 Flow 提示。

该判断属于启发式检测。如果经常把鼠标停在桌面外侧边缘，可在菜单中提高触发
延迟以减少误判。

## 构建运行

```bash
./scripts/build_app.sh
open dist/InputLinkTips.app
```

应用启动后仅出现在菜单栏，不显示在 Dock。

## 构建未公证 DMG

```bash
./scripts/build_dmg.sh
```

生成的磁盘映像位于 `dist/`，其中包含应用、Applications 快捷方式和中文安装
说明。

应用采用临时签名且未经 Apple 公证。从网络下载后，首次启动请按住 Control
点击应用并选择“打开”；也可以前往“系统设置 → 隐私与安全性”选择“仍要打开”。

## 开发与验证

```bash
./scripts/check.sh
```

贡献流程见 [CONTRIBUTING.md](../CONTRIBUTING.md)，真实 Flow 和多显示器发布
验收见 [VALIDATION.md](../VALIDATION.md)。

## 诊断与隐私

从菜单栏选择“打开诊断日志”可查看 Flow 候选、切换、设备和遮罩窗口状态。
日志位于 macOS 当前临时目录，文件名为 `InputLinkTips.log`。

应用只读取本机屏幕布局、指针位置、运行中的应用状态和 Logitech HID 元数据，
不会向外发送或长期保存数据。

## 许可证

仓库当前没有授予开源许可证。在仓库所有者添加许可证前，保留所有权利。
