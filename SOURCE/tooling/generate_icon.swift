import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

// Original code-drawn Wafa mark. No third-party image or font files.
// Run from SOURCE; writes only the scaffold's enumerated app-icon PNGs.
let project = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let icons = project.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset")
let data = try Data(contentsOf: icons.appendingPathComponent("Contents.json"))
let contents = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let entries = contents["images"] as! [[String: Any]]
var rendered = Set<String>()
for entry in entries {
    guard let name = entry["filename"] as? String,
          name.hasPrefix("Icon-App-"), name.hasSuffix(".png"),
          !name.contains("/"), !rendered.contains(name),
          let size = entry["size"] as? String,
          let scale = entry["scale"] as? String,
          let points = Double(size.components(separatedBy: "x")[0]),
          let factor = Double(scale.replacingOccurrences(of: "x", with: "")) else { continue }
    let pixels = Int((points * factor).rounded())
    let context = CGContext(data: nil, width: pixels, height: pixels,
        bitsPerComponent: 8, bytesPerRow: pixels * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let s = CGFloat(pixels)
    context.setFillColor(red: 18/255, green: 63/255, blue: 50/255, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: s, height: s))
    context.setLineWidth(s * 0.055)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: s * 0.21, y: s * 0.65))
    context.addLine(to: CGPoint(x: s * 0.34, y: s * 0.31))
    context.addLine(to: CGPoint(x: s * 0.50, y: s * 0.60))
    context.addLine(to: CGPoint(x: s * 0.66, y: s * 0.31))
    context.addLine(to: CGPoint(x: s * 0.79, y: s * 0.65))
    context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.strokePath()
    context.setFillColor(red: 189/255, green: 220/255, blue: 204/255, alpha: 1)
    context.fillEllipse(in: CGRect(x: s * 0.465, y: s * 0.75, width: s * 0.07, height: s * 0.07))
    let destination = CGImageDestinationCreateWithURL(icons.appendingPathComponent(name) as CFURL,
        UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG generation failed") }
    rendered.insert(name)
}
print("Generated \(rendered.count) original Wafa app-icon sizes.")
