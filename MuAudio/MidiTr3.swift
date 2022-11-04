//
//  MidiTr3.swift
//  MuseSky2
//
//  Created by warren on 11/4/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import Foundation
import AudioKit
import AVFoundation
import Tr3

class MidiTr3 {

    var noteOnIn˚       : Tr3
    var noteOffIn˚      : Tr3
    var controllerIn˚   : Tr3
    var afterTouchIn˚   : Tr3
    var pitchBendIn˚    : Tr3
    var programChangeIn˚: Tr3
    var nrpnIn˚         : Tr3

    var noteOnOut˚       : Tr3
    var noteOffOut˚      : Tr3
    var controllerOut˚   : Tr3
    var afterTouchOut˚   : Tr3
    var pitchBendOut˚    : Tr3
    var programChangeOut˚: Tr3
    var nrpnOut˚         : Tr3

    var nrpnNumMsb: Float = -1
    var nrpnNumLsb: Float = -1
    var nrpnValMsb: Float = -1
    var nrpnValLsb: Float = -1


    public var setOptions: Tr3SetOptions = [.activate]

    init(_ root: Tr3) {

        let midi = root.bindPath("midi")

        let input = midi.bindPath("input")
        noteOnIn˚        = input.bindPath("note.on")
        noteOffIn˚       = input.bindPath("note.off")
        controllerIn˚    = input.bindPath("controller")
        afterTouchIn˚    = input.bindPath("afterTouch")
        pitchBendIn˚     = input.bindPath("pitchBend")
        programChangeIn˚ = input.bindPath("programChange")
        nrpnIn˚          = input.bindPath("nrpn")

        let output = midi.bindPath("output")
        noteOnOut˚        = output.bindPath("note.on") { _ ,_ in print("*** yo") }
        noteOffOut˚       = output.bindPath("note.off") { _ ,_ in print("*** oy") }
        controllerOut˚    = output.bindPath("controller")
        afterTouchOut˚    = output.bindPath("afterTouch")
        pitchBendOut˚     = output.bindPath("pitchBend")
        programChangeOut˚ = output.bindPath("programChange")
        nrpnOut˚          = output.bindPath("nrpn")
    }

    func noteOnIn(_ num: MIDINoteNumber,
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

        noteOnIn˚.setAny(exprs, setOptions)
    }

    func noteOffIn(_ num: MIDINoteNumber,
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

        noteOffIn˚.setAny(exprs, setOptions)
    }

    func controllerIn(_ cc: MIDIByte,
                      _ val: MIDIVelocity,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?) {

        switch cc {

            case 99: nrpnNumMsb = Float(val) ; return
            case 98: nrpnNumLsb = Float(val) ; return
            case  6: nrpnValMsb = Float(val) ; return

            case 38: nrpnValLsb = Float(val)

                if settingNrpn() {

                    let num = (nrpnNumMsb * 128) + nrpnNumLsb
                    let val = ((nrpnValMsb * 128) + nrpnValLsb) / 16383

                    let exprs = Tr3Exprs(nameFloats: [
                        ("num" , num),
                        ("val" , val),
                        ("chan", Float(chan)),
                        ("port", Float(port ?? 0)),
                        ("time", Float(time ?? 0))])

                    let icon = String(format: "%.0f:%.3f", num, val)
                    let seq = String(format: "[%.0f_%.0f : %.0f_%.0f]\n",
                                     nrpnNumMsb, nrpnNumLsb, nrpnValMsb, nrpnValLsb)
                    MidiLog.print(icon,seq)

                    nrpnIn˚.setAny(exprs, setOptions)
                    return
                }
            default: break //clearNrpn()
        }

        let exprs = Tr3Exprs(nameFloats: [
            ("cc"  , Float(cc)),
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        controllerIn˚.setAny(exprs, setOptions)
    }

    func settingNrpn() -> Bool {
        if nrpnNumMsb != -1,
           nrpnNumLsb != -1,
           nrpnValMsb != -1 {
            return true
        }
        return false
    }
    func clearNrpn() {
        nrpnNumMsb = -1
        nrpnNumLsb = -1
        nrpnValMsb = -1
        nrpnValLsb = -1
    }

    func aftertouchIn(_ num: MIDINoteNumber,
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

        afterTouchIn˚.setAny(exprs, setOptions)
    }

    func aftertouchIn(_ val: MIDIByte,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        afterTouchIn˚.setAny(exprs, setOptions)
    }

    func pitchWheelIn(_ val : MIDIWord,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("val" , Float(val)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])

        pitchBendIn˚.setAny(exprs, setOptions)
    }

    func programChangeIn(_ num : MIDIByte,
                         _ chan: MIDIChannel,
                         _ port: MIDIUniqueID?,
                         _ time: MIDITimeStamp?) {

        let exprs = Tr3Exprs(nameFloats: [
            ("num" , Float(num)),
            ("chan", Float(chan)),
            ("port", Float(port ?? 0)),
            ("time", Float(time ?? 0))])
        programChangeIn˚.setAny(exprs, setOptions)
    }
}
