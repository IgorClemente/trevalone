//
//  AccessLoginViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 10/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import UIKit
import GoogleSignIn
import Spring

class AccessLoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    
    @IBOutlet weak var trevalonerAccountLoginButton: UIButton?
    
    @IBOutlet weak var backgroundImageVisualEffectView: UIVisualEffectView?
    @IBOutlet weak var backgroundImageView: UIImageView?
    
    @IBOutlet weak var layoutDirectionIndicatorArrowLeft: UIImageView?
    @IBOutlet weak var layoutDirectionIndicatorArrowRight: UIImageView?
    @IBOutlet weak var layoutDirectionIndicatorArrowDown: UIImageView?
    
    @IBOutlet weak var mainLogoSpringImageView: SpringImageView?
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    private var viewControllerTransitionDirection: SlideDirection = .Center
    
    private var termsAndConditionViewForController: UIView? = nil
    private var signupViewForController: UIView? = nil
    private var socialViewForController: UIView? = nil
    
    private var socialArrowViewForController: UIImageView? = nil
    
    private var keyboardModeVisible: Bool = false
    private var editingFieldMode: Bool = false
    
    enum ErrorType : String {
    case UNKNOWN
    case REQUIRED
    case USERNOTFOUND = "34"
    case INCORRECT = "20"
    case PATTERN = "25"
    }
    
    enum Segue : String {
    case HomeStoryboard = "HomeStoryboard"
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
    
    private var combinationOfErrorCodeAndMessage: [ErrorType:[String:String]]? {
        return [
            .UNKNOWN : ["title":"Ops, um erro aconteceu", "message":"Aconteceu um erro ao tentar fazer login. Tente novamente."],
            .USERNOTFOUND : ["title":"Usuário não encontrado", "message":"Não conseguimos te identificar. Por favor, verifique seus dados e tente novamente."],
            .INCORRECT : ["title":"Login ou Senha incorretos", "message":"Verificamos seu cadastro e notamos que voce digitou seu Login ou sua senha incorretamente. Por favor, verifique seus dados e tente novamente."],
            .PATTERN : ["title":"Algo está errado", "message":"Notei que voce digitou seu endereço de E-mail no padrão incorreto. Tente novamente, desta vez digitando-o desta nessa forma: example@example.com ou example@example.com.br"],
            .REQUIRED: ["title":"Ei, campo vázio", "message":"Voce esqueceu de preencher os campos. Coloque suas informações no campo correto e tente novamente."]
        ]
    }
    
    private var allFieldsMapped: [UITextField:UITextField?]? {
        guard let usernameTextField = self.usernameTextField,
              let passwordTextField = self.passwordTextField else {
            return nil
        }
        
        return [usernameTextField : passwordTextField,
                passwordTextField : nil]
    }
    
    private var usernameText: String? {
        guard let usernameTextField = self.usernameTextField else { return nil }
        return usernameTextField.text
    }
    
    private var passwordText: String? {
        guard let passwordTextField = self.passwordTextField else { return nil }
        return passwordTextField.text
    }
    
    private var transitionLimitValue: CGFloat = 0.0 {
        didSet {
            print("LIMIT: \(self.transitionLimitValue)")
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.enableInterface(false)
        self.setupViewsForTransition()
        self.setupSwipeGestures()
        self.setupBackgroundImageWithEffect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.shootMainLogoAnimate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.directionIndicatorArrowImageWithEffect()
        self.setupOnKeyboardShown()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.clearAllFields()
    }
    
    private func displayErrorMessage(for errorType: ErrorType,and error: NSError, _ completion: (()->Void)?) {
        let errorCode = error.code
        let errorCodeString = String(errorCode)
        
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
    
    private func displaySuccessMessage() -> () {
        self.performSegue(withIdentifier: Segue.HomeStoryboard.rawValue, sender: nil)
    }
    
    private func hideKeyboard() -> Void {
        guard let usernameTextField = self.usernameTextField,
              let passwordTextField = self.passwordTextField else {
            return
        }
        
        if usernameTextField.isFirstResponder || passwordTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
            passwordTextField.resignFirstResponder()
        }
    }
    
    private func allFieldsFilledOut() -> Bool {
        guard let usernameText = self.usernameText,
              let passwordText = self.passwordText else {
            return false
        }
        
        if usernameText.count > 0 && passwordText.count > 0 {
            return true
        }
        return false
    }
    
    private func enableInterface(_ enabled: Bool) -> () {
        guard let trevalonerAccountLoginButton = self.trevalonerAccountLoginButton else { return }
        trevalonerAccountLoginButton.isEnabled = enabled
        trevalonerAccountLoginButton.alpha = enabled ? 1.0 : 0.5
    }
    
    private func setupSwipeGestures() -> () {
        let swipeTopGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeTopGestureAction(_:)))
        swipeTopGesture.direction = .down
        self.view.addGestureRecognizer(swipeTopGesture)
    }
    
    private func setupOnKeyboardShown() -> () {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupDisableOnkeyboardShown() -> () {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupViewsForTransition() -> () {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if self.termsAndConditionViewForController == nil {
            if let termsAndConditionViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.TermsAndConditionStoryboard.rawValue) as? TermsAndConditionViewController {
                termsAndConditionViewController.view.alpha = 0.0
                view.addSubview(termsAndConditionViewController.view)
                self.termsAndConditionViewForController = termsAndConditionViewController.view
            }
        }
        
        if self.signupViewForController == nil {
            if let signupViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SignupStoryboard.rawValue) as? AccessSignupViewController {
                signupViewController.view.alpha = 0.0
                view.addSubview(signupViewController.view)
                self.signupViewForController = signupViewController.view
            }
        }
        
        if self.socialViewForController == nil {
            if let socialViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SocialLoginStoryboard.rawValue) as? AccessSocialLoginViewController {
                socialViewController.view.alpha = 0.0
                view.addSubview(socialViewController.view)
                self.socialViewForController = socialViewController.view
                self.socialArrowViewForController = socialViewController.layoutDirectionIndicatorArrowRightView
            }
        }
    }
    
    private func trevalonerLoginAccount() -> () {
        guard let usernameText = self.usernameText,
              let passwordText = self.passwordText,
              !usernameText.isEmpty && !passwordText.isEmpty else {
            return
        }
        
        let cognitoUserPoolController = CognitoUserPoolController.sharedInstance()
        cognitoUserPoolController.login(username: usernameText, password: passwordText) { (error) in
            if let error = error {
                print("ERROR: \(error)")
                self.displayErrorMessage(for: .UNKNOWN, and: error as NSError, nil)
                return
            }
            performUIMain {
                self.displaySuccessMessage()
            }
        }
    }
    
    private func redefineViewFrame(less viewForSlideDirection: SlideDirection) -> () {
        switch viewForSlideDirection {
        case .Left:
            self.termsAndConditionViewForController?.alpha = 0.0
        case .Right:
            self.termsAndConditionViewForController?.alpha = 0.0
        case .Up:
            self.signupViewForController?.alpha = 0.0
            self.socialViewForController?.alpha = 0.0
        case .Center: break
        }
    }
    
    private func shootMainLogoAnimate() -> () {
        guard let mainLogoSpringImageView = self.mainLogoSpringImageView else { return }
        mainLogoSpringImageView.animation = "pop"
        mainLogoSpringImageView.duration = 1.5
        mainLogoSpringImageView.animate()
    }
    
    private func setupBackgroundImageWithEffect() -> () {
        guard let backgroundImageVisualEffectView = self.backgroundImageVisualEffectView,
              let backgroundImageView = self.backgroundImageView else {
            return
        }
        
        backgroundImageView.isHidden = true
        backgroundImageVisualEffectView.isHidden = true
        backgroundImageVisualEffectView.alpha = 0.0
    }
    
    private func presentBackgroundImageWithEffect() -> () {
        guard let backgroundImageVisualEffectView = self.backgroundImageVisualEffectView,
              let backgroundImageView = self.backgroundImageView else {
            return
        }
        
        backgroundImageView.isHidden = false
        backgroundImageVisualEffectView.isHidden = false
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            backgroundImageView.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseIn, animations: {
                backgroundImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                backgroundImageVisualEffectView.alpha = 0.6
            }, completion: nil)
        }
    }
    
    private func dismissBackgroundImageWithEffect() -> () {
        guard let backgroundImageVisualEffectView = self.backgroundImageVisualEffectView,
              let backgroundImageView = self.backgroundImageView else {
            return
        }
    
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            backgroundImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            backgroundImageVisualEffectView.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
                backgroundImageView.alpha = 0.0
                backgroundImageVisualEffectView.alpha = 0.0
                backgroundImageView.isHidden = true
                backgroundImageVisualEffectView.isHidden = true
            }, completion: nil)
        }
    }
    
    private func alternatingBetweenFieldsImageWithEffect() -> () {
        guard let backgroundImageView = self.backgroundImageView else { return }
        
        self.directionIndicatorArrowImageWithEffect()
        self.shootMainLogoAnimate()
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            backgroundImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (_) in
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                backgroundImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
        }
    }
    
    private func directionIndicatorArrowImageWithEffect() -> () {
        guard let directionIndicatorArrowLeft = self.layoutDirectionIndicatorArrowLeft,
              let directionIndicatorArrowRight = self.layoutDirectionIndicatorArrowRight,
              let directionIndicatorArrowDown = self.layoutDirectionIndicatorArrowDown else {
            return
        }
        
        UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
            directionIndicatorArrowLeft.transform = CGAffineTransform(translationX: -5, y: 0)
            directionIndicatorArrowRight.transform = CGAffineTransform(translationX: 5, y: 0)
            directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 5)
        }) { (_) in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                directionIndicatorArrowLeft.transform = CGAffineTransform(translationX: 0, y: 0)
                directionIndicatorArrowRight.transform = CGAffineTransform(translationX: 0, y: 0)
                directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)
        }
    }
    
    private func clearAllFields() -> () {
        guard let usernameTextField = self.usernameTextField,
              let passwordTextField = self.passwordTextField else {
            return
        }
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        
        guard !keyboardModeVisible else { return }
        
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.x - initialTouchPoint.x < -20 {
                self.viewControllerTransitionDirection = .Left
                
                self.view.frame = CGRect(x: touchPoint.x - initialTouchPoint.x, y: 0,
                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                self.signupViewForController?.frame = CGRect(x: self.view.frame.width, y: 0,
                                                             width: self.view.frame.size.width, height: self.view.frame.size.height)
                self.signupViewForController?.alpha = 1.0
                self.redefineViewFrame(less: .Left)
            } else if touchPoint.x - initialTouchPoint.x > 20 {
                    self.viewControllerTransitionDirection = .Right
                
                    self.view.frame = CGRect(x: touchPoint.x - initialTouchPoint.x, y: 0,
                                             width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                    self.socialViewForController?.frame = CGRect(x: -self.view.frame.width, y: 0,
                                                                 width: self.view.frame.size.width, height: self.view.frame.size.height)
                    self.socialViewForController?.alpha = 1.0
                    self.redefineViewFrame(less: .Right)
                
                    let leftToRightLimit = ((self.view.frame.size.width / 2) - 60)
                
                    if touchPoint.x - initialTouchPoint.x > leftToRightLimit {
                        self.transitionLimitValue = (touchPoint.x - initialTouchPoint.x)
                    }
            } else {
                if touchPoint.y - initialTouchPoint.y < -20 {
                    self.viewControllerTransitionDirection = .Up
                    
                    self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y,
                                             width: self.view.frame.size.width, height: self.view.frame.size.height)
                    
                    self.termsAndConditionViewForController?.frame = CGRect(x: 0, y: self.view.frame.height,
                                                                            width: self.view.frame.size.width, height: self.view.frame.size.height)
                    self.termsAndConditionViewForController?.alpha = 1.0
                    self.redefineViewFrame(less: .Up)
                }
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            
            let rightToLeftLimit = ((self.view.frame.size.width / 2) - 60)
            let leftToRightLimit = ((self.view.frame.size.width / 2) - 60)
            
            if viewControllerTransitionDirection == .Right {
                if touchPoint.x - initialTouchPoint.x > leftToRightLimit {
                    self.performSegue(withIdentifier: Segue.SocialLoginStoryboard.rawValue,
                                      sender: self.socialViewForController)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.socialViewForController?.alpha = 0.0
                        self.viewControllerTransitionDirection = .Center
                    })
                }
            } else if viewControllerTransitionDirection == .Left {
                if ((touchPoint.x - initialTouchPoint.x) * -1) > rightToLeftLimit {
                    self.performSegue(withIdentifier: Segue.SignupStoryboard.rawValue, sender: self.signupViewForController)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.signupViewForController?.alpha = 0.0
                        self.viewControllerTransitionDirection = .Center
                    })
                }
            } else if viewControllerTransitionDirection == .Up {
                if (touchPoint.y - initialTouchPoint.y) < -250 {
                    self.performSegue(withIdentifier: Segue.TermsAndCondition.rawValue, sender: self.termsAndConditionViewForController)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.termsAndConditionViewForController?.alpha = 0.0
                        self.viewControllerTransitionDirection = .Center
                    })
                }
            }
        }
    }
    
    @IBAction func tapTrevaloneAccountLoginAction() {
        self.trevalonerLoginAccount()
    }
    
    @IBAction func tapToHideKeyboard(_ gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            self.editingFieldMode = false
            self.hideKeyboard()
        }
    }
    
    @objc private func swipeTopGestureAction(_ gesture: UISwipeGestureRecognizer) -> () {
        if gesture.state == .ended {
            self.hideKeyboard()
        }
    }
    
    @objc private func keyboardWillShow() -> () {
        self.keyboardModeVisible = true
    }
    
    @objc private func keyboardWillHide() -> () {
        self.keyboardModeVisible = false
        self.enableInterface(allFieldsFilledOut())
    }
}

