#!/usr/bin/swift
import Cocoa
import CoreText
import Foundation

// Check if arguments are provided
guard CommandLine.arguments.count > 1 else {
    print("Use: \(CommandLine.arguments[0]) <fontAwesomeUnicode> [hexColor]")
    exit(1)
}

let iconUnicode = CommandLine.arguments[1]
let inputHexColor = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "#3498db"
let iconGradientRaw = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : "YES"
let iconGradient = iconGradientRaw.lowercased() == "yes"

// Path to the FontAwesome.ttf font file
let fontPath = "./FontAwesome.ttf"

// Function to convert HEX color to NSColor
func colorFromHex(_ hex: String) -> NSColor? {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hexSanitized.hasPrefix("#") {
        hexSanitized.removeFirst()
    }
    
    guard hexSanitized.count == 6, let hexNumber = UInt32(hexSanitized, radix: 16) else {
        return nil
    }
    
    let red = CGFloat((hexNumber >> 16) & 0xFF) / 255.0
    let green = CGFloat((hexNumber >> 8) & 0xFF) / 255.0
    let blue = CGFloat(hexNumber & 0xFF) / 255.0
    
    return NSColor(red: red, green: green, blue: blue, alpha: 1.0)
}

// Function to load font from file
func loadFont(from path: String, size: CGFloat) -> NSFont? {
    guard let fontData = NSData(contentsOfFile: path) else {
        print("❌ Font file not found!")
        return nil
    }
    
    let provider = CGDataProvider(data: fontData)
    guard CGFont(provider!) != nil else {
        print("❌ Error loading font")
        return nil
    }
    
    var error: Unmanaged<CFError>?
    let fontURL = URL(fileURLWithPath: path)
    if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
        print("❌ Font registration failed: \(error!.takeUnretainedValue())")
        return nil
    }
    
    return NSFont(name: "FontAwesome", size: size)
}

// Fetching the base color
guard let baseColor = colorFromHex(inputHexColor) else {
    print("Invalid HEX color format: \(inputHexColor)")
    exit(1)
}

// Generating the second color (70% darker)
let withFraction = iconGradient ? 0.7 : 0.0
let gradientColor = baseColor.blended(withFraction: withFraction, of: NSColor.black) ?? baseColor

// Setting the sizes
let canvasSize = NSSize(width: 512, height: 512)
let pointSize: CGFloat = canvasSize.height * 0.7

// Create an image where we will draw
let image = NSImage(size: canvasSize)
image.lockFocus()

// Drawing gradient background
if let context = NSGraphicsContext.current?.cgContext {
    let colors = [baseColor.cgColor, gradientColor.cgColor] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let locations: [CGFloat] = [0.0, 1.0]
    
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = max(canvasSize.width, canvasSize.height) * 0.7
        context.drawRadialGradient(gradient,
                                   startCenter: center,
                                   startRadius: 0,
                                   endCenter: center,
                                   endRadius: radius,
                                   options: [])
    }
}

// load font FontAwesome
guard let font = loadFont(from: fontPath, size: pointSize) else {
    print("❌ Nie udało się załadować czcionki.")
    exit(1)
}

// Creating text with Font Awesome
let iconCharacter = String(UnicodeScalar(UInt32(iconUnicode, radix: 16)!)!)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    
    .shadow: {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 10
        shadow.shadowOffset = NSSize(width: 5, height: -5)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.8)
        return shadow
    }()
]

let attributedString = NSAttributedString(string: iconCharacter, attributes: attributes)
let textSize = attributedString.size()

let textRect = NSRect(
    x: (canvasSize.width - textSize.width) / 2,
    y: (canvasSize.height - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)

attributedString.draw(in: textRect)

// Finish drawing
image.unlockFocus()

// Get the current user's directory
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let outputPath = "\(currentPath)/output.png"

// Save to PNG file
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Icon saved as: \(outputPath)")
    } catch {
        print("Error saving file: \(error)")
    }
} else {
    print("Failed to generate PNG data")
}
