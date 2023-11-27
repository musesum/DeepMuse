// created by musesum.
#if os(visionOS)
import CompositorServices

extension LayerRenderer.Clock.Instant {
    func toTimeInterval() -> TimeInterval {
        let duration = LayerRenderer.Clock.Instant.epoch.duration(to: self)
        let secondsPart = Double(duration.components.seconds)
        let attosecondsPart = Double(duration.components.attoseconds) / 1e18
        return secondsPart + attosecondsPart
    }
}
extension LayerRenderer.Clock.Instant.Duration {
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}
#endif
