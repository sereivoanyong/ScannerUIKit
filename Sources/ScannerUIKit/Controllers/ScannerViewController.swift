//
//  ScannerViewController.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit
import AVFoundation
import EmptyUIKit

public enum ScannerError: Error {

  case accessRestricted
  case accessDenied
  case noVideoDevice
  case cannotCapture(Error)
}

open class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, EmptyViewStateProviding, EmptyViewDataSource {

  public let sessionQueue: DispatchQueue = .global(qos: .userInteractive)

  public let session: AVCaptureSession = AVCaptureSession()

  open private(set) var isSessionRunningOnMain: Bool = false

  private var scannerView: ScannerView!

  open private(set) var scannerFrameConstraints: [NSLayoutConstraint] = []

  open var scannerFrameInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: -8, leading: -8, bottom: -8, trailing: -8)

  open private(set) var scannerFrameView: ScannerFrameView!

  open private(set) var scannerInterestView: UIView!

  open var supportedMetadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr]

  open private(set) var currentError: ScannerError? {
    didSet {
      if currentError != nil {
        emptyView.reload()
      } else {
        emptyViewIfLoaded?.removeFromSuperview()
        emptyViewIfLoaded = nil
      }
    }
  }

  public let contentLayoutGuide = UILayoutGuide()

  private var emptyViewIfLoaded: EmptyView?
  open var emptyView: EmptyView {
    if let emptyViewIfLoaded {
      return emptyViewIfLoaded
    }
    let emptyView = EmptyView()
    emptyView.stateProvider = self
    emptyView.dataSource = self
    emptyViewIfLoaded = emptyView
    view.addSubview(emptyView)

    emptyView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: contentLayoutGuide.centerXAnchor),
      emptyView.centerYAnchor.constraint(equalTo: contentLayoutGuide.centerYAnchor),
    ])
    return emptyView
  }

  // MARK: Init / Deinit

  public override init(nibName: String? = nil, bundle: Bundle? = nil) {
    super.init(nibName: nibName, bundle: bundle)

    if #available(iOS 13.0, *) {
      overrideUserInterfaceStyle = .dark
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    if type(of: self) == ScannerViewController.self {
      print("\(Self.self) deinit")
    }
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 13.0, *) {
      view.backgroundColor = .systemBackground
    } else {
      view.backgroundColor = .black
    }

    do {
      view.addLayoutGuide(contentLayoutGuide)

      NSLayoutConstraint.activate([
        contentLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        contentLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: ScannerView.bottomControlHeight),
        view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
      ])
    }

    configure()
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    configure(requestAccessIfNeeded: true)
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    startOutputtingMetadataObjects()
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    stopOutputtingMetadataObjects()
  }

  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    stopRunningSession()
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let scannerView, let connection = scannerView.layer.connection, connection.isVideoOrientationSupported {
      switch UIDevice.current.orientation {
      case .portrait:
        connection.videoOrientation = .portrait
      case .landscapeRight:
        connection.videoOrientation = .landscapeLeft
      case .landscapeLeft:
        connection.videoOrientation = .landscapeRight
      case .portraitUpsideDown:
        connection.videoOrientation = .portraitUpsideDown
      default:
        connection.videoOrientation = .portrait
      }
    }
  }

  open override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    if let parent = parent as? UINavigationController, parent.viewControllers.first === self {
      let dismissButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismiss(_:)))
      dismissButtonItem.tintColor = .white
      navigationItem.rightBarButtonItem = dismissButtonItem
    }
  }

  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: Private

  private func configure(requestAccessIfNeeded: Bool = false) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      if requestAccessIfNeeded {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
          guard let self else { return }
          DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if isGranted {
              currentError = nil
              configureScannerViewIfNeeded()
              startRunningSession()
            } else {
              configure()
            }
          }
        }
      }

    case .restricted:
      currentError = .accessRestricted

    case .denied:
      currentError = .accessDenied

    case .authorized:
      configureScannerViewIfNeeded()
      startRunningSession()

    @unknown default:
      break
    }
  }

  private func configureScannerViewIfNeeded() {
    guard scannerView == nil else { return }

    let result = configureSession()
    switch result {
    case .success((let device, let deviceInput, let metadataOutput)):
      do {
        scannerInterestView = UIView()
        view.addSubview(scannerInterestView)

        scannerInterestView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          scannerInterestView.widthAnchor.constraint(equalTo: contentLayoutGuide.widthAnchor, multiplier: 0.7),
          scannerInterestView.widthAnchor.constraint(equalTo: scannerInterestView.heightAnchor),
          scannerInterestView.centerXAnchor.constraint(equalTo: contentLayoutGuide.centerXAnchor),
          scannerInterestView.centerYAnchor.constraint(equalTo: contentLayoutGuide.centerYAnchor)
        ])
      }

      do {
        scannerFrameView = ScannerFrameView()
        view.insertSubview(scannerFrameView, belowSubview: scannerInterestView)

        scannerFrameView.translatesAutoresizingMaskIntoConstraints = false
        scannerFrameConstraints = [
          scannerFrameView.topAnchor.constraint(equalTo: scannerInterestView.topAnchor, constant: scannerFrameInsets.top),
          scannerFrameView.leadingAnchor.constraint(equalTo: scannerInterestView.leadingAnchor, constant: scannerFrameInsets.leading),
          scannerInterestView.bottomAnchor.constraint(equalTo: scannerFrameView.bottomAnchor, constant: scannerFrameInsets.bottom),
          scannerInterestView.trailingAnchor.constraint(equalTo: scannerFrameView.trailingAnchor, constant: scannerFrameInsets.trailing)
        ]
        NSLayoutConstraint.activate(scannerFrameConstraints)
      }

      do {
        scannerView = ScannerView(frame: view.bounds, device: device, deviceInput: deviceInput, metadataOutput: metadataOutput)
        scannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scannerView.session = session
        scannerView.viewOfInterest = scannerInterestView
        view.insertSubview(scannerView, at: 0)
      }

    case .failure(let error):
      currentError = error
    }
  }

  private func configureSession() -> Result<(AVCaptureDevice, AVCaptureDeviceInput, AVCaptureMetadataOutput), ScannerError> {
    guard let device = AVCaptureDevice.default(for: .video) else {
      return .failure(.noVideoDevice)
    }

    session.beginConfiguration()

    // Input
    let deviceInput: AVCaptureDeviceInput
    do {
      deviceInput = try AVCaptureDeviceInput(device: device)
    } catch {
      session.commitConfiguration()
      return .failure(.cannotCapture(error))
    }
    if session.canAddInput(deviceInput) {
      session.addInput(deviceInput)
    }

    // Output
    let metadataOutput = AVCaptureMetadataOutput()
    if session.canAddOutput(metadataOutput) {
      session.addOutput(metadataOutput)
    }
    metadataOutput.metadataObjectTypes = supportedMetadataObjectTypes
    metadataOutput.setMetadataObjectsDelegate(self, queue: .main)

    session.commitConfiguration()
    return .success((device, deviceInput, metadataOutput))
  }

  // MARK: Actions

  open func startRunningSession() {
    isSessionRunningOnMain = true
    sessionQueue.async { [weak session] in
      session?.startRunning()
    }
  }

  open func stopRunningSession() {
    isSessionRunningOnMain = false
    sessionQueue.async { [weak session] in
      session?.stopRunning()
    }
  }

  open func startOutputtingMetadataObjects() {
    guard let scannerView else { return }
    scannerView.metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
  }

  open func stopOutputtingMetadataObjects() {
    guard let scannerView else { return }
    scannerView.metadataOutput.setMetadataObjectsDelegate(nil, queue: nil)
  }

  open func didOutput(_ metadataObject: AVMetadataObject) {
  }

  @objc private func dismiss(_ sender: UIBarButtonItem) {
    dismiss(animated: true)
  }

  @objc private func didTapEmptyViewButton(_ sender: UIButton) {
    guard let currentError else { return }
    switch currentError {
    case .accessRestricted, .accessDenied:
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        return
      }
      UIApplication.shared.open(url)

    case .noVideoDevice, .cannotCapture:
      break
    }
  }

  // MARK: - AVCaptureMetadataOutputObjectsDelegate AVCaptureMetadataOutputObjectsDelegate {

  open func metadataOutput(_ metadataOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard
      metadataOutput.metadataObjectsDelegate != nil,
      let metadataObject = metadataObjects.first,
      let metadataObject = scannerView.layer.transformedMetadataObject(for: metadataObject)
    else {
      return
    }

    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if isSessionRunningOnMain {
      stopRunningSession()
      didOutput(metadataObject)
    }
  }

  // MARK: EmptyViewStateProviding

  open func state(for emptyView: EmptyView) -> EmptyView.State? {
    if let currentError {
      return .error(currentError)
    }
    return nil
  }

  // MARK: EmptyViewDataSource

  open func emptyView(_ emptyView: EmptyView, configureContentFor state: EmptyView.State) {
    switch state {
    case .empty:
      break
    case .error(let error):
      if !emptyView.button.allTargets.contains(self) {
        emptyView.button.addTarget(self, action: #selector(didTapEmptyViewButton(_:)), for: .touchUpInside)
      }
      guard let error = error as? ScannerError else { return }
      switch error {
      case .accessRestricted:
        emptyView.title = "Access Restricted"
        emptyView.button.setTitle("Open Settings", for: .normal)
      case .accessDenied:
        emptyView.title = "Access Denied"
        emptyView.button.setTitle("Open Settings", for: .normal)
      case .noVideoDevice:
        emptyView.title = "No Camera"
      case .cannotCapture(let error):
        emptyView.title = "Camera Not Available"
        emptyView.message = error.localizedDescription
      }
    }
  }
}
