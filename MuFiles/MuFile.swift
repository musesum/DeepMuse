//
//  MuFile.swift
//  MuseSky
//
//  Created by warren on 9/23/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import UIKit
import Compression
import ZIPFoundation

class MuFile {
    
    static let shared = MuFile()
    private let fileManager = FileManager.default
    private let docURL: URL
    private var fileURLs: [URL]

    init() {
        docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURLs = fileManager.contentsOf(ext: nil)
        printFileURLs()
    }
    func printFileURLs() {
        for url in fileURLs {
            print(url)
        }
    }
    func saveFile(_ name: String, script: String) {
        let filename = docURL.appendingPathComponent(name)
        do {
            try script.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("🚫 \(error)")
        }
    }
    func saveFile(_ name: String, image: UIImage) -> Bool {

        let filename = docURL.appendingPathComponent(name)

        do {
            if name.hasSuffix("jpg") {
                if let data = image.jpegData(compressionQuality: 1)  {
                    try data.write(to: filename)
                }

            } else {
                if let data = image.pngData() {
                    try data.write(to: filename)
                }
            }
        }
        catch {
            print("🚫 \(error)")
            return false
        }
        return true
    }
    func saveFile(_ name: String, data: Data) -> Bool {

        let filename = docURL.appendingPathComponent(name)

        do { try data.write(to: filename) }

        catch {
            print("🚫 \(error)")
            return false
        }
        return true
    }

}
