//
//  MuArchive.swift
//  MuseSky
//
//  Created by warren on 7/23/21.
//  Copyright © 2021 Muse. All rights reserved.

import Foundation
import ZIPFoundation

public class MuArchive {
    
    private let fileManager = FileManager.default
    private var docURL: URL
    private var archiveName: String
    private var archiveURL: URL
    
    public var archive: Archive?
    
    public init(_ archiveName: String, readOnly: Bool = false) {
        
        self.archiveName = archiveName
        docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        archiveURL = docURL
        archiveURL.appendPathComponent(archiveName)
        
        if readOnly {
            archive = Archive(url: archiveURL, accessMode: .read)
        } else {
            archive = Archive(url: archiveURL, accessMode: .update)
            if archive == nil {
                archive = Archive(url: archiveURL, accessMode: .create)
            }
        }
    }
    
    /// return a preexisting archive, otherwise return nil
    static func readArchive(_ archiveName: String) -> MuArchive? {
        let muArchive = MuArchive(archiveName, readOnly: true)
        if muArchive.archive != nil {
            return muArchive
        } else {
            return nil
        }
    }
    
    func add(_ filename: String, data: Data) {
        guard let archive = archive else {
            print("⁉️ nil archive available for add(\(filename))")
            return
        }
        do {

            try archive.addEntry(
                with: filename,
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate) { (position, size)  in
                    let pos = Int(position)
                    return data.subdata(in: pos ..< (pos + size))
                }
        }
        catch {
            print("⁉️ \(error)")
        }
    }
    
    func get(_ filename: String,
             _ bufSize: Int,
             _ callback: @escaping  ((Data?)->())) {

        guard let archive = archive else {
            print("⁉️ nil archive available for get(\(filename))")
            callback(nil)
            return
        }
        
        if let entry = archive[filename] {
            var dataRet = Data()
            do {
                _ = try archive.extract(entry, bufferSize: Int(bufSize))  { data in
                    dataRet.append(data)
                }
                callback(dataRet)
            }
            catch {
                print("⁉️ \(error)")
            }
        }
    }
    func copy(_ at: String,  to: String) {
        let atURL = docURL.appendingPathComponent(at)
        let toURL = docURL.appendingPathComponent(to)
        
        do {
            _ = try FileManager.default.replaceItemAt(toURL, withItemAt: atURL)
        } catch {
            print("⁉️ could not copy \(at) to: \(to)")
        }
    }
    
}

///// Created by Gui Rambo
///// This wraps Apple's Compression framework to compress/decompress Data objects.
///// It will use Compression's modern API for iOS 13+ and its old API for older versions.
///// For more information, check out Apple's documentation: https://developer.apple.com/documentation/compression
//
//
//import Compression
//
//public extension Data {
//
//    /// Compresses the data using the specified compression algorithm.
//    func compressed(using algo: compression_algorithm = COMPRESSION_LZMA, pageSize: Int = 128) throws -> Data {
//
//        var outputData = Data()
//        let filter = try OutputFilter(.compress, using: Algorithm(rawValue: algo)!, bufferCapacity: pageSize, writingTo: { $0.flatMap({ outputData.append($0) }) })
//
//        var index = 0
//        let bufferSize = count
//
//        while true {
//            let rangeLength = Swift.min(pageSize, bufferSize - index)
//
//            let subdata = self.subdata(in: index ..< index + rangeLength)
//            index += rangeLength
//
//            try filter.write(subdata)
//
//            if (rangeLength == 0) { break }
//        }
//
//        return outputData
//    }
//
//    /// Decompresses the data using the specified compression algorithm.
//    func decompressed(from algo: compression_algorithm = COMPRESSION_LZMA, pageSize: Int = 128) throws -> Data {
//
//        do {
//            var outputData = Data()
//            let bufferSize = count
//            var decompressionIndex = 0
//
//            let filter = try InputFilter(.decompress, using: Algorithm(rawValue: algo)!) { (length: Int) -> Data? in
//                let rangeLength = Swift.min(length, bufferSize - decompressionIndex)
//                let subdata = self.subdata(in: decompressionIndex ..< decompressionIndex + rangeLength)
//                decompressionIndex += rangeLength
//
//                return subdata
//            }
//
//            while let page = try filter.readData(ofLength: pageSize) {
//                outputData.append(page)
//            }
//
//            return outputData
//        } catch {
//            // Try legacy decompression if modern decompression fails
//            return try gunzipped()
//        }
//    }
//}
