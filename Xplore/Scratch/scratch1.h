

sky { // visual music synth
    main { // main controls
        fps(1…60~60) // frames per second
        run(0…1~1) // currently running
        anim(0…1~0.5) // animation transition speed
    }
    network {
        bonjour // bonjour status
        follow(0…1~1) // follow remote events
        midi(0…1~1) // follow midi events
    }
    color { // false color mapping palette
        pal0("roygbik")
        pal1("wKZ")
        xfade(x 0…1~0.5 = 0)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2) >> shader.compute.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1~1)
        }
        radius(1…92~9 = 1) // finger silhouette
        tilt(0…1~1)
        force(0…0.5) >> sky.draw.brush.size
    }
    draw { // draw on metal layer
        screen { // fill cellular automata universe
            fill(0…1~0)
        }
        brush { // type of brush and range
            size(1…64~10) // range of radius
            press(0…1~1) // pressure changes size
            index(1…255~127) // index in 256 color palette
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot {
            on(x 0_11 = 0, y 0_11 = 0, z 0_127 = 0)
            off(x 0_11, y 0_11, z 0_127)
        }
    }
}
shader {
    pipeline {
        draw slide color flatmap plato }
    cell {
        fade(1.2…3 = 2) >> shader.cell.fade.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        ave(0…1 = 0.5) >> shader.cell.ave.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        melt(0…1 = 0.5) >> shader.cell.melt.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        tunl(0…5 = 0.833333) >> shader.cell.tunl.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0),
                           shader.cell.ave.on(0),
                           shader.cell.melt.on(0),
                           shader.cell.tunl.on(0),
                           shader.cell.slide.on(0),
                           shader.cell.fred.on(0),
                           shader.cell.zha.on(0))
        }
        slide(0…7 = 2.625) >> shader.cell.slide.on(1) {
            on(%2 = 1) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        fred(0…4 = 4) >> shader.cell.fred.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        zha(0…6 = 1.714286) >> shader.cell.zha.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
            bits(2…4 = 3)
            loops(11)
        }
        cell.* >> (shader.cell.fade.on(1), shader.cell.ave.on(1), shader.cell.melt.on(1), shader.cell.tunl.on(1), shader.cell.slide.on(1), shader.cell.fred.on(1), shader.cell.zha.on(1)) cell˚on >> (shader.cell.fade.on(1), shader.cell.ave.on(1), shader.cell.melt.on(1), shader.cell.tunl.on(1), shader.cell.slide.on(1), shader.cell.fred.on(1), shader.cell.zha.on(1)) }
    compute {
        draw(x 0…1~0.5 = 0.5, y 0…1~0.5 = 0.5) {
            on(0…1~1)
        }
        record {
            on(0…1~0)
        }
        camera {
            on(0…1~0)
            front(%2~1)
        }
        camix {
            mix(0…1~0.5)
        }
        color(y 0…1~0.1 = 0)
    }
    render {
        flatmap {
            frame(x 0, y 0, w 1080, h 1920)
            repeat(x -1…1~0, y -1…1~0)
            mirror(x 0…1~0 = 0, y 0…1~0 = 0)
        }
        cubemap {
            frame(x 0, y 0, w 1080, h 1920)
            repeat(x -1…1~0, y -1…1~0)
            mirror(x 0…1~0 = 0, y 0…1~0 = 0)
            gravity(0…2~0)
            on(%2~0)
        }
        plato {
            on(%2~0)
        }
    }
}
model {
    canvas {
        tile {
            mirror(x 0…1~0 = 0, y 0…1~0 = 0) <> (shader.render.flatmap.mirror, shader.render.cubemap.mirror) ^ sky.main.anim
            shift(x 0…1~0.5 = 0.5, y 0…1~0.5 = 0.5) <> shader.compute.draw ^ sky.main.anim
            repeat(x -1…1~0, y -1…1~0) <> (shader.render.flatmap.repeat, shader.render.cubemap.repeat) >> (midi.cc.skypad.repeatX(val x), midi.cc.skypad.repeatY(val y)) ^ sky.main.anim
        }
        color {
            fade(x 0…1~0.5 = 0, y 0…1~0.1 = 0) >> (shader.compute.color, sky.color.xfade) ^ sky.main.anim
            fill_0(%1) <> sky.draw.screen.fill(0)
            fill_1(%1) <> sky.draw.screen.fill(1)
        }
        speed {
            fps(0_60~60) <> sky.main.fps
            run(%2~1) <> sky.main.run
            anim(0…1~0.24) <> sky.main.anim
        }
        plato {
            shade {
                phase(x 0…1, y 0.9…1.1)
                convex(0.9…1.1~1)
                colors(x 0…255~0, y 0…1~0)
                shadow(x 0…1~0, y 0…1~0)
                invert(0…1~1)
            }
            zoom(0…1~0.5) ^ sky.main.anim
            wire(%2~0)
            morph(%2~1)
            show(%2~0) <> shader.render.plato.on
        }
        cube {
            motion(%2~1)
            rotate(x -1…1~0, y -1…1~0)
            back(%2~1)
            show(%2~0) <> shader.render.cubemap.on
        }
    }
    brush {
        size(0…1~0.5) <> sky.draw.brush.size
        press(%2~1) <> sky.draw.brush.press
        tilt(%2~0) <> sky.input.tilt
        index(1_255~127) <> sky.draw.brush.index
    }
    cell {
        fade(0.2…2~1 = 1) <> shader.cell.fade
        ave(0…1~0.5 = 0.5) <> shader.cell.ave
        melt(0…1~0.5 = 0.5) <> shader.cell.melt
        tunl(0_5~1 = 1) <> shader.cell.tunl
        zha(0_6~2 = 2) <> shader.cell.zha
        slide(0_7~3 = 3) <> shader.cell.slide
        fred(0_4~4) <> shader.cell.fred
    }
    camera {
        stream(%2~0) <> shader.compute.camera.on
        front(%2~1) <> shader.compute.camera.front
        mix(0…1~0.5) <> shader.compute.camix.mix //mask   (%2~1)

    }
    network {
        bonjour(peer "bonjour") <>sky.main.peer.bonjour
        follow(%2~1) <>sky.main.peer.follow
        midi(%2~1) <>sky.main.peer.midi
    }
}
_menu {
    canvas(svg "icon.canvas") {
        tile(svg "icon.tile") {
            mirror(svg "icon.mirror")
            repeat(svg "icon.repeat.arrows")
            shift(svg "icon.direction")
        }
        color(img "icon.pal.main") {
            fade(svg "icon.gradient")
            fill_0(sym "drop")
            fill_1(sym "drop.fill")
        }
        speed(img "icon.speed") {
            fps(sym "speedometer")
            run(sym "goforward")
            anim(sym "bolt.fill")
        }
        plato(svg "icon.plato.wire") {
            shade(svg "icon.peacock") {
                phase(sym "calendar.day.timeline.left")
                convex(svg "icon.convex")
                colors(sym "figure.stair.stepper")
                shadow(sym "shadow")
                invert(sym "circle.lefthalf.filled")
            }
            zoom(svg "icon.zoom")
            morph(svg "icon.counter")
            wire(svg "icon.wireframe")
            show(svg "icon.plato.show")
        }
        cube(sym "cube") {
            motion(sym "gyroscope")
            rotate(svg "icon.direction")
            back(sym "cube")
            show(sym "cube.fill")
        }
    }
    brush(svg "icon.brush") {
        size(svg "icon.size.dot")
        press(sym "scribble.variable")
        tilt(sym "angle")
        index(sym "calendar.day.timeline.left")
    }
    cell(svg "icon.ca.grid") {
        fade(img "icon.cell.fade")
        ave(img "icon.cell.ave")
        melt(img "icon.cell.melt")
        tunl(img "icon.cell.tunl")
        zha(img "icon.cell.zha")
        slide(img "icon.cell.slide")
        fred(img "icon.cell.fred")
    }
    camera(sym "camera") {
        stream(sym "video")
        front(svg "icon.camera.facing")
        mask(svg "icon.face")
        mix(sym "camera.filters")
    }
    network(sym "network") {
        bonjour(sym "bonjour")
        follow(sym "shared.with.you")
        midi(sym "pianokeys.inverse")
    }
}
menu {
    SW @_menu { // SE @ _menu
                // NE @ _menu
                // NW @ _menu
        canvas(svg "icon.canvas") {
            tile(svg "icon.tile") {
                mirror(svg "icon.mirror")
                repeat(svg "icon.repeat.arrows")
                shift(svg "icon.direction")
            }
            color(img "icon.pal.main") {
                fade(svg "icon.gradient")
                fill_0(sym "drop")
                fill_1(sym "drop.fill")
            }
            speed(img "icon.speed") {
                fps(sym "speedometer")
                run(sym "goforward")
                anim(sym "bolt.fill")
            }
        }
        brush(svg "icon.brush") {
            size(svg "icon.size.dot")
            press(sym "scribble.variable")
            tilt(sym "angle")
            index(sym "calendar.day.timeline.left")
        }
        cell(svg "icon.ca.grid") {
            fade(img "icon.cell.fade")
            ave(img "icon.cell.ave")
            melt(img "icon.cell.melt")
            tunl(img "icon.cell.tunl")
            zha(img "icon.cell.zha")
            slide(img "icon.cell.slide")
            fred(img "icon.cell.fred")
        }
        camera(sym "camera") {
            stream(sym "video")
            front(svg "icon.camera.facing")
            mask(svg "icon.face")
            mix(sym "camera.filters")
        }
        network(sym "network") {
            bonjour(sym "bonjour")
            follow(sym "shared.with.you")
            midi(sym "pianokeys.inverse")
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0_127, velo 0_127, chan 1_32, port 1_16, time) >> (midi.notes.dot.on, midi.output.note.on)
            off(num 0_127, velo 0_127, chan 1_32, port 1_16, time) >> (midi.notes.dot.off, midi.output.note.off)
        }
        controller(cc 0_127, val 0_127, chan 1_32, port 1_16, time) >> (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0_127, val 0_127, chan 1_32, port 1_16, time)
        pitchBend(val 0_16384~8192, chan 1_32, port 1_16, time)
        program(num 0_255, chan 1_32, port 1_16, time)
        nrpn(num 0_16383, val 0…1, chan, time) >> (midi.skypad.plane, midi.skypad.fade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0_127, velo 0_127, chan 1_32, port 1_16, time)
            off(num 0_127, velo 0_127, chan 1_32, port 1_16, time)
        }
        controller(cc 0_127 = 11, val 0_127 = 0, chan 1_32 = 1, port 1_16 = 1, time) << (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0_127, val 0_127, chan 1_32, port 1_16, time)
        pitchBend(val 0_16384~8192, chan 1_32, port 1_16, time)
        program(num 0_255, chan 1_32, port 1_16, time)
        nrpn(num 0_16383, val 0…1, chan, time)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time) <> model.canvas.color.fade(x val)
        fade(num == 130, val 0…1, chan, time) <> model.canvas.color.fade(y val)
    }
    cc { //??? cc.skypad˚. >> output.note.on(num val)
        skypad {
            zoom(cc == 4, val 0_127) <> model.canvas.plato.zoom
            convex(cc == 5, val 0_127) <> model.canvas.plato.shade.convex
            colorY(cc == 6, val 0_127) <> model.canvas.plato.shade.colors(y val)
            camix(cc == 9, val 0_127) <>model.camix.mix(val)
            fade(cc == 10, val 0_127) <> model.canvas.color.fade(x val)
            plane(cc == 11, val 0_127) <> model.canvas.color.fade(y val)
            shiftX(cc == 12, val 0_127) <> model.canvas.tile.shift(x val)
            shiftY(cc == 13, val 0_127) <> model.canvas.tile.shift(y val)
            repeatX(cc == 14, val 0_127) <> model.canvas.tile.repeat(x val)
            repeatY(cc == 15, val 0_127) <> model.canvas.tile.repeat(y val)
        }
        roli {
            lightpad {
                x(cc == 114, val 0_127) <> sky.draw.dot.on(x val)
                y(cc == 113, val 0_127) <> sky.draw.dot.on(y val)
                z(cc == 115, val 0_127) <> (sky.draw.dot.on(z val), sky.color.xfade(x val))
            }
            loopblock {
                mode(cc == 102, val 0_127)
                mute(cc == 103, val 0_127)
                metro(cc == 104, val 0_127)
                skip(cc == 105, val 0_127)
                back(cc == 106, val 0_127)
                play(cc == 107, val 0_127)
                record(cc == 108, val 0_127)
                learn(cc == 109, val 0_127)
                prev(cc == 110, val 0_127)
                next(cc == 111, val 0_127)
            }
        }
    }
    notes {
        dot {
            on(x num %12, y num / 12, z velo) >> sky.draw.dot.on
            off(x num %12, y num / 12, z velo) >> sky.draw.dot.off
        }
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32_63, val, chan, time)
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _main2 {
            bankSelect(num == 0, val, chan, time)
            breathCtrl(num == 2, val, chan, time)
            footPedal(num == 4, val, chan, time)
            dataEntry(num == 6, val, chan, time)
            effectCtrl1(num == 12, val, chan, time)
            effectCtrl2(num == 13, val, chan, time)
        }
        _sound {
            soundVariation(num == 70, val, chan, time)
            resonance(num == 71, val, chan, time)
            soundReleaseTime(num == 72, val, chan, time)
            soundAttackTime(num == 73, val, chan, time)
            frequencyCutoff(num == 74, val, chan, time)
            timbre(num == 71, val, chan, time)
            brightness(num == 74, val, chan, time)
        }
        _button {
            button1(num == 80, val, chan, time)
            button2(num == 81, val, chan, time)
            button3(num == 82, val, chan, time)
            button4(num == 83, val, chan, time)
            decayor(num == 80, val, chan, time)
            hiPassFilter(num == 81, val, chan, time)
            generalPurpose82(num == 82, val, chan, time)
            generalPurpose83(num == 83, val, chan, time)
        }
        _roland {
            rolandToneLevel1(num == 80, val, chan, time)
            rolandToneLevel2(num == 81, val, chan, time)
            rolandToneLevel3(num == 82, val, chan, time)
            rolandToneLevel4(num == 83, val, chan, time)
        }
        _level {
            reverbLevel(num == 91, val, chan, time)
            tremoloLevel(num == 92, val, chan, time)
            chorusLevel(num == 93, val, chan, time)
            detuneLevel(num == 94, val, chan, time)
            phaserLevel(num == 95, val, chan, time)
        }
        _parameter {
            dataButtonIncrement(num == 96, val, chan, time)
            dataButtonDecrement(num == 97, val, chan, time)
            nonregisteredParameterLSB(num == 98, val, chan, time)
            nonregisteredParameterMSB(num == 99, val, chan, time)
            registeredParameterLSB(num == 100, val, chan, time)
            registeredParameterMSB(num == 101, val, chan, time)
        }
        _soundControl {
            soundControl6(num == 75, val, chan, time)
            soundControl7(num == 76, val, chan, time)
            soundControl8(num == 77, val, chan, time)
            soundControl9(num == 78, val, chan, time)
            soundControl10(num == 79, val, chan, time)
        }
        _undefined {
            undefined_3(num == 3, val, chan, time)
            undefined_9(num == 9, val, chan, time)
            undefined_14_31(num in 14_31, val, chan, time)
            undefined_85_90(num in 85_90, val, chan, time)
            undefined_102_119(num in 102_119, val, chan, time)
        }
        _mode {
            allSoundOff(num == 120, val, chan, time)
            allControllersOff(num == 121, val, chan, time)
            localKeyboard(num == 122, val, chan, time)
            allNotesOff(num == 123, val, chan, time)
            monoOperation(num == 126, val, chan, time)
            polyMode(num == 127, val, chan, time)
        }
        _omni {
            omniModeOff(num == 124, val, chan, time)
            omniModeOn(num == 125, val, chan, time)
            omniMode(0_1) << (midi._cc._omni.omniModeOff(0), midi._cc._omni.omniModeOn(1))
        }
    }
}





