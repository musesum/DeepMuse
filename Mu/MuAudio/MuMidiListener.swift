//
//  MuMidiListener.swift
//  MuseSky2
//
//  Created by warren on 11/4/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import Foundation
import AudioKit
import AVFoundation
import MuFlo
import MuPar // Visitor

class MuMidiListener: MIDIListener {

    public var midiFlo: MidiFlo

    init(_ root: Flo) {
        midiFlo = MidiFlo(root)
    }

    func note(_ note: MIDINoteNumber,
              _ velocity: MIDIVelocity) -> String {

        let names = ["C", "D♭", "D", "E♭", "E", "F",
                     "G♭", "G", "A♭", "A", "B♭", "B"]
        let octave = Int(note / 12)
        let note = Int(note % 12)
        let name = names[note]
        return "\(name)\(octave):\(velocity)"
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber,
                            velocity: MIDIVelocity,
                            channel: MIDIChannel,
                            portID: MIDIUniqueID?,
                            timeStamp: MIDITimeStamp?) {

        MidiLog.print("\n♪", note(noteNumber, velocity))
        midiFlo.noteOnIn(noteNumber, velocity, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber,
                             velocity: MIDIVelocity,
                             channel: MIDIChannel,
                             portID: MIDIUniqueID?,
                             timeStamp: MIDITimeStamp?) {

        MidiLog.print("∅", note(noteNumber, velocity))
        midiFlo.noteOffIn(noteNumber, velocity, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDIController(_ cc: MIDIByte,
                                value: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {


        let icon = MidiLog.nextIcon("🎚\(channel):\(cc) ")
        MidiLog.print(icon, "\(value)")
        midiFlo.controllerIn(cc, value, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber,
                                pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {

        MidiLog.print("􀖓", note(noteNumber, pressure))
        midiFlo.aftertouchIn(noteNumber, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDIAftertouch(_ pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        MidiLog.print("􀖓", "\(channel):\(pressure)")
        midiFlo.aftertouchIn(pressure, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        let icon = MidiLog.nextIcon("􁂩")
        MidiLog.print(icon, "\(Int64(pitchWheelValue)-8192)")
        midiFlo.pitchwheelIn(pitchWheelValue, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDIProgramChange(_ program: MIDIByte,
                                   channel: MIDIChannel,
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MidiLog.print("􀣋", "\(program)")
        midiFlo.programChangeIn(program, channel, portID, timeStamp, Visitor(.midi))
    }

    func receivedMIDISystemCommand(_ data: [MIDIByte],
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MidiLog.print("􀩿", " Midi System \(data)\n")
    }

    func receivedMIDISetupChange() {
        MidiLog.print("􁀘", " Midi Setup change\n")
        MIDI.sharedInstance.openInput()
        MIDI.sharedInstance.openOutput()
    }

    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {
        MidiLog.print("􀡷", " Midi Property messageID: \(propertyChangeInfo.messageID)\n")
    }

    func receivedMIDINotification(notification: MIDINotification) {
        MidiLog.print("􀑬", " Midi Notification messageID: \(notification.messageID)\n")
    }
}
