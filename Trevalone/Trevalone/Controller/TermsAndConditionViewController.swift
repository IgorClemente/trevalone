//
//  TermsAndConditionViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 05/05/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import UIKit
import Spring

class TermsAndConditionViewController: UIViewController {
    
    @IBOutlet weak var layoutDirectionIndicatorArrowUp: UIImageView?
    @IBOutlet weak var mainLogoSpringImageView: SpringImageView?
    
    enum Segue : String {
        case SigninStoryboard = "SigninStoryboard"
        case SocialLoginStoryboard = "SocialLoginStoryboard"
        case SignupStoryboard = "SignupStoryboard"
        case TermsAndCondition = "TermsAndConditionStoryboard"
    }
    
    enum Storyboard : String {
        case SigninStoryboard = "SigninStoryboard"
        case SocialLoginStoryboard = "SocialLoginStoryboard"
        case SignupStoryboard = "SignupStoryboard"
        case TermsAndConditionStoryboard = "TermsAndConditionStoryboard"
    }
    
    enum SlideDirection {
        case Left
        case Right
        case Center
        case Up
    }
    
    enum ViewController {
        case SocialViewController
        case SignupViewController
        case SigninViewController
        case None
    }
    
    public var initialTransitionView: UIView? = nil
    public var viewControllerNamedType: ViewController = .None
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    var transitionDirection: SlideDirection = .Center
    
    var signinViewForController: UIView? = nil
    var signupViewForController: UIView? = nil
    var socialViewForController: UIView? = nil
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if initialTransitionView != nil {
            self.setupViewsTransition()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let initialTransitionView = self.initialTransitionView {
            self.view.frame = initialTransitionView.frame
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.directionIndicatorArrowImageWithEffect()
        self.shootMainLogoAnimate()
    }
    
    private func shootMainLogoAnimate() -> () {
        guard let mainLogoSpringImageView = self.mainLogoSpringImageView else { return }
        mainLogoSpringImageView.animation = "pop"
        mainLogoSpringImageView.duration = 1.5
        mainLogoSpringImageView.animate()
    }
    
    private func directionIndicatorArrowImageWithEffect() -> () {
        guard let directionIndicatorArrowUp = self.layoutDirectionIndicatorArrowUp else {
            return
        }
        
        UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
            directionIndicatorArrowUp.transform = CGAffineTransform(translationX: 0, y: 5)
        }) { (_) in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                directionIndicatorArrowUp.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)
        }
    }
    
    private func setupViewsTransition() -> () {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        switch viewControllerNamedType {
        case .SigninViewController:
            if let signinViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SigninStoryboard.rawValue) as? AccessLoginViewController {
                signinViewController.view.alpha = 0.0
                view.addSubview(signinViewController.view)
                self.signinViewForController = signinViewController.view
            }
        case .SocialViewController:
            if let socialViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SocialLoginStoryboard.rawValue) as? AccessSocialLoginViewController {
                socialViewController.view.alpha = 0.0
                view.addSubview(socialViewController.view)
                self.socialViewForController = socialViewController.view
            }
        case .SignupViewController:
            if let signupViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SignupStoryboard.rawValue) as? AccessSignupViewController {
                signupViewController.view.alpha = 0.0
                view.addSubview(signupViewController.view)
                self.signupViewForController = signupViewController.view
            }
        case .None: break
        }
    }
    
    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.transitionDirection = .Up
                
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y,
                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
            
                switch viewControllerNamedType {
                case .SigninViewController:
                    self.signinViewForController?.frame = CGRect(x: 0, y: -self.view.frame.height,
                                                              width: self.view.frame.size.width,
                                                              height: self.view.frame.size.height)
                    self.signinViewForController?.alpha = 1.0
                case .SocialViewController:
                    self.socialViewForController?.frame = CGRect(x: 0, y: -self.view.frame.height,
                                                              width: self.view.frame.size.width,
                                                              height: self.view.frame.size.height)
                    self.socialViewForController?.alpha = 1.0
                case .SignupViewController:
                    self.signupViewForController?.frame = CGRect(x: 0, y: -self.view.frame.height,
                                                              width: self.view.frame.size.width,
                                                              height: self.view.frame.size.height)
                    self.signupViewForController?.alpha = 1.0
                case .None: break
                }
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if transitionDirection == .Up {
                if touchPoint.y - initialTouchPoint.y > 250 {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        
                        switch self.viewControllerNamedType {
                        case .SigninViewController:
                            self.signinViewForController?.alpha = 0.0
                        case .SocialViewController:
                            self.socialViewForController?.alpha = 0.0
                        case .SignupViewController:
                            self.signupViewForController?.alpha = 0.0
                        case .None: break
                        }
                        self.transitionDirection = .Center
                    })
                }
            }
        }
    }
}
