#!/usr/bin/swift
import Foundation

struct ColorJSON: Codable {
    struct ColorEntry: Codable {
        struct Color: Codable {
            struct Components: Codable {
                let alpha: String
                let blue: String
                let green: String
                let red: String
            }
            
            let colorSpace: String
            let components: Components
            
            enum CodingKeys: String, CodingKey {
                case colorSpace = "color-space"
                case components
            }
        }
        
        let color: Color
        let idiom: String
    }
    
    struct Info: Codable {
        let author: String
        let version: Int
    }
    
    let colors: [ColorEntry]
    let info: Info
}

func hexToRGBComponents(hex: String) -> (red: Double, green: Double, blue: Double)? {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if hexSanitized.hasPrefix("#") {
        hexSanitized.removeFirst()
    }
    
    guard hexSanitized.count == 6 else { return nil }
    
    var rgbValue: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgbValue)
    
    let red = Double((rgbValue >> 16) & 0xFF) / 255.0
    let green = Double((rgbValue >> 8) & 0xFF) / 255.0
    let blue = Double(rgbValue & 0xFF) / 255.0
    
    return (red, green, blue)
}

func generateColorJSON(from hexColor: String) -> Data? {
    guard let (red, green, blue) = hexToRGBComponents(hex: hexColor) else { return nil }
    
    let colorJSON = ColorJSON(
        colors: [
            .init(
                color: .init(
                    colorSpace: "srgb",
                    components: .init(
                        alpha: "1.000",
                        blue: String(format: "%.3f", blue),
                        green: String(format: "%.3f", green),
                        red: String(format: "%.3f", red)
                    )
                ),
                idiom: "universal"
            )
        ],
        info: .init(author: "xcode", version: 1)
    )
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    return try? encoder.encode(colorJSON)
}

func saveJSONToFile(jsonData: Data, filePath: String) {
    let fileURL = URL(fileURLWithPath: filePath)
    
    do {
        try jsonData.write(to: fileURL, options: .atomic)
        print("✅ JSON file saved at: \(fileURL.path)")
    } catch {
        print("❌ Failed to save JSON file: \(error.localizedDescription)")
    }
}

// MARK: - Command Line Interface
let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    print("❌ Usage:  \(CommandLine.arguments[0]) <hex_color> <file_path>")
    exit(1)
}

let hexColor = arguments[1]
let filePath = arguments[2]

if let jsonData = generateColorJSON(from: hexColor) {
    saveJSONToFile(jsonData: jsonData, filePath: filePath)
} else {
    print("❌ Invalid hex color format. Please provide a valid 6-character hex code (e.g., #FF6600).")
    exit(1)
}
