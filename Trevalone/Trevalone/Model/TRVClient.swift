//
//  TRVClient.swift
//  Trevalone
//
//  Created by Igor Clemente on 25/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation

class TRVClient {
    
    private init() {}
    static func sharedInstance() -> TRVClient {
        struct Singleton {
            static let sharedInstance = TRVClient()
        }
        return Singleton.sharedInstance
    }
}
