//
//  ViewController.swift
//  Example
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit
import ScannerUIKit

final class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  @IBAction private func showQRScanner(_ sender: Any) {
    let viewController = ScannerViewController()
    viewController.title = "Scan QR"
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.modalPresentationStyle = .fullScreen
    navigationController.modalTransitionStyle = .crossDissolve
    present(navigationController, animated: true)
  }
}
