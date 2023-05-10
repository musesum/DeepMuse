
model.canvas.plato (tog 0…1=1) {
        wire  (tog 0…1)
        morph (tog 0…1=1)
        coloriz (tog 0…1=1) {
            colors (val 0…1=1)
            shadow (tog 0…1=1)
            invert (tog 0…1=1)
        }
        counter (val 0…1=1)
        rotate  (x -1…1, y -1…1)
    }
}

class Dyna() {
    func gett() -> Any { return any }
    func sett(_ any: Any) { self.any = any }
    var any: Any!
}
class Plato: Dyna {
    let wire = Dyna()
    let morphing = Dyna()
    let coloriz = Colorize()
    class Colorize: Dyna() {
        let colors = Dyna()
        let shadow = Dyna()
        let invert = Dyna()
    }
}
class Test2 {
    let plato = Plato()
    func run() {
        plato.wire.sett(true)
        plato.morphing.sett(true)
        plato.colorize.colors.sett(true)
    }
}
