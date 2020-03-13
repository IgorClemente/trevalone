//
//  GCDBox.swift
//  Trevalone
//
//  Created by Igor Clemente on 10/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation

func performUIMain(_ completion: @escaping ()->()) {
    DispatchQueue.main.async {
        completion()
    }
}
