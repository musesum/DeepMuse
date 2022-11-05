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
import Tr3

class MuMidiListener: MIDIListener {

    private var midiTr3: MidiTr3

    init(_ root: Tr3) {
        midiTr3 = MidiTr3(root)
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
        midiTr3.noteOnIn(noteNumber, velocity, channel, portID, timeStamp)
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber,
                             velocity: MIDIVelocity,
                             channel: MIDIChannel,
                             portID: MIDIUniqueID?,
                             timeStamp: MIDITimeStamp?) {

        MidiLog.print("∅", note(noteNumber, velocity))
        midiTr3.noteOffIn(noteNumber, velocity, channel, portID, timeStamp)
    }

    func receivedMIDIController(_ cc: MIDIByte,
                                value: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {


        let icon = MidiLog.nextIcon("🎚\(channel):\(cc) ")
        MidiLog.print(icon, "\(value)")
        midiTr3.controllerIn(cc, value, channel, portID, timeStamp)
    }

    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber,
                                pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {

        MidiLog.print("👆", note(noteNumber, pressure))
        midiTr3.aftertouchIn(noteNumber, channel, portID, timeStamp)
    }

    func receivedMIDIAftertouch(_ pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        MidiLog.print("👇", "\(channel):\(pressure)")
        midiTr3.aftertouchIn(pressure, channel, portID, timeStamp)
    }

    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        let icon = MidiLog.nextIcon("±⃝")
        MidiLog.print(icon, "\(Int64(pitchWheelValue)-8192)")
        midiTr3.pitchWheelIn(pitchWheelValue, channel, portID, timeStamp)
    }

    func receivedMIDIProgramChange(_ program: MIDIByte,
                                   channel: MIDIChannel,
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MidiLog.print("⚙️", "\(program)")
        midiTr3.programChangeIn(program, channel, portID, timeStamp)
    }

    func receivedMIDISystemCommand(_ data: [MIDIByte],
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MidiLog.print("🆇", " Midi System \(data)\n")
    }

    func receivedMIDISetupChange() {
        MidiLog.print("🅢", " Midi Setup change\n")
    }

    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {
        MidiLog.print("🅟", " Midi Property messageID: \(propertyChangeInfo.messageID)\n")
    }

    func receivedMIDINotification(notification: MIDINotification) {
        MidiLog.print("🅼", " Midi Notification messageID: \(notification.messageID)\n")
    }
}
