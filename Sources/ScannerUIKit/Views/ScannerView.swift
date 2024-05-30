//
//  ScannerView.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit
import AVFoundation

final class ScannerView: AVCaptureVideoPreviewView {

  static let bottomControlHeight: CGFloat = 49 // tab bar height on portrait

  private let cutoutView: ScannerCutoutView = .init()

  // MARK: Private AVFoundation

  let device: AVCaptureDevice
  let deviceInput: AVCaptureDeviceInput

  weak var viewOfInterest: UIView?

  private var torchButton: UIButton!
  private var torchObservations: [NSKeyValueObservation] = []

  // MARK: Init

  init(frame: CGRect, device: AVCaptureDevice, deviceInput: AVCaptureDeviceInput) {
    self.device = device
    self.deviceInput = deviceInput
    super.init(frame: frame)

    videoGravity = .resizeAspectFill

    cutoutView.frame = bounds
    cutoutView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cutoutView.delegate = self
    addSubview(cutoutView)

    reloadTorchButton()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public

  func reloadTorchButton() {
    if device.hasTorch {
      guard torchButton == nil else { return }
      torchButton = UIButton(type: .system)
      torchButton.tintColor = .white
      torchButton.addTarget(self, action: #selector(toggleTorch(_:)), for: .touchUpInside)
      let reloadTorchImageHandler: (AVCaptureDevice) -> Void = { [unowned self] device in
        torchButton.setImage(makeTorchImage(for: device), for: .normal)
        torchButton.isEnabled = device.isTorchAvailable
      }
      torchObservations = [
        device.observe(\.isTorchAvailable, options: .new) { device, _ in
          reloadTorchImageHandler(device)
        },
        device.observe(\.isTorchActive, options: .new) { device, _ in
          reloadTorchImageHandler(device)
        }
      ]
      reloadTorchImageHandler(device)
      addSubview(torchButton)

      torchButton.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        torchButton.widthAnchor.constraint(equalToConstant: Self.bottomControlHeight),
        torchButton.heightAnchor.constraint(equalToConstant: Self.bottomControlHeight),
        torchButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
        layoutMarginsGuide.bottomAnchor.constraint(equalTo: torchButton.bottomAnchor)
      ])
    } else {
      torchButton?.removeFromSuperview()
      torchButton = nil
    }
  }

  private func makeTorchImage(for device: AVCaptureDevice) -> UIImage? {
    if device.isTorchAvailable {
      if device.isTorchActive {
        return UIImage(systemName: "flashlight.on.fill")
      } else {
        return UIImage(systemName: "flashlight.off.fill")
      }
    } else {
      return UIImage(systemName: "flashlight.slash")
    }
  }

  @objc private func toggleTorch(_ sender: UIButton) {
    let targetTorchMode: AVCaptureDevice.TorchMode = device.torchMode == .on ? .off : .on
    guard device.isTorchModeSupported(targetTorchMode) else { return }
    do {
      try device.lockForConfiguration()
      device.torchMode = targetTorchMode
      device.unlockForConfiguration()
    } catch {
      print(error)
    }
  }
}

// MARK: - ScannerCutoutViewDelegate

extension ScannerView: ScannerCutoutViewDelegate {

  func cutoutRect(for scannerCutoutView: ScannerCutoutView) -> CGRect {
    if let viewOfInterest {
      return viewOfInterest.convert(viewOfInterest.bounds, to: self)
    }
    return scannerCutoutView.bounds
  }
}
