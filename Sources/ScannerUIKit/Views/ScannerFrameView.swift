//
//  ScannerFrameView.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit

extension ScannerFrameView {

  public struct Configuration {

    public var length: CGFloat
    public var color: UIColor
    public var radius: CGFloat
    public var thickness: CGFloat

    public static var `default`: Self {
      return Self.init(length: 40, color: .white, radius: 8 + 8/2, thickness: 8)
    }
  }
}

open class ScannerFrameView: UIView {

  open var configuration: Configuration = .default {
    didSet {
      setNeedsDisplay()
    }
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    assert(!clipsToBounds)
    isOpaque = false
    assert(clearsContextBeforeDrawing)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open override func draw(_ rect: CGRect) {
    let halfThickness = configuration.thickness / 2
    let rect = bounds.insetBy(dx: halfThickness, dy: halfThickness)
    let path = UIBezierPath()

    // Top left
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + configuration.length + configuration.radius))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + configuration.radius))
    path.addArc(withCenter: CGPoint(x: rect.minX + configuration.radius, y: rect.minY + configuration.radius), radius: configuration.radius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)
    path.addLine(to: CGPoint(x: rect.minX + configuration.length + configuration.radius, y: rect.minY))

    // Top right
    path.move(to: CGPoint(x: rect.maxX, y: rect.minY + configuration.length + configuration.radius))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + configuration.radius))
    path.addArc(withCenter: CGPoint(x: rect.maxX - configuration.radius, y: rect.minY + configuration.radius), radius: configuration.radius, startAngle: 0, endAngle: .pi * 3 / 2, clockwise: false)
    path.addLine(to: CGPoint(x: rect.maxX - configuration.length - configuration.radius, y: rect.minY))

    // Bottom left
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY - configuration.length - configuration.radius))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - configuration.radius))
    path.addArc(withCenter: CGPoint(x: rect.minX + configuration.radius, y: rect.maxY - configuration.radius), radius: configuration.radius, startAngle: .pi, endAngle: .pi / 2, clockwise: false)
    path.addLine(to: CGPoint(x: rect.minX + configuration.length + configuration.radius, y: rect.maxY))

    // Bottom right
    path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - configuration.length - configuration.radius))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - configuration.radius))
    path.addArc(withCenter: CGPoint(x: rect.maxX - configuration.radius, y: rect.maxY - configuration.radius), radius: configuration.radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
    path.addLine(to: CGPoint(x: rect.maxX - configuration.length - configuration.radius, y: rect.maxY))

    path.lineWidth = configuration.thickness

    configuration.color.setStroke()
    path.stroke()
  }
}
