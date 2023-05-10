//
//  MuMidi.swift
//  MuseSky
//
//  Created by warren on 9/19/20.
//  Copyright © 2020 Muse. All rights reserved.


import Foundation
import AudioKit
import MuFlo
import MuPar // Visitor

class MuMidi {

    let listener: MuMidiListener
    
    init(root: Flo) {
        let midi = MIDI.sharedInstance
        listener = MuMidiListener(root)
        
        midi.openInput()
        midi.addListener(listener)
        midi.openOutput()
        // startupMidiFighterTest() // not used
    }
    
    public func startupMidiFighterTest() {
        let midi = MIDI.sharedInstance
        Task {
            for cc in 0...15 {
                for value in 0...126 {
                    midi.sendControllerMessage(
                        MIDIByte(cc),
                        value: MIDIByte(value),
                        channel: MIDIChannel(0))
                    try await Task.sleep(nanoseconds: 1_000_000)
                }
            }
        }
    }

    public func remoteMidiItem(_ item: MidiItem) {
        let midiFlo = listener.midiFlo
        
        switch item.type {
            case .noteOn:     if let i = item.item as? MidiNoteItem         { midiFlo.noteOnIn(i.num, i.velo, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
            case .noteOff:    if let i = item.item as? MidiNoteItem         { midiFlo.noteOffIn(i.num , i.velo, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
            case .controller: if let i = item.item as? MidiControllerItem   { midiFlo.controllerIn(i.cc, i.velo, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
            case .aftertouch: if let i = item.item as? MidiAftertouchItem   { midiFlo.aftertouchIn(i.num, i.val, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
            case .pitchwheel: if let i = item.item as? MidiPitchwheelItem   { midiFlo.pitchwheelIn(i.val, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
            case .program:    if let i = item.item as? MidiProgramItem      { midiFlo.programChangeIn(i.num, i.chan, i.port, i.time, Visitor(item.visitFrom + .remote)) }
        }
    }
}
