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

        ccOutputZero() // not used
    }
    
    public func ccOutputZero() {
        let midi = MIDI.sharedInstance
        let value = 120
        Task {
            for cc in 0...15 {

                midi.sendControllerMessage(
                    MIDIByte(cc),
                    value: MIDIByte(value),
                    channel: MIDIChannel(0))
                try await Task.sleep(nanoseconds: 1_000)
            }
        }
    }

    /// received a midi event marshalled from Sky
    public func remoteMidiItem(_ item: MidiItem) {

        guard let any = item.item else { return }

        let flo = listener.midiFlo
        let visit = Visitor(item.visitFrom + .remote)

        switch item.type {
        case .noteOn:     if let i = any as? MidiNoteItem       { flo.noteOnIn        (i.num, i.velo, i.chan, i.port, i.time, visit) }
        case .noteOff:    if let i = any as? MidiNoteItem       { flo.noteOffIn       (i.num, i.velo, i.chan, i.port, i.time, visit) }
        case .controller: if let i = any as? MidiControllerItem { flo.controllerIn    (i.cc,  i.velo, i.chan, i.port, i.time, visit) }
        case .aftertouch: if let i = any as? MidiAftertouchItem { flo.aftertouchIn    (i.num, i.val,  i.chan, i.port, i.time, visit) }
        case .pitchbend:  if let i = any as? MidiPitchbendItem  { flo.pitchwheelIn    (       i.val,  i.chan, i.port, i.time, visit) }
        case .program:    if let i = any as? MidiProgramItem    { flo.programChangeIn (i.num,         i.chan, i.port, i.time, visit) }
        }
    }
}
