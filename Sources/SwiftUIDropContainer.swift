#if os(iOS) || os(visionOS)
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Internal container that hosts a SwiftUI view inside a regular `UIView` so it can
/// participate in the existing UIKit‐based animation and gesture system.
@available(iOSApplicationExtension, unavailable)
internal final class SwiftUIDropContainer<Content: View>: UIView {

  // MARK: - Init
  init(content: Content) {
    self.hostingController = UIHostingController(rootView: content)
    super.init(frame: .zero)

    // Embed hosting controller's view.
    let hostedView = hostingController.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    hostedView.backgroundColor = .clear
    addSubview(hostedView)

    NSLayoutConstraint.activate([
      hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostedView.topAnchor.constraint(equalTo: topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    // Replicate DropView's shadow styling.
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = .zero
    layer.shadowRadius = 25
    layer.shadowOpacity = 0.15
    layer.shouldRasterize = true
    #if os(iOS)
    layer.rasterizationScale = UIScreen.main.scale
    #endif
    layer.masksToBounds = false
  }

  required init?(coder _: NSCoder) {
    return nil
  }

  // MARK: - Layout
  override func layoutSubviews() {
    super.layoutSubviews()
    // Maintain the pill‐shaped corner radius used by DropView.
    layer.cornerRadius = bounds.cornerRadius
  }

  // MARK: - Private
  private let hostingController: UIHostingController<Content>
}
#endif 
