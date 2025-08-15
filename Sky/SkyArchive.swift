// created by musesum on 11/26/24

import MuFlo
import MuVision
import MuSky

public class SkyArchive: ArchiveFlo {

    private var bundles = [MuSky.bundle, MuVision.bundle]
    private var snapName = "Snapshot"
    private var texNames = ["pipe.draw.out"] // textures
#if os(visionOS)
    private var  scriptNames = ["sky", "pipe.avp", "canvas", "plato.avp", "cell", "more", "hand", "chat", "midi", "tape"]
#else
    private var scriptNames  = ["sky", "pipe", "canvas", "plato", "cell", "camera", "more", "hand", "chat", "midi", "tape"]
#endif
    init(_ root˚: Flo, _ nextFrame: NextFrame) {
        super.init(root˚, bundles, snapName, scriptNames, texNames, nextFrame)
    }
}
