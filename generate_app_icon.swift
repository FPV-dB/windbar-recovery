#!/usr/bin/env swift

import AppKit

// Generate app icon using SF Symbol "wind" with blue gradient background
func generateAppIcon(size: CGFloat, scale: CGFloat, filename: String) {
    let pixelSize = size * scale
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))

    image.lockFocus()

    // Draw gradient background (sky blue to light blue)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0)
    ])
    gradient?.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize), angle: -90)

    // Draw wind symbol in white
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: pixelSize * 0.55, weight: .medium)
    if let windSymbol = NSImage(systemSymbolName: "wind", accessibilityDescription: "Wind")?.withSymbolConfiguration(symbolConfig) {
        let symbolSize = windSymbol.size
        let x = (pixelSize - symbolSize.width) / 2
        let y = (pixelSize - symbolSize.height) / 2

        windSymbol.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height))
    }

    image.unlockFocus()

    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: filename)
        try? pngData.write(to: url)
        print("Generated: \(filename)")
    }
}

// Generate all required sizes
let basePath = "/Users/d/Desktop/files/Assets.xcassets/AppIcon.appiconset"

generateAppIcon(size: 16, scale: 1, filename: "\(basePath)/icon_16x16.png")
generateAppIcon(size: 16, scale: 2, filename: "\(basePath)/icon_16x16@2x.png")
generateAppIcon(size: 32, scale: 1, filename: "\(basePath)/icon_32x32.png")
generateAppIcon(size: 32, scale: 2, filename: "\(basePath)/icon_32x32@2x.png")
generateAppIcon(size: 128, scale: 1, filename: "\(basePath)/icon_128x128.png")
generateAppIcon(size: 128, scale: 2, filename: "\(basePath)/icon_128x128@2x.png")
generateAppIcon(size: 256, scale: 1, filename: "\(basePath)/icon_256x256.png")
generateAppIcon(size: 256, scale: 2, filename: "\(basePath)/icon_256x256@2x.png")
generateAppIcon(size: 512, scale: 1, filename: "\(basePath)/icon_512x512.png")
generateAppIcon(size: 512, scale: 2, filename: "\(basePath)/icon_512x512@2x.png")

print("App icons generated successfully!")
