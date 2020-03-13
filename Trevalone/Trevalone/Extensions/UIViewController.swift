//
//  UIViewController.swift
//  Trevalone
//
//  Created by Igor Clemente on 10/04/19.
//  Copyright © 2019 Trevalone. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlertWith(_ title: String,_ message: String,in vc: UIViewController,_ completion: (()->())?) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AlertInformation") as? AlertInformationViewController else { return }
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.definesPresentationContext = true
        viewController.modalPresentationCapturesStatusBarAppearance = false
        viewController.providesPresentationContextTransitionStyle = true
        viewController.alertTitleText = title
        viewController.alertMessageText = message
        viewController.alertType = .Confirm
        viewController.alertConfirmAction = completion
        performUIMain {
            vc.present(viewController, animated: true, completion: nil)
        }
    }
    
    func showAlertEntryWith(_ title: String,_ message: String,in vc: UIViewController, confirm: @escaping (String?)->(), alternative: @escaping ()->()) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AlertEntryInformation") as? AlertInformationViewController else { return }
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.definesPresentationContext = true
        viewController.modalPresentationCapturesStatusBarAppearance = false
        viewController.providesPresentationContextTransitionStyle = true
        viewController.alertTitleText = title
        viewController.alertMessageText = message
        viewController.alertType = .Entry
        viewController.alertEntryConfirmAction = confirm
        viewController.alertAlternativeAction = alternative
        performUIMain {
            vc.present(viewController ,animated: true, completion: nil)
        }
    }
}
