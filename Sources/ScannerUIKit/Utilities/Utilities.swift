//
//  Utilities.swift
//
//  Created by Sereivoan Yong on 1/24/24.
//

import UIKit

extension UIColor {

  func resolvedColorIfAvailable(with traitCollection: UITraitCollection) -> UIColor {
    if #available(iOS 13.0, *) {
      return resolvedColor(with: traitCollection)
    } else {
      return self
    }
  }
}
