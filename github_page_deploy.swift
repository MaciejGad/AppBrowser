#!/usr/bin/swift

import Foundation

let branch = "gh-pages"
let exportPath = "build"
let projectName = "AppBrowser"
let ipaName = "\(projectName).ipa"
let ipaPath = "\(exportPath)/\(ipaName)"
let plistPath = "\(exportPath)/manifest.plist"
let otaHTMLPath = "\(exportPath)/index.html"
let qrPath = "\(exportPath)/qr.png"

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

print("🚀 Building and exporting IPA...")
print(shell("swift build_ota.swift \(githubPagesURL)"))

print("🚀 Deploying to GitHub Pages...")
shell("git checkout -B \(branch)")
shell("mkdir -p docs")
shell("mv \(ipaPath) \(plistPath) \(otaHTMLPath) \(qrPath) docs/")

shell("git add docs/\(ipaName) docs/manifest.plist docs/index.html docs/qr.png")
shell("git commit -m \"🚀 Deploy OTA build \(Date())\"")
shell("git push -f origin \(branch)")

print("🎉 OTA build deployed!")
print("➡️ Share this link with testers:")
print("📲 \(githubPagesURL)/index.html")
shell("git checkout main")