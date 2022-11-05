//
//  MuMidi.swift
//  MuseSky
//
//  Created by warren on 9/19/20.
//  Copyright © 2020 Muse. All rights reserved.
//

import Foundation
import AudioKit
import AVFoundation
import Tr3

class MuMidi {
    
    public static let shared = MuMidi()
    
    public func test(root: Tr3) {
        let midi = MIDI.sharedInstance
        let listener = MuMidiListener(root)
        
        midi.openInput()
        midi.addListener(listener)
        //??? midi.openOutput()
        // startupMidiFighterTest() // not used
    }

    public func startupMidiFighterTest() {
        let midi = MIDI.sharedInstance
        Task {
            for cc in 0...15 {
                for value in 0...126 {
                    midi.sendControllerMessage(MIDIByte(cc),
                                               value: MIDIByte(value),
                                               channel: MIDIChannel(0))
                    try await Task.sleep(nanoseconds: 1_000_000)
                }
            }
        }
    }
}
