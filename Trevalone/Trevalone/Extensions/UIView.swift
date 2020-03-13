//
//  UIView.swift
//  Trevalone
//
//  Created by Igor Clemente on 10/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func shade(_ radi: CGFloat) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize.zero
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
}
