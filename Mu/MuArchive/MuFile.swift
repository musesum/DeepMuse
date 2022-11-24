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
    private let documentURL: URL
    private let libraryURL: URL
    private var fileURLs: [URL]
    
    init() {
        documentURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first!
        
        libraryURL = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask).first!
        
        fileURLs = FileManager.default.contentsOf(ext: nil)
        printFileURLs()
    }
    func printFileURLs() {
        for url in fileURLs {
            print(url)
        }
    }
    
    /**
     Get creation date from file. This is explicitely set and should match between devices.
     */
    func getFileTime(_ filePath: String) -> TimeInterval {
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileDate = (fileAttributes[FileAttributeKey.modificationDate] as? NSDate)!
            let fileTime = fileDate.timeIntervalSince1970
            //Log("⧉ \(#function) \(fileTime)")
            return fileTime
        }
        catch  { }
        return 0
    }
    public func documentDate(_ fileName: String) -> TimeInterval {
        let date = getFileTime( documentURL.path + "/" + fileName)
        if date == 0 {
            print("*** no Documents/\(fileName) ")
        }
        return getFileTime( documentURL.path + "/" + fileName)
    }
    public func pathDate(_ filePath: String) -> TimeInterval {
        return getFileTime( filePath)
    }
}
