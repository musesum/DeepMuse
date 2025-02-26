// created by musesum on 11/26/24

import MuFlo
import MuVision
import MuSky

class SkyArchive: ArchiveFlo {

    public static let shared = SkyArchive()

    private var bundles = [MuSky.bundle, MuVision.bundle]
    private var snapName = "Snapshot"
    private var texNames = ["pipe.draw.out"] // textures
#if os(visionOS)
    private var  scriptNames = ["sky", "pipe.vision", "menu.vision", "hand", "midi" ]
#else
    private var scriptNames  = ["sky", "pipe", "menu", "midi"]
#endif
    init() {
        super.init(bundles, snapName, scriptNames, texNames)
    }
}
