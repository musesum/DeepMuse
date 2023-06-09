//
//  MidiFlo.swift
//  MuseSky2
//
//  Created by warren on 11/4/22.
//  Copyright © 2022 Muse. All rights reserved.

import Foundation
import AudioKit
import AVFoundation
import MuFlo
import MuPar

class MidiFlo {

    var noteOnIn˚        : Flo
    var noteOffIn˚       : Flo
    var controllerIn˚    : Flo
    var afterTouchIn˚    : Flo
    var pitchBendIn˚     : Flo
    var programChangeIn˚ : Flo
    var nrpnIn˚          : Flo

    var noteOnOut˚       : Flo
    var noteOffOut˚      : Flo
    var controllerOut˚   : Flo
    var afterTouchOut˚   : Flo
    var pitchBendOut˚    : Flo
    var programChangeOut˚: Flo
    var nrpnOut˚         : Flo

    var nrpnNumMsb: Float = -1
    var nrpnNumLsb: Float = -1
    var nrpnValMsb: Float = -1
    var nrpnValLsb: Float = -1

    public var setOptions: FloSetOps = [.activate]

    init(_ root: Flo) {

        let midi = root.bind("midi")

        let input = midi.bind("input")
        noteOnIn˚        = input.bind("note.on")
        noteOffIn˚       = input.bind("note.off")
        controllerIn˚    = input.bind("controller")
        afterTouchIn˚    = input.bind("afterTouch")
        pitchBendIn˚     = input.bind("pitchBend")
        programChangeIn˚ = input.bind("programChange")
        nrpnIn˚          = input.bind("nrpn")

        let output = midi.bind("output")
        noteOnOut˚        = output.bind("note.on")
        noteOffOut˚       = output.bind("note.off")
        controllerOut˚    = output.bind("controller")
        afterTouchOut˚    = output.bind("afterTouch")
        pitchBendOut˚     = output.bind("pitchBend")
        programChangeOut˚ = output.bind("programChange")
        nrpnOut˚          = output.bind("nrpn")
    }

    func noteOnIn(_ num: MIDINoteNumber,
                  _ velo: MIDIVelocity,
                  _ chan: MIDIChannel,
                  _ port: MIDIUniqueID?,
                  _ time: MIDITimeStamp?,
                  _ visit: Visitor) {

        let exprs = FloExprs(Flo("noteOnIn"), [
            ("num" , Double(num)),
            ("velo", Double(velo)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])


        noteOnIn˚.setAny(exprs, setOptions, visit)
        if !visit.from.remote {
            let noteItem = MidiNoteItem(num, velo, chan, port, time)
            let midiItem = MidiItem(noteOn: noteItem)
            MidiItem.sendItemToPeers(midiItem)
        }
    }

    func noteOffIn(_ num: MIDINoteNumber,
                   _ velo: MIDIVelocity,
                   _ chan: MIDIChannel,
                   _ port: MIDIUniqueID?,
                   _ time: MIDITimeStamp?,
                   _ visit: Visitor) {

        let exprs = FloExprs(Flo("noteOffIn"), [
            ("num" , Double(num)),
            ("velo", Double(velo)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        noteOffIn˚.setAny(exprs, setOptions, visit)
        if !visit.from.remote {
            let noteItem = MidiNoteItem(num, velo, chan, port, time)
            let midiItem = MidiItem(noteOff: noteItem)
            MidiItem.sendItemToPeers(midiItem)
        }
    }

    func controllerIn(_ cc  : MIDIByte,
                      _ velo: MIDIVelocity,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?,
                      _ visit: Visitor) {

        switch cc {

            case 99: nrpnNumMsb = Float(velo) ; return
            case 98: nrpnNumLsb = Float(velo) ; return
            case  6: nrpnValMsb = Float(velo) ; return
            case 38: nrpnValLsb = Float(velo)

                if settingNrpn() {

                    let num = (nrpnNumMsb * 128) + nrpnNumLsb
                    let velo = ((nrpnValMsb * 128) + nrpnValLsb) / 16383

                    let exprs = FloExprs(Flo("controllerIn.Nrpn"), [
                        ("num" , Double(num)),
                        ("val" , Double(velo)),
                        ("chan", Double(chan)),
                        ("port", Double(port ?? 0)),
                        ("time", Double(time ?? 0))])

                    let icon = String(format: "%.0f:%.3f", num, velo)
                    let seq = String(format: "[%.0f_%.0f : %.0f_%.0f]\n",
                                     nrpnNumMsb, nrpnNumLsb, nrpnValMsb, nrpnValLsb)
                    MidiLog.print(icon,seq)

                    nrpnIn˚.setAny(exprs, setOptions, visit)
                    return
                }
            default: break //clearNrpn()
        }

        let exprs = FloExprs(Flo("controllerIn"), [
            ("cc"  , Double(cc)),
            ("val" , Double(velo)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        controllerIn˚.setAny(exprs, setOptions, visit)

        if !visit.from.remote {
            let item = MidiControllerItem(cc,velo,chan,port,time)
            let midiItem = MidiItem(controller: item)
            MidiItem.sendItemToPeers(midiItem)
        }
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

    func aftertouchIn(_ num : MIDINoteNumber,
                      _ val : MIDIByte,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?,
                      _ visit: Visitor) {

        let exprs = FloExprs(Flo("afterTouchIn"), [
            ("num" , Double(num)),
            ("val" , Double(val)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        afterTouchIn˚.setAny(exprs, setOptions, visit)

        if !visit.from.remote {
            let item = MidiAftertouchItem(num, val,chan,port,time)
            let midiItem = MidiItem(aftertouch: item)
            MidiItem.sendItemToPeers(midiItem)
        }
    }

    func aftertouchIn(_ val : MIDIByte,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?,
                      _ visit: Visitor) {

        let exprs = FloExprs(Flo("aftertouchIn"), [
            ("num" , Double(0)),
            ("val" , Double(val)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        afterTouchIn˚.setAny(exprs, setOptions, visit)

        if !visit.from.remote {
            let item = MidiAftertouchItem(0, val,chan,port,time)
            let midiItem = MidiItem(aftertouch: item)
            MidiItem.sendItemToPeers(midiItem)
        }
    }

    func pitchwheelIn(_ val : MIDIWord,
                      _ chan: MIDIChannel,
                      _ port: MIDIUniqueID?,
                      _ time: MIDITimeStamp?,
                      _ visit: Visitor) {

        let exprs = FloExprs(Flo("pitchwheelIn"), [
            ("val" , Double(val)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        pitchBendIn˚.setAny(exprs, setOptions, visit)

        if !visit.from.remote {
            let item = MidiPitchwheelItem(val,chan,port,time)
            let midiItem = MidiItem(pitchwheel: item)
            MidiItem.sendItemToPeers(midiItem)
        }
    }

    func programChangeIn(_ num : MIDIByte,
                         _ chan: MIDIChannel,
                         _ port: MIDIUniqueID?,
                         _ time: MIDITimeStamp?,
                         _ visit: Visitor) {

        let exprs = FloExprs(Flo("programChangeIn"),[
            ("num" , Double(num)),
            ("chan", Double(chan)),
            ("port", Double(port ?? 0)),
            ("time", Double(time ?? 0))])

        programChangeIn˚.setAny(exprs, setOptions, visit)

        if !visit.from.remote {
            let item = MidiProgramItem(num,chan,port,time)
            let midiItem = MidiItem(program: item)
            MidiItem.sendItemToPeers(midiItem)
        }
    }
}
