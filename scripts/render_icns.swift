#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: render_icns.swift SOURCE_PNG OUTPUT_ICNS\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to load \(sourceURL.path)\n", stderr)
    exit(1)
}

let variants: [(type: String, pixels: Int)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]

func encodedUInt32(_ value: Int) -> Data {
    var bigEndian = UInt32(value).bigEndian
    return Data(bytes: &bigEndian, count: MemoryLayout<UInt32>.size)
}

func encodedFourCC(_ value: String) -> Data {
    Data(value.utf8)
}

func renderPNG(size: Int) -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: size * 4,
        bitsPerPixel: 32
    ) else {
        fputs("Unable to allocate \(size)x\(size) bitmap\n", stderr)
        exit(1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    sourceImage.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: NSRect(origin: .zero, size: sourceImage.size),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Unable to encode \(size)x\(size) PNG\n", stderr)
        exit(1)
    }
    return png
}

var elements = Data()
for variant in variants {
    let png = renderPNG(size: variant.pixels)
    elements.append(encodedFourCC(variant.type))
    elements.append(encodedUInt32(png.count + 8))
    elements.append(png)
}

var icon = Data()
icon.append(encodedFourCC("icns"))
icon.append(encodedUInt32(elements.count + 8))
icon.append(elements)

try icon.write(to: outputURL, options: .atomic)
print(outputURL.path)
