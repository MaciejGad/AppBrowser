#!/usr/bin/swift
import Cocoa
import CoreText
import Foundation

// Sprawdzenie, czy podano argumenty
guard CommandLine.arguments.count > 1 else {
    print("Użycie: \(CommandLine.arguments[0]) <fontAwesomeUnicode> [hexColor]")
    exit(1)
}

let iconUnicode = CommandLine.arguments[1]
let inputHexColor = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "#3498db"

// Ścieżka do pliku czcionki FontAwesome.ttf
let fontPath = "./FontAwesome.ttf"

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

// Funkcja ładująca czcionkę z pliku
func loadFont(from path: String, size: CGFloat) -> NSFont? {
    guard let fontData = NSData(contentsOfFile: path) else {
        print("❌ Nie znaleziono pliku czcionki!")
        return nil
    }
    
    let provider = CGDataProvider(data: fontData)
    guard let cgFont = CGFont(provider!) else {
        print("❌ Błąd ładowania czcionki")
        return nil
    }
    
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
        print("❌ Rejestracja czcionki nie powiodła się: \(error!.takeUnretainedValue())")
        return nil
    }
    
    return NSFont(name: "FontAwesome", size: size)
}

// Pobranie koloru bazowego
guard let baseColor = colorFromHex(inputHexColor) else {
    print("Niepoprawny format koloru HEX: \(inputHexColor)")
    exit(1)
}

// Generowanie drugiego koloru (ciemniejszy o 70%)
let gradientColor = baseColor.blended(withFraction: 0.7, of: NSColor.black) ?? baseColor

// Ustalamy rozmiary
let canvasSize = NSSize(width: 512, height: 512)
let pointSize: CGFloat = canvasSize.height * 0.7

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

// Wczytanie czcionki FontAwesome
guard let font = loadFont(from: fontPath, size: pointSize) else {
    print("❌ Nie udało się załadować czcionki.")
    exit(1)
}

// Tworzenie tekstu z Font Awesome
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
print("Rozmiar tekstu: \(textSize)")   
let textRect = NSRect(
    x: (canvasSize.width - textSize.width) / 2,
    y: (canvasSize.height - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)

attributedString.draw(in: textRect)

// Kończymy rysowanie
image.unlockFocus()

// Pobieramy aktualny katalog użytkownika
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let outputPath = "\(currentPath)/output.png"

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
