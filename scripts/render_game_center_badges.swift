// Appended to AchievementCatalog.swift by export_game_center.py. Outside the app target.
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let badges = output.appendingPathComponent("Badges", isDirectory: true)
try FileManager.default.createDirectory(at: badges, withIntermediateDirectories: true)
precondition(AchievementCatalog.all.count <= 100)
precondition(AchievementCatalog.all.reduce(0) { $0 + $1.points } <= 1000)
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
try encoder.encode(AchievementCatalog.all).write(to: output.appendingPathComponent("achievements.json"))

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r, g, b, 1])!
}
func text(_ value: String, y: CGFloat, size: CGFloat, bold: Bool, ink: CGColor, in context: CGContext) {
    let font = CTFontCreateWithName((bold ? "HelveticaNeue-Bold" : "HelveticaNeue-Medium") as CFString, size, nil)
    let string = NSAttributedString(string: value, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink
    ])
    let line = CTLineCreateWithAttributedString(string)
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    context.textPosition = CGPoint(x: (1024 - width) / 2, y: y)
    CTLineDraw(line, context)
}

for item in AchievementCatalog.all {
    let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                            bytesPerRow: 4096, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let cream = color(0.97, 0.94, 0.85)
    let green = color(0.23, 0.39, 0.28)
    let gold = color(0.73, 0.57, 0.30)
    context.setFillColor(cream)
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    let disk = CGRect(x: 102, y: 102, width: 820, height: 820)
    context.saveGState()
    context.addEllipse(in: disk)
    context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [color(0.45, 0.59, 0.35), green] as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 250, y: 900), end: CGPoint(x: 800, y: 100), options: [])
    context.restoreGState()
    context.setStrokeColor(gold)
    context.setLineWidth(18)
    context.strokeEllipse(in: disk)
    context.setStrokeColor(cream.copy(alpha: 0.35)!)
    context.setLineWidth(3)
    context.strokeEllipse(in: CGRect(x: 128, y: 128, width: 768, height: 768))
    // Native vector sprout shared by the garden's badge system.
    context.setFillColor(cream)
    let left = CGMutablePath()
    left.move(to: CGPoint(x: 510, y: 540))
    left.addCurve(to: CGPoint(x: 350, y: 694), control1: CGPoint(x: 352, y: 520), control2: CGPoint(x: 335, y: 610))
    left.addCurve(to: CGPoint(x: 510, y: 540), control1: CGPoint(x: 470, y: 710), control2: CGPoint(x: 520, y: 645))
    context.addPath(left)
    context.fillPath()
    let right = CGMutablePath()
    right.move(to: CGPoint(x: 517, y: 585))
    right.addCurve(to: CGPoint(x: 690, y: 749), control1: CGPoint(x: 500, y: 722), control2: CGPoint(x: 598, y: 760))
    right.addCurve(to: CGPoint(x: 517, y: 585), control1: CGPoint(x: 710, y: 620), control2: CGPoint(x: 630, y: 575))
    context.addPath(right)
    context.fillPath()
    context.setStrokeColor(cream)
    context.setLineCap(.round)
    context.setLineWidth(15)
    context.move(to: CGPoint(x: 510, y: 490))
    context.addQuadCurve(to: CGPoint(x: 550, y: 665), control: CGPoint(x: 495, y: 600))
    context.strokePath()
    for x in [CGFloat(290), 734] {
        context.setFillColor(gold)
        context.fillEllipse(in: CGRect(x: x - 8, y: 574, width: 16, height: 16))
    }
    text("TERRARIUM IDLE", y: 793, size: 29, bold: true, ink: cream, in: context)
    let number = item.titleEN.split(separator: " ").last.map(String.init) ?? "1"
    text("•  \(number)  •", y: 420, size: 42, bold: true, ink: color(0.95, 0.80, 0.47), in: context)
    let title = item.titleEN.split(separator: " ").dropLast().joined(separator: " ")
    text(title.uppercased(), y: 342, size: title.count > 20 ? 27 : 34, bold: true, ink: cream, in: context)
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .decimal
    let target = formatter.string(from: NSNumber(value: item.target))!
    text(target, y: 264, size: 37, bold: false, ink: cream, in: context)
    let destination = CGImageDestinationCreateWithURL(badges.appendingPathComponent(item.id + ".png") as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyDPIWidth: 72, kCGImagePropertyDPIHeight: 72] as CFDictionary)
    precondition(CGImageDestinationFinalize(destination))
}
