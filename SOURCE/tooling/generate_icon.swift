import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

// Wafa mark from the LOCK 6 SVG's 100 × 100 viewBox.
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
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let s = CGFloat(pixels)
    context.setFillColor(red: 18/255, green: 63/255, blue: 50/255, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: s, height: s))
    context.translateBy(x: 0, y: s)
    context.scaleBy(x: s / 100, y: -s / 100)
    context.setLineWidth(7)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: 58, y: 52))
    context.addCurve(to: CGPoint(x: 47, y: 38),
        control1: CGPoint(x: 47, y: 54), control2: CGPoint(x: 43, y: 45))
    context.addCurve(to: CGPoint(x: 64, y: 42),
        control1: CGPoint(x: 51, y: 31), control2: CGPoint(x: 63, y: 32))
    context.addCurve(to: CGPoint(x: 33, y: 76),
        control1: CGPoint(x: 66, y: 58), control2: CGPoint(x: 52, y: 72))
    context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.strokePath()
    context.setFillColor(red: 189/255, green: 220/255, blue: 204/255, alpha: 1)
    context.fillEllipse(in: CGRect(x: 66, y: 20, width: 8, height: 8))
    let destination = CGImageDestinationCreateWithURL(icons.appendingPathComponent(name) as CFURL,
        UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG generation failed") }
    rendered.insert(name)
}
print("Generated \(rendered.count) original Wafa app-icon sizes.")
