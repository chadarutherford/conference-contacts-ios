//
//  SignUpViewController.swift
//  swaap
//
//  Created by Michael Redig on 11/19/19.
//  Copyright © 2019 swaap. All rights reserved.
//

import UIKit
import Auth0

class SignUpViewController: UIViewController, AuthAccessor {
	@IBOutlet private weak var emailForm: FormInputView!
	@IBOutlet private weak var passwordForm: FormInputView!
	@IBOutlet private weak var passwordConfirmForm: FormInputView!
	@IBOutlet private weak var signUpButton: ButtonHelper!
	@IBOutlet private weak var passwordStrengthLabel: UILabel!

	var authManager: AuthManager?

	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
	}

	private func setupUI() {
		overrideUserInterfaceStyle = .light
		emailForm.contentType = .emailAddress
		emailForm.keyboardType = .emailAddress
		passwordForm.contentType = .newPassword
		passwordConfirmForm.contentType = .newPassword
		updateSignUpButtonEnabled()
		updatePasswordStrengthLabel()
	}

	@IBAction func signupTapped(_ sender: ButtonHelper) {
		guard let (email, password) = checkFormValidity() else { return }
		authManager?.signUp(with: email, password: password, completion: {  [weak self] error in
			if let error = error {
				let alertVC = UIAlertController(error: error)
				self?.present(alertVC, animated: true)
			}
		})

		[sender, emailForm, passwordForm, passwordConfirmForm].forEach { $0.resignFirstResponder() }
	}

	@IBAction func textFieldChanged(_ sender: FormInputView) {
		updateSignUpButtonEnabled()
	}

	@IBAction func emailFormDidFinish(_ sender: FormInputView) {
		sender.validationState = checkEmail() != nil ? .pass : .fail
	}

	@IBAction func passwordFormDidFinish(_ sender: FormInputView) {
		sender.validationState = checkPasswordStrength() != nil ? .pass : .fail
	}

	@IBAction func textFieldDidBeginEditing(_ sender: FormInputView) {
		sender.validationState = .hidden
	}

	@IBAction func passwordFieldDidChange(_ sender: FormInputView) {
		updatePasswordStrengthLabel()
	}

	@IBAction func confirmPasswordFormDidFinish(_ sender: FormInputView) {
		sender.validationState = (checkPasswordStrength() != nil && checkPasswordMatch()) ? .pass : .fail
	}

	// MARK: - Form Validation
	private func updateSignUpButtonEnabled() {
		signUpButton.isEnabled = checkFormValidity() != nil
	}

	private func updatePasswordStrengthLabel() {
		let passwordStrengthText = """
			Password must be at least 8 characters, have at least one lowercase & uppercase character, a symbol, \
			and at least one number. It cannot contain any part of your email.
			""" as NSString
		let attrStr = NSMutableAttributedString(string: passwordStrengthText as String, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote)])
		if let password = passwordForm.text {
			let color: UIColor = .systemTeal
			if password.hasAtLeastXCharacters(8) {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "8 characters"))
			}

			if password.hasALowercaseCharacter {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "lowercase"))
			}

			if password.hasAnUppercaseCharacter {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "uppercase"))
			}

			if password.hasANumericalCharacter {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "at least one number"))
			}

			if password.hasASpecialCharacter {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "symbol"))
			}

			if !password.hasPartOfEmailAddress(checkEmail()) {
				attrStr.addAttribute(.foregroundColor, value: color, range: passwordStrengthText.range(of: "part of your email"))
			}
		}

		passwordStrengthLabel.attributedText = attrStr
	}

	private func checkEmail() -> String? {
		(emailForm.text?.isEmail ?? false) ? emailForm.text : nil
	}

	private func checkPasswordStrength() -> String? {
		guard let password = passwordForm.text,
			password.hasAtLeastXCharacters(8),
			password.hasALowercaseCharacter,
			password.hasAnUppercaseCharacter,
			password.hasANumericalCharacter,
			password.hasASpecialCharacter,
			!password.hasPartOfEmailAddress(checkEmail()) else { return nil }
		return password
	}

	private func checkPasswordMatch() -> Bool {
		passwordForm.text == passwordConfirmForm.text
	}

	private func checkFormValidity() -> (email: String, password: String)? {
		guard let email = checkEmail(), let password = checkPasswordStrength(), checkPasswordMatch() else { return nil }
		signUpButton.isEnabled = true
		return (email, password)
	}
}

extension SignUpViewController: RootAuthViewControllerDelegate {
	func controllerWillScroll(_ controller: RootAuthViewController) {
		[emailForm, passwordForm, passwordConfirmForm].forEach { _ = $0.resignFirstResponder() }
	}
}
