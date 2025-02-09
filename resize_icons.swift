#!/usr/bin/swift
import Foundation
import AppKit

func resizeImage(atPath path: String, toSize size: CGSize, outputPath: String) throws {
    guard let image = NSImage(contentsOfFile: path) else {
        throw NSError(domain: "Cannot load image", code: 1)
    }

    let realSize = CGSize(width: size.width * 0.5, height: size.height * 0.5) 

    let newImage = NSImage(size: realSize)
    newImage.lockFocus()

    let rect = NSRect(origin: .zero, size: realSize)
    let imageRect = NSRect(origin: .zero, size: image.size)
    let aspectRatio = min(realSize.width / image.size.width, realSize.height / image.size.height)
    let scaledImageRect = NSRect(
        x: (realSize.width - image.size.width * aspectRatio) / 2,
        y: (realSize.height - image.size.height * aspectRatio) / 2,
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

    try pngData.write(to: URL(fileURLWithPath: outputPath))
}

let fileManager = FileManager.default
let currentDirectoryPath = fileManager.currentDirectoryPath

let outputPath = "\(currentDirectoryPath)/output.png"

let icon57Path = "\(currentDirectoryPath)/icon.57x57.png"
let icon512Path = "\(currentDirectoryPath)/icon.512x512.png"

try resizeImage(atPath: outputPath, toSize: CGSize(width: 57, height: 57), outputPath: icon57Path)
try resizeImage(atPath: outputPath, toSize: CGSize(width: 512, height: 512), outputPath: icon512Path)