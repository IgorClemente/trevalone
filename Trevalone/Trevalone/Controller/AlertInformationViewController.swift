//
//  AlertInformationViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 11/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import UIKit


class AlertInformationViewController: UIViewController {

    @IBOutlet weak var alertMainView: UIView?
    @IBOutlet weak var alertConfirmButton: UIButton?
    @IBOutlet weak var alertResendButton: UIButton?
    @IBOutlet weak var alertTitleAroundView: UIView?
    @IBOutlet weak var alertTitleLabel: UILabel?
    @IBOutlet weak var alertMessageLabel: UILabel?
    
    @IBOutlet var allCharacterFields: [UITextField]?
    
    public var alertTitleText: String?
    public var alertMessageText: String?
    
    public var alertType: AlertType?
    
    public var alertConfirmAction: (()->())?
    public var alertEntryConfirmAction: ((String?)->())?
    public var alertAlternativeAction: (()->())?
    
    private var keyboardModeVisible: Bool = false
    private var keyboardModeVisibleMainViewConstraint: [NSLayoutConstraint]? = nil
    private var keyboardModeUnvisibleMainViewConstraint: [NSLayoutConstraint]? = nil
    
    enum AlertType {
    case Confirm
    case Entry
    }
    
    private var allFieldsIdentifierMapped: [String:String?] {
        return ["DIGIT_1" : "DIGIT_2",
                "DIGIT_2" : "DIGIT_3",
                "DIGIT_3" : "DIGIT_4",
                "DIGIT_4" : "DIGIT_5",
                "DIGIT_5" : "DIGIT_6",
                "DIGIT_6" : nil ]
    }
    
    private var allFieldsIdentifierReversed: [String:String?] {
        return ["DIGIT_6" : "DIGIT_5",
                "DIGIT_5" : "DIGIT_4",
                "DIGIT_4" : "DIGIT_3",
                "DIGIT_3" : "DIGIT_2",
                "DIGIT_2" : "DIGIT_1",
                "DIGIT_1" : nil ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupInitialView()
        self.enableInterface(false)
        
        self.setupRecognizers()
        self.setupViewResizerOnKeyboardShown()
        self.setupKeyboardToolbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentAlertInformation()
        self.populatingAlertInformation()
        
        self.enableInterface(false)
        self.focusAndEmptyField("DIGIT_1")
    }
    
    public func presentAlertInformation() -> () {
        guard let alertMainView = self.alertMainView else { return }
        
        alertMainView.alpha = 0.0
        alertMainView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            alertMainView.alpha = 1.0
            alertMainView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }
    
    public func dismissAlertInformation(_ completion: (()->())?) -> () {
        guard let alertMainView = self.alertMainView else { return }
        
        alertMainView.alpha = 1.0
        alertMainView.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            alertMainView.alpha = 0.0
            alertMainView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            self.dismiss(animated: true, completion: completion)
        }, completion: nil)
    }
    
    private func populatingAlertInformation() -> () {
        guard let alertTitleText = self.alertTitleText,
              let alertMessageText = self.alertMessageText,
              let alertTitleLabel = self.alertTitleLabel,
              let alertMessageLabel = self.alertMessageLabel else {
            return
        }
        alertTitleLabel.text = alertTitleText
        alertMessageLabel.text = alertMessageText
    }
    
    private func enableInterface(_ enabled: Bool) -> () {
        guard let alertConfirmButton = self.alertConfirmButton,
              let alertType = self.alertType else {
            return
        }
    
        if alertType == .Entry {
            alertConfirmButton.isEnabled = enabled
            alertConfirmButton.alpha = (enabled ? 1.0 : 0.5)
        }
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
    
    private func setupRecognizers() -> () {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        self.view.addGestureRecognizer(gesture)
    }
    
    private func hideKeyboard() -> () {
        self.allCharacterFields?.filter({ (field) -> Bool in
            return field.isFirstResponder
        }).first?.resignFirstResponder()
    }
    
    private func allFieldsCompleted() -> Bool {
        guard let allCharacterFields = self.allCharacterFields else { return false }
        let filtered = allCharacterFields.filter { (textField) -> Bool in
            return textField.text == ""
        }
        return filtered.isEmpty
    }
    
    private func focusAndEmptyField(_ identifier: String) -> () {
        guard let allFields = self.allCharacterFields else { return }
        
        for field in allFields {
            guard let restorationIdentifier = field.restorationIdentifier else { return }
            if restorationIdentifier == identifier {
                field.becomeFirstResponder()
            }
        }
    }
    
    private func allFieldsSorted(_ array: [UITextField]) -> [UITextField]? {
        let fieldsSorted = array.sorted { (textField1, textField2) -> Bool in
            guard let restorationIdentifierString1 = textField1.restorationIdentifier,
                  let restorationIdentifierString2 = textField2.restorationIdentifier else {
                return false
            }
            
            let splitIdentifierResult1 = restorationIdentifierString1.split(separator: "_")
            let splitIdentifierResult2 = restorationIdentifierString2.split(separator: "_")
            
            guard let splitIdentifierFirstResult1 = splitIdentifierResult1.last,
                  let splitIdentifierFirstResult2 = splitIdentifierResult2.last,
                  let splitIdentifierInteger1 = Int(splitIdentifierFirstResult1),
                  let splitIdentifierInteger2 = Int(splitIdentifierFirstResult2) else {
                return false
            }
            return splitIdentifierInteger1 < splitIdentifierInteger2
        }
        
        guard !fieldsSorted.isEmpty else { return nil }
        return fieldsSorted
    }
    
    private func getConfirmationCode() -> String? {
        guard let allFieldsArray = self.allCharacterFields,
              let allFieldsSorted = self.allFieldsSorted(allFieldsArray) else {
            return nil
        }
        
        var characteresArray: [String] = []
        characteresArray = allFieldsSorted.map({
            if let textForField = $0.text {
                return textForField
            }
            return ""
        })
        
        let characteresJoinedText = characteresArray.joined()
        
        guard !characteresJoinedText.isEmpty else { return nil }
        return characteresJoinedText
    }
    
    private func setupInitialView() -> () {
        guard let alertMainView = self.alertMainView else { return }
        alertMainView.alpha = 0.0
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }
    
    private func setupKeyboardToolbar() -> () {
        let emptyFieldsBarButton = UIBarButtonItem(title: "LIMPAR", style: .plain, target: self, action: #selector(emptyAllFields))
        let toolbar = UIToolbar()
        toolbar.barStyle = .black
        toolbar.tintColor = UIColor.white
        toolbar.items = [emptyFieldsBarButton]
        toolbar.sizeToFit()
        
        guard let allCharacterFields = self.allCharacterFields else { return }
        allCharacterFields.forEach({ (textField) in
            textField.inputAccessoryView = toolbar
        })
    }
    
    private func getAllFieldsEmpty() -> [UITextField]? {
        guard let allCharacterFields = self.allCharacterFields else { return nil }
        
        let fieldsFiltered = allCharacterFields.filter { (textField) -> Bool in
            return textField.text == ""
        }
        
        guard let fieldsSorted = self.allFieldsSorted(fieldsFiltered), !fieldsSorted.isEmpty else { return nil }
        return fieldsSorted
    }
    
    private func focusNextFieldEmpty() -> () {
        guard let allEmptyCharacterFields = self.getAllFieldsEmpty(),
              let firstField = allEmptyCharacterFields.first else {
            return
        }
        firstField.becomeFirstResponder()
    }
    
    private func confirmActionAlert() -> () {
        guard let currentAlertType = self.alertType else { return }
        switch currentAlertType {
        case .Confirm:
            self.dismissAlertInformation {
                guard let alertConfirmAction = self.alertConfirmAction else { return }
                alertConfirmAction()
            }
        case .Entry:
            self.dismissAlertInformation {
                guard let alertEntryConfirmAction = self.alertEntryConfirmAction,
                      let confirmationCodeText = self.getConfirmationCode() else {
                    return
                }
                alertEntryConfirmAction(confirmationCodeText)
            }
        }
    }
    
    private func applyConstraintShowKeyboardForMainView(with keyboardSize: CGRect) -> () {
        guard let alertMainView = self.alertMainView else { return }
        
        if let window = self.view.window?.frame {
            let alertMainViewUpY: CGFloat = ((((window.height) - keyboardSize.height) - alertMainView.frame.height) - 50)
            let alertMainViewDownY: CGFloat = ((keyboardSize.height) + 50)
            
            alertMainView.translatesAutoresizingMaskIntoConstraints = false
            
            let constraintDictionary = ["alertMainView" : alertMainView]
            let constraintVisualFormat = "V:|-\(alertMainViewUpY)-[alertMainView]-\(alertMainViewDownY)-|"
            let constraint = NSLayoutConstraint.constraints(withVisualFormat: constraintVisualFormat, options: [], metrics: nil,
                                                            views: constraintDictionary)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                NSLayoutConstraint.activate(constraint)
            }, completion: nil)
            
            self.keyboardModeVisibleMainViewConstraint = constraint
        }
    }
    
    private func applyConstraintHideKeyboardForMainView() -> () {
        guard let alertMainView = self.alertMainView else { return }
        
        let alertMainViewMiddleHeight = ((self.view.frame.height - alertMainView.frame.height) / 2)
        
        alertMainView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraintDictionary = ["alertMainView" : alertMainView]
        let constraintVisualFormat = "V:|-\(alertMainViewMiddleHeight)-[alertMainView]-\(alertMainViewMiddleHeight)-|"
        let constraint = NSLayoutConstraint.constraints(withVisualFormat: constraintVisualFormat, options: [], metrics: nil,
                                                        views: constraintDictionary)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            NSLayoutConstraint.activate(constraint)
        }, completion: nil)
    
        self.keyboardModeUnvisibleMainViewConstraint = constraint
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) -> () {
        
        self.keyboardModeVisible = true
        
        if let keyboardModeUnvisibleMainViewConstraint = self.keyboardModeUnvisibleMainViewConstraint {
            NSLayoutConstraint.deactivate(keyboardModeUnvisibleMainViewConstraint)
        }
        
        if let keyboardModeVisibleMainViewConstraint = self.keyboardModeVisibleMainViewConstraint {
            NSLayoutConstraint.activate(keyboardModeVisibleMainViewConstraint)
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.applyConstraintShowKeyboardForMainView(with: keyboardSize)
            
            if allFieldsCompleted() {
                self.focusAndEmptyField("DIGIT_6")
                return
            }
            self.focusNextFieldEmpty()
        } else {
            debugPrint("Cannot find keyboard frame size")
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) -> () {
        self.keyboardModeVisible = false
        if let keyboardModeVisibleMainViewConstraint = self.keyboardModeVisibleMainViewConstraint {
            NSLayoutConstraint.deactivate(keyboardModeVisibleMainViewConstraint)
        }
        
        if let keyboardModeUnvisibleMainViewConstraint = self.keyboardModeUnvisibleMainViewConstraint {
            NSLayoutConstraint.activate(keyboardModeUnvisibleMainViewConstraint)
            return
        }
        self.applyConstraintHideKeyboardForMainView()
    }
    
    @objc private func hideKeyboard(_ gesture: UITapGestureRecognizer) -> () {
        if gesture.state == .ended {
            self.hideKeyboard()
        }
    }
    
    @objc private func emptyAllFields() -> () {
        guard let allFields = self.allCharacterFields,
              let allFieldsSorted = self.allFieldsSorted(allFields) else {
            return
        }
        
        allFieldsSorted.forEach { (textField) in
            textField.text = ""
        }
        
        if let firstField = allFieldsSorted.first {
            firstField.becomeFirstResponder()
        }
        self.enableInterface(false)
    }
    
    @IBAction func tapConfirmAlert() -> () {
        self.confirmActionAlert()
    }
    
    @IBAction func tapAlternativeAlert() -> () {
        guard let alertAlternativeAction = self.alertAlternativeAction else { return }
        self.dismissAlertInformation {
            alertAlternativeAction()
        }
    }
}

