//
//  ScheduleViewController.swift
//  mysched
//
//  Created by Ryan Sheridan on 25/04/2023.
//

import UIKit
import KeychainSwift

class ScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    
    var shiftMessages: [String] = []
    var scheduleInstance: MySchedule?
    
    var gPersonInfo: [String]?
    var rightLabel: UILabel?

    
    var logoutButton: UIButton?
    var rightButton: UIButton?
    var leftButton: UIButton?
    var addButton: UIButton?
    var infoButton: UIButton?
    
    // MARK: UI Elements
    
    let bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(0xE91E63)
        return view
    }()
    
    let bannerTitle: UILabel = {
        let label = UILabel()
        label.text = "undefined"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.allowsSelection = false
        return tableView
    }()
    
    let buttonHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(0x3c3c3c)
        view.layer.cornerRadius = 40
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func createEstimatedPayContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.from(0x3c3c3c)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let leftLabel = UILabel()
        rightLabel = UILabel()
        
        leftLabel.text = "Estimated Week Pay"
        rightLabel?.text = "Loading"
        
        leftLabel.textColor = .white
        rightLabel?.textColor = .white
        
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        rightLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftLabel)
        container.addSubview(rightLabel!)
        
        NSLayoutConstraint.activate([
            leftLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            
            rightLabel!.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightLabel!.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }

    private func updateRightLabel() {
        self.rightLabel?.text = "Loading ..."
        scheduleInstance!.getPersonInfo { (personInfo) in
            if let personInfo = personInfo {
                self.gPersonInfo = personInfo
                
                DispatchQueue.main.async { [self] in
                    let currencyString = personInfo[5]
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencySymbol = "€"

                    if let number = formatter.number(from: currencyString) {
                        var amount = number.doubleValue
                        amount = (scheduleInstance?.weeklyHours())! * amount
                        
                        if let currencyString = formatter.string(from: NSNumber(value: amount)) {
                            self.rightLabel?.text = currencyString
                        }
                        
                    } else {
                        print("Failed to convert currency string to Double.")
                    }
                    
                }

                print("Person info: \(personInfo)")
            } else {
                print("Failed to fetch person info")
            }
        }
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let estimatedPayContainer = createEstimatedPayContainer()
        view.addSubview(estimatedPayContainer)
        
        updateRightLabel()
        
        view.backgroundColor = UIColor.from(0x2c2c2c)
        bannerTitle.text = scheduleInstance?.getDateText()
        
        logoutButton = UIButton(type: .system)
        if let logoutIcon = UIImage(named: "logout") {
            let newSize = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            logoutIcon.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            logoutButton?.setImage(resizedImage, for: .normal)
        }
        logoutButton?.tintColor = .white
        logoutButton?.backgroundColor = UIColor.from(0xFF5733)
        logoutButton?.layer.cornerRadius = 10 // Add corner radius
        logoutButton?.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        
        rightButton = UIButton(type: .system)
        if let nextIcon = UIImage(named: "next") {
            let newSize = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            nextIcon.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            rightButton?.setImage(resizedImage, for: .normal)
        }
        rightButton?.backgroundColor = UIColor.from(0x1DABE1)
        rightButton?.layer.cornerRadius = 30 // Add corner radius
        rightButton?.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        
        leftButton = UIButton(type: .system)
        if let previousIcon = UIImage(named: "previous") {
            let newSize = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            previousIcon.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            leftButton?.setImage(resizedImage, for: .normal)
        }
        leftButton?.backgroundColor = UIColor.from(0x1DABE1)
        leftButton?.layer.cornerRadius = 30 // Add corner radius
        leftButton?.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        
        addButton = UIButton(type: .system)
        if let addIcon = UIImage(named: "add_icon") {
            let newSize = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            addIcon.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            addButton?.setImage(resizedImage, for: .normal)
        }
        addButton?.tintColor = .white
        addButton?.addTarget(self, action: #selector(saveLoginTapped), for: .touchUpInside)
        addButton?.translatesAutoresizingMaskIntoConstraints = false
        
        infoButton = UIButton(type: .system)
        if let infoIcon = UIImage(named: "info_icon") {
            let newSize = CGSize(width: 24, height: 24)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            infoIcon.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            infoButton?.setImage(resizedImage, for: .normal)
        }
        infoButton?.tintColor = .white
        infoButton?.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        infoButton?.translatesAutoresizingMaskIntoConstraints = false

        
        guard let unwrappedLogoutButton = logoutButton else { return }
        guard let unwrappedRightButton = rightButton else { return }
        guard let unwrappedLeftButton = leftButton else { return }
        guard let unwrappedAddButton = addButton else { return }
        guard let unwrappedInfoButton = infoButton else { return }
        
        // Add subviews
        view.addSubview(bannerView)
        view.addSubview(tableView)
        view.addSubview(buttonHolderView)
        view.addSubview(unwrappedLogoutButton)
        
        buttonHolderView.addSubview(unwrappedLeftButton)
        buttonHolderView.addSubview(unwrappedRightButton)
        bannerView.addSubview(unwrappedAddButton)
        bannerView.addSubview(unwrappedInfoButton)
        bannerView.addSubview(bannerTitle)
        
        // Configure table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Set up layout constraints
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        unwrappedLogoutButton.translatesAutoresizingMaskIntoConstraints = false
        unwrappedLeftButton.translatesAutoresizingMaskIntoConstraints = false
        unwrappedRightButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Banner view
            bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), // Make the banner touch the top of the safe area
            bannerView.heightAnchor.constraint(equalToConstant: 50), // Set the height to 100 points
            
            // Table view
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: bannerView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonHolderView.topAnchor, constant: -40),
            
            // Logout button
            unwrappedLogoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            unwrappedLogoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            unwrappedLogoutButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            unwrappedLogoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Button holder view
            buttonHolderView.bottomAnchor.constraint(equalTo: unwrappedLogoutButton.topAnchor, constant: -60),
            buttonHolderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonHolderView.widthAnchor.constraint(equalToConstant: 260),
            buttonHolderView.heightAnchor.constraint(equalToConstant: 80),

            // Left button
            unwrappedLeftButton.centerYAnchor.constraint(equalTo: buttonHolderView.centerYAnchor),
            unwrappedLeftButton.leadingAnchor.constraint(equalTo: buttonHolderView.leadingAnchor, constant: 10),
            unwrappedLeftButton.widthAnchor.constraint(equalToConstant: 100),
            unwrappedLeftButton.heightAnchor.constraint(equalToConstant: 60),

            // Right button
            unwrappedRightButton.centerYAnchor.constraint(equalTo: buttonHolderView.centerYAnchor),
            unwrappedRightButton.trailingAnchor.constraint(equalTo: buttonHolderView.trailingAnchor, constant: -10),
            unwrappedRightButton.widthAnchor.constraint(equalToConstant: 100),
            unwrappedRightButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Centered title
            bannerTitle.centerXAnchor.constraint(equalTo: bannerView.centerXAnchor),
            bannerTitle.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor),
            
            unwrappedAddButton.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -16),
            unwrappedAddButton.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor),
            
            unwrappedInfoButton.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 16),
            unwrappedInfoButton.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor),
            
            estimatedPayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            estimatedPayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            estimatedPayContainer.centerYAnchor.constraint(equalTo: tableView.bottomAnchor),
            estimatedPayContainer.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "CustomCell")
    }
    
    // MARK: Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shiftMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        
        if indexPath.row < shiftMessages.count {
            let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            
            cell.dayLabel.text = daysOfWeek[indexPath.row % 7]
            cell.shiftMessageLabel.text = shiftMessages[indexPath.row]
        }
        
        return cell
    }

    
    // MARK: Button Actions
    
    @objc func logoutButtonTapped() {
        let viewController = ViewController()
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true, completion: nil)
    }

    private func updateTableView(_ newMessages: [String]) -> () {
        shiftMessages = newMessages
        tableView.reloadData()
        bannerTitle.text = scheduleInstance?.getDateText()
    }
    
    @objc func leftButtonTapped() {
        scheduleInstance?.goBackOneWeek()
        guard let newShiftMessages = scheduleInstance?.getShiftMessages() else { return }
        updateRightLabel()
        updateTableView(newShiftMessages)
    }
    
    @objc func rightButtonTapped() {
        scheduleInstance?.goForwardOneWeek()
        guard let newShiftMessages = scheduleInstance?.getShiftMessages() else { return }
        updateRightLabel()
        updateTableView(newShiftMessages)
    }
    
    @objc func saveLoginTapped() {
        guard let userID = scheduleInstance?.getUserID(), let pass = scheduleInstance?.getPass() else { return }
        
        let alert = UIAlertController(title: "Save Login", message: "Do you want to save the login for \(userID)?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if CredentialsManager.shared.saveCredentials(userID: String(userID), password: pass) {
                UserDefaults.standard.set(userID, forKey: "savedLoginUserID")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func infoButtonTapped() {
        guard let userInfo = gPersonInfo else { return }
        
        let alertTitle = "Employee Info"
        let alertMessage = """
            Store Number: \(userInfo[0])
            Name: \(userInfo[1]) \(userInfo[2])
            Date of Hire: \(userInfo[3])
            Title: \(userInfo[4])
            Base Rate: \(userInfo[5])
            """

        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
}

class CustomTableViewCell: UITableViewCell {
    let dayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let shiftMessageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.from(0x3c3c3c)
        
        addSubview(dayLabel)
        addSubview(shiftMessageLabel)
        
        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            shiftMessageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            shiftMessageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

