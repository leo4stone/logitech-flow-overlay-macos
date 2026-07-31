# Logitech Flow Overlay for macOS

[English](../README.md)

一个非官方的 macOS 菜单栏工具，让 Logitech Flow 的跨设备切换状态变得
清晰可见。鼠标通过 Flow 离开当前 Mac 时，应用会在所有显示器上显示醒目的
全屏毛玻璃遮罩；鼠标返回后遮罩立即消失。

> 本项目与 Logitech 无隶属或官方合作关系。

## 功能

- 在每块已连接显示器上显示全屏毛玻璃遮罩
- 当前活动设备检测支持桌面左、右、上、下四个方向
- 识别多显示器内部接缝，不会把本机跨屏移动误认为 Flow
- Logitech 鼠标输入恢复后立即移除遮罩
- 可分别调整深色蒙层透明度、系统毛玻璃强度和文字内容
- 使用 macOS 原生全屏毛玻璃，不需要“屏幕录制”权限
- 遮罩提供手动关闭按钮，方便处理误触发或结束预览
- 可选择 0.2、0.4 或 0.8 秒触发延迟
- 主界面显示实时状态，并提供遮罩预览和诊断日志
- 可从 Dock 或菜单栏重新打开主界面
- 系统首选语言为中文时显示中文，其他语言显示英文
- 无网络请求、无分析统计

## 运行要求

- macOS 13 或更高版本
- 已运行 Logi Options+ 并配置 Logitech Flow
- 支持 Flow 的 Logitech 鼠标
- 从源码构建时需要 Xcode Command Line Tools

当前 DMG 面向 Apple Silicon Mac。Swift 源码不依赖第三方库。

## 下载与安装

从 [GitHub Releases](https://github.com/leo4stone/logitech-flow-overlay-macos/releases/latest)
下载当前 Apple Silicon 安装包。打开 DMG，把“Logitech Flow Overlay”拖到
“Applications”快捷方式。

应用采用临时签名且未经 Apple 公证。如果首次启动被阻止，请前往“系统设置 →
隐私与安全性”，在安全性区域选择“仍要打开”。

## 检测原理

Logi Options+ 没有提供稳定的公开 Flow 状态接口。应用在以下条件同时成立时
判断鼠标已经切换：

1. Logi Options+ 主程序或后台设备管理程序正在运行。
2. 指针明确向桌面组合区域的外侧边缘移动。
3. 当前 Mac 在设定的延迟时间内不再收到指针移动。

应用会为每个 `NSScreen` 创建独立、不拦截输入的遮罩窗口。本机显示器之间的
内部接缝不会触发 Flow 提示。

该判断属于启发式检测。如果经常把鼠标停在桌面外侧边缘，可在菜单中提高触发
延迟以减少误判。

## 构建运行

```bash
./scripts/build_app.sh
open "dist/Logitech Flow Overlay.app"
```

应用启动后会显示状态主界面，并保留 Dock 与菜单栏入口。关闭主界面不会停止
当前活动设备检测。可以在主界面的“蒙层设置”中分别调整深色蒙层透明度、
系统毛玻璃强度，或替换设备切换时显示的文字。拖动任意滑块时，主窗口会临时
置于真实全屏遮罩之上，因此预览效果与实际切换一致。

毛玻璃使用 AppKit 原生全屏材质，不需要“屏幕录制”权限。强度滑块控制系统
材质的 alpha 遮罩，通过非线性视觉响应把内部 60%–100% 映射到界面完整的
0%–100%。界面 50% 对应约 92% 系统材质，不使用等比换算。它不会改变独立
的深色蒙层。新安装默认使用 20% 蒙层透明度和 80% 毛玻璃强度。

全屏提示的图标和文字位于中央圆角卡片内；卡片下方单独显示一个圆形 `X`
图标按钮，界面不显示额外按钮文字。

## 构建未公证 DMG

```bash
./scripts/build_dmg.sh
```

生成的磁盘映像位于 `dist/`。Finder 安装窗口直接显示应用、Applications
快捷方式、拖拽方向和未经公证应用的系统放行路径，不附带额外说明文件。
Finder 背景不能执行语言检测，因此安装提示同时显示中英文。

## 开发与验证

```bash
./scripts/check.sh
```

贡献流程见 [CONTRIBUTING.md](../CONTRIBUTING.md)，真实 Flow 和多显示器发布
验收见 [VALIDATION.md](../VALIDATION.md)。

## 诊断与隐私

从菜单栏选择“打开诊断日志”可查看 Flow 候选、切换、设备和遮罩窗口状态。
日志位于 macOS 当前临时目录，文件名为 `LogitechFlowOverlay.log`。

应用只读取本机屏幕布局、指针位置、运行中的应用状态和 Logitech HID 元数据，
不会向外发送或长期保存数据。

## 许可证

仓库当前没有授予开源许可证。在仓库所有者添加许可证前，保留所有权利。
