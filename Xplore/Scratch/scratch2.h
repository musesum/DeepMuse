
sky { // visual music synth
    main { // main controls
        run( 0… 1~ 1) // currently running
        anim( 0… 1~ 0.5) // animation transition speed
    }
    network {
        bonjour // bonjour status
        follow( 0… 1~ 1) // follow remote events
        midi( 0… 1~ 1) // follow midi events
    }
    color { // false color mapping palette
        pal0("roygbik")
        pal1("wKZ")
        xfade(x  0… 1~ 0.5)
    }
    input { // phone and tablet pencil input
        azimuth(x  -0.2… 0.2, y  -0.2… 0.2) >> shader.compute.draw
        accel(x  -0.3… 0.3, y  -0.3… 0.3, z  -0.3… 0.3) { // accelerometer
            on( 0… 1~ 1)
        }
        radius( 1… 92~ 9) // finger silhouette
        tilt( 0… 1~ 1)
        force( 0… 0.5) >> sky.draw.brush.size
    }
    draw { // draw on metal layer
        screen { // fill cellular automata universe
            fill( 0… 1~ 0)
        }
        brush { // type of brush and range
            size( 1… 64~ 10) // range of radius
            press( 0… 1~ 1) // pressure changes size
            index( 1… 255~ 127) // index in 256 color palette
        }
        line { // place holder for line drawing
            prev(x  0… 1, y  0… 1) // staring point of segment
            next(x  0… 1, y  0… 1) // endint point of segment
        }
        dot {
            on(x  0_ 11, y  0_ 11, z  0_ 127)
            off(x  0_ 11, y  0_ 11, z  0_ 127)
        }
    }
    canvas(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint) <<model.hand˚middle.tip
}
shader {
    pipeline {
        draw slide color cubemap plato }
    cell {
        fade( 1.2… 3) >> shader.cell.fade.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        ave( 0… 1 =  0.5) >> shader.cell.ave.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        melt( 0… 1 =  0.5) >> shader.cell.melt.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        tunl( 0… 5 =  1) >> shader.cell.tunl.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        slide( 0… 7 =  3) >> shader.cell.slide.on( 1) {
            on(% 2~ 1) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        fred( 0… 4 =  4) >> shader.cell.fred.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
        }
        zha( 0… 6 =  2) >> shader.cell.zha.on( 1) {
            on(% 2) >> (shader.cell.fade.on( 0), shader.cell.ave.on( 0), shader.cell.melt.on( 0), shader.cell.tunl.on( 0), shader.cell.slide.on( 0), shader.cell.fred.on( 0), shader.cell.zha.on( 0))
            bits( 2… 4 =  3)
            loops( 11)
        }
    }
    compute {
        draw(x  0… 1~ 0.5, y  0… 1~ 0.5) {
            on( 0… 1~ 1)
        }
        record {
            on( 0… 1~ 0)
        }
        camera {
            on( 0… 1~ 0)
            front(% 2~ 1)
        }
        camix {
            mix( 0… 1~ 0.5)
        }
        color(y  0… 1)
    }
    render {
        flatmap {
            frame(x  0, y  0, w  2160, h  3840)
            repeat(x  -1… 1~ 0, y  -1… 1~ 0)
            mirror(x  0… 1~ 0, y  0… 1~ 0)
            on(% 2~ 0)
        }
        cubemap {
            frame(x  0, y  0, w  2160, h  3840)
            repeat(x  -1… 1~ 0, y  -1… 1~ 0)
            mirror(x  0… 1~ 0, y  0… 1~ 0)
            rotate(x  0… 1~ 0, y  0… 1~ 0)
            gravity( 0… 2~ 0)
            on(% 2~ 1)
        }
        plato {
            on(% 2~ 0)
        }
    }
}
_model {
    canvas {
        mirror(x  0… 1~ 0, y  0… 1~ 0) <> (shader.render.flatmap.mirror, shader.render.cubemap.mirror) ^ sky.main.anim
        shift(x  0… 1~ 0.5, y  0… 1~ 0.5) <> shader.compute.draw ^ sky.main.anim
        repeat(x  -1… 1~ 0, y  -1… 1~ 0) <> (shader.render.flatmap.repeat, shader.render.cubemap.repeat) >> (midi.cc.skypad.repeatX(val x), midi.cc.skypad.repeatY(val y)) ^ sky.main.anim
        color {
            fade(x  0… 1, y  0… 1) >> (shader.compute.color, sky.color.xfade) ^ sky.main.anim
            fill_0(% 1) <> sky.draw.screen.fill( 0)
            fill_1(% 1) <> sky.draw.screen.fill( 1)
        }
        brush {
            size( 0… 1~ 0.5) <> sky.draw.brush.size
            press(% 2~ 1) <> sky.draw.brush.press
            tilt(% 2~ 0) <> sky.input.tilt
            index( 1_ 255~ 127) <> sky.draw.brush.index
        }
    }
    plato {
        more {
            wire(% 2~ 0)
            phase( 0_ 10~ 1)
            harmonic( 0_ 6~ 1)
            show(% 2~ 0) >>(model.more.show.platomodel.more.show.cubemap),
            run(% 2~ 1)
        }
        reflect( 0… 1~ 0.8)
        invert( 0… 1~ 1)
        shadow(x  0… 1~ 0, y  0… 1~ 0)
        zoom( 0… 1~ 0.5) ^ sky.main.anim
        convex( 0.9… 1.1~ 0.9)
    }
    cell {
        fade( 0.2… 2~ 1) <> shader.cell.fade
        ave( 0… 1~ 0.5) <> shader.cell.ave
        melt( 0… 1~ 0.5) <> shader.cell.melt
        tunl( 0_ 5~ 1) <> shader.cell.tunl
        zha( 0_ 6~ 2) <> shader.cell.zha
        slide( 0_ 7~ 3) <> shader.cell.slide
        fred( 0_ 4~ 4) <> shader.cell.fred
    }
    camera {
        stream(% 2~ 0) <> shader.compute.camera.on
        front(% 2~ 1) <> shader.compute.camera.front
        mix( 0… 1~ 0.5) <> shader.compute.camix.mix
        fade(x  0… 1~ 0.5, y  0… 1~ 0.1) <> _model.canvas.color.fade
    }
    more {
        speed {
            fps( 0_ 60~ 60) <>sky.main.fps
            run(% 2~ 1) <> sky.main.run
            anim( 0… 1~ 0.24) <> sky.main.anim
        }
        network {
            bonjour(peer "bonjour") <> sky.network.bonjour
            follow(% 2~ 1) <> sky.network.follow
            midi(% 2~ 1) <> sky.network.midi
        }
        motion(% 2~ 1)
        rotate(x  -1… 1~ 0, y  -1… 1~ 0) <> shader.render.cubemap.rotate
        show {
            cubemap(% 2~ 0) <> shader.render.cubemap.on
            canvas(% 2~ 0)
            plato(% 2~ 0) <> shader.render.plato.on
        }
    }
    hand @_hand {
        thumb {
            knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        }
        index {
            meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        }
        middle {
            meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        }
        ring {
            meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        }
        little {
            meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        }
    }
}
_hand {
    thumb {
        knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
    }
    index {
        meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
    }
    middle {
        meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
    }
    ring {
        meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
    }
    little {
        meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
        tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
    }
}
model {
    left @_model {
        canvas {
            mirror(x  0… 1~ 0, y  0… 1~ 0)
            shift(x  0… 1~ 0.5, y  0… 1~ 0.5)
            repeat(x  -1… 1~ 0, y  -1… 1~ 0)
            color {
                fade(x  0… 1, y  0… 1)
                fill_0(% 1)
                fill_1(% 1)
            }
            brush {
                size( 0… 1~ 0.5)
                press(% 2~ 1)
                tilt(% 2~ 0)
                index( 1_ 255~ 127)
            }
        }
        plato {
            more {
                wire(% 2~ 0)
                phase( 0_ 10~ 1)
                harmonic( 0_ 6~ 1)
                show(% 2~ 0)
                run(% 2~ 1)
            }
            reflect( 0… 1~ 0.8)
            invert( 0… 1~ 1)
            shadow(x  0… 1~ 0, y  0… 1~ 0)
            zoom( 0… 1~ 0.5)
            convex( 0.9… 1.1~ 0.9)
        }
        cell {
            fade( 0.2… 2~ 1)
            ave( 0… 1~ 0.5)
            melt( 0… 1~ 0.5)
            tunl( 0_ 5~ 1)
            zha( 0_ 6~ 2)
            slide( 0_ 7~ 3)
            fred( 0_ 4~ 4)
        }
        camera {
            stream(% 2~ 0)
            front(% 2~ 1)
            mix( 0… 1~ 0.5)
            fade(x  0… 1~ 0.5, y  0… 1~ 0.1)
        }
        more {
            speed {
                fps( 0_ 60~ 60)
                run(% 2~ 1)
                anim( 0… 1~ 0.24)
            }
            network {
                bonjour(peer "bonjour")
                follow(% 2~ 1)
                midi(% 2~ 1)
            }
            motion(% 2~ 1)
            rotate(x  -1… 1~ 0, y  -1… 1~ 0)
            show {
                cubemap(% 2~ 0)
                canvas(% 2~ 0)
                plato(% 2~ 0)
            }
        }
        hand @_hand {
            thumb {
                knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            }
            index {
                meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            }
            middle {
                meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            }
            ring {
                meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            }
            little {
                meta(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                knuc(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                base(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                inter(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
                tip(x  -0.3… 0.3, y  0.8… 1.2, z  -0.5… 0.01, time, phase, joint)
            }
        }
    }
    right }
_menu {
    canvas(svg "icon.canvas") {
        mirror(svg "icon.mirror")
        repeat(svg "icon.repeat.arrows")
        shift(svg "icon.direction")
        color(img "icon.pal.main") {
            fade(svg "icon.gradient")
            fill_0(sym "drop")
            fill_1(sym "drop.fill")
        }
        brush(svg "icon.brush") {
            size(svg "icon.size.dot")
            press(sym "scribble.variable")
            tilt(sym "angle")
            index(sym "calendar.day.timeline.left")
        }
    }
    plato(svg "icon.plato.icosa") {
        more(svg "icon.more") {
            wire(svg "icon.wireframe")
            phase(svg "icon.plato.phase")
            harmonic(svg "icon.subtriangle")
            show(sym "eye")
            run(svg "icon.counter")
        }
        reflect(svg "icon.opacity")
        shadow(sym "shadow")
        invert(svg "icon.invert")
        zoom(svg "icon.zoom")
        convex(svg "icon.convex")
    }
    cell(svg "icon.cellular.automata") {
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
        fade(svg "icon.gradient")
    }
    more(svg "icon.more") {
        speed(img "icon.speed") {
            fps(sym "speedometer")
            run(sym "goforward")
            anim(sym "bolt.fill")
        }
        network(sym "bonjour") {
            bonjour(sym "network")
            follow(sym "app.connected.to.app.below.fill")
            midi(sym "pianokeys.inverse")
        }
        motion(sym "gyroscope")
        rotate(svg "icon.rotate")
        show(sym "eye") {
            cubemap(sym "cube")
            canvas(svg "icon.canvas")
            plato(svg "icon.dodec")
        }
    }
}
menu {
    left @_menu {
        canvas(svg "icon.canvas") {
            mirror(svg "icon.mirror")
            repeat(svg "icon.repeat.arrows")
            shift(svg "icon.direction")
            color(img "icon.pal.main") {
                fade(svg "icon.gradient")
                fill_0(sym "drop")
                fill_1(sym "drop.fill")
            }
            brush(svg "icon.brush") {
                size(svg "icon.size.dot")
                press(sym "scribble.variable")
                tilt(sym "angle")
                index(sym "calendar.day.timeline.left")
            }
        }
        plato(svg "icon.plato.icosa") {
            more(svg "icon.more") {
                wire(svg "icon.wireframe")
                phase(svg "icon.plato.phase")
                harmonic(svg "icon.subtriangle")
                show(sym "eye")
                run(svg "icon.counter")
            }
            reflect(svg "icon.opacity")
            shadow(sym "shadow")
            invert(svg "icon.invert")
            zoom(svg "icon.zoom")
            convex(svg "icon.convex")
        }
        cell(svg "icon.cellular.automata") {
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
            fade(svg "icon.gradient")
        }
        more(svg "icon.more") {
            speed(img "icon.speed") {
                fps(sym "speedometer")
                run(sym "goforward")
                anim(sym "bolt.fill")
            }
            network(sym "bonjour") {
                bonjour(sym "network")
                follow(sym "app.connected.to.app.below.fill")
                midi(sym "pianokeys.inverse")
            }
            motion(sym "gyroscope")
            rotate(svg "icon.rotate")
            show(sym "eye") {
                cubemap(sym "cube")
                canvas(svg "icon.canvas")
                plato(svg "icon.dodec")
            }
        }
        hand(svg "hand.left") {
            thumb {
                knuc base inter tip }
            index {
                meta knuc base inter tip }
            middle {
                meta knuc base inter tip }
            ring {
                meta knuc base inter tip }
            little {
                meta knuc base inter tip }
        }
    }
    right @_menu {
        canvas(svg "icon.canvas") {
            mirror(svg "icon.mirror")
            repeat(svg "icon.repeat.arrows")
            shift(svg "icon.direction")
            color(img "icon.pal.main") {
                fade(svg "icon.gradient")
                fill_0(sym "drop")
                fill_1(sym "drop.fill")
            }
            brush(svg "icon.brush") {
                size(svg "icon.size.dot")
                press(sym "scribble.variable")
                tilt(sym "angle")
                index(sym "calendar.day.timeline.left")
            }
        }
        plato(svg "icon.plato.icosa") {
            more(svg "icon.more") {
                wire(svg "icon.wireframe")
                phase(svg "icon.plato.phase")
                harmonic(svg "icon.subtriangle")
                show(sym "eye")
                run(svg "icon.counter")
            }
            reflect(svg "icon.opacity")
            shadow(sym "shadow")
            invert(svg "icon.invert")
            zoom(svg "icon.zoom")
            convex(svg "icon.convex")
        }
        cell(svg "icon.cellular.automata") {
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
            fade(svg "icon.gradient")
        }
        more(svg "icon.more") {
            speed(img "icon.speed") {
                fps(sym "speedometer")
                run(sym "goforward")
                anim(sym "bolt.fill")
            }
            network(sym "bonjour") {
                bonjour(sym "network")
                follow(sym "app.connected.to.app.below.fill")
                midi(sym "pianokeys.inverse")
            }
            motion(sym "gyroscope")
            rotate(svg "icon.rotate")
            show(sym "eye") {
                cubemap(sym "cube")
                canvas(svg "icon.canvas")
                plato(svg "icon.dodec")
            }
        }
        hand(svg "hand.right") {
            thumb {
                knuc base inter tip }
            index {
                meta knuc base inter tip }
            middle {
                meta knuc base inter tip }
            ring {
                meta knuc base inter tip }
            little {
                meta knuc base inter tip }
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num  0_ 127, velo  0_ 127, chan  1_ 32, port  1_ 16, time)
            off(num  0_ 127, velo  0_ 127, chan  1_ 32, port  1_ 16, time)
        }
        afterTouch(num  0_ 127, val  0_ 127, chan  1_ 32, port  1_ 16, time)
        pitchBend(val  0_ 16384~ 8192, chan  1_ 32, port  1_ 16, time)
        program(num  0_ 255, chan  1_ 32, port  1_ 16, time)
        nrpn(num  0_ 16383, val  0… 1, chan, time) >> (midi.skypad.plane, midi.skypad.fade)
        controller(cc  0_ 127, val  0_ 127, chan  1_ 32, port  1_ 16, time) >> (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num  0_ 127, velo  0_ 127, chan  1_ 32, port  1_ 16, time)
            off(num  0_ 127, velo  0_ 127, chan  1_ 32, port  1_ 16, time)
        }
        afterTouch(num  0_ 127, val  0_ 127, chan  1_ 32, port  1_ 16, time)
        pitchBend(val  0_ 16384~ 8192, chan  1_ 32, port  1_ 16, time)
        program(num  0_ 255, chan  1_ 32, port  1_ 16, time)
        nrpn(num  0_ 16383, val  0… 1, chan, time)
        controller(cc  0_ 127, val  0_ 127, chan  1_ 32, port  1_ 16, time) << (midi.cc.skypad.zoom, midi.cc.skypad.convex, midi.cc.skypad.colorY, midi.cc.skypad.camix, midi.cc.skypad.fade, midi.cc.skypad.plane, midi.cc.skypad.shiftX, midi.cc.skypad.shiftY, midi.cc.skypad.repeatX, midi.cc.skypad.repeatY, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
    }
    skypad {
        plane(num ==  129, val  0… 1, chan, time) <>model.canvas.color.fade(x val)
        fade(num ==  130, val  0… 1, chan, time) <>model.canvas.color.fade(y val)
    }
    cc {
        skypad {
            zoom(cc ==  4, val  0_ 127) <>model.plato.zoom
            convex(cc ==  5, val  0_ 127) <>model.plato.shade.convex
            colorY(cc ==  6, val  0_ 127) <>model.plato.shade.colors(y val)
            camix(cc ==  9, val  0_ 127) <>model.camera.mix(val)
            fade(cc ==  10, val  0_ 127) <>model.canvas.color.fade(x val)
            plane(cc ==  11, val  0_ 127) <>model.canvas.color.fade(y val)
            shiftX(cc ==  12, val  0_ 127) <>model.canvas.tile.shift(x val)
            shiftY(cc ==  13, val  0_ 127) <>model.canvas.tile.shift(y val)
            repeatX(cc ==  14, val  0_ 127) <>model.canvas.tile.repeat(x val)
            repeatY(cc ==  15, val  0_ 127) <>model.canvas.tile.repeat(y val) // skypad˚. >> output.note.on(num val)

        }
        roli {
            lightpad {
                x(cc ==  114, val  0_ 127) //<> sky.draw.dot.on(x val)
                y(cc ==  113, val  0_ 127) //<> sky.draw.dot.on(y val)
                z(cc ==  115, val  0_ 127) //<> (sky.draw.dot.on(z val),
                                           //    sky.color.xfade(x val))
            }
            loopblock {
                mode(cc ==  102, val  0_ 127)
                mute(cc ==  103, val  0_ 127)
                metro(cc ==  104, val  0_ 127)
                skip(cc ==  105, val  0_ 127)
                back(cc ==  106, val  0_ 127)
                play(cc ==  107, val  0_ 127)
                record(cc ==  108, val  0_ 127)
                learn(cc ==  109, val  0_ 127)
                prev(cc ==  110, val  0_ 127)
                next(cc ==  111, val  0_ 127)
            }
        }
    }
    notes {
        dot {
            on(x num % 12, y num /  12, z velo) >> sky.draw.dot.on
            off(x num % 12, y num /  12, z velo) >> sky.draw.dot.off
        }
        input {
            note {
                on >> (midi.notes.dot.on, midi.output.note.on) off >> (midi.notes.dot.off, midi.output.note.off) }
        }
    }
    _cc {
        main {
            modWheel(num ==  1, val, chan, time)
            volume(num ==  7, val, chan, time)
            balance(num ==  8, val, chan, time)
            panPosition(num ==  10, val, chan, time)
            expression(num ==  11, val, chan, time)
            controller(num in  32_ 63, val, chan, time)
            portamento {
                time(num ==  5, val, chan, time)
                amount(num ==  84, val, chan, time)
            }
        }
        pedal {
            hold(num ==  64, val, chan, time)
            porta(num ==  65, val, chan, time)
            sosta(num ==  66, val, chan, time)
            _soft(num ==  67, val, chan, time)
            _legato(num ==  68, val, chan, time)
            _hold2(num ==  69, val, chan, time)
        }
        _main2 {
            bankSelect(num ==  0, val, chan, time)
            breathCtrl(num ==  2, val, chan, time)
            footPedal(num ==  4, val, chan, time)
            dataEntry(num ==  6, val, chan, time)
            effectCtrl1(num ==  12, val, chan, time)
            effectCtrl2(num ==  13, val, chan, time)
        }
        _sound {
            soundVariation(num ==  70, val, chan, time)
            resonance(num ==  71, val, chan, time)
            soundReleaseTime(num ==  72, val, chan, time)
            soundAttackTime(num ==  73, val, chan, time)
            frequencyCutoff(num ==  74, val, chan, time)
            timbre(num ==  71, val, chan, time)
            brightness(num ==  74, val, chan, time)
        }
        _button {
            button1(num ==  80, val, chan, time)
            button2(num ==  81, val, chan, time)
            button3(num ==  82, val, chan, time)
            button4(num ==  83, val, chan, time)
            decayor(num ==  80, val, chan, time)
            hiPassFilter(num ==  81, val, chan, time)
            generalPurpose82(num ==  82, val, chan, time)
            generalPurpose83(num ==  83, val, chan, time)
        }
        _roland {
            rolandToneLevel1(num ==  80, val, chan, time)
            rolandToneLevel2(num ==  81, val, chan, time)
            rolandToneLevel3(num ==  82, val, chan, time)
            rolandToneLevel4(num ==  83, val, chan, time)
        }
        _level {
            reverbLevel(num ==  91, val, chan, time)
            tremoloLevel(num ==  92, val, chan, time)
            chorusLevel(num ==  93, val, chan, time)
            detuneLevel(num ==  94, val, chan, time)
            phaserLevel(num ==  95, val, chan, time)
        }
        _parameter {
            dataButtonIncrement(num ==  96, val, chan, time)
            dataButtonDecrement(num ==  97, val, chan, time)
            nonregisteredParameterLSB(num ==  98, val, chan, time)
            nonregisteredParameterMSB(num ==  99, val, chan, time)
            registeredParameterLSB(num ==  100, val, chan, time)
            registeredParameterMSB(num ==  101, val, chan, time)
        }
        _soundControl {
            soundControl6(num ==  75, val, chan, time)
            soundControl7(num ==  76, val, chan, time)
            soundControl8(num ==  77, val, chan, time)
            soundControl9(num ==  78, val, chan, time)
            soundControl10(num ==  79, val, chan, time)
        }
        _undefined {
            undefined_3(num ==  3, val, chan, time)
            undefined_9(num ==  9, val, chan, time)
            undefined_14_31(num in  14_ 31, val, chan, time)
            undefined_85_90(num in  85_ 90, val, chan, time)
            undefined_102_119(num in  102_ 119, val, chan, time)
        }
        _mode {
            allSoundOff(num ==  120, val, chan, time)
            allControllersOff(num ==  121, val, chan, time)
            localKeyboard(num ==  122, val, chan, time)
            allNotesOff(num ==  123, val, chan, time)
            monoOperation(num ==  126, val, chan, time)
            polyMode(num ==  127, val, chan, time)
        }
        _omni {
            omniModeOff(num ==  124, val, chan, time)
            omniModeOn(num ==  125, val, chan, time)
            omniMode( 0_ 1) << (midi._cc._omni.omniModeOff( 0), midi._cc._omni.omniModeOn( 1))
        }
    }
}
