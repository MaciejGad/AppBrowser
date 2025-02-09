#!/usr/bin/swift
import Foundation
import AppKit

// File paths
let configPath = "config.json"
let xcconfigPath = "AppBrowser/Config.xcconfig"

let fileManager = FileManager.default
let currentDirectoryPath = fileManager.currentDirectoryPath

// Read config.json file
guard let configData = fileManager.contents(atPath: configPath) else {
    print("Cannot read \(configPath)")
    exit(1)
}

// Define a struct for the JSON data
struct Config: Codable {
    let app_url: String
    let display_name: String
    let bundle_id: String
    let biometric_authentication: Bool?
    let icon_name: String?
    let icon_background_color: String?
    let icon_link: String? 
    let exception_list_url: String?
    let exception_list: [String]?

    var shouldCreateIcon: Bool {
        return icon_name != nil || icon_link != nil
    }   
}

// Decode the JSON data into the Config struct
let decoder = JSONDecoder()
guard let config = try? decoder.decode(Config.self, from: configData) else {
    print("Error decoding JSON")
    exit(1)
}

// Process app_url into BASE_HOST and BASE_PATH
var baseHost = ""
var basePath = ""
if let url = URL(string: config.app_url) {
    baseHost = url.host ?? ""
    basePath = url.path
} else {
    print("Error processing hostname and path")
    exit(1)
}

// Create content for Config.xcconfig
var xcconfigContent = ""
xcconfigContent += "DISPLAY_NAME = \(config.display_name)\n"
xcconfigContent += "PRODUCT_BUNDLE_IDENTIFIER = \(config.bundle_id)\n"

let biometric_authentication = config.biometric_authentication ?? false
xcconfigContent += "BIOMETRIC_AUTHENTICATION = \(biometric_authentication ? "YES" : "NO")\n"

func remove(file: String) throws {
    if fileManager.fileExists(atPath: file) {
            try fileManager.removeItem(atPath: file)
            print("Removed \(file)")
    }
}   

func copy(file: String, to: String) throws {
    try remove(file: to)
    try fileManager.copyItem(atPath: file, toPath: to)
    print("Copied \(file) to \(to)")
}

func generate(iconName: String, iconBackgroundColor: String, output: String) throws{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["swift", "icon_gen.swift", iconName, iconBackgroundColor, output]
    try process.run()
    process.waitUntilExit()
}

func resizeImage(atPath path: String, toSize size: CGSize) throws {
    guard let image = NSImage(contentsOfFile: path) else {
        throw NSError(domain: "Cannot load image", code: 1)
    }

    let newImage = NSImage(size: size)
    newImage.lockFocus()

    let rect = NSRect(origin: .zero, size: size)
    let imageRect = NSRect(origin: .zero, size: image.size)
    let aspectRatio = min(size.width / image.size.width, size.height / image.size.height)
    let scaledImageRect = NSRect(
        x: (size.width - image.size.width * aspectRatio) / 2,
        y: (size.height - image.size.height * aspectRatio) / 2,
        width: image.size.width * aspectRatio,
        height: image.size.height * aspectRatio
    )

    NSColor.white.setFill()
    rect.fill()

    image.draw(in: scaledImageRect, from: imageRect, operation: .sourceOver, fraction: 1.0)
    newImage.unlockFocus()

    guard let tiffData = newImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Cannot create PNG data", code: 2)
    }

    try pngData.write(to: URL(fileURLWithPath: path))
}

if config.shouldCreateIcon {
    do {
        // Remove existing output.png file
        let outputPath = "\(currentDirectoryPath)/output.png"
        let destinationPath = "\(currentDirectoryPath)/AppBrowser/Assets.xcassets/AppIcon.appiconset/icon.png"

        try remove(file: outputPath)

        if let iconName = config.icon_name {
            // Generate icon using icon_gen.swift
            let iconBackgroundColor = config.icon_background_color ?? "#3498db"  // Default color is blue  
            try generate(iconName: iconName, iconBackgroundColor: iconBackgroundColor, output: outputPath)
            try copy(file: outputPath, to: destinationPath)
        } else if let iconLink = config.icon_link {
           // Download icon from URL
            guard let url = URL(string: iconLink) else {
                throw NSError(domain: "Invalid icon link URL", code: 1)
            }
            let data = try Data(contentsOf: url)
            fileManager.createFile(atPath: outputPath, contents: data, attributes: nil)
            try resizeImage(atPath: outputPath, toSize: CGSize(width: 512, height: 512))
            try copy(file: outputPath, to: destinationPath)
        }
    } catch {
        print("\(error)")
        exit(1)
    } 
}

xcconfigContent += "BASE_HOST = \(baseHost)\n"
xcconfigContent += "BASE_PATH = \(basePath)\n"
if let exceptionListURL = config.exception_list_url {
    xcconfigContent += "EXCEPTIONS_LIST = \(exceptionListURL.replacingOccurrences(of: "//", with: "/\\()/"))\n"
}

if let exception_list = config.exception_list {
    let exceptionListData = try JSONSerialization.data(withJSONObject: exception_list, options: .prettyPrinted)
    let exceptionListPath = "\(currentDirectoryPath)/AppBrowser/url_exceptions.json"
    try exceptionListData.write(to: URL(fileURLWithPath: exceptionListPath))
}

// Save to Config.xcconfig file
do {
    try xcconfigContent.write(toFile: xcconfigPath, atomically: true, encoding: .utf8)
    print("File \(xcconfigPath) has been generated.")
} catch {
    print("Error writing file: \(error)")
    exit(1)
}
