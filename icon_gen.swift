import Cocoa
import Foundation

// Sprawdzenie, czy podano argumenty
guard CommandLine.arguments.count > 1 else {
    print("Użycie: \(CommandLine.arguments[0]) <systemIconName> [hexColor]")
    exit(1)
}

let iconName = CommandLine.arguments[1]
let inputHexColor = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "#3498db"
let outputFileName =  CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "\(iconName).png"

// Funkcja do konwersji koloru HEX na NSColor
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

// Funkcja generująca pasujący drugi kolor do gradientu (jaśniejszy lub ciemniejszy wariant)
func adjustedColor(for color: NSColor, brightnessFactor: CGFloat) -> NSColor {
    let hue = color.hueComponent
    let saturation = color.saturationComponent
    let brightness = max(0.1, min(1.0, color.brightnessComponent * brightnessFactor))
    return NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
}

// Pobranie koloru bazowego
guard let baseColor = colorFromHex(inputHexColor) else {
    print("Niepoprawny format koloru HEX: \(inputHexColor)")
    exit(1)
}

// Generowanie drugiego koloru (ciemniejszy o 70%)
let gradientColor = adjustedColor(for: baseColor, brightnessFactor: 0.7)

// Ustalamy rozmiary
let canvasSize = NSSize(width: 512, height: 512)
let pointSize: CGFloat = canvasSize.height / 2

// Tworzymy obraz, w którym będziemy rysować
let image = NSImage(size: canvasSize)
image.lockFocus()

// Rysowanie gradientowego tła
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

// Wczytanie systemowej ikony SF Symbol
guard let systemImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) else {
    print("Nie znaleziono ikony systemowej o nazwie \(iconName)")
    exit(1)
}

// Konfiguracja rozmiaru ikony
let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
print(configuration)
guard let configuredImage = systemImage.withSymbolConfiguration(configuration) else {
    print("Nie udało się skonfigurować ikony")
    exit(1)
}

let iconSize = configuredImage.size

// Barwienie obrazu
func tintedImage(_ image: NSImage, with tint: NSColor) -> NSImage {
    let tinted = image.copy() as! NSImage
    tinted.lockFocus()
    tint.set()
    let imageRect = NSRect(origin: .zero, size: tinted.size)
    imageRect.fill(using: .sourceAtop)
    tinted.unlockFocus()
    return tinted
}

// Barwimy ikonę na biało
let finalIcon = tintedImage(configuredImage, with: NSColor.white)

// Efekt cienia
let shadow = NSShadow()
shadow.shadowOffset = NSSize(width: 5, height: -5)
shadow.shadowBlurRadius = 10
shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
shadow.set()

// Prostokąt dla ikony
let iconRect = NSRect(
    x: (canvasSize.width - iconSize.width) / 2,
    y: (canvasSize.height - iconSize.height) / 2,
    width: iconSize.width,
    height: iconSize.height
)

// Rysujemy ikonę na tle
finalIcon.draw(in: iconRect)

// Kończymy rysowanie
image.unlockFocus()

// Pobieramy aktualny katalog użytkownika
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let outputPath = "\(currentPath)/\(outputFileName)"

// Zapis do pliku PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Ikona zapisana jako: \(outputPath)")
    } catch {
        print("Błąd podczas zapisywania pliku: \(error)")
    }
} else {
    print("Nie udało się wygenerować danych PNG")
}
