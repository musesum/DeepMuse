//
//  FileManager+extension.swift
//  MuseSky
//
//  Created by warren on 9/23/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation

extension FileManager {

    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
    func contentsOf(ext: String?) -> [URL] {
        do {
            let docURL = urls(for: .documentDirectory, in: .userDomainMask).first!
            let allFiles = try contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil)
            if let ext = ext {
                return allFiles.filter{ $0.pathExtension == ext }
            }
            else  {
                return allFiles
            }
        }
        catch {
            print("🚫 \(error)")
            return []
        }
    }
    func removeItemIfExist(at url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("🚫 \(error)")
        }
    }
}

