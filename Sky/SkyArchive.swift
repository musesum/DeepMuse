// created by musesum on 11/26/24

import MuFlo
import MuVision
import MuSky

class SkyArchive: ArchiveFlo {
    
    private var bundles = [MuSky.bundle, MuVision.bundle]
    private var snapName = "Snapshot"
    private var texNames = ["pipe.draw.out"] // textures
#if os(visionOS)
    private var  scriptNames = ["sky", "pipe.avp", "canvas", "plato.avp", "cell", "camera", "more", "hand", "midi" ]
#else
    private var scriptNames  = ["sky", "pipe", "canvas", "plato", "cell", "camera", "more", "midi"]
#endif
    init(_ root: Flo) {
        super.init(root, bundles, snapName, scriptNames, texNames)
    }
}
