//
//  TRVConstants.swift
//  Trevalone
//
//  Created by Igor Clemente on 22/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

extension TRVClient {
    
    struct Constants {
        static let GoogleClientID = "754529459638-an04cnt4l5g99f3jk7uqlei8vtrs868j.apps.googleusercontent.com"
        
        static let AmazonUserPoolID = "us-east-1_31pukQkCQ"
        static let AmazonUserPoolRegionType: AWSRegionType = .USEast1
        static let AmazonUserPoolRegionTypeString = "us-east-1"
        static let AmazonUserPoolName = "TrevaloneIOSApplication"
        
        static let AmazonIdentityPoolRegionType: AWSRegionType = .USEast1
        static let AmazonIdentityPoolRegionTypeString = "useast1"
        static let AmazonIdentityPoolID = "us-east-1:6f3396bc-9361-4afb-a1f6-2cb010f578e4"
        static let AmazonIdentityAppClientID = "28ddvp71cl359n6tgtlujl1kqt"
        static let AmazonIdentityAppSecretID = "dd34frp6fagnu9rhmg0hrg3llrm6hd7f7b7mde1jc7ob6lbuivj"
        
        static let GoogleDataSetName = "googleUserData"
        static let FacebookDataSetName = "facebookUserData"
        static let AmazonUserPoolDataSetName = "amazonUserData"
        
        static let AmazonUserPoolIdentityKeyName = "cognito-idp.\(AmazonUserPoolRegionTypeString).amazonaws.com/\(AmazonUserPoolID)"
        
        static let AmazonUserIdentityAttributeName = "username"
        static let AmazonUserIdentityAttributeEmailAddress = "email"
    }
}


