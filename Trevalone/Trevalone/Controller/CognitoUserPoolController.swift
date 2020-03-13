//
//  CognitoUserPoolController.swift
//  Trevalone
//
//  Created by Igor Clemente on 09/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

class CognitoUserPoolController {
    
    private let userPoolRegion: AWSRegionType = TRVClient.Constants.AmazonUserPoolRegionType
    private let userPoolID: String = TRVClient.Constants.AmazonUserPoolID
    private let appClient: String = TRVClient.Constants.AmazonIdentityAppClientID
    private let appClientSecret: String = TRVClient.Constants.AmazonIdentityAppSecretID
    
    let currentUserPool: AWSCognitoIdentityUserPool?
    
    private init() {
        let serviceConfiguration = AWSServiceConfiguration(region: userPoolRegion, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: appClient,
                                                                            clientSecret: appClientSecret,
                                                                            poolId: userPoolID)
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration,
                                            userPoolConfiguration: userPoolConfiguration,
                                            forKey: TRVClient.Constants.AmazonUserPoolName)
        
        let userPool: AWSCognitoIdentityUserPool = AWSCognitoIdentityUserPool(forKey: TRVClient.Constants.AmazonUserPoolName)
        self.currentUserPool = userPool
        AWSDDLog.init().logLevel = .verbose
    }
    
    public func login(username: String, password: String, completion: @escaping (Error?)->Void) {
        let user = self.currentUserPool?.getUser(username)
        let task = user?.getSession(username, password: password, validationData: nil)
        task?.continueWith(block: { (task) -> Any? in
            if let loginError = task.error {
                completion(loginError)
                return nil
            }
            completion(nil)
            return nil
        })
    }
    
    public func signup(username: String, password: String, emailAddress: String, completion: @escaping (Error?,AWSCognitoIdentityUser?)->Void) {
        var attributes: [AWSCognitoIdentityUserAttributeType] = Array<AWSCognitoIdentityUserAttributeType>()
        let emailAttribute: AWSCognitoIdentityUserAttributeType = AWSCognitoIdentityUserAttributeType(name: "email", value: emailAddress)
        attributes.append(emailAttribute)
        
        let task = self.currentUserPool?.signUp(username, password: password, userAttributes: attributes, validationData: nil)
        task?.continueWith(block: { (task) -> Any? in
            if let signupError = task.error {
                completion(signupError,nil)
                return nil
            }
            
            guard let result = task.result else {
                let userInfo: [String:Any] = ["__type" : "Unknown Error","message" : "error occurred while registering."]
                let signupError: NSError = NSError(domain: "com.trevalone.Trevalone", code: 1000, userInfo: userInfo)
                completion(signupError,nil)
                return nil
            }
            
            completion(nil,result.user)
            return nil
        })
    }
    
    public func confirmSignup(user: AWSCognitoIdentityUser, confirmationCode: String, completion: @escaping (Error?)->Void) {
        let task = user.confirmSignUp(confirmationCode)
        task.continueWith { (task) -> Any? in
            if let error = task.error {
                completion(error)
                return nil
            }
            completion(nil)
            return nil
        }
    }
    
    public func resendConfirmationCode(user: AWSCognitoIdentityUser, completion: @escaping (Error?)->Void) {
        let task = user.resendConfirmationCode()
        task.continueWith { (task) -> Any? in
            if let resendConfirmationError = task.error {
                completion(resendConfirmationError)
                return nil
            }
            completion(nil)
            return nil
        }
    }
    
    public func getUserDetails(user: AWSCognitoIdentityUser, completion: @escaping (Error?,AWSCognitoIdentityUserGetDetailsResponse?)->Void) {
        let task = user.getDetails()
        task.continueWith { (task) -> Any? in
            if let error = task.error {
                completion(error,nil)
                return nil
            }
            completion(nil,task.result)
            return nil
        }
    }
    
    static func sharedInstance() -> CognitoUserPoolController {
        struct Singleton {
            static let sharedInstance = CognitoUserPoolController()
        }
        return Singleton.sharedInstance
    }
}
