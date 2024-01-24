//
//  AVCaptureVideoPreviewView.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit
import AVFoundation

open class AVCaptureVideoPreviewView: UIView {

  open override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }

  open override var layer: AVCaptureVideoPreviewLayer {
    return unsafeDowncast(super.layer, to: AVCaptureVideoPreviewLayer.self)
  }

  open var session: AVCaptureSession? {
    get { return layer.session }
    set { layer.session = newValue }
  }

  open var connection: AVCaptureConnection? {
    return layer.connection
  }

  open var videoGravity: AVLayerVideoGravity {
    get { return layer.videoGravity }
    set { layer.videoGravity = newValue }
  }

  @available(iOS 13.0, *)
  open var isPreviewing: Bool {
    return layer.isPreviewing
  }
}