scriptDef ⟹

sky { // visual music synth
    main { // main controls
        fps(1…60~60) // frames per second
        run(0…1~1) // currently running
        anim(0…1~0.5) // animation transition speed
    }
    network {
        bonjour // bonjour status
        follow(0…1~1) // follow remote events
        midi(0…1~1) // follow midi events
    }
    color { // false color mapping palette
        pal0("roygbik")
        pal1("wKZ")
        xfade(x 0…1~0.5 = 0)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2) >> shader.compute.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1~1)
        }
        radius(1…92~9 = 1) // finger silhouette
        tilt(0…1~1)
        force(0…0.5) >> sky.draw.brush.size
    }
    draw { // draw on metal layer
        screen { // fill cellular automata universe
            fill(0…1~0)
        }
        brush { // type of brush and range
            size(1…64~10) // range of radius
            press(0…1~1) // pressure changes size
            index(1…255~127) // index in 256 color palette
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot {
            on(x 0_11 = 0, y 0_11 = 0, z 0_127 = 0)
            off(x 0_11, y 0_11, z 0_127)
        }
    }
}
shader {
    pipeline {
        draw slide color flatmap plato }
    cell {
        fade(1.2…3 = 2) >> shader.cell.fade.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        ave(0…1 = 0.5) >> shader.cell.ave.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        melt(0…1 = 0.5) >> shader.cell.melt.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        tunl(0…5 = 0.833333) >> shader.cell.tunl.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        slide(0…7 = 2.625) >> shader.cell.slide.on(1) {
            on(%2 = 1) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        fred(0…4 = 4) >> shader.cell.fred.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
        }
        zha(0…6 = 1.714286) >> shader.cell.zha.on(1) {
            on(%2 = 0) >> (shader.cell.fade.on(0), shader.cell.ave.on(0), shader.cell.melt.on(0), shader.cell.tunl.on(0), shader.cell.slide.on(0), shader.cell.fred.on(0), shader.cell.zha.on(0))
            bits(2…4 = 3)
            loops(11)
        }
        cell.* >> (shader.cell.fade.on(1), shader.cell.ave.on(1), shader.cell.melt.on(1), shader.cell.tunl.on(1), shader.cell.slide.on(1), shader.cell.fred.on(1), shader.cell.zha.on(1)) cell˚on >> (shader.cell.fade.on(1), shader.cell.ave.on(1), shader.cell.melt.on(1), shader.cell.tunl.on(1), shader.cell.slide.on(1), shader.cell.fred.on(1), shader.cell.zha.on(1)) }
    compute {
        draw(x 0…1~0.5 = 0.5, y 0…1~0.5 = 0.5) {
            on(0…1~1)
        }
        record {
            on(0…1~0)
        }
        camera {
            on(0…1~0)
            front(%2~1)
        }
        camix {
            mix(0…1~0.5)
        }
        color(y 0…1~0.1 = 0)
    }
    render {
        flatmap {
            frame(x 0, y 0, w 1080, h 1920)
            repeat(x -1…1~0, y -1…1~0)
            mirror(x 0…1~0 = 0, y 0…1~0 = 0)
        }
        cubemap {
            frame(x 0, y 0, w 1080, h 1920)
            repeat(x -1…1~0, y -1…1~0)
            mirror(x 0…1~0 = 0, y 0…1~0 = 0)
            gravity(0…2~0)
            on(%2~0)
        }
        plato {
            on(%2~0)
        }
    }
}
model {
    canvas {
        tile {
            mirror(x 0…1~0 = 0, y 0…1~0 = 0) <> (shader.render.flatmap.mirror, shader.render.cubemap.mirror) ^ sky.main.anim
            shift(x 0…1~0.5 = 0.5, y 0…1~0.5 = 0.5) <> shader.compute.draw ^ sky.main.anim
            repeat(x -1…1~0, y -1…1~0) <> (shader.render.flatmap.repeat, shader.render.cubemap.repeat) >> (midi.cc.skypad.repeatX(val x), midi.cc.skypad.repeatY(val y)) ^ sky.main.anim
        }
        color {
            fade(x 0…1~0.5 = 0, y 0…1~0.1 = 0) >> (shader.compute.color, sky.color.xfade) ^ sky.main.anim
            fill_0(%1) <> sky.draw.screen.fill(0)
            fill_1(%1) <> sky.draw.screen.fill(1)
        }
        speed {
            fps(0_60~60) <> sky.main.fps
            run(%2~1) <> sky.main.run
            anim(0…1~0.24) <> sky.main.anim
        }
        plato {
            shade {
                phase(x 0…1, y 0.9…1.1)
                convex(0.9…1.1~1)
                colors(x 0…255~0, y 0…1~0)
                shadow(x 0…1~0, y 0…1~0)
                invert(0…1~1)
            }
            zoom(0…1~0.5) ^ sky.main.anim
            wire(%2~0)
            morph(%2~1)
            show(%2~0) <> shader.render.plato.on
        }
        cube {
            motion(%2~1)
            rotate(x -1…1~0, y -1…1~0)
            back(%2~1)
            show(%2~0) <> shader.render.cubemap.on
        }
    }
    brush {
        size(0…1~0.5) <> sky.draw.brush.size
        press(%2~1) <> sky.draw.brush.press
        tilt(%2~0) <> sky.input.tilt
        index(1_255~127) <> sky.draw.brush.index
    }
    cell {
        fade(0.2…2~1 = 1) <> shader.cell.fade
        ave(0…1~0.5 = 0.5) <> shader.cell.ave
        melt(0…1~0.5 = 0.5) <> shader.cell.melt
        tunl(0_5~1 = 1) <> shader.cell.tunl
        zha(0_6~2 = 2) <> shader.cell.zha
        slide(0_7~3 = 3) <> shader.cell.slide
        fred(0_4~4) <> shader.cell.fred
    }
    camera {
        stream(%2~0) <> shader.compute.camera.on
        front(%2~1) <> shader.compute.camera.front
        mix(0…1~0.5) <> shader.compute.camix.mix //mask   (%2~1)

    }
    network {
        bonjour(peer "bonjour") <>sky.main.peer.bonjour
        follow(%2~1) <>sky.main.peer.follow
        midi(%2~1) <>sky.main.peer.midi
    }
}
_menu {
    canvas(svg "icon.canvas") {
        tile(svg "icon.tile") {
            mirror(svg "icon.mirror")
            repeat(svg "icon.repeat.arrows")
            shift(svg "icon.direction")
        }
        color(img "icon.pal.main") {
            fade(svg "icon.gradient")
            fill_0(sym "drop")
            fill_1(sym "drop.fill")
        }
        speed(img "icon.speed") {
            fps(sym "speedometer")
            run(sym "goforward")
            anim(sym "bolt.fill")
        }
        plato(svg "icon.plato.wire") {
            shade(svg "icon.peacock") {
                phase(sym "calendar.day.timeline.left")
                convex(svg "icon.convex")
                colors(sym "figure.stair.stepper")
                shadow(sym "shadow")
                invert(sym "circle.lefthalf.filled")
            }
            zoom(svg "icon.zoom")
            morph(svg "icon.counter")
            wire(svg "icon.wireframe")
            show(svg "icon.plato.show")
        }
        cube(sym "cube") {
            motion(sym "gyroscope")
            rotate(svg "icon.direction")
            back(sym "cube")
            show(sym "cube.fill")
        }
    }
    brush(svg "icon.brush") {
        size(svg "icon.size.dot")
        press(sym "scribble.variable")
        tilt(sym "angle")
        index(sym "calendar.day.timeline.left")
    }
    cell(svg "icon.ca.grid") {
        fade(img "icon.cell.fade")
        ave(img "icon.cell.ave")
        melt(img "icon.cell.melt")
        tunl(img "icon.cell.tunl")
        zha(img "icon.cell.zha")
        slide(img "icon.cell.slide")
        fred(img "icon.cell.fred")
    }
    camera(sym "camera") {
        stream(sym "video")
        front(svg "icon.camera.facing")
        mask(svg "icon.face")
        mix(sym "camera.filters")
    }
    network(sym "network") {
        bonjour(sym "bonjour")
        follow(sym "shared.with.you")
        midi(sym "pianokeys.inverse")
    }
}
menu {
    SW @_menu { // SE @ _menu
                // NE @ _menu
                // NW @ _menu
        canvas(svg "icon.canvas") {
            tile(svg "icon.tile") {
                mirror(svg "icon.mirror")
                repeat(svg "icon.repeat.arrows")
                shift(svg "icon.direction")
            }
            color(img "icon.pal.main") {
                fade(svg "icon.gradient")
                fill_0(sym "drop")
                fill_1(sym "drop.fill")
            }
            speed(img "icon.speed") {
                fps(sym "speedometer")
                run(sym "goforward")
                anim(sym "bolt.fill")
            }
        }
        brush(svg "icon.brush") {
            size(svg "icon.size.dot")
            press(sym "scribble.variable")
            tilt(sym "angle")
            index(sym "calendar.day.timeline.left")
        }
        cell(svg "icon.ca.grid") {
            fade(img "icon.cell.fade")
            ave(img "icon.cell.ave")
            melt(img "icon.cell.melt")
            tunl(img "icon.cell.tunl")
            zha(img "icon.cell.zha")
            slide(img "icon.cell.slide")
            fred(img "icon.cell.fred")
        }
        camera(sym "camera") {
            stream(sym "video")
            front(svg "icon.camera.facing")
            mask(svg "icon.face")
            mix(sym "camera.filters")
        }
        network(sym "network") {
            bonjour(sym "bonjour")
            follow(sym "shared.with.you")
            midi(sym "pianokeys.inverse")
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0_127, velo 0_127, chan 1_32, port 1_16, time) >> (midi.notes.dot.on, midi.output.note.on)
            off(num 0_127, velo 0_127, chan 1_32, port 1_16, time) >> (midi.notes.dot.off, midi.output.note.off)
        }
        controller(cc 0_127, val 0_127, chan 1_32, port 1_16, time) >> (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0_127, val 0_127, chan 1_32, port 1_16, time)
        pitchBend(val 0_16384~8192, chan 1_32, port 1_16, time)
        program(num 0_255, chan 1_32, port 1_16, time)
        nrpn(num 0_16383, val 0…1, chan, time) >> (midi.skypad.plane, midi.skypad.fade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0_127, velo 0_127, chan 1_32, port 1_16, time)
            off(num 0_127, velo 0_127, chan 1_32, port 1_16, time)
        }
        controller(cc 0_127 = 11, val 0_127 = 0, chan 1_32 = 1, port 1_16 = 1, time) << (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0_127, val 0_127, chan 1_32, port 1_16, time)
        pitchBend(val 0_16384~8192, chan 1_32, port 1_16, time)
        program(num 0_255, chan 1_32, port 1_16, time)
        nrpn(num 0_16383, val 0…1, chan, time)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time) <> model.canvas.color.fade(x val)
        fade(num == 130, val 0…1, chan, time) <> model.canvas.color.fade(y val)
    }
    cc { //??? cc.skypad˚. >> output.note.on(num val)
        skypad {
            zoom(cc == 4, val 0_127) <> model.canvas.plato.zoom
            convex(cc == 5, val 0_127) <> model.canvas.plato.shade.convex
            colorY(cc == 6, val 0_127) <> model.canvas.plato.shade.colors(y val)
            camix(cc == 9, val 0_127) <>model.camix.mix(val)
            fade(cc == 10, val 0_127) <> model.canvas.color.fade(x val)
            plane(cc == 11, val 0_127) <> model.canvas.color.fade(y val)
            shiftX(cc == 12, val 0_127) <> model.canvas.tile.shift(x val)
            shiftY(cc == 13, val 0_127) <> model.canvas.tile.shift(y val)
            repeatX(cc == 14, val 0_127) <> model.canvas.tile.repeat(x val)
            repeatY(cc == 15, val 0_127) <> model.canvas.tile.repeat(y val)
        }
        roli {
            lightpad {
                x(cc == 114, val 0_127) <> sky.draw.dot.on(x val)
                y(cc == 113, val 0_127) <> sky.draw.dot.on(y val)
                z(cc == 115, val 0_127) <> (sky.draw.dot.on(z val), sky.color.xfade(x val))
            }
            loopblock {
                mode(cc == 102, val 0_127)
                mute(cc == 103, val 0_127)
                metro(cc == 104, val 0_127)
                skip(cc == 105, val 0_127)
                back(cc == 106, val 0_127)
                play(cc == 107, val 0_127)
                record(cc == 108, val 0_127)
                learn(cc == 109, val 0_127)
                prev(cc == 110, val 0_127)
                next(cc == 111, val 0_127)
            }
        }
    }
    notes {
        dot {
            on(x num %12, y num / 12, z velo) >> sky.draw.dot.on
            off(x num %12, y num / 12, z velo) >> sky.draw.dot.off
        }
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32_63, val, chan, time)
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _main2 {
            bankSelect(num == 0, val, chan, time)
            breathCtrl(num == 2, val, chan, time)
            footPedal(num == 4, val, chan, time)
            dataEntry(num == 6, val, chan, time)
            effectCtrl1(num == 12, val, chan, time)
            effectCtrl2(num == 13, val, chan, time)
        }
        _sound {
            soundVariation(num == 70, val, chan, time)
            resonance(num == 71, val, chan, time)
            soundReleaseTime(num == 72, val, chan, time)
            soundAttackTime(num == 73, val, chan, time)
            frequencyCutoff(num == 74, val, chan, time)
            timbre(num == 71, val, chan, time)
            brightness(num == 74, val, chan, time)
        }
        _button {
            button1(num == 80, val, chan, time)
            button2(num == 81, val, chan, time)
            button3(num == 82, val, chan, time)
            button4(num == 83, val, chan, time)
            decayor(num == 80, val, chan, time)
            hiPassFilter(num == 81, val, chan, time)
            generalPurpose82(num == 82, val, chan, time)
            generalPurpose83(num == 83, val, chan, time)
        }
        _roland {
            rolandToneLevel1(num == 80, val, chan, time)
            rolandToneLevel2(num == 81, val, chan, time)
            rolandToneLevel3(num == 82, val, chan, time)
            rolandToneLevel4(num == 83, val, chan, time)
        }
        _level {
            reverbLevel(num == 91, val, chan, time)
            tremoloLevel(num == 92, val, chan, time)
            chorusLevel(num == 93, val, chan, time)
            detuneLevel(num == 94, val, chan, time)
            phaserLevel(num == 95, val, chan, time)
        }
        _parameter {
            dataButtonIncrement(num == 96, val, chan, time)
            dataButtonDecrement(num == 97, val, chan, time)
            nonregisteredParameterLSB(num == 98, val, chan, time)
            nonregisteredParameterMSB(num == 99, val, chan, time)
            registeredParameterLSB(num == 100, val, chan, time)
            registeredParameterMSB(num == 101, val, chan, time)
        }
        _soundControl {
            soundControl6(num == 75, val, chan, time)
            soundControl7(num == 76, val, chan, time)
            soundControl8(num == 77, val, chan, time)
            soundControl9(num == 78, val, chan, time)
            soundControl10(num == 79, val, chan, time)
        }
        _undefined {
            undefined_3(num == 3, val, chan, time)
            undefined_9(num == 9, val, chan, time)
            undefined_14_31(num in 14_31, val, chan, time)
            undefined_85_90(num in 85_90, val, chan, time)
            undefined_102_119(num in 102_119, val, chan, time)
        }
        _mode {
            allSoundOff(num == 120, val, chan, time)
            allControllersOff(num == 121, val, chan, time)
            localKeyboard(num == 122, val, chan, time)
            allNotesOff(num == 123, val, chan, time)
            monoOperation(num == 126, val, chan, time)
            polyMode(num == 127, val, chan, time)
        }
        _omni {
            omniModeOff(num == 124, val, chan, time)
            omniModeOn(num == 125, val, chan, time)
            omniMode(0_1) << (midi._cc._omni.omniModeOff(0), midi._cc._omni.omniModeOn(1))
        }
    }
}
