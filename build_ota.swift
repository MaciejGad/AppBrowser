#!/usr/bin/swift

import Foundation

// MARK: - Configuration

let projectName = "AppBrowser"
let scheme = "AppBrowser"
let configuration = "Release"
let exportPath = "build"
let archiveFolder = "archives"
let archivePath = "\(archiveFolder)/\(projectName).xcarchive"
let ipaName = "\(projectName).ipa"
let ipaPath = "\(exportPath)/\(ipaName)"
let exportOptionsPlist = "\(exportPath)/exportOptions.plist"
let branch = "gh-pages"

// read script arguments
let arguments = CommandLine.arguments
let shouldPublish = arguments.contains("--publish")

// Detect GitHub repository info
func getGitHubRepoInfo() -> (user: String, repo: String)? {
    let remoteURL = shell("git config --get remote.origin.url").trimmingCharacters(in: .whitespacesAndNewlines)
    guard remoteURL.contains("github.com") else { return nil }

    let regex = try! NSRegularExpression(pattern: "(?:git@|https://)github.com[:/]([^/]+)/([^/.]+)", options: [])
    if let match = regex.firstMatch(in: remoteURL, range: NSRange(remoteURL.startIndex..., in: remoteURL)) {
        let user = (remoteURL as NSString).substring(with: match.range(at: 1))
        let repo = (remoteURL as NSString).substring(with: match.range(at: 2))
        return (user, repo)
    }
    return nil
}

guard let (githubUser, githubRepo) = getGitHubRepoInfo() else {
    print("❌ Could not detect GitHub repository.")
    exit(1)
}

let githubPagesURL = "https://\(githubUser).github.io/\(githubRepo)"
let plistURL = "\(githubPagesURL)/manifest.plist"
let ipaURL = "\(githubPagesURL)/\(ipaName)"
let otaHTMLPath = "\(exportPath)/index.html"
let plistPath = "\(exportPath)/manifest.plist"

// MARK: - Utility Functions

@discardableResult
func shell(_ command: String) -> String {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", command]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.launch()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: outputData, encoding: .utf8) ?? ""
}

// MARK: - Build and Export Process
print("🛠 Creating build directory...")
shell("mkdir -p \(exportPath)")
shell("mkdir -p \(archiveFolder)")

print("🚀 Configuring project")
shell("./configurator.swift")

print("📝 Generating exportOptions.plist...")
let exportOptions = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
"""
try? exportOptions.write(toFile: exportOptionsPlist, atomically: true, encoding: .utf8)

print("📦 Building and archiving the app...")
let buildCommand = """
xcodebuild -project \(projectName).xcodeproj \
    -scheme \(scheme) \
    -configuration \(configuration) \
    -sdk iphoneos \
    -archivePath \(archivePath) \
    -allowProvisioningUpdates \
    archive
"""
let buildOutput = shell(buildCommand)
print(buildOutput)

print("📤 Exporting IPA...")
let exportCommand = """
xcodebuild -exportArchive \
    -archivePath \(archivePath) \
    -exportPath \(exportPath) \
    -exportOptionsPlist \(exportOptionsPlist) \
    -allowProvisioningUpdates
"""
let exportOutput = shell(exportCommand)
print(exportOutput)

// Check if IPA file exists
guard FileManager.default.fileExists(atPath: ipaPath) else {
    print("❌ Error: IPA file was not created.")
    exit(1)
}

print("✅ IPA file created at: \(ipaPath)")

print("🔍 Reading bundle identifier from IPA...")
let ipaInfoCommand = "unzip -p \(ipaPath) 'Payload/*.app/Info.plist' | plutil -convert xml1 -o - -"
let ipaInfoPlist = shell(ipaInfoCommand)

guard let data = ipaInfoPlist.data(using: .utf8),
    let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
    let bundleIdentifier = plist["CFBundleIdentifier"] as? String else {
    print("❌ Error: Could not read bundle identifier from IPA.")
    exit(1)
}

print("✅ Bundle identifier: \(bundleIdentifier)")

// MARK: - Generate OTA Files

print("📝 Generating manifest.plist...")
let manifestTemplatePath = "manifest_template.plist"
guard let manifestTemplate = try? String(contentsOfFile: manifestTemplatePath, encoding: .utf8) else {
    print("❌ Error: Could not read manifest template file.")
    exit(1)
}

let manifestPlist = manifestTemplate
    .replacingOccurrences(of: "$(bundleIdentifier)", with: bundleIdentifier)
    .replacingOccurrences(of: "$(ipaURL)", with: ipaURL)
    .replacingOccurrences(of: "$(projectName)", with: projectName)

try manifestPlist.write(toFile: plistPath, atomically: true, encoding: .utf8)

print("📝 Generating OTA installation page...")

let otaTemplatePath = "ota_template.html"
guard let otaTemplate = try? String(contentsOfFile: otaTemplatePath, encoding: .utf8) else {
    print("❌ Error: Could not read OTA template file.")
    exit(1)
}

let otaHTML = otaTemplate
    .replacingOccurrences(of: "$(projectName)", with: projectName)
    .replacingOccurrences(of: "$(plistURL)", with: plistURL)

try otaHTML.write(toFile: otaHTMLPath, atomically: true, encoding: .utf8)

// MARK: - Deploy to GitHub Pages

if shouldPublish {
    print("🚀 Deploying to GitHub Pages...")
    shell("git checkout -B \(branch)")
    shell("mkdir -p docs")
    shell("mv \(ipaPath) \(plistPath) \(otaHTMLPath) docs/")
    shell("./generate_qr.swift \(githubPagesURL) docs/qr.png")
    shell("git add docs/\(ipaName) docs/manifest.plist docs/index.html docs/qr.png")
    shell("git commit -m \"🚀 Deploy OTA build \(Date())\"")
    shell("git push -f origin \(branch)")

    print("🎉 OTA build deployed!")
    print("➡️ Share this link with testers:")
    print("📲 \(githubPagesURL)/index.html")
    shell("git checkout main")
}
