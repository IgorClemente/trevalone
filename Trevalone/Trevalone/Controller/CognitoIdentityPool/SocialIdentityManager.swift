//
//  SocialIdentityManager.swift
//  Trevalone
//
//  Created by Igor Clemente on 17/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

class SocialIdentityManager : NSObject {
    
    private var loginDictionary: [String:String]
    
    private override init() {
        self.loginDictionary = [String:String]()
        super.init()
    }
    
    func registerFacebookToken(_ token: String) -> () {
        self.loginDictionary[AWSIdentityProviderFacebook] = token
    }
    
    func registerGoogleToken(_ token: String) -> () {
        self.loginDictionary[AWSIdentityProviderGoogle] = token
    }
    
    func registerAmazonToken(key: String, token: String) -> () {
        self.loginDictionary[key] = token
    }
    
    static func sharedInstance() -> SocialIdentityManager {
        struct Singleton {
            static let sharedInstance: SocialIdentityManager = SocialIdentityManager()
        }
        return Singleton.sharedInstance
    }
}

extension SocialIdentityManager : AWSIdentityProviderManager {
    
    func logins() -> AWSTask<NSDictionary> {
        return AWSTask(result: self.loginDictionary as NSDictionary)
    }
}
