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

class MuLog {
    static func print(_ icon: String, _ msg: String) {
        Swift.print(icon + msg, terminator: " ")
    }
}

class MidiTr3 {

    var noteOn˚: Tr3?
    var noteOff˚: Tr3?
    var controller˚: Tr3?
    var afterTouch˚: Tr3?
    var pitchBend˚: Tr3?
    var programChange˚: Tr3?


    public var setOptions: Tr3SetOptions = [.activate]

    init(_ root: Tr3, io: String) {
        bindTr3(root, io: io)
    }

    func bindTr3(_ root: Tr3, io: String) {

        if  let midi = root.findPath("midi"),
            let io = midi.findPath(io) { // input or output

            noteOn˚ = io.findPath("note.on")
            noteOff˚ = io.findPath("note.off")
            controller˚ = io.findPath("controller")
            afterTouch˚ = io.findPath("afterTouch")
            pitchBend˚ = io.findPath("pitchBend")
            programChange˚ = io.findPath("programChange")
        }
    }

    func noteOn(_ num: MIDINoteNumber,
                _ velo: MIDIVelocity,
                _ chan: MIDIChannel,
                _ port: MIDIUniqueID?,
                _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("num", num),
            ("velo", velo),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        noteOn˚?.setAny(tuple, setOptions)
    }

    func noteOff(_ num: MIDINoteNumber,
                 _ velo: MIDIVelocity,
                 _ chan: MIDIChannel,
                 _ port: MIDIUniqueID?,
                 _ time: MIDITimeStamp?) {
        let tuple: [(String, Any)] = [
            ("num", num),
            ("velo", velo),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        noteOff˚?.setAny(tuple, setOptions)
    }

    func controller(_ ctrl: MIDIByte,
                    _ val: MIDIVelocity,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("ctrl", ctrl),
            ("val", val),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        controller˚?.setAny(tuple, setOptions)
    }

    func aftertouch(_ num: MIDINoteNumber,
                    _ val: MIDIByte,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("num", num),
            ("val", val),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        afterTouch˚?.setAny(tuple, setOptions)
    }

    func aftertouch(_ val: MIDIByte,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("val", val),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        afterTouch˚?.setAny(tuple, setOptions)
    }

    func pitchWheel(_ val: MIDIWord,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("val", val),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        pitchBend˚?.setAny(tuple, setOptions)
    }

    func programChange(_ num: MIDIByte,
                       _ chan: MIDIChannel,
                       _ port: MIDIUniqueID?,
                       _ time: MIDITimeStamp?) {

        let tuple: [(String, Any)] = [
            ("num", num),
            ("chan", chan),
            ("port", port ?? 0),
            ("time", time ?? 0)]

        programChange˚?.setAny(tuple, setOptions)
    }
}

class MuMidiListener: MIDIListener {

    private var receive: MidiTr3

    init(_ root: Tr3) {
        receive = MidiTr3(root, io: "input")
    }

    func note(_ note: MIDINoteNumber, _ velocity: MIDIVelocity) -> String {
        let names = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
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

        MuLog.print("♪", note(noteNumber, velocity))
        receive.noteOn(noteNumber, velocity, channel, portID, timeStamp)
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber,
                             velocity: MIDIVelocity,
                             channel: MIDIChannel,
                             portID: MIDIUniqueID?,
                             timeStamp: MIDITimeStamp?) {

        MuLog.print("∅", note(noteNumber, velocity))
        receive.noteOn(noteNumber, velocity, channel, portID, timeStamp)
    }

    func receivedMIDIController(_ controller: MIDIByte,
                                value: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {

        MuLog.print("🎚", "\(controller):\(value)")
        receive.controller(controller, value, channel, portID, timeStamp)
    }

    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber,
                                pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {

        MuLog.print("👆", note(noteNumber, pressure))
        receive.aftertouch(noteNumber, channel, portID, timeStamp)
    }

    func receivedMIDIAftertouch(_ pressure: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        MuLog.print("👆", "\(channel):\(pressure)")
        receive.aftertouch(pressure, channel, portID, timeStamp)
    }

    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        MuLog.print("◯⃝", "\(pitchWheelValue)")
        receive.pitchWheel(pitchWheelValue, channel, portID, timeStamp)
    }

    func receivedMIDIProgramChange(_ program: MIDIByte,
                                   channel: MIDIChannel,
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MuLog.print("⚙️", "\(program)")
        receive.programChange(program, channel, portID, timeStamp)
    }

    func receivedMIDISystemCommand(_ data: [MIDIByte],
                                   portID: MIDIUniqueID?,
                                   timeStamp: MIDITimeStamp?) {
        MuLog.print("🆇", " Midi System \(data)\n")
    }
    
    func receivedMIDISetupChange() {
        MuLog.print("🅢", " Midi Setup change\n")
    }

    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {
        MuLog.print("🅟", " Midi Property messageID: \(propertyChangeInfo.messageID)\n")
    }

    func receivedMIDINotification(notification: MIDINotification) {
        MuLog.print("🅼", " Midi Notification messageID:\(notification.messageID)\n")
    }
}

class MuMidi {

    public static let shared = MuMidi()

    public func test(root: Tr3 ) {
        let midi = MIDI.sharedInstance
        let listener = MuMidiListener(root)
        midi.openInput()
        midi.addListener(listener)
    }
}
