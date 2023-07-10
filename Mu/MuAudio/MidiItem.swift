//  Created by warren on 1/10/23.

import SwiftUI
import AVFoundation
import AudioKit
import MuPeer // PeersController
import MuPar // Visitor

public struct MidiNoteItem: Codable {

    var num:  MIDINoteNumber
    var velo: MIDIVelocity
    var chan: MIDIChannel
    var port: MIDIUniqueID?
    var time: MIDITimeStamp?

    init (_ num:  MIDINoteNumber,
          _ velo: MIDIVelocity  ,
          _ chan: MIDIChannel   ,
          _ port: MIDIUniqueID? ,
          _ time: MIDITimeStamp?) {

        self.num  = num
        self.velo = velo
        self.chan = chan
        self.port = port
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case  num, velo, chan, port, time }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try num = container.decode(MIDINoteNumber.self, forKey: .num)
        try velo = container.decode(MIDIVelocity.self, forKey: .velo)
        try chan = container.decode(MIDIChannel.self, forKey: .chan)
        try port = container.decodeIfPresent(MIDIUniqueID.self, forKey: .port)
        try time = container.decodeIfPresent(MIDITimeStamp.self, forKey: .time)
    }
}

public struct MidiControllerItem: Codable {

    var cc  : MIDIByte
    var velo: MIDIVelocity
    var chan: MIDIChannel
    var port: MIDIUniqueID?
    var time: MIDITimeStamp?

    init (_ cc  : MIDIByte,
          _ velo: MIDIVelocity,
          _ chan: MIDIChannel,
          _ port: MIDIUniqueID?,
          _ time: MIDITimeStamp?) {

        self.cc   = cc
        self.velo = velo
        self.chan = chan
        self.port = port
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case  cc, velo, chan, port, time }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try cc   = container.decode         (MIDIByte     .self, forKey: .cc  )
        try velo = container.decode         (MIDIVelocity .self, forKey: .velo)
        try chan = container.decode         (MIDIChannel  .self, forKey: .chan)
        try port = container.decodeIfPresent(MIDIUniqueID .self, forKey: .port)
        try time = container.decodeIfPresent(MIDITimeStamp.self, forKey: .time)
    }
}

public struct MidiAftertouchItem: Codable {

    var num : MIDINoteNumber
    var val : MIDIByte
    var chan: MIDIChannel
    var port: MIDIUniqueID?
    var time: MIDITimeStamp?

    init (_ num : MIDINoteNumber,
          _ val : MIDIByte,
          _ chan: MIDIChannel,
          _ port: MIDIUniqueID?,
          _ time: MIDITimeStamp?) {

        self.num  = num
        self.val  = val
        self.chan = chan
        self.port = port
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case  num, val, chan, port, time }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try num  = container.decode         (MIDINoteNumber.self, forKey: .num )
        try val  = container.decode         (MIDIByte      .self, forKey: .val )
        try chan = container.decode         (MIDIChannel   .self, forKey: .chan)
        try port = container.decodeIfPresent(MIDIUniqueID  .self, forKey: .port)
        try time = container.decodeIfPresent(MIDITimeStamp .self, forKey: .time)
    }
}

public struct MidiPitchbendItem: Codable {

    var val : MIDIWord
    var chan: MIDIChannel
    var port: MIDIUniqueID?
    var time: MIDITimeStamp?

    init (_ val : MIDIWord,
          _ chan: MIDIChannel,
          _ port: MIDIUniqueID?,
          _ time: MIDITimeStamp?) {

        self.val  = val
        self.chan = chan
        self.port = port
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case val, chan, port, time }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try val  = container.decode         (MIDIWord      .self, forKey: .val )
        try chan = container.decode         (MIDIChannel   .self, forKey: .chan)
        try port = container.decodeIfPresent(MIDIUniqueID  .self, forKey: .port)
        try time = container.decodeIfPresent(MIDITimeStamp .self, forKey: .time)
    }
}

public struct MidiProgramItem: Codable {

