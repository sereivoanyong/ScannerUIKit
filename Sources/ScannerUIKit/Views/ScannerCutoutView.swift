//
//  ScannerCutoutView.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit

protocol ScannerCutoutViewDelegate: AnyObject {

  func cutoutRect(for scannerCutoutView: ScannerCutoutView) -> CGRect
}

final class ScannerCutoutView: UIView {

  weak var delegate: ScannerCutoutViewDelegate? {
    didSet {
      setNeedsDisplay()
    }
  }

  // MARK: Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    isOpaque = false
    backgroundColor = .black.withAlphaComponent(0.7)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Lifecycle

  override func draw(_ rect: CGRect) {
    UIColor.clear.setFill()
    UIBezierPath(roundedRect: delegate?.cutoutRect(for: self) ?? bounds, cornerRadius: 8).fill(with: .copy, alpha: 1)
  }
}
