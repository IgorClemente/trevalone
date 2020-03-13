//
//  BottomLineTextField.swift
//  Trevalone
//
//  Created by Igor Clemente on 4/4/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import UIKit


class BottomLineTextField: UITextField {

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets.init(top: 0, left: 2.0, bottom: 0, right: 5.0))
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets.init(top: 0, left: 2.0, bottom: 0, right: 5.0))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.clearsContextBeforeDrawing = true
        
        self.borderStyle = .none
        
        let defaultTint: UIColor = UIColor.white
        let defaultColor: UIColor = UIColor(red: 0.506, green: 0.506, blue: 0.506, alpha: 1)
        let defaultColorPlaceholder: UIColor = UIColor(red: 0.867, green: 0.867, blue: 0.867, alpha: 1)
        
        let borderWidth: CGFloat = 1.0
        
        let defaultFont: UIFont = UIFont(name: "Roboto-Medium", size: 15) ?? UIFont()
        
        if let placeholderText = self.placeholder {
            let attributesDictionary = [.foregroundColor : defaultColorPlaceholder, .font : defaultFont] as [NSAttributedString.Key : Any]
            let attributes: NSAttributedString = NSAttributedString(string: placeholderText, attributes: attributesDictionary)
            self.attributedPlaceholder = attributes
        }
        
        let border = CALayer()
        border.backgroundColor = defaultColor.cgColor
        border.frame = CGRect(x: 0, y: (frame.height - borderWidth), width: frame.size.width, height: frame.size.height)
        
        self.tintColor = defaultTint
        self.textColor = defaultTint
        
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}
