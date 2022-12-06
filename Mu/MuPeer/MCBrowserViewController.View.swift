import Combine
import MultipeerConnectivity
import protocol SwiftUI.UIViewControllerRepresentable

public extension MCBrowserViewController {

  final class View: NSObject {
    public init(serviceType: String,
                session: MCSession,
                peerCountRange: ClosedRange<Int>? = nil) {

      self.serviceType = serviceType
      self.session = session
      self.peerCountRange = peerCountRange
    }

    private let serviceType: String
    private unowned let session: MCSession
    private let peerCountRange: ClosedRange<Int>?

    private let didFinishSubject = CompletionSubject()
    private let wasCancelledSubject = CompletionSubject()
  }
}

// MARK: - public
public extension MCBrowserViewController.View {
  var didFinishPublisher: AnyPublisher<Void, Never> { didFinishSubject.eraseToAnyPublisher() }
  var wasCancelledPublisher: AnyPublisher<Void, Never> { wasCancelledSubject.eraseToAnyPublisher() }
}

// MARK: - private
private extension MCBrowserViewController {
  typealias CompletionSubject = PassthroughSubject<Void, Never>
}

// MARK: - UIViewControllerRepresentable
extension MCBrowserViewController.View: UIViewControllerRepresentable {
  public func makeUIViewController(context _: Context) -> MCBrowserViewController {
    let browser = MCBrowserViewController(
      serviceType: serviceType,
      session: session
    )

    browser.delegate = self

    if let peerCountRange = peerCountRange {
      browser.minimumNumberOfPeers = peerCountRange.lowerBound
      browser.maximumNumberOfPeers = peerCountRange.upperBound
    }

    return browser
  }

  public func updateUIViewController(_: MCBrowserViewController, context _: Context) { }
}

// MARK: - MCBrowserViewControllerDelegate
extension MCBrowserViewController.View: MCBrowserViewControllerDelegate {
  public func browserViewControllerDidFinish(_: MCBrowserViewController) {
    didFinishSubject.send()
  }

  public func browserViewControllerWasCancelled(_: MCBrowserViewController) {
    wasCancelledSubject.send()
  }
}
