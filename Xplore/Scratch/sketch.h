dock {
    command "⌘" {
        copy  "c"
        cut   "x"
        slice "s"
        paste "v"
        find  "f"

        save  "s"
        open  "o"

        undo  "z"
        redo  "⇧z"
        mark  "m"

        option  "⌥"
        control "⌃"
        shift   "⇧"
    }
    value {
        cell {
            fade  (0..1 = 0.5) >> sky.shader.fade.buffer.version
            ave   (0..1 = 0.4) >> sky.shader.ave.buffer.version
            melt  (0..1 = 1.0) >> sky.shader.melt.buffer.version
            tunl  (0..1 = 1.0) >> sky.shader.tunl.buffer.version
            slide (0..1 = 1.0) >> sky.shader.slide.buffer.version
            fred  (0..1 = 0.5) >> sky.shader.fred.buffer.version
        }
        view {
            bitplane (0..1) >> sky.shader.color.buffer.bitplane
            scroll   (x 0..1 = 0.5, y 0..1 = 0.5) <> sky.input.azimuth >> sky.shader.draws.buffer.scroll
            tile {
                repeat  (x 0..1, y 0..1) >> sky.shader.render.buffer.repeat
                mirror  (x 0..1, y 0..1) >> sky.shader.render.buffer.mirror
            }
            weave {
                spread  (x 0..1, y 0..1) <> shader.buffer.spread
                divide  (x 0..1, y 0..1) <> shader.buffer.divide
            }
        }
        brush {
            color
            size  (0..1) <> sky.draw.brush.size
            user >> brush.press.value(0)
            press (%2) <> sky.draw.brush.press
            type {
                circle (%2) >> ..*(0)
                square (%2) >> ..*(0)
                line   (%2) >> ..*(0)
            }
            fill {
                zero >> sky.draw.screen.fillZero
                one  >> sky.draw.screen.fillOne
            }
        }
        tape {
            record
            play (%2) >> stop(0)
            stop (%2) >> play(0)
            loop (%2)
            rewind
            prev
            next
            mark
            speed (-4..4 = 0)
        }
        music {
            audio
            beat
            midi
        }
        camera {
            snapshot
            video
            album
            reality
        }
        share {
            wifi {
                connect
                disconnect
            }
            sharePlay {
                connect
                disconnect
            }
            social {
                tiktok
                youtube
                instagram
                facebook
                twitter
                mail
            }
        }
    }
    icon {
        cell {
            fader "icon.cell.fade.png"
            ave   "icon.cell.ave.png"
            melt  "icon.cell.melt.png"
            tunl  "icon.cell.tunl.png"
            slide "icon.cell.slide.png"
            fred  "icon.cell.fred.png"
        }
        view {
            bitplane "icon.pearl.white.png"
            scroll   "icon.scroll.png"
            tile     "icon.shader.tile.png"
            weave    "icon.shader.weave.png"
        }
        brush      "icon.cell.brush.png" {
            tilt   "icon.pen.tilt.png"
            press  "icon.pen.press.png"
            color  "icon.pal.main.png"
            size
            type {
                circle
                square
                line
            }
            fill {
                zero "icon.drop.clear.png"
                one  "icon.drop.gray.png"
            }
        }
        tape "✇" {
            record { on "⏺" off "⏹"}
            play { on "▶️" off "⏸" }
            loop { on "🔁" off "⏹"
            speed "icon.magnet.png"
            beat "❤️"
            midi "🎹"
        }
        camera {
            snapshot
            video
            album
        }
        share {
            wifi {
                connect
                disconnect
            }
            sharePlay {
                connect
                disconnect
            }
            social {
                tiktok
                youtube
                instagram
                facebook
                twitter
                mail
            }
        }
    }    select˚˚(0) -> ..*(0)

}


cal {
    century { 2000 1900 }
    decade { 20 10 00 90 80 70 60 50 40 30 20 }
    year { 2021 2020 2019 }
    month { jan feb mar apr may jun jul aug sep oct nov dec }
    week { one two three four five }
    day {
        _1  _2  _3  _4  _5  _6  _7
        _8  _9  _10 _11 _12 _13 _14
        _15 _16 _17 _18 _19 _20 _21
        _22 _23 _24 _25 _26 _27 _28
        _29 _30 _31
    }
    hour {
        _00 _01 _02 _03 _04 _05 _06 _07 _08
        _09 _10 _11 _12 _13 _14 _15 _16 _17
        _18 _19 _20 _21 _22 _23 _24 _25 _26
    }
    min {
    }
}

menu {
    who { me you social }
    what { hello.µ }
    when = cal
    where { here }
    how {
        sky {
            cell {
                fader       (0..1 = 0.5) >> sky.shader.fade.buffer.version
                average     (0..1 = 0.4) >> sky.shader.ave.buffer.version
                melt        (0..1 = 1.0) >> sky.shader.melt.buffer.version
                timetunnel  (0..1 = 1.0) >> sky.shader.tunl.buffer.version
                slide       (0..1 = 1.0) >> sky.shader.slide.buffer.version
                fredkin     (0..1 = 0.5) >> sky.shader.fred.buffer.version
            }
            view {
                bitplane    (0..1) >> sky.shader.color.buffer.bitplane
                scroll      (x 0..1 = 0.5, y 0..1 = 0.5) <> sky.input.azimuth >> sky.shader.draw.buffer.scroll
                tile {
                    repeat  (x 0..1, y 0..1) >> sky.shader.render.buffer.repeat
                    mirror  (x 0..1, y 0..1) >> sky.shader.render.buffer.mirror
                }
                weave {
                    spread  (x 0..1, y 0..1) <> shader.buffer.spread
                    divide  (x 0..1, y 0..1) <> shader.buffer.divide
                }
            }
            brush {
                color
                size  (0..1) <> sky.draw.brush.size
                user >> brush.press.value(0)
                press (%2) <> sky.draw.brush.press
                type {
                    circle (%2) >> ..*(0)
                    square (%2) >> ..*(0)
                    line   (%2) >> ..*(0)
                }
                fill {
                    zero >> sky.draw.screen.fillZero
                    one  >> sky.draw.screen.fillOne
                }
            }
            tape {
                record
                play (%2) >> stop(0)
                stop (%2) >> play(0)
                loop (%2)
                rewind
                prev
                next
                mark
                speed (-4..4 = 0)
            }
            music {
                audio
                beat
                midi
            }
            camera {
                snapshot
                video
                album
                reality
            }
            share {
                wifi {
                    connect
                    disconnect
                }
                sharePlay {
                    connect
                    disconnect
                }
                social {
                    tiktok
                    youtube
                    instagram
                    facebook
                    twitter
                    mail
                }
            }
        }
    }
}
