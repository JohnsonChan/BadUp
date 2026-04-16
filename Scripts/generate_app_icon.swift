import AppKit

let pixelSize = 1024
let size = CGSize(width: pixelSize, height: pixelSize)
let outputPath = "/Users/chenrs/Documents/iosapp/XiaoLang/BadUp/BadUp/BadUp/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ),
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
else {
    fatalError("Unable to create bitmap context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let context = graphicsContext.cgContext

context.setAllowsAntialiasing(true)
context.interpolationQuality = .high

let canvas = CGRect(origin: .zero, size: size)
let radius: CGFloat = 230
let roundedPath = NSBezierPath(roundedRect: canvas, xRadius: radius, yRadius: radius)
roundedPath.addClip()

let colorSpace = CGColorSpaceCreateDeviceRGB()
let backgroundColors = [
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.19, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.18, green: 0.08, blue: 0.15, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.35, green: 0.12, blue: 0.09, alpha: 1).cgColor
] as CFArray
let backgroundLocations: [CGFloat] = [0.0, 0.48, 1.0]

if let gradient = CGGradient(colorsSpace: colorSpace, colors: backgroundColors, locations: backgroundLocations) {
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 120, y: 1024),
        end: CGPoint(x: 924, y: 0),
        options: []
    )
}

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -24), blur: 80, color: NSColor.black.withAlphaComponent(0.35).cgColor)
let badgeRect = CGRect(x: 146, y: 146, width: 732, height: 732)
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 180, yRadius: 180)
NSColor(calibratedRed: 0.97, green: 0.93, blue: 0.85, alpha: 1).setFill()
badgePath.fill()
context.restoreGState()

let innerGlowColors = [
    NSColor.white.withAlphaComponent(0.33).cgColor,
    NSColor.white.withAlphaComponent(0.0).cgColor
] as CFArray
let innerGlowLocations: [CGFloat] = [0.0, 1.0]
if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: innerGlowColors, locations: innerGlowLocations) {
    context.saveGState()
    badgePath.addClip()
    context.drawRadialGradient(
        glowGradient,
        startCenter: CGPoint(x: 320, y: 760),
        startRadius: 10,
        endCenter: CGPoint(x: 360, y: 720),
        endRadius: 420,
        options: []
    )
    context.restoreGState()
}

func roundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    color.setFill()
    path.fill()
}

let pillShadowColor = NSColor.black.withAlphaComponent(0.12).cgColor
func drawPill(rect: CGRect, color: NSColor) {
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: pillShadowColor)
    roundedRect(rect, radius: 42, color: color)
    context.restoreGState()
}

let pillX: CGFloat = 250
let pillWidth: CGFloat = 524
let pillHeight: CGFloat = 124
let pillRects = [
    CGRect(x: pillX, y: 626, width: pillWidth, height: pillHeight),
    CGRect(x: pillX, y: 455, width: pillWidth, height: pillHeight),
    CGRect(x: pillX, y: 284, width: pillWidth, height: pillHeight)
]
let pillColors = [
    NSColor(calibratedRed: 0.95, green: 0.42, blue: 0.34, alpha: 1),
    NSColor(calibratedRed: 0.96, green: 0.67, blue: 0.20, alpha: 1),
    NSColor(calibratedRed: 0.12, green: 0.67, blue: 0.74, alpha: 1)
]

for (rect, color) in zip(pillRects, pillColors) {
    drawPill(rect: rect, color: color)
}

func drawPlaySymbol(in rect: CGRect) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + 10, y: rect.minY))
    path.line(to: CGPoint(x: rect.maxX, y: rect.midY))
    path.line(to: CGPoint(x: rect.minX + 10, y: rect.maxY))
    path.close()
    NSColor.white.setFill()
    path.fill()
}

func drawMoonSymbol(in rect: CGRect) {
    let outer = NSBezierPath(ovalIn: rect)
    NSColor.white.setFill()
    outer.fill()

    let cutout = NSBezierPath(ovalIn: rect.offsetBy(dx: 24, dy: 6))
    NSColor(calibratedRed: 0.12, green: 0.67, blue: 0.74, alpha: 1).setFill()
    cutout.fill()
}

func drawSparkSymbol(in rect: CGRect) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.line(to: CGPoint(x: rect.maxX - 18, y: rect.midY + 16))
    path.line(to: CGPoint(x: rect.midX + 18, y: rect.midY + 12))
    path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.line(to: CGPoint(x: rect.midX, y: rect.midY - 14))
    path.line(to: CGPoint(x: rect.minX, y: rect.minY))
    path.line(to: CGPoint(x: rect.minX + 20, y: rect.midY + 12))
    path.line(to: CGPoint(x: rect.minX + 18, y: rect.midY + 16))
    path.close()
    NSColor.white.setFill()
    path.fill()
}

drawSparkSymbol(in: CGRect(x: 302, y: 656, width: 64, height: 64))
drawPlaySymbol(in: CGRect(x: 302, y: 489, width: 58, height: 58))
drawMoonSymbol(in: CGRect(x: 294, y: 312, width: 66, height: 66))

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .left

func drawLabel(_ text: String, at point: CGPoint, size: CGFloat) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: .bold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.96),
        .paragraphStyle: paragraph
    ]
    NSString(string: text).draw(at: point, withAttributes: attributes)
}

drawLabel("撸管", at: CGPoint(x: 404, y: 654), size: 46)
drawLabel("VIDEO", at: CGPoint(x: 404, y: 483), size: 46)
drawLabel("LATE", at: CGPoint(x: 404, y: 312), size: 46)

let badgeCircle = CGRect(x: 712, y: 720, width: 180, height: 180)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 20, color: NSColor.black.withAlphaComponent(0.18).cgColor)
let badgeCirclePath = NSBezierPath(ovalIn: badgeCircle)
NSColor(calibratedRed: 0.25, green: 0.84, blue: 0.48, alpha: 1).setFill()
badgeCirclePath.fill()
context.restoreGState()

let plusAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 74, weight: .black),
    .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.15, blue: 0.10, alpha: 1)
]
NSString(string: "+1").draw(at: CGPoint(x: 742, y: 764), withAttributes: plusAttributes)

let borderPath = NSBezierPath(roundedRect: canvas.insetBy(dx: 10, dy: 10), xRadius: 220, yRadius: 220)
borderPath.lineWidth = 20
NSColor.white.withAlphaComponent(0.08).setStroke()
borderPath.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode PNG")
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print(outputPath)