extension AccessLoginViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.enableInterface(allFieldsFilledOut())
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let allFieldsMappedDictionary = self.allFieldsMapped else { return false }
        if let field = allFieldsMappedDictionary[textField] {
            if let next = field {
                next.becomeFirstResponder()
                return false
            }
            
            self.dismissBackgroundImageWithEffect()
            textField.resignFirstResponder()
            self.editingFieldMode = false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !editingFieldMode {
            editingFieldMode = true
            self.presentBackgroundImageWithEffect()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !editingFieldMode {
            self.dismissBackgroundImageWithEffect()
            return
        }
        self.alternatingBetweenFieldsImageWithEffect()
    }
}

extension AccessLoginViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.dismissBackgroundImageWithEffect()
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case Segue.HomeStoryboard.rawValue: break
        case Segue.SignupStoryboard.rawValue:
            guard let destination = segue.destination as? AccessSignupViewController,
                  let sender = sender as? UIView else {
                return
            }
            destination.initialTransitionView = sender
        case Segue.SocialLoginStoryboard.rawValue:
            guard let destination = segue.destination as? AccessSocialLoginViewController,
                  let sender = sender as? UIView else {
                return
            }
            destination.initialTransitionView = sender
        case Segue.TermsAndCondition.rawValue:
            guard let destination = segue.destination as? TermsAndConditionViewController,
                  let sender = sender as? UIView else {
                return
            }
            destination.initialTransitionView = sender
            destination.viewControllerNamedType = .SigninViewController
        default: break
        }
    }
}