extension AlertInformationViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let oldText = textField.text as NSString? else { return false }
        let newText = oldText.replacingCharacters(in: range, with: string)
        
        if (newText.count > oldText.length) && (newText.count == 1) {
            textField.text = newText
            if let currentIdentifier = textField.restorationIdentifier {
                if let nextFieldIdentifier = self.allFieldsIdentifierMapped[currentIdentifier] {
                    if nextFieldIdentifier != nil {
                        guard let allFieldsOfDigits = self.allCharacterFields else { return false }
                            
                        let nextFieldResults = allFieldsOfDigits.filter { (field) -> Bool in
                            return field.restorationIdentifier == nextFieldIdentifier
                        }
                        
                        guard !nextFieldResults.isEmpty, let nextField = nextFieldResults.first else { return false }
                        nextField.becomeFirstResponder()
                    } else {
                        textField.resignFirstResponder()
                    }
                }
            }
        } else if (newText.count > oldText.length) && (newText.count > 1) {
            textField.text = oldText as String
            return false
        }
        
        if allFieldsCompleted() {
            self.enableInterface(true)
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let newText = textField.text else { return false }
        if (newText == "") {
            return true
        }
        
        if allFieldsCompleted() {
            return true
        }
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let newText = textField.text else { return }
    
        if (newText == "") && keyboardModeVisible {
            self.focusNextFieldEmpty()
        }
        
        if allFieldsCompleted() && keyboardModeVisible {
            self.focusAndEmptyField("DIGIT_6")
        }
    }
}