    var num : MIDIByte
    var chan: MIDIChannel
    var port: MIDIUniqueID?
    var time: MIDITimeStamp?

    init (_ num : MIDIByte,
          _ chan: MIDIChannel,
          _ port: MIDIUniqueID?,
          _ time: MIDITimeStamp?) {

        self.num  = num
        self.chan = chan
        self.port = port
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case num, chan, port, time }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try num  = container.decode         (MIDIByte      .self, forKey: .num )
        try chan = container.decode         (MIDIChannel   .self, forKey: .chan)
        try port = container.decodeIfPresent(MIDIUniqueID  .self, forKey: .port)
        try time = container.decodeIfPresent(MIDITimeStamp .self, forKey: .time)
    }
}

public enum MidiType: String, CodingKey {
    case noteOn, noteOff, controller, aftertouch, pitchbend, program }

public struct MidiItem: Codable {

    public var type: MidiType
    public var time: TimeInterval
    public var item: Any?
    public var from: Int

    public init(noteOn: MidiNoteItem) {
        self.type = .noteOn
        self.time = Date().timeIntervalSince1970
        self.item = noteOn
        self.from = VisitFrom.midi.rawValue
    }
    public init(noteOff: MidiNoteItem) {
        self.type = .noteOff
        self.time = Date().timeIntervalSince1970
        self.item = noteOff
        self.from = VisitFrom.midi.rawValue
    }
    public init(controller: MidiControllerItem) {
        self.type = .controller
        self.time = Date().timeIntervalSince1970
        self.item = controller
        self.from = VisitFrom.midi.rawValue
    }
    public init(aftertouch: MidiAftertouchItem) {
        self.type = .aftertouch
        self.time = Date().timeIntervalSince1970
        self.item = aftertouch
        self.from = VisitFrom.midi.rawValue
    }
    public init(pitchwheel: MidiPitchbendItem) {
        self.type = .pitchbend
        self.time = Date().timeIntervalSince1970
        self.item = pitchwheel
        self.from = VisitFrom.midi.rawValue
    }
    public init(program: MidiProgramItem) {
        self.type = .program
        self.time = Date().timeIntervalSince1970
        self.item = program
        self.from = VisitFrom.midi.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case type, time, item, from }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type.stringValue, forKey: .type)
        try c.encode(time, forKey: .time)
        try c.encode(from, forKey: .from)
        switch type {
            case .noteOn     : try c.encode(item as? MidiNoteItem      , forKey: .item)
            case .noteOff    : try c.encode(item as? MidiNoteItem      , forKey: .item)
            case .controller : try c.encode(item as? MidiControllerItem, forKey: .item)
            case .aftertouch : try c.encode(item as? MidiAftertouchItem, forKey: .item)
            case .pitchbend  : try c.encode(item as? MidiPitchbendItem , forKey: .item)
            case .program    : try c.encode(item as? MidiProgramItem   , forKey: .item)
        }
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = MidiType(rawValue: try c.decode(String.self, forKey: .type)) ?? .noteOn
        time = try c.decode(Double.self, forKey: .time)
        from = try c.decode(Int.self, forKey: .from)

        switch type {
            case .noteOn     : try item = c.decode(MidiNoteItem.self        , forKey: .item)
            case .noteOff    : try item = c.decode(MidiNoteItem.self        , forKey: .item)
            case .controller : try item = c.decode(MidiControllerItem.self  , forKey: .item)
            case .aftertouch : try item = c.decode(MidiAftertouchItem.self  , forKey: .item)
            case .pitchbend  : try item = c.decode(MidiPitchbendItem.self   , forKey: .item)
            case .program    : try item = c.decode(MidiProgramItem.self     , forKey: .item)
        }
    }
    var visitFrom: VisitFrom {
        VisitFrom(rawValue: from)
    }
}
extension MidiItem {

    static func sendItemToPeers(_ item: MidiItem) {

        let peers = PeersController.shared
        if peers.hasPeers {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }

}
