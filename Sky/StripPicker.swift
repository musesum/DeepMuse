// created by musesum on 9/9/26

import UIKit
import Photos
import PhotosUI
import UniformTypeIdentifiers
import MuFlo
import MuVision

/// PHPicker for the photo strip: up to eight stills or movies, delivered in picked order.
/// Dreamatic's AlbumPicker filter and loading: movies are checked before images (so Live
/// Photos and the video sub-kinds arrive as movies) and come back as file copies.
@MainActor
enum StripPicker {

    /// one delegate per live picker, keyed by the picker itself (PHPickerViewController.delegate
    /// is weak, so this dictionary is the only strong owner); `active` guards re-entrancy
    private static var delegates = [ObjectIdentifier: Delegate]()
    private static weak var active: PHPickerViewController?
    private static var pending = false

    static func install() {
        StripNode.present = { done in
            Task { @MainActor in present(done) }
        }
    }

    static func present(_ done: @escaping ([StripPick]) -> Void) {
        // a picker is already up or its authorization ask is still pending: ignore the
        // extra fire instead of stacking a second picker on top of the first (Dev
        // 2026-09-18: multiple pick fires used to orphan the visible picker's delegate)
        guard active == nil, !pending else { return }
        // ask once for read-write, as Dreamatic does, so Settings can offer Full Access;
        // the out-of-process picker runs whatever the answer
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .notDetermined {
            pending = true
            Task {
                _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                pending = false
                present(done)
            }
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.keyWindow?.rootViewController else { return }
        // full access: the library-backed picker, whose results carry the asset
        // identifiers an archive's local link names the set by. Otherwise the
        // no-arg config = the out-of-process picker: the whole library even under
        // Limited Access (`.shared()` scopes to the grant and hid every video)
        var config = PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
            ? PHPickerConfiguration(photoLibrary: .shared())
            : PHPickerConfiguration()
        // a flat union: `.videos` alone drops slo-mo, timelapse, cinematic, screen
        // recordings and Live Photo motion; a nested `.any(of:)` is unreliable
        config.filter = .any(of: [.images, .videos, .slomoVideos, .timelapseVideos,
                                  .cinematicVideos, .screenRecordings, .livePhotos])
        config.selectionLimit = 8
        config.selection = .ordered
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        // a touch outside the sheet puts it away, the way any sheet does. The
        // dismissal has to be caught: it bypasses didFinishPicking, and `active`
        // would stay set (weak) until the picker deallocates, blocking a fresh
        // present() -- presentationControllerDidDismiss below clears it
        picker.isModalInPresentation = false
        let delegate = Delegate(done)
        delegates[ObjectIdentifier(picker)] = delegate
        picker.delegate = delegate
        picker.presentationController?.delegate = delegate
        active = picker
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(picker, animated: true)
    }

    /// picked slots, filled from the provider callbacks in any order
    final class Picks: @unchecked Sendable {
        private let lock = NSLock()
        private var picks: [StripPick?]
        init(_ count: Int) { picks = Array(repeating: nil, count: count) }
        func set(_ i: Int, _ pick: StripPick) { lock.withLock { picks[i] = pick } }
        var ordered: [StripPick] { lock.withLock { picks.compactMap { $0 } } }
    }

    /// an archive's local link: the photo library's assets by identifier, in
    /// the archive's order, delivered as a pick delivers them (a movie or a
    /// Live Photo as a file copy, a still as an image); one the library no
    /// longer has is left out. Asks for access first when never asked
    static func load(assetIds: [String], done: @escaping ([StripPick]) -> Void) {
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .notDetermined {
            Task {
                _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                load(assetIds: assetIds, done: done)
            }
            return
        }
        var byId = [String: PHAsset]()
        PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
            .enumerateObjects { asset, _, _ in byId[asset.localIdentifier] = asset }
        let picks = Picks(assetIds.count)
        let group = DispatchGroup()
        for (i, id) in assetIds.enumerated() {
            guard let asset = byId[id] else {
                PrintLog("⁉️ StripPicker link \(i): not in the library")
                continue
            }
            let resources = PHAssetResource.assetResources(for: asset)
            // a movie, or a Live Photo's motion: the picker hands both back as movies
            let movie = asset.mediaType == .video
                ? (resources.first { $0.type == .fullSizeVideo } ?? resources.first { $0.type == .video })
                : resources.first { $0.type == .pairedVideo }
            group.enter()
            if let movie {
                let ext = (movie.originalFilename as NSString).pathExtension.lowercased()
                let copy = FileManager.default.temporaryDirectory
                    .appendingPathComponent("strip-\(UUID().uuidString).\(ext.isEmpty ? "mov" : ext)")
                let options = PHAssetResourceRequestOptions()
                options.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(for: movie, toFile: copy, options: options) { error in
                    if let error {
                        PrintLog("⁉️ StripPicker link \(i) movie: \(error.localizedDescription)")
                    } else {
                        picks.set(i, StripPick(.video(copy), assetId: id))
                    }
                    group.leave()
                }
            } else {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat // one delivery
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize,
                                                      contentMode: .aspectFit, options: options) { image, _ in
                    if let image { picks.set(i, StripPick(.image(image), assetId: id)) }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            DebugLog { P("🎞️ strip links \(picks.ordered.count) of \(assetIds.count)") }
            done(picks.ordered)
        }
    }

    final class Delegate: NSObject, PHPickerViewControllerDelegate,
                          UIAdaptivePresentationControllerDelegate {
        let done: ([StripPick]) -> Void
        init(_ done: @escaping ([StripPick]) -> Void) { self.done = done }

        /// put away by a touch outside the sheet or a swipe down: nothing was
        /// picked, so the strip keeps the set it has; the slot is released so
        /// the next album control can bring the picker straight back up
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            guard let picker = presentationController.presentedViewController
                    as? PHPickerViewController else { return }
            MainActor.assumeIsolated {
                StripPicker.active = nil
                StripPicker.delegates[ObjectIdentifier(picker)] = nil
                done([])
            }
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // dismiss the picker itself, not whatever it may be presenting
            (picker.presentingViewController ?? picker).dismiss(animated: true)
            // release right away so a new present() is unblocked while the loads below finish
            StripPicker.active = nil
            StripPicker.delegates[ObjectIdentifier(picker)] = nil
            let providers = results.map(\.itemProvider)
            // nil unless the picker was made with the library (full access)
            let ids = results.map(\.assetIdentifier)
            let picks = Picks(providers.count)
            let group = DispatchGroup()
            for (i, provider) in providers.enumerated() {
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        defer { group.leave() }
                        guard let url else {
                            return PrintLog("⁉️ StripPicker movie \(i): \(error?.localizedDescription ?? "no file")")
                        }
                        // the provider deletes its file when this returns: copy it out first
                        let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension.lowercased()
                        let copy = FileManager.default.temporaryDirectory
                            .appendingPathComponent("strip-\(UUID().uuidString).\(ext)")
                        do {
                            try FileManager.default.copyItem(at: url, to: copy)
                            picks.set(i, StripPick(.video(copy), assetId: ids[i]))
                        } catch {
                            PrintLog("⁉️ StripPicker movie \(i) copy: \(error.localizedDescription)")
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                          provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage { picks.set(i, StripPick(.image(image), assetId: ids[i])) }
                        group.leave()
                    }
                }
            }
            let done = self.done
            group.notify(queue: .main) {
                done(picks.ordered)
            }
        }
    }
}
