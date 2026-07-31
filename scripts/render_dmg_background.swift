#!/usr/bin/env swift

import AppKit
import Foundation

let projectDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = projectDirectory
    .appendingPathComponent("Resources/Artwork/DMGBackgroundBase.png")
let outputURL = projectDirectory
    .appendingPathComponent("Resources/Artwork/DMGBackground.png")

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to load \(sourceURL.path)\n", stderr)
    exit(1)
}

let canvasSize = NSSize(width: 920, height: 520)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: Int(canvasSize.width) * 4,
    bitsPerPixel: 32
) else {
    fputs("Unable to allocate DMG background bitmap\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let sourceAspect = sourceImage.size.width / sourceImage.size.height
let canvasAspect = canvasSize.width / canvasSize.height
let drawRect: NSRect
if sourceAspect < canvasAspect {
    let height = canvasSize.width / sourceAspect
    drawRect = NSRect(
        x: 0,
        y: (canvasSize.height - height) / 2,
        width: canvasSize.width,
        height: height
    )
} else {
    let width = canvasSize.height * sourceAspect
    drawRect = NSRect(
        x: (canvasSize.width - width) / 2,
        y: 0,
        width: width,
        height: canvasSize.height
    )
}

sourceImage.draw(
    in: drawRect,
    from: NSRect(origin: .zero, size: sourceImage.size),
    operation: .copy,
    fraction: 1
)

for cardRect in [
    NSRect(x: 100, y: 138, width: 240, height: 230),
    NSRect(x: 580, y: 138, width: 240, height: 230)
] {
    let card = NSBezierPath(roundedRect: cardRect, xRadius: 22, yRadius: 22)
    NSColor.white.withAlphaComponent(0.16).setFill()
    card.fill()
    NSColor.white.withAlphaComponent(0.28).setStroke()
    card.lineWidth = 1
    card.stroke()
}

func drawCentered(
    _ text: String,
    y: CGFloat,
    font: NSFont,
    color: NSColor
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    text.draw(
        in: NSRect(x: 48, y: y, width: canvasSize.width - 96, height: 40),
        withAttributes: attributes
    )
}

drawCentered(
    "Logitech Flow Overlay",
    y: 460,
    font: .systemFont(ofSize: 26, weight: .bold),
    color: .white
)
drawCentered(
    "拖到“应用程序” / Drag to Applications",
    y: 292,
    font: .systemFont(ofSize: 15, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.86)
)

let arrowColor = NSColor.white.withAlphaComponent(0.88)
let arrow = NSBezierPath()
arrow.lineWidth = 5
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: 372, y: 252))
arrow.line(to: NSPoint(x: 548, y: 252))
arrowColor.setStroke()
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 548, y: 252))
arrowHead.line(to: NSPoint(x: 524, y: 268))
arrowHead.line(to: NSPoint(x: 524, y: 236))
arrowHead.close()
arrowColor.setFill()
arrowHead.fill()

drawCentered(
    "首次打开被阻止：系统设置 → 隐私与安全性 → 仍要打开\n"
        + "If blocked: System Settings → Privacy & Security → Open Anyway",
    y: 18,
    font: .systemFont(ofSize: 12, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.82)
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to render DMG background\n", stderr)
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
