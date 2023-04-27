//
//  SettingsViewController.swift
//  mysched
//
//  Created by Ryan Sheridan on 27/04/2023.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: SettingsViewControllerDelegate?
    
    let tableView = UITableView()
    var biometricAuthEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "biometricAuthEnabled") == nil {
                UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
            }
            return UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "biometricAuthEnabled")
        }
    }

    let bannerTitle: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bannerTitle)
        
        biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        
        NSLayoutConstraint.activate([
            bannerTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: bannerTitle.font.pointSize / 2)
        ])
        
        view.backgroundColor = UIColor.from(0xE91E63)
        title = "Settings"
        
        setupTableView()
    }
    
    override func updateViewConstraints() {
       self.view.frame.size.height = UIScreen.main.bounds.height / 2
       self.view.frame.origin.y =  UIScreen.main.bounds.height / 2
       self.view.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
       super.updateViewConstraints()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Table View Delegate & Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundColor = UIColor.from(0x1c1c1e)
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let toggleSwitch = UISwitch()
        toggleSwitch.isOn = biometricAuthEnabled
        toggleSwitch.addTarget(self, action: #selector(biometricAuthSwitchToggled), for: .valueChanged)
        
        if indexPath[0] == 0 {
            cell.textLabel?.text = "Biometric Authentication"
            cell.accessoryView = toggleSwitch
            cell.textLabel?.textColor = UIColor.from(0xf0f0f0)
        } else {
            cell.textLabel?.text = "Remove Saved Login"
            cell.textLabel?.textColor = UIColor.from(0xFF3B30)
        }
        
        cell.backgroundColor = UIColor.from(0x1c1c1e)
        
        return cell
    }
    
    @objc func biometricAuthSwitchToggled(sender: UISwitch) {
        BiometricAuthentication.shared.authenticateUser { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.biometricAuthEnabled = sender.isOn
                UserDefaults.standard.set(self.biometricAuthEnabled, forKey: "biometricAuthEnabled")
                
                // Notify the delegate about the change
                self.delegate?.biometricAuthStatusChanged(enabled: self.biometricAuthEnabled)
            } else {
                print("Biometric Authorization failed in switch toggle")
            }
        }
    }

}

extension UIView {
  func roundCorners(corners: UIRectCorner, radius: CGFloat) {
       let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
       let mask = CAShapeLayer()
       mask.path = path.cgPath
       layer.mask = mask
   }
}

