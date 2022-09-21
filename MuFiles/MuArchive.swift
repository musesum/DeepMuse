//
//  MuArchive.swift
//  MuseSky
//
//  Created by warren on 7/23/21.
//  Copyright © 2021 Muse. All rights reserved.

import Foundation
import ZIPFoundation

class MuArchive {

    private let fileManager = FileManager.default
    private var docURL: URL
    private var archiveName: String
    private var archiveURL: URL

    public var archive: Archive?

    init(_ archiveName: String, readOnly: Bool = false) {

        self.archiveName = archiveName
        docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        archiveURL = docURL
        archiveURL.appendPathComponent(archiveName)

        if readOnly {
            archive = Archive(url: archiveURL, accessMode: .read)
        }
        else {
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
            print("🚫 nil archive available for add(\(filename))")
            return
        }
        do {
            try archive.addEntry(
                with: filename, type: .file,
                uncompressedSize: UInt32(data.count),
                compressionMethod: .deflate) { (position, size)  in

                    return data.subdata(in: position ..< position+size)
                }
        }
        catch {
            print("🚫 \(error)")
        }
    }

    func get(_ filename: String, _ bufSize: Int, _ callback: @escaping  ((Data?)->())) {
        guard let archive = archive else {
            print("🚫 nil archive available for get(\(filename))")
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
                print("🚫 \(error)")
            }
        }
    }
    func copy(_ at: String,  to: String) {
        let atURL = docURL.appendingPathComponent(at)
        let toURL = docURL.appendingPathComponent(to)

        do {
            _ = try FileManager.default.replaceItemAt(toURL, withItemAt: atURL)
        } catch {
            print("🚫 could not copy \(at) to: \(to)")
        }
    }

}
