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
    static var lastIcon = ""
    static func nextIcon(_ icon: String)  -> String {
        if icon == lastIcon { return "" }
        lastIcon = icon
        return icon
    }

    static func print(_ icon: String, _ msg: String, terminator: String = " ") {
        Swift.print(icon + msg, terminator: terminator)
        if !icon.isEmpty {
            lastIcon = icon
        }
    }
}

class MidiTr3 {

    var noteOn˚       : Tr3
    var noteOff˚      : Tr3
    var controller˚   : Tr3
    var afterTouch˚   : Tr3
    var pitchBend˚    : Tr3
    var programChange˚: Tr3

    public var setOptions: Tr3SetOptions = [.activate]

    init(_ root: Tr3) {
        
        let midi = root.bindPath("midi")
        let input = midi.bindPath("input")
        
        noteOn˚        = input.bindPath("note.on")
        noteOff˚       = input.bindPath("note.off")
        controller˚    = input.bindPath("controller")
        afterTouch˚    = input.bindPath("afterTouch")
        pitchBend˚     = input.bindPath("pitchBend")
        programChange˚ = input.bindPath("programChange")
    }

    func noteOn(_ num: MIDINoteNumber,
                _ velo: MIDIVelocity,
                _ chan: MIDIChannel,
                _ port: MIDIUniqueID?,
                _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("num" , Float(num)),
            ("velo", Float(velo)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        noteOn˚.setAny(exprs, setOptions)
    }

    func noteOff(_ num: MIDINoteNumber,
                 _ velo: MIDIVelocity,
                 _ chan: MIDIChannel,
                 _ port: MIDIUniqueID?,
                 _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("num" , Float(num)),
            ("velo", Float(velo)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        noteOff˚.setAny(exprs, setOptions)
    }

    func controller(_ cc: MIDIByte,
                    _ val: MIDIVelocity,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("cc" , Float(cc)),
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        controller˚.setAny(exprs, setOptions)
    }

    func aftertouch(_ num: MIDINoteNumber,
                    _ val: MIDIByte,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("num" , Float(num)),
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        afterTouch˚.setAny(exprs, setOptions)
    }

    func aftertouch(_ val: MIDIByte,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        afterTouch˚.setAny(exprs, setOptions)
    }

    func pitchWheel(_ val : MIDIWord,
                    _ chan: MIDIChannel,
                    _ port: MIDIUniqueID?,
                    _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        pitchBend˚.setAny(exprs, setOptions)
    }

    func programChange(_ num : MIDIByte,
                       _ chan: MIDIChannel,
                       _ port: MIDIUniqueID?,
                       _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("num" , Float(num)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])
        programChange˚.setAny(exprs, setOptions)
    }
}

class MuMidiListener: MIDIListener {

    private var receive: MidiTr3

    init(_ root: Tr3) {
        receive = MidiTr3(root)
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

        MuLog.print("\n♪", note(noteNumber, velocity))
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

    func receivedMIDIController(_ cc: MIDIByte,
                                value: MIDIByte,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {


        let icon = MuLog.nextIcon("🎚\(channel):\(cc) ")
        MuLog.print(icon, "\(value)")
        receive.controller(cc, value, channel, portID, timeStamp)
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
        MuLog.print("👇", "\(channel):\(pressure)")
        receive.aftertouch(pressure, channel, portID, timeStamp)
    }

    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
                                channel: MIDIChannel,
                                portID: MIDIUniqueID?,
                                timeStamp: MIDITimeStamp?) {
        let icon = MuLog.nextIcon("±⃝")
        MuLog.print(icon, "\(Int64(pitchWheelValue)-8192)")
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
        MuLog.print("🅼", " Midi Notification messageID: \(notification.messageID)\n")
    }
}

class MuMidi {
    
    public static let shared = MuMidi()
    
    public func test(root: Tr3) {
        let midi = MIDI.sharedInstance
        let listener = MuMidiListener(root)
        
        midi.openInput()
        midi.addListener(listener)
//        midi.openOutput()
//        Task {
//            for cc in 0...15 {
//                for value in 0...126 {
//                    midi.sendControllerMessage(MIDIByte(cc),
//                                               value: MIDIByte(value),
//                                               channel: MIDIChannel(0))
//                    try await Task.sleep(nanoseconds: 1_000_000)
//                }
//            }
//        }
    }
}
