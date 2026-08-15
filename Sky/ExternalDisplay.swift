// created by musesum on 7/6/26.

#if os(iOS)
import SwiftUI
import UIKit
import Combine
import MuDisplay
import MuFlo

/// Detects an external display connect/disconnect and, in **Extend** mode, drives a secondary
/// `UIWindow` on that screen showing ONLY the render surface — the pipeline's `CAMetalLayer` is
/// reparented from `TouchView` into the external window, leaving the device with the menus.
/// **Mirror** mode restores the layer and tears the secondary window down so the OS hardware
/// mirror stays in place.
///
/// This uses the `UIScreen` connect/disconnect notifications + a `UIWindow` bound to the external
/// screen. The scene-based external-display API requires `UIApplicationSupportsMultipleScenes`,
/// which this app leaves `false` (single scene), so the window-on-screen path is the correct one
/// here. The secondary display can only be exercised on a physical device — not the simulator —
/// so behavior here is compile-verified and must be confirmed on device.
@MainActor
final class ExternalDisplayManager: ObservableObject {

    static let modeKey = "externalDisplayMode"

    @Published private(set) var connected = false
    /// Drives the Mirror/Extend chooser presentation (true just after a connect).
    @Published var showChoice = false
    @Published private(set) var mode: ExternalDisplayMode
    /// The size the external screen reports (read back after any resolution apply).
    @Published private(set) var currentSize: CGSize?

    private var externalWindow: UIWindow?
    /// TouchView-relative frame of the pipeline layer, saved across reparenting.
    private var savedLayerFrame: CGRect?
    private var cancellables = Set<AnyCancellable>()

    init() {
        mode = UserDefaults.standard.string(forKey: Self.modeKey)
            .flatMap { ExternalDisplayMode(rawValue: $0) } ?? .mirror

        NotificationCenter.default.publisher(for: LegacyDisplay.didConnectNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.handleConnect() } }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: LegacyDisplay.didDisconnectNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.handleDisconnect() } }
            .store(in: &cancellables)
        // A display already attached at launch.
        if externalScreen != nil {
            handleConnect()
        }
        // Menu "tv" leaf (more.flo.h → sky.main.monitor): tapping reopens the chooser on demand.
        if let monitor˚ = SkyModel.shared.root˚.findPath("sky.main.monitor") {
            monitor˚.addClosure { [weak self] _, _ in
                Task { @MainActor in self?.presentChoice() }
            }
        }
        // Rotation resets pipeline.layer.frame to device bounds (Pipeline.resizeFrame
        // via SkyView geometry onChange) while the layer sits in the external window,
        // shrinking the image each rotation. Reassert the external frame after the
        // geometry settles — the automatic form of re-choosing Extend in the dialog.
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in Task { @MainActor in self?.reassertExtendedFrame() } }
            .store(in: &cancellables)
    }

    /// Re-fit the reparented layer to the external window after rotation.
    /// Frame only — drawableSize stays as the pipeline set it.
    private func reassertExtendedFrame() {
        guard mode == .extend, connected,
              let root = externalWindow?.rootViewController?.view else { return }
        let layer = SkyModel.shared.pipeline.layer
        guard layer.superlayer === root.layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = root.bounds
        CATransaction.commit()
    }

    /// Present the chooser on demand — not only at connect time.
    func presentChoice() {
        currentSize = externalScreen?.currentMode?.size ?? externalScreen?.bounds.size
        showChoice = true
    }

    /// The first connected screen that isn't the device's own (shared legacy shim — the
    /// deprecated members remain the functional discovery path).
    var externalScreen: UIScreen? { LegacyDisplay.externalScreen }

    private func handleConnect() {
        connected = true
        currentSize = externalScreen?.currentMode?.size ?? externalScreen?.bounds.size
        showChoice = true   // ask Mirror vs Extend
    }

    private func handleDisconnect() {
        connected = false
        showChoice = false
        currentSize = nil
        teardownWindow()
    }

    /// Apply the user's Mirror/Extend choice from the chooser.
    func choose(_ newMode: ExternalDisplayMode) {
        mode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: Self.modeKey)
        showChoice = false
        switch newMode {
        case .mirror: teardownWindow()   // OS mirrors the device — all controls visible externally
        case .extend: attachWindow()     // external shows only the render surface
        }
    }

    /// Apply a resolution pick, then read back the size the screen actually negotiated.
    func applyResolution(_ resolution: DisplayResolution) {
        guard let screen = externalScreen else { return }
        currentSize = DisplayModeProvider.apply(resolution, to: screen)
        if mode == .extend, let root = externalWindow?.rootViewController?.view {
            SkyModel.shared.pipeline.layer.frame = root.bounds
        }
    }

    private func attachWindow() {
        guard let screen = externalScreen else { return }
        // Prefer the external display's OWN UIWindowScene when the system vended one (the modern,
        // non-deprecated path). With UIApplicationSupportsMultipleScenes=false the system mirrors
        // instead of vending a second scene, so fall back to the legacy `window.screen` association
        // — the documented (now-deprecated) external-display mechanism. If neither presents the
        // window on device, enabling multiple-scene support is the required next step.
        let externalScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.screen === screen }
        let window: UIWindow
        if let externalScene {
            window = externalWindow ?? UIWindow(windowScene: externalScene)
        } else {
            // Legacy association, reached through the shared MuDisplay shims.
            window = externalWindow ?? LegacyDisplay.makeWindow(on: screen)
        }
        let host = UIViewController()
        host.view.backgroundColor = .black
        window.rootViewController = host
        window.isHidden = false
        externalWindow = window
        reparentLayer(into: host.view)
    }

    /// Move the pipeline's `CAMetalLayer` from `TouchView` into the external window. The layer is
    /// a plain sublayer of `TouchView` (added in TouchView.init); touch handling reads UITouch
    /// events on the view, not the layer, so drawing on the device keeps working while the render
    /// surface shows externally. `contentsGravity = .resizeAspectFill` scales the drawable.
    private func reparentLayer(into hostView: UIView) {
        let layer = SkyModel.shared.pipeline.layer
        if savedLayerFrame == nil {
            savedLayerFrame = layer.frame
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hostView.layer.addSublayer(layer)
        layer.frame = hostView.bounds
        CATransaction.commit()
    }

    /// Restore the pipeline layer to `TouchView` (Mirror choice or disconnect).
    private func restoreLayer() {
        let skyModel = SkyModel.shared
        let layer = skyModel.pipeline.layer
        guard layer.superlayer !== skyModel.touchView.layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        skyModel.touchView.layer.addSublayer(layer)
        if let savedLayerFrame {
            layer.frame = savedLayerFrame
        }
        CATransaction.commit()
        savedLayerFrame = nil
    }

    private func teardownWindow() {
        restoreLayer()
        externalWindow?.isHidden = true
        externalWindow = nil
    }
}
#endif
