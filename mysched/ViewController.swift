//
//  ViewController.swift
//  mysched
//
//  Created by Ryan Sheridan on 25/04/2023.
//

import UIKit
import Foundation

class ViewController: UIViewController, UITextFieldDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private let currentSchedule = MySchedule()
    private var hasSavedLogin: Bool = false
    private var savedCredentials: Credentials?
    
    public struct Credentials: Codable {
        let username: String
        let password: String
    }
    
    public func loadCredentials() -> Credentials? {
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("credentials.json")
                
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let credentials = try decoder.decode(Credentials.self, from: data)
                return credentials
            }
        } catch {
            print("Error decoding credentials: \(error)")
        }
        return nil
    }

    private let mainTitle: UILabel = {
        let title = UILabel()
        title.text = "MySchedule"
        title.textAlignment = .center
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    private let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.from(0x424242) // Choose a color for the container
        return view
    }()

    
    private let userIDTextField: UITextField = {
        let textField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
                                        placeholder: "User ID",
                                        placeholderColor: .lightGray)
        textField.backgroundColor = UIColor.from(0x3c3c3c)
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()

    private let passwordTextField: UITextField = {
        let textField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
                                        placeholder: "Password",
                                        placeholderColor: .lightGray)
        textField.backgroundColor = UIColor.from(0x3c3c3c)
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.from(0x1DABE1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10 // Add corner radius
        button.layer.masksToBounds = true
        return button
    }()
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let savedLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.from(0x28A745)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10 // Add corner radius
        button.layer.masksToBounds = true
        return button
    }()
    
    private func getStartOfWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        let weekday = components.weekday!
        let daysToSubtract = (weekday + 5) % 7 + 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
        return startOfWeek
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let credentials = loadCredentials() {
            savedCredentials = credentials
            hasSavedLogin.toggle()
        }
        
        view.backgroundColor = UIColor.from(0x2c2c2c)
        
        userIDTextField.delegate = self
        passwordTextField.delegate = self
        
        if let userIDString = savedCredentials?.username {
            savedLoginButton.setTitle("Login as \(userIDString)", for: .normal)
        }
        
        setupViews(savedLogin: hasSavedLogin)
        loginButton.addTarget(self, action: #selector(loginButtonPressed), for: .touchUpInside)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        savedLoginButton.addGestureRecognizer(longPressRecognizer)
        savedLoginButton.addTarget(self, action: #selector(savedLoginButtonPressed), for: .touchUpInside)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userIDTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            loginButtonPressed()
        }
        return true
    }
    
    private func setupViews(savedLogin: Bool) {
        view.addSubview(container)
        container.addSubview(mainTitle)
        container.addSubview(userIDTextField)
        container.addSubview(passwordTextField)
        container.addSubview(loginButton)
        
        if savedLogin {
            container.addSubview(orLabel)
            container.addSubview(savedLoginButton)
        }
        
        let containerHeight: CGFloat = savedLogin ? 405 : 300
        
        var constraints = [
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 280),
            container.heightAnchor.constraint(equalToConstant: containerHeight),

            mainTitle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mainTitle.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),

            userIDTextField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            userIDTextField.topAnchor.constraint(equalTo: mainTitle.bottomAnchor, constant: 20),
            userIDTextField.widthAnchor.constraint(equalToConstant: 220),
            userIDTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            passwordTextField.topAnchor.constraint(equalTo: userIDTextField.bottomAnchor, constant: 20),
            passwordTextField.widthAnchor.constraint(equalToConstant: 220),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            loginButton.widthAnchor.constraint(equalToConstant: 220),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
        ]
        
        if savedLogin {
            constraints += [
                orLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                orLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
                orLabel.widthAnchor.constraint(equalToConstant: 220),
                orLabel.heightAnchor.constraint(equalToConstant: 20),
                
                savedLoginButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                savedLoginButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 20),
                savedLoginButton.widthAnchor.constraint(equalToConstant: 220),
                savedLoginButton.heightAnchor.constraint(equalToConstant: 50)
            ]
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func handleLogin(_ shiftMessages: [String]) -> Bool {
        if shiftMessages.first == "undefined" {
            return false
        }
        let schViewController = ScheduleViewController()
        schViewController.shiftMessages = shiftMessages
        schViewController.scheduleInstance = currentSchedule
        schViewController.modalPresentationStyle = .fullScreen
        self.present(schViewController, animated: true, completion: nil)

        return true
    }
    
    private func removeLoginCredentials() {
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("credentials.json")
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error removing credentials: \(error)")
        }
    }
    
    private func reloadViewController() {
        let viewController = ViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true, completion: nil)
    }

    
    @objc private func loginButtonPressed() {
        let userID = userIDTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        if userID.isEmpty && password.isEmpty {
            showAlert(title: "Error", message: "Both fields are empty.")
        } else if userID.isEmpty {
            showAlert(title: "Error", message: "User ID field is empty.")
        } else if password.isEmpty {
            showAlert(title: "Error", message: "Password field is empty.")
        } else {
            currentSchedule.setUserAndPass(user: Int(userID)!, pass: password.base64Encoded!)
            currentSchedule.setNewDate(date: getStartOfWeek(from: Date()))
            
            let shiftMessages = currentSchedule.getShiftMessages()
            if !handleLogin(shiftMessages) {
                showAlert(title: "Error", message: "Login details incorrect")
            }
        }
    }
    
    @objc private func savedLoginButtonPressed() {
        guard let userIDString = savedCredentials?.username,
              let password = savedCredentials?.password,
              let userID = Int(userIDString) else {
            print("Error: Invalid saved credentials")
            return
        }
        
        currentSchedule.setUserAndPass(user: userID, pass: password.base64Decoded!)
        currentSchedule.setNewDate(date: getStartOfWeek(from: Date()))
        
        let shiftMessages = currentSchedule.getShiftMessages()
        if !handleLogin(shiftMessages) {
            showAlert(title: "Error", message: "Saved Login details incorrect")
        }
    }
    
    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            guard let userIDString = savedCredentials?.username else {
                return
            }
            let alert = UIAlertController(title: "Remove saved login?", message: "Do you want to remove the saved login details for \(userIDString)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
                self!.removeLoginCredentials()
                self!.reloadViewController()
            }))
            present(alert, animated: true, completion: nil)
        }
    }

    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension UIColor {
    static func from(_ hex: UInt64) -> UIColor? {
        let rgbValue: UInt64 = hex
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension String {
    var base64Encoded: String? {
        let data = self.data(using: .utf8)
        return data?.base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

class PaddedTextField: UITextField {

    let padding: UIEdgeInsets

    init(padding: UIEdgeInsets, placeholder: String, placeholderColor: UIColor) {
        self.padding = padding
        super.init(frame: .zero)
        self.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                        attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}