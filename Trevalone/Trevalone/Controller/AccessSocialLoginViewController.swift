//
//  AccessSocialLoginViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 17/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import UIKit
import Spring
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit

class AccessSocialLoginViewController : UIViewController {
    
    @IBOutlet weak var accessSocialFacebookButton: UIButton?
    @IBOutlet weak var accessSocialGoogleButton: UIButton?
    
    @IBOutlet weak var layoutDirectionIndicatorArrowRight: UIImageView?
    @IBOutlet weak var layoutDirectionIndicatorArrowDown: UIImageView?
    
    @IBOutlet weak var mainLogoSpringImageView: SpringImageView?
    
    private var facebookLoginManager: FBSDKLoginManager?
    
    private var termsAndConditionsViewController: UIView? = nil
    private var homeViewController: UIView? = nil
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    private var transitionDirection: SlideDirection = .Center
    
    public var initialTransitionView: UIView? = nil {
        didSet {
            if let initialTransitionView = self.initialTransitionView {
                self.view.frame = initialTransitionView.frame
            }
        }
    }
    
    public var layoutDirectionIndicatorArrowRightView: UIImageView? {
        guard let layoutDirectionIndicatorArrowRight = self.layoutDirectionIndicatorArrowRight else { return nil }
        return layoutDirectionIndicatorArrowRight
    }
    
    enum Segue : String {
        case HomeStoryboard = "HomeStoryboard"
        case SocialLoginStoryboard = "SocialLoginStoryboard"
        case SignupStoryboard = "SignupStoryboard"
        case TermsAndConditionStoryboard = "TermsAndConditionsStoryboard"
    }
    
    enum Storyboard : String {
        case SigninStoryboard = "SigninStoryboard"
        case SocialLoginStoryboard = "SocialLoginStoryboard"
        case SignupStoryboard = "SignupStoryboard"
        case TermsAndConditionStoryboard = "TermsAndConditionStoryboard"
    }
    
    enum ErrorType : String {
        case UNKNOWN
        case TOKEN_NOT_FOUND = "100"
        case PARSE_TYPE = "202"
        case FACEBOOK_PROCESS_CANCELLED = "302"
        case GOOGLE_PROCESS_CANCELLED = "-5"
    }
    
    enum SlideDirection {
        case Left
        case Right
        case Center
        case Up
    }
    
    private var combinationOfErrorCodeAndMessage: [ErrorType:[String:String]]? {
        return [
            .UNKNOWN : ["title":"Ops, um erro aconteceu","message":"Desculpe-me, aconteceu um erro ao tentar fazer login. Por favor, tente novamente."],
            .FACEBOOK_PROCESS_CANCELLED : ["title":"Facebook Login","message":"O processo de login com Facebook foi cancelado."],
            .GOOGLE_PROCESS_CANCELLED : ["title":"Google Login","message":"O processo de login com Google foi cancelado."]
        ]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if initialTransitionView != nil {
            self.socialSignInSetup()
            self.setupViewsTransition()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if initialTransitionView != nil {
            self.presentInitialViewControllerWithTransition()
            self.shootMainLogoAnimate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.directionIndicatorArrowImageWithEffect()
    }
    
    private func enableInterface(_ enabled: Bool) -> () {
        guard let accessSocialFacebookButton = self.accessSocialFacebookButton,
              let accessSocialGoogleButton = self.accessSocialGoogleButton else {
            return
        }
        
        accessSocialGoogleButton.isEnabled = enabled
        accessSocialFacebookButton.isEnabled = enabled
        accessSocialGoogleButton.alpha = !enabled ? 0.5 : 1.0
        accessSocialFacebookButton.alpha = !enabled ? 0.5 : 1.0
    }
    
    private func presentInitialViewControllerWithTransition() -> () {
        if initialTransitionView != nil {
            self.view.alpha = 0.0
            UIView.animate(withDuration: 0.4, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: .curveEaseIn, animations: {
                self.view.alpha = 1.0
            }) { (success) in
                if success {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                }
            }
        }
    }
    
    private func setupViewsTransition() -> () {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let termsAndConditionViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.TermsAndConditionStoryboard.rawValue) as? TermsAndConditionViewController {
            termsAndConditionViewController.view.alpha = 0.0
            view.addSubview(termsAndConditionViewController.view)
            self.termsAndConditionsViewController = termsAndConditionViewController.view
        }
        
        if let homeViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SigninStoryboard.rawValue) as? AccessLoginViewController {
            homeViewController.view.alpha = 0.0
            view.addSubview(homeViewController.view)
            self.homeViewController = homeViewController.view
        }
    }
    
