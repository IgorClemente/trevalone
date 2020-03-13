//
//  CognitoIdentityPoolController.swift
//  Trevalone
//
//  Created by Igor Clemente on 17/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import AWSCognito
import AWSCognitoIdentityProvider

class CognitoIdentityPoolController {
    
    private let identityPoolRegion: AWSRegionType = TRVClient.Constants.AmazonIdentityPoolRegionType
    private let identityPoolID: String = TRVClient.Constants.AmazonIdentityPoolID
    private var identityProvider: AWSCognitoCredentialsProvider?
    private var serviceConfiguration: AWSServiceConfiguration?
    
    private var currentIdentityID: String?
    
    private init() {
        let identityManager = SocialIdentityManager.sharedInstance()
        let cognitoIdentityProvider = AWSCognitoCredentialsProvider(regionType: identityPoolRegion,
                                                                    identityPoolId: identityPoolID, identityProviderManager: identityManager)
        self.identityProvider = cognitoIdentityProvider
        let serviceConfiguration = AWSServiceConfiguration(region: self.identityPoolRegion, credentialsProvider: self.identityProvider)
        self.serviceConfiguration = serviceConfiguration
        
        AWSServiceManager.default()?.defaultServiceConfiguration = self.serviceConfiguration
    }
    
    public func getFederatedIdentityForFacebook(_ idToken: String, username: String, email: String?,_ completion: @escaping (Error?)->()) -> () {
        let identityManager: SocialIdentityManager = SocialIdentityManager.sharedInstance()
        identityManager.registerFacebookToken(idToken)
        
        let task = self.identityProvider?.getIdentityId()
        task?.continueWith(block: { (task) -> Any? in
            if let error = task.error {
                completion(error)
                return nil
            }
            
            guard let currentIdentityID = task.result as String? else { return nil }
            self.currentIdentityID = currentIdentityID
            
            let syncClient = AWSCognito.default()
            let dataSet = syncClient.openOrCreateDataset(TRVClient.Constants.FacebookDataSetName)
            
            dataSet.setString(username, forKey: TRVClient.Constants.AmazonUserIdentityAttributeName)
            if let emailAddress = email {
                dataSet.setString(emailAddress, forKey: TRVClient.Constants.AmazonUserIdentityAttributeEmailAddress)
            }
            
            let task = dataSet.synchronize()
            task?.continueWith(block: { (task) -> Any? in
                if let error = task.error {
                    completion(error)
                    return nil
                }
                completion(nil)
                return nil
            })
            return nil
        })
    }
    
    public func getFederatedIdentityForGoogle(_ idToken: String, username: String, email: String?,_ completion: @escaping (Error?)->()) -> () {
        let identityManager = SocialIdentityManager.sharedInstance()
        identityManager.registerGoogleToken(idToken)
        
        let task = self.identityProvider?.getIdentityId()
        task?.continueWith(block: { (task) -> Any? in
            if let error = task.error {
                completion(error)
                return nil
            }
            
            guard let currentIdentityID = task.result as String? else { return nil }
            self.currentIdentityID = currentIdentityID
            
            let syncClient = AWSCognito.default()
            let dataSet = syncClient.openOrCreateDataset(TRVClient.Constants.GoogleDataSetName)
            dataSet.setString(username, forKey: TRVClient.Constants.AmazonUserIdentityAttributeName)
            
            if let emailAddress = email {
                dataSet.setString(emailAddress, forKey: TRVClient.Constants.AmazonUserIdentityAttributeEmailAddress)
            }
            
            let task = dataSet.synchronize()
            task?.continueWith(block: { (task) -> Any? in
                if let error = task.error {
                    completion(error)
                    return nil
                }
                completion(nil)
                return nil
            })
            return nil
        })
    }
    
    public func getFederatedIdentityForAmazon(_ idToken: String, username: String, email: String?, userPoolID: String, userPoolRegion: String,
                                              _ completion: @escaping (Error?)->()) -> () {
        
        let key: String = TRVClient.Constants.AmazonUserPoolIdentityKeyName
        
        let identityManager: SocialIdentityManager = SocialIdentityManager.sharedInstance()
        identityManager.registerAmazonToken(key: key, token: idToken)
        
        let syncClient = AWSCognito.default()
        let dataSet = syncClient.openOrCreateDataset(TRVClient.Constants.AmazonUserPoolDataSetName)
        dataSet.setString(username, forKey: TRVClient.Constants.AmazonUserIdentityAttributeName)
        
        if let emailAddress = email {
            dataSet.setString(emailAddress, forKey: TRVClient.Constants.AmazonUserIdentityAttributeEmailAddress)
        }
        
        let task = dataSet.synchronize()
        task?.continueWith(block: { (task) -> Any? in
            if let error = task.error {
                completion(error)
                return nil
            }
            completion(nil)
            return nil
        })
    }
    
    static func sharedInstance() -> CognitoIdentityPoolController {
        struct Singleton {
            static let sharedInstance: CognitoIdentityPoolController = CognitoIdentityPoolController()
        }
        return Singleton.sharedInstance
    }
}
