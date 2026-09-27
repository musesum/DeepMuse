// created by musesum on 11/26/24

import MuFlo
import MuVision
import MuSky

public class SkyArchive: ArchiveFlo {

    private var bundles = [MuSky.bundle, MuVision.bundle]
    private var snapName = "Snapshot"
#if os(visionOS)
    private var  scriptNames = ["sky", "canvas", "pipe", "cells", "plato", "camera", "layers", "more", "hand", "midi", "tape", "graph"]
#else
    private var scriptNames  = ["sky", "canvas", "pipe", "cells", "plato", "camera", "layers", "more", "hand", "midi", "tape", "graph"]
#endif
    init(_ root˚: Flo) {
        super.init(root˚, bundles, snapName, scriptNames)
    }
}
