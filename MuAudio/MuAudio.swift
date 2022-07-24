//
//  MuAudio.swift
//  MuseSky
//
//  Created by warren on 7/22/21.
//  Copyright © 2021 Muse. All rights reserved.
//

import Foundation
import AudioKit

class MuAudio {

    public static let shared = MuAudio()
    let engine = AudioEngine()

    public func test() {

        let oscillator = AudioKit.PlaygroundOscillator()
        engine.output = oscillator
        do {
            try engine.start()
            oscillator.start()
            oscillator.frequency = 440
            sleep(4)
            oscillator.stop()
        }
        catch {
            print("🚫 \(error)")
        }

    }
}
