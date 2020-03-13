//
//  Rounder.swift
//  Trevalone
//
//  Created by Igor Clemente on 4/3/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class Rounder : UIView {
    @IBInspectable var shadow: Bool = false
    @IBInspectable var radi: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = radi
            layer.masksToBounds = true
        }
    }
}

@IBDesignable
class RounderButton : UIButton {
    @IBInspectable var shadow: Bool = false
    @IBInspectable var radi: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = radi
            layer.masksToBounds = true
        }
    }
}
