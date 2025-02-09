#!/usr/bin/swift
import Foundation

// File paths
let configPath = "config.json"
let xcconfigPath = "AppBrowser/Config.xcconfig"

// Read config.json file
guard let configData = FileManager.default.contents(atPath: configPath) else {
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

if let iconName = config.icon_name {
    let iconBackgroundColor = config.icon_background_color ?? "#3498db"  // Default color is blue  
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["swift", "icon_gen.swift", iconName, iconBackgroundColor, "output.png"]
    do {
        try process.run()
        process.waitUntilExit()
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        let sourcePath = "\(currentDirectoryPath)/output.png"
        let destinationPath = "\(currentDirectoryPath)/AppBrowser/Assets.xcassets/AppIcon.appiconset/icon.png"
        if fileManager.fileExists(atPath: destinationPath) {
            try fileManager.removeItem(atPath: destinationPath) // Remove existing icon file    
        }
        try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
        print("Icon file copied to \(destinationPath)")
    } catch {
        print("Error running icon_gen command: \(error)")
        exit(1)
    }
}
xcconfigContent += "BASE_HOST = \(baseHost)\n"
xcconfigContent += "BASE_PATH = \(basePath)\n"

// Save to Config.xcconfig file
do {
    try xcconfigContent.write(toFile: xcconfigPath, atomically: true, encoding: .utf8)
    print("File \(xcconfigPath) has been generated.")
} catch {
    print("Error writing file: \(error)")
    exit(1)
}
