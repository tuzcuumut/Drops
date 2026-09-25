#if os(iOS) || os(visionOS)
import UIKit
import SwiftUI

/// Only custom SwiftUI content uses the definite-width, content-height layout.
internal protocol SwiftUIDropHosting: AnyObject {
  func attach(to parent: UIViewController)
  func detach()
  func horizontalConstraints(in container: UIView) -> [NSLayoutConstraint]
}

/// Hosts SwiftUI content while preserving the UIKit animation and gesture surface.
@available(iOSApplicationExtension, unavailable)
internal final class SwiftUIDropContainer<Content: View>: UIView, SwiftUIDropHosting {
  init(content: Content) {
    hostingController = UIHostingController(rootView: content)
    super.init(frame: .zero)

    if #available(iOS 16.4, *) {
      // The presenter already places this entire view inside its safe area.
      // Do not change SwiftUI's proposal as the toast animates across that edge.
      hostingController.safeAreaRegions = []
    }
    hostingController.view.backgroundColor = .clear
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = .zero
    layer.shadowRadius = 25
    layer.shadowOpacity = 0.15
    layer.shouldRasterize = true
    layer.masksToBounds = false
  }

  required init?(coder _: NSCoder) {
    return nil
  }

  func attach(to parent: UIViewController) {
    guard hostingController.parent !== parent else { return }
    detach()
    parent.addChild(hostingController)
    let hostedView = hostingController.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostedView)
    NSLayoutConstraint.activate([
      hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostedView.topAnchor.constraint(equalTo: topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
    hostingController.didMove(toParent: parent)
    invalidateIntrinsicContentSize()
  }

  func detach() {
    guard hostingController.parent != nil else { return }
    hostingController.willMove(toParent: nil)
    hostingController.view.removeFromSuperview()
    hostingController.removeFromParent()
  }

  func horizontalConstraints(in container: UIView) -> [NSLayoutConstraint] {
    // Supply available space only. SwiftUI content owns its margins and width limits.
    [
      leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor),
      trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor)
    ]
  }

  override var intrinsicContentSize: CGSize {
    guard bounds.width > 0 else {
      return CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
    let fittingSize = hostingController.sizeThatFits(
      in: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
    )
    return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fittingSize.height))
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.cornerRadius
    layer.rasterizationScale = traitCollection.displayScale
    if measuredWidth != bounds.width {
      measuredWidth = bounds.width
      invalidateIntrinsicContentSize()
    }
  }

  // iOS 13 remains supported, so observe traits with its available lifecycle API.
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  private let hostingController: UIHostingController<Content>
  private var measuredWidth: CGFloat = 0
}
#endif
