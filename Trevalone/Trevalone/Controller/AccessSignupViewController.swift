//
//  AccessSignupViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 11/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import UIKit
import Spring
import AWSCognitoIdentityProvider


class AccessSignupViewController : UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField?
    @IBOutlet weak var emailAddressTextField: UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    
    @IBOutlet weak var layoutDirectionIndicatorArrowLeft: UIImageView?
    @IBOutlet weak var layoutDirectionIndicatorArrowDown: UIImageView?
    
    @IBOutlet weak var mainLogoSpringImageView: SpringImageView?
    
    @IBOutlet weak var signupButton: UIButton?
    
    @IBOutlet var allFields: [UITextField]?
    
    public var currentConfirmationCode: String? = nil
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    private var transitionDirection: SlideDirection = .Center
    
    private var termsAndConditionViewForController: UIView? = nil
    private var homeViewForController: UIView? = nil
    
    private var confirmationCodeAlertInformation: AlertInformationViewController? = nil
    
    private var keyboardModeVisible: Bool = false
    private var editingFieldMode: Bool = false
    
    private var keyboardModeVisibleViewConstraintH: [NSLayoutConstraint]? = nil
    private var keyboardModeVisibleViewConstraintV: [NSLayoutConstraint]? = nil
    private var keyboardModeUnvisibleViewConstraintH: [NSLayoutConstraint]? = nil
    private var keyboardModeUnvisibleViewConstraintV: [NSLayoutConstraint]? = nil
    
    enum ErrorType : String {
        case UNKNOWN
        case REQUIRED
        case USERNAME_EXISTS = "37"
        case USERNOTFOUND = "34"
        case INCORRECT = "20"
        case PATTERN_PASSWORD = "14"
        case PATTERN_GENERAL = "13"
        case PATTERN_GENERAL_EMAIL = "13:1"
        case PATTERN_GENERAL_PASSWORD = "13:2"
        case CONFIRMATION_CODE = "3"
        case EMAIL_ADDRESS_EXISTS = "1"
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
    
    var usernameFieldText: String? {
        guard let usernameTextField = self.usernameTextField,
              let text = usernameTextField.text, !text.isEmpty else { return nil }
        return text
    }
    
    var emailAddressFieldText: String? {
        guard let emailAddressTextField = self.emailAddressTextField,
              let text = emailAddressTextField.text, !text.isEmpty else { return nil }
        return text
    }
    
    var passwordFieldText: String? {
        guard let passwordTextField = self.passwordTextField,
              let text = passwordTextField.text, !text.isEmpty else { return nil }
        return text
    }
    
    var allFieldsMapped: [UITextField : UITextField?]? {
        guard let usernameTextField = self.usernameTextField,
              let emailAddressTextField = self.emailAddressTextField,
              let passwordTextField = self.passwordTextField else {
            return nil
        }
        
        return [ emailAddressTextField : usernameTextField,
                 usernameTextField : passwordTextField,
                 passwordTextField : nil ]
    }
    
    public var initialTransitionView: UIView? = nil {
        didSet {
            if let initialTransitionView = self.initialTransitionView {
                self.view.frame = initialTransitionView.frame
            }
        }
    }
    
    private var errorCodeSkippingProcess: [ErrorType.RawValue:Bool]? {
        return ["1" : true]
    }
    
    private var errorAndPossibleMessageBody: [ErrorType.RawValue:[String:[String:String]]]? {
        return [
            "13" : ["1" : ["__type":"InvalidParameterException", "message":"invalid,email,address,format"],
                    "2" : ["__type":"InvalidParameterException", "message":"validation,password,constraint,length,equal"]]
        ]
    }
    
    private var errorCodeCombinedAMessage: [ErrorType:[String:Any]]? {
        return [
            .UNKNOWN : ["title":"Ops, um erro aconteceu", "message":"Aconteceu um erro ao tentar fazer login. Tente novamente."],
            .USERNOTFOUND : ["title":"Usuário não encontrado", "message":"Não conseguimos te identificar. Por favor, verifique seus dados e tente novamente."],
            .INCORRECT : ["title":"Login ou Senha incorretos", "message":"Verificamos seu cadastro e notamos que você digitou seu Login ou sua senha incorretamente. Por favor, verifique seus dados e tente novamente."],
            .PATTERN_GENERAL_EMAIL : ["title":"Algo está errado", "message":"Notei que você digitou seu endereço\n de E-mail no padrão incorreto.\n Tente isso: example@example.com(.br)"],
            .PATTERN_GENERAL_PASSWORD : ["title":"Algo está errado", "message":"Notei que você digitou um senha muito curta. Tente uma senha com mais de 6 caracteres."],
            .PATTERN_PASSWORD : ["title":"Algo está errado", "message":"Notei que você digitou sua senha\n no padrão incorreto.\n Tente usar: Letras Maíusculas/Mínusculas, Números e Caracter especial."],
            .REQUIRED: ["title":"Ei, campo vázio", "message":"Você esqueceu de preencher os campos. Coloque suas informações no campo correto e tente novamente."],
            .CONFIRMATION_CODE : ["title":"Código incorreto", "message":"O código que você digitou está incorreto. Por favor, tente novamente."],
            .USERNAME_EXISTS : ["title":"Usuário já existe", "message":"Username não disponível, tente um diferente."],
            .EMAIL_ADDRESS_EXISTS : ["title":"E-mail já existe", "message":"E-mail não disponível, tente um diferente."]
        ]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSwipeGestures()
        self.setupViewResizerOnKeyboardShown()
        self.enableInterface(false)
        
        if initialTransitionView != nil {
            self.setupViewsTransition()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.shootMainLogoAnimate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.directionIndicatorArrowImageWithEffect()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.emptyAllFields()
    }
    
    private func accessOnCreateAccount() -> () {
        self.hideKeyboard()
       
        guard let usernameTextFieldText = self.usernameFieldText,
              let emailAddressTextFieldText = self.emailAddressFieldText,
              let passwordTextFieldText = self.passwordFieldText else {
            let userInfo: [String:Any] = ["__type" : "Required fields", "message" : "Fields required empty"]
            let error: NSError = NSError(domain: "com.trevalone.Trevalone", code: 100, userInfo: userInfo)
            self.displayErrorMessage(for: error, nil)
            return
        }
        
        let cognitoUserPoolController = CognitoUserPoolController.sharedInstance()
        cognitoUserPoolController.signup(username: usernameTextFieldText, password: passwordTextFieldText, emailAddress: emailAddressTextFieldText) {
            (error, user) in
            if let error = error {
                self.displayErrorMessage(for: error as NSError, nil)
                return
            }
                                            
            guard let user = user else {
                let userInfo: [String:Any] = ["__type" : "Unknown Error", "message" : "Could not return user object"]
                let error: NSError = NSError(domain: "com.trevalone.Trevalone", code: 2000, userInfo: userInfo)
                self.displayErrorMessage(for: error, nil)
                return
            }
                                            
            if user.confirmedStatus != .confirmed {
                self.requestConfirmationCode(user, nil)
                return
            }
                                        
            performUIMain {
                self.displaySuccessMessage()
            }
        }
    }
    
    private func requestConfirmationCode(_ user: AWSCognitoIdentityUser,_ completion: (()->())?) -> () {
        self.setupViewResizerDisableOnkeyboardShown()
        
        let alertTitle: String = "CÓDIGO DE VERIFICAÇÃO"
        let alertMessage: String = "Foi enviado um código de verificação\n de 6 - digítos para seu E-mail, Por favor digite-o."
        
        self.showAlertEntryWith(alertTitle, alertMessage, in: self, confirm: { (confirmationCode) in
            
            guard let confirmationCode = confirmationCode else { return }
            
            let cognitoUserPoolController = CognitoUserPoolController.sharedInstance()
            cognitoUserPoolController.confirmSignup(user: user, confirmationCode: confirmationCode, completion: { (error) in
                if let error = error {
                    self.displayErrorMessage(for: error as NSError, {
                        self.requestConfirmationCode(user, nil)
                    })
                    return
                }
                
                performUIMain {
                    self.displaySuccessMessage()
                }
            })
        }, alternative: {
            let cognitoUserPoolController = CognitoUserPoolController.sharedInstance()
            cognitoUserPoolController.resendConfirmationCode(user: user, completion: { (error) in
                if let error = error {
                    self.displayErrorMessage(for: error as NSError, {
                        self.requestConfirmationCode(user, nil)
                    })
                    return
                }
                self.displayCodeResentMessage(user)
            })
        })
    }
    
    private func displayErrorMessage(for error: NSError, _ completion: (()->Void)?) {
        let errorCode = error.code
        let errorCodeString = String(errorCode)
        print("ERROR -- \(error)")
        if let dictionaryResult = handlerErrorMessage(forError: errorCodeString, and: error.userInfo) {
            if let titleForAlert = dictionaryResult["title"] as? String,
               let messageForAlert = dictionaryResult["message"] as? String {
            
                if let skipProcessStatus = dictionaryResult["skipProcess"] as? Bool, skipProcessStatus {
                    self.showAlertWith(titleForAlert, messageForAlert, in: self, nil)
                    return
                }
                self.showAlertWith(titleForAlert, messageForAlert, in: self, completion)
            }
        }
    }
    
    private func handlerErrorMessage(forError code: String,and body: [String:Any]?) -> [String:Any]? {
        guard let combinationOfErrorCodeAndMessage = self.errorCodeCombinedAMessage else { return nil }
        
        let minimumNumberOfCombinations: Int = 2
        var numberOfCombinations: Int = 0
        
        var errorCode = code
        
        if let errorAndPossibleMessageBody = self.errorAndPossibleMessageBody {
            if let dictionary = errorAndPossibleMessageBody[code] {
                for (key,value) in dictionary {
                    if let userInfoDictionary = body {
                        if let type = value["__type"] {
                            if let userInfoErrorType = userInfoDictionary["__type"] as? String {
                                if userInfoErrorType == type {
                                    numberOfCombinations += 1
                                }
                            }
                        }
                        
                        if let message = value["message"] {
                            let messageKeysComponents = message.uppercased().components(separatedBy: ",")
                            for component in messageKeysComponents {
                                if let userInfoMessage = userInfoDictionary["message"] as? String {
                                    let userInfoMessageKeysComponents = userInfoMessage.uppercased().components(separatedBy: " ")
                                
                                    if userInfoMessageKeysComponents.contains(component) {
                                        numberOfCombinations += 1
                                    }
                                }
                            }
                        }
                    }
                    
                    if numberOfCombinations > minimumNumberOfCombinations {
                        errorCode = "\(errorCode):\(key)"
                    }
                    numberOfCombinations = 0
                }
            }
        }
        
        var resultDictionary: [String:Any] = Dictionary<String,Any>()
        
        if let errorCodeSkippingProcess = self.errorCodeSkippingProcess {
            if let errorCodeSkippingStatus = errorCodeSkippingProcess[errorCode] {
                resultDictionary["skipProcess"] = errorCodeSkippingStatus
            }
        }
        
        if let errorType = ErrorType(rawValue: errorCode) {
            if let errorDictionary = combinationOfErrorCodeAndMessage[errorType] {
                resultDictionary.merge(errorDictionary) { (current, _) -> Any in current }
                return resultDictionary
            }
        } else if let unknownErrorDictionary = combinationOfErrorCodeAndMessage[.UNKNOWN] {
            return unknownErrorDictionary
        }
        return nil
    }
    
    private func displaySuccessMessage() -> () {
        self.emptyAllFields()
        self.setupViewResizerOnKeyboardShown()
        self.performSegue(withIdentifier: Segue.HomeStoryboard.rawValue, sender: nil)
    }
    
    private func displayCodeResentMessage(_ user: AWSCognitoIdentityUser) -> () {
        let alertTitle: String = "Código de verificação"
        let alertMessage: String = "Um código de 6 dígitos foi enviado para o seu E-mail."
        self.showAlertWith(alertTitle, alertMessage, in: self) {
            self.requestConfirmationCode(user, nil)
        }
    }

    private func emptyAllFields() -> () {
        guard let allFields = self.allFields else { return }
        allFields.forEach { (field) in
            performUIMain {
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                    field.text = ""
                }, completion: nil)
            }
        }
    }
    
    private func hideKeyboard() -> () {
        guard let usernameTextField = self.usernameTextField,
              let emailAddressTextField = self.emailAddressTextField,
              let passwordTextField = self.passwordTextField else {
            return
        }
        
        if usernameTextField.isFirstResponder || emailAddressTextField.isFirstResponder || passwordTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
            emailAddressTextField.resignFirstResponder()
            passwordTextField.resignFirstResponder()
        }
    }
    
    private func setupSwipeGestures() -> () {
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownGestureAction(_:)))
        swipeDownGesture.direction = .down
        self.view.addGestureRecognizer(swipeDownGesture)
    }
    
    private func setupViewResizerOnKeyboardShown() -> () {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupViewResizerDisableOnkeyboardShown() -> () {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    private func enableInterface(_ enabled: Bool) -> () {
        guard let signupButton = self.signupButton else { return }
        signupButton.isEnabled = enabled
        signupButton.alpha = !enabled ? 0.5 : 1.0
    }
    
    private func setupViewsTransition() -> () {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let termsAndConditionViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.TermsAndConditionStoryboard.rawValue) as? TermsAndConditionViewController {
            termsAndConditionViewController.view.alpha = 0.0
            view.addSubview(termsAndConditionViewController.view)
            self.termsAndConditionViewForController = termsAndConditionViewController.view
        }
        
        if let homeViewController = storyboard.instantiateViewController(withIdentifier: Storyboard.SigninStoryboard.rawValue) as? AccessLoginViewController {
            homeViewController.view.alpha = 0.0
            view.addSubview(homeViewController.view)
            self.homeViewForController = homeViewController.view
        }
    }
    
    private func redefineViewFrame(less viewForSlideDirection: SlideDirection) -> () {
        switch viewForSlideDirection {
        case .Right:
            self.termsAndConditionViewForController?.alpha = 0.0
        case .Up:
            self.homeViewForController?.alpha = 0.0
        case .Center: break
        case .Left: break
        }
    }
    
    private func shootMainLogoAnimate() -> () {
        guard let mainLogoSpringImageView = self.mainLogoSpringImageView else { return }
        mainLogoSpringImageView.animation = "pop"
        mainLogoSpringImageView.duration = 1.5
        mainLogoSpringImageView.animate()
    }
    
    private func directionIndicatorArrowImageWithEffect() -> () {
        guard let directionIndicatorArrowLeft = self.layoutDirectionIndicatorArrowLeft,
              let directionIndicatorArrowDown = self.layoutDirectionIndicatorArrowDown else {
            return
        }
        
        UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
            directionIndicatorArrowLeft.transform = CGAffineTransform(translationX: -5, y: 0)
            directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 5)
        }) { (_) in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                directionIndicatorArrowLeft.transform = CGAffineTransform(translationX: 0, y: 0)
                directionIndicatorArrowDown.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)
        }
    }
    
    private func allFieldsFilledOut() -> Bool {
        guard let usernameFieldText = self.usernameFieldText,
              let emailAddressFieldText = self.emailAddressFieldText,
              let passwordFieldText = self.passwordFieldText else {
            return false
        }
        
        if (usernameFieldText.count > 0) && (emailAddressFieldText.count > 0) && (passwordFieldText.count > 0) {
            return true
        }
        return false
    }
    
    private func applyConstraintShowKeyboardForView(with keyboardSize: CGRect) -> () {
        
        let alertMainViewUpY: CGFloat = -((keyboardSize.height - (keyboardSize.height / 2)) - 50)
        let alertMainViewDownY: CGFloat = -((keyboardSize.height - (keyboardSize.height / 2)) - 50)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraintDictionary = ["view" : self.view]
        let constraintVisualFormatH = "H:|[view]|"
        
        let constraintTopV = NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: self.view.superview,
                                                attribute: .top, multiplier: 1, constant: alertMainViewUpY)
        
        let constraintBottomV = NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.view.superview,
                                                   attribute: .bottom, multiplier: 1, constant: alertMainViewDownY)
        
        let constraintH = NSLayoutConstraint.constraints(withVisualFormat: constraintVisualFormatH, options: [],
                                                         metrics: nil, views: constraintDictionary as [String : Any])
        
        NSLayoutConstraint.activate(constraintH)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
            NSLayoutConstraint.activate([constraintTopV,constraintBottomV])
        }, completion: nil)
        
        self.keyboardModeVisibleViewConstraintH = constraintH
        self.keyboardModeVisibleViewConstraintV = [constraintTopV, constraintBottomV]
    }
    
    private func applyConstraintHideKeyboardForMainView() -> () {
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraintDictionary = ["view" : self.view]
        let constraintVisualFormatV = "V:|[view]|"
        let constraintVisualFormatH = "H:|[view]|"
        
        let constraintV = NSLayoutConstraint.constraints(withVisualFormat: constraintVisualFormatV, options: [],
                                                         metrics: nil, views: constraintDictionary as [String : Any])
        
        let constraintH = NSLayoutConstraint.constraints(withVisualFormat: constraintVisualFormatH, options: [],
                                                         metrics: nil, views: constraintDictionary as [String : Any])
        
        NSLayoutConstraint.activate(constraintH)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
            NSLayoutConstraint.activate(constraintV)
        }, completion: nil)
        
        self.keyboardModeUnvisibleViewConstraintH = constraintH
        self.keyboardModeUnvisibleViewConstraintV = constraintV
    }
    
    @objc private func keyboardWillShow(notification: Notification) -> () {
        
        self.keyboardModeVisible = true
        
        if let keyboardModeUnvisibleMainConstraintH = self.keyboardModeUnvisibleViewConstraintH {
            NSLayoutConstraint.deactivate(keyboardModeUnvisibleMainConstraintH)
        }
        
        if let keyboardModeUnvisibleMainConstraintV = self.keyboardModeUnvisibleViewConstraintV {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                NSLayoutConstraint.deactivate(keyboardModeUnvisibleMainConstraintV)
            }, completion: nil)
        }
        
        if let keyboardModeVisibleViewConstraintH = self.keyboardModeVisibleViewConstraintH,
           let keyboardModeVisibleViewConstraintV = self.keyboardModeVisibleViewConstraintV {
            NSLayoutConstraint.activate(keyboardModeVisibleViewConstraintH)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
                NSLayoutConstraint.activate(keyboardModeVisibleViewConstraintV)
            }, completion: nil)
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.applyConstraintShowKeyboardForView(with: keyboardSize)
        } else {
            debugPrint("Cannot find keyboard frame size")
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) -> () {
        
        self.keyboardModeVisible = false
        self.enableInterface(self.allFieldsFilledOut())
        
        if let keyboardModeVisibleViewConstraintH = self.keyboardModeVisibleViewConstraintH {
            NSLayoutConstraint.deactivate(keyboardModeVisibleViewConstraintH)
        }
        
        if let keyboardModeVisibleViewConstraintV = self.keyboardModeVisibleViewConstraintV {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                NSLayoutConstraint.deactivate(keyboardModeVisibleViewConstraintV)
            }, completion: nil)
        }
        
        if let keyboardModeUnvisibleViewConstraintH = self.keyboardModeUnvisibleViewConstraintH,
           let keyboardModeUnvisibleViewConstraintV = self.keyboardModeUnvisibleViewConstraintV {
            NSLayoutConstraint.activate(keyboardModeUnvisibleViewConstraintH)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
                NSLayoutConstraint.activate(keyboardModeUnvisibleViewConstraintV)
            }, completion: nil)
            return
        }
        self.applyConstraintHideKeyboardForMainView()
    }
    
    @objc private func swipeDownGestureAction(_ gesture: UISwipeGestureRecognizer) -> () {
        if gesture.state == .ended {
            self.hideKeyboard()
        }
    }
    
    @IBAction func tapAccessOnCreateAccount() -> () {
        self.accessOnCreateAccount()
    }
    
    @IBAction func tapHideKeyboard(_ gesture: UIGestureRecognizer) -> () {
        if gesture.state == .ended {
            self.editingFieldMode = false
            self.hideKeyboard()
        }
    }
    
    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        
        guard !keyboardModeVisible else { return }
        
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.x - initialTouchPoint.x > 20 {
                self.transitionDirection = .Right
                self.view.frame = CGRect(x: touchPoint.x - initialTouchPoint.x, y: 0,
                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                self.homeViewForController?.frame = CGRect(x: -self.view.frame.width, y: 0,
                                                        width: self.view.frame.size.width, height: self.view.frame.size.height)
    
                self.homeViewForController?.alpha = 1.0
                self.redefineViewFrame(less: .Right)
                
            } else if touchPoint.y - initialTouchPoint.y < -20 {
                    self.transitionDirection = .Up
                    
                    self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y,
                                             width: self.view.frame.size.width, height: self.view.frame.size.height)
                    
                    self.termsAndConditionViewForController?.frame = CGRect(x: 0, y: self.view.frame.height,
                                                                         width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                    self.termsAndConditionViewForController?.alpha = 1.0
                    self.redefineViewFrame(less: .Up)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            
            let rightToLeftLimit = ((self.view.frame.size.width / 2) + 60)
            
            if transitionDirection == .Right {
                if (touchPoint.x - initialTouchPoint.x) > rightToLeftLimit {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.homeViewForController?.alpha = 0.0
                        self.transitionDirection = .Right
                    })
                }
            } else if transitionDirection == .Up {
                if (touchPoint.y - initialTouchPoint.y) < -250 {
                    self.performSegue(withIdentifier: Segue.TermsAndCondition.rawValue, sender: self.termsAndConditionViewForController)
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                        self.termsAndConditionViewForController?.alpha = 0.0
                        self.transitionDirection = .Center
                    })
                }
            }
        }
    }
}

extension AccessSignupViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.enableInterface(self.allFieldsFilledOut())
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let allFieldsMapped = self.allFieldsMapped else { return false }
        
        if let field = allFieldsMapped[textField] {
            if let next = field {
                next.becomeFirstResponder()
                return false
            }
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.enableInterface(self.allFieldsFilledOut())
        
        if !editingFieldMode {
            editingFieldMode = true
            self.shootMainLogoAnimate()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if editingFieldMode {
            self.shootMainLogoAnimate()
        }
    }
}

extension AccessSignupViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case Segue.TermsAndCondition.rawValue:
            guard let destination = segue.destination as? TermsAndConditionViewController,
                  let sender = sender as? UIView else {
                return
            }
            destination.initialTransitionView = sender
            destination.viewControllerNamedType = .SignupViewController
        default: break
        }
    }
}
