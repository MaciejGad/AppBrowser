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
    let auto_authenticate: Bool?
    let icon_name: String?
    let icon_background_color: String?
    let icon_gradient: Bool?
    let icon_link: String? 
    let external_host: String?
    let exception_list_url: String?
    let exception_list: [String]?
    let toolbar_items: String?
    let show_path: Bool?

    
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

let auto_authenticate = config.auto_authenticate ?? true
xcconfigContent += "AUTO_AUTHENTICATION = \(auto_authenticate ? "YES" : "NO")\n"

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


func run(command: String, arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments
    try process.run()
    process.waitUntilExit()
}

func generate(iconName: String, iconBackgroundColor: String, output: String, backgroundGradient: Bool) throws {
    try run(command: "swift", arguments: ["icon_gen.swift", iconName, iconBackgroundColor, output, backgroundGradient ? "YES" : "NO"])
}

func resize() throws {
    try run(command: "swift", arguments: ["resize_icons.swift"])
}

if config.shouldCreateIcon {
    // Remove existing output.png file
    let outputPath = "\(currentDirectoryPath)/output.png"
    
    try remove(file: outputPath)

    if let iconName = config.icon_name {
        let iconGradient = config.icon_gradient ?? true
        // Generate icon using icon_gen.swift
        let iconBackgroundColor = config.icon_background_color ?? "#3498db"  // Default color is blue  
        try generate(
            iconName: iconName, 
            iconBackgroundColor: iconBackgroundColor, 
            output: outputPath, 
            backgroundGradient: iconGradient)
    } else if let iconLink = config.icon_link {
        // Download icon from URL
        guard let url = URL(string: iconLink) else {
            throw NSError(domain: "Invalid icon link URL", code: 1)
        }
        let data = try Data(contentsOf: url)
        fileManager.createFile(atPath: outputPath, contents: data, attributes: nil)
    }
    try resize()
}

try run(command: "swift", arguments: ["color_gen.swift", config.icon_background_color ?? "#3498db", "AppBrowser/Assets.xcassets/AccentColor.colorset/Contents.json"])

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

if let externalHost = config.external_host {
    xcconfigContent += "EXTERNAL_HOST = \(externalHost)\n"
}

if let toolbarItems = config.toolbar_items {
    xcconfigContent += "TOOLBAR_ITEMS = \(toolbarItems)\n"
}

let show_path = config.show_path ?? true
xcconfigContent += "SHOW_PATH = \(show_path ? "YES" : "NO")\n"

// Save to Config.xcconfig file
do {
    try xcconfigContent.write(toFile: xcconfigPath, atomically: true, encoding: .utf8)
    print("File \(xcconfigPath) has been generated.")
} catch {
    print("Error writing file: \(error)")
    exit(1)
}