    private func socialSignInSetup() -> () {
        let facebookLoginManager = FBSDKLoginManager()
        self.facebookLoginManager = facebookLoginManager
        
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.shouldFetchBasicProfile = true
    }
    
    private func displaySuccessMessage() -> () {
        self.performSegue(withIdentifier: Segue.HomeStoryboard.rawValue, sender: nil)
    }
    
    private func facebookLoginAction() -> () {
        self.enableInterface(false)
        self.facebookLoginManager?.logIn(withReadPermissions: ["public_profile","email"], from: self, handler: { (result, error) in
            if error != nil {
                guard let error = error as NSError? else { return }
                self.displayErrorMessage(for: error, nil)
                self.enableInterface(true)
                return
            }
            
            guard let result = result else {
                self.enableInterface(true)
                return
            }
            
            if result.isCancelled {
                let userInfo: [String : Any] = ["__type" : "Facebook login process", "message" : "Facebook login process cancelled"]
                let error: NSError = NSError(domain: "com.trevalone.Trevalone", code: 302, userInfo: userInfo)
                self.displayErrorMessage(for: error, nil)
                self.enableInterface(true)
                return
            }
            
            guard let idToken = FBSDKAccessToken.current()?.tokenString else {
                let userInfo: [String : Any] = ["__type" : "Facebook login ID token", "message" : "Could not find ID token"]
                let error: NSError = NSError(domain: "com.trevalone.Trevalone", code: 100, userInfo: userInfo)
                self.displayErrorMessage(for: error, nil)
                self.enableInterface(true)
                return
            }
            
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "name,email"])
            graphRequest?.start(completionHandler: { (connection, result, error) in
                if let error = error {
                    self.displayErrorMessage(for: error as NSError, nil)
                    self.enableInterface(true)
                    return
                }
                
                guard let result = result as? [String : AnyHashable] else {
                    let userInfo: [String : Any] = ["__type" : "Facebook login graph request result", "message" : "Result is not of the correct type"]
                    let error: NSError = NSError(domain: "com.trevalone.Trevalone", code: 202, userInfo: userInfo)
                    self.displayErrorMessage(for: error, nil)
                    self.enableInterface(true)
                    return
                }
                
                if let username = result["name"] as? String,
                   let emailAddress = result["email"] as? String {
                    let cognitoIdentityPoolController = CognitoIdentityPoolController.sharedInstance()
                    cognitoIdentityPoolController.getFederatedIdentityForFacebook(idToken, username: username, email: emailAddress,
                    { (error) in
                        if let error = error {
                            self.displayErrorMessage(for: error as NSError, nil)
                            self.enableInterface(true)
                            return
                        }
                        
                        performUIMain {
                            self.displaySuccessMessage()
                            self.enableInterface(true)
                        }
                    })
                }
            })
        })
    }
    
    private func googleLoginAction() -> () {
        self.enableInterface(false)
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    private func redefineViewFrame(less viewForSlideDirection: SlideDirection) -> () {
        switch viewForSlideDirection {
        case .Left:
            self.termsAndConditionsViewController?.alpha = 0.0
        case .Right:
            self.termsAndConditionsViewController?.alpha = 0.0
        case .Up: break
        case .Center: break
        }
    }
    
    private func shootMainLogoAnimate() -> () {
        guard let mainLogoSpringImageView = self.mainLogoSpringImageView else { return }
        mainLogoSpringImageView.animation = "pop"
        mainLogoSpringImageView.duration = 1.5
        mainLogoSpringImageView.animate()
    }
    
    private func directionIndicatorArrowImageWithEffect() -> () {
        guard let directionIndicatorArrowRight = self.layoutDirectionIndicatorArrowRight,
              let directionIndicatorArrowDown = self.layoutDirectionIndicatorArrowDown else {
            return
        }
        
        UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
            directionIndicatorArrowRight.transform = CGAffineTransform(translationX: 5, y: 0)
            directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 5)
        }) { (_) in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                directionIndicatorArrowRight.transform = CGAffineTransform(translationX: 0, y: 0)
                directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)
        }
    }
    
    private func displayErrorMessage(for error: NSError, _ completion: (()->Void)?) {
        let errorCode = error.code
        let errorCodeString = String(errorCode)
        print("DEBUG - ERROR MESSAGE: \(error)")
        if let dictionaryResult = handlerErrorMessage(forError: errorCodeString) {
            if let titleForAlert = dictionaryResult["title"],
               let messageForAlert = dictionaryResult["message"] {
                self.showAlertWith(titleForAlert, messageForAlert, in: self, completion)
            }
        }
    }
    
    private func handlerErrorMessage(forError code: String) -> [String:String]? {
        guard let combinationOfErrorCodeAndMessage = self.combinationOfErrorCodeAndMessage else { return nil }
        
        if let errorType = ErrorType(rawValue: code) {
            if let errorDictionary = combinationOfErrorCodeAndMessage[errorType] {
                return errorDictionary
            }
        } else if let unknownErrorDictionary = combinationOfErrorCodeAndMessage[.UNKNOWN] {
            return unknownErrorDictionary
        }
        return nil
    }
    
    @IBAction func tapToFacebookLogin() -> () {
        self.facebookLoginAction()
    }
    
    @IBAction func tapToGoogleLogin() -> () {
        self.googleLoginAction()
    }
    
    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.x - initialTouchPoint.x < -20 {
                self.transitionDirection = .Left
                self.view.frame = CGRect(x: touchPoint.x - initialTouchPoint.x, y: 0,
                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
            
                self.homeViewController?.frame = CGRect(x: self.view.frame.width, y: 0,
                                                        width: self.view.frame.size.width, height: self.view.frame.size.height)
                self.homeViewController?.alpha = 1.0
                self.redefineViewFrame(less: .Left)
            } else if touchPoint.y - initialTouchPoint.y < -20 {
                self.transitionDirection = .Up
                
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y,
                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                self.termsAndConditionsViewController?.frame = CGRect(x: 0, y: self.view.frame.height,
                                                                      width: self.view.frame.size.width, height: self.view.frame.size.height)
                self.termsAndConditionsViewController?.alpha = 1.0
                self.redefineViewFrame(less: .Up)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            
            let rightToLeftLimit = ((self.view.frame.size.width / 2) - 60)
            
            if transitionDirection == .Left {
                if ((touchPoint.x - initialTouchPoint.x) * -1) > rightToLeftLimit {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.homeViewController?.alpha = 0.0
                        self.transitionDirection = .Center
                    })
                }
            } else if transitionDirection == .Up {
                if (touchPoint.y - initialTouchPoint.y) < -250 {
                    self.performSegue(withIdentifier: Segue.TermsAndConditionStoryboard.rawValue, sender: self.termsAndConditionsViewController)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.termsAndConditionsViewController?.alpha = 0.0
                        self.transitionDirection = .Center
                    })
                }
            }
        }
    }
}

extension AccessSocialLoginViewController : GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            self.displayErrorMessage(for: error as NSError, nil)
            self.enableInterface(true)
            return
        }
        
        let idToken: String = user.authentication.idToken
        let username: String = user.profile.name
        let email: String = user.profile.email
        
        let cognitoIdentityPoolController = CognitoIdentityPoolController.sharedInstance()
        cognitoIdentityPoolController.getFederatedIdentityForGoogle(idToken, username: username, email: email) { (error) in
            if let error = error {
                self.displayErrorMessage(for: error as NSError, nil)
                self.enableInterface(true)
                return
            }
            
            performUIMain {
                self.displaySuccessMessage()
                self.enableInterface(true)
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //
    }
}

extension AccessSocialLoginViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case Segue.TermsAndConditionStoryboard.rawValue:
            guard let destination = segue.destination as? TermsAndConditionViewController,
                  let sender = sender as? UIView else {
                return
            }
            destination.initialTransitionView = sender
            destination.viewControllerNamedType = .SocialViewController
        default: break
        }
    }
}

