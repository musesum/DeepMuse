// created by musesum on 1/20/24

import MuFlo

class FloXyzOn {

    var flo˚ : Flo?
    var xyz˚ : Flo? ; var xyz = SIMD3<Float>.zero
    var on˚  : Flo? ; var on = false

    func parse(_ hand˚: Flo, _ joint: HandJoints) {

        flo˚ = hand˚.bind(joint.rawValue)
        xyz˚ = flo˚?.bind("pos") { f,_ in self.xyz = f.xyz  }
        on˚  = flo˚?.bind("on")  { f,_ in self.on  = f.bool }

        guard let flo˚ else { return err("\(joint.rawValue)") }
        if xyz˚ == nil      { return err("\(flo˚.name).xyz") }
        if on˚  == nil      { return err("\(flo˚.name).on") }

        func err(_ msg: String) {
            print("⁉️ hand.\(joint.rawValue) not Found")
        }
    }
}
