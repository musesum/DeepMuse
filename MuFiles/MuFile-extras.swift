//
//  MuFile-extras.swift
//  MuseSky
//
//  Created by warren on 7/23/21.
//  Copyright © 2021 Muse. All rights reserved.
//

import Foundation
import Compression

func testUnzipArchive() {

    let fileManager = FileManager()
    let currentWorkingPath = fileManager.currentDirectoryPath
    var sourceURL = URL(fileURLWithPath: currentWorkingPath)
    sourceURL.appendPathComponent("archive.zip")
    var destinationURL = URL(fileURLWithPath: currentWorkingPath)
    destinationURL.appendPathComponent("directory")
    do {
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: sourceURL, to: destinationURL)
    } catch {
        print("Extraction of ZIP archive failed with error:\(error)")
    }
}
/// see https://github.com/weichsel/ZIPFoundation
func testZipArchive() {

    let fileManager = FileManager()
    let currentWorkingPath = fileManager.currentDirectoryPath
    var sourceURL = URL(fileURLWithPath: currentWorkingPath)
    sourceURL.appendPathComponent("file.txt")
    var destinationURL = URL(fileURLWithPath: currentWorkingPath)
    destinationURL.appendPathComponent("archive.zip")
    do {
        try fileManager.zipItem(at: sourceURL, to: destinationURL)
    } catch {
        print("Creation of ZIP archive failed with error:\(error)")
    }
}

// straight decompress using Apple Compress Lib
func decompress(_ data: Data) -> String {

    let size = 8_000_000
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
    let result = data.subdata(in: 2 ..< data.count).withUnsafeBytes ({
        let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                             data.count - 2, nil, COMPRESSION_ZLIB)
        return String(decoding: Data(bytes: buffer, count: read), as: UTF8.self)
    }) as String
    buffer.deallocate()
    return result
}

