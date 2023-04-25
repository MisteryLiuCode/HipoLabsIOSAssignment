//
//  AddNewMemberViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 19.04.2023.
//

import UIKit
import CoreData
import SystemConfiguration

class AddNewMemberViewController: UIViewController {
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var githubView: UIView!
    @IBOutlet weak var PositionView: UIView!
    @IBOutlet weak var YearsView: UIView!
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var githubText: UITextField!
    @IBOutlet weak var positionText: UITextField!
    @IBOutlet weak var yearsText: UITextField!
    
    @IBOutlet weak var addButtonOutlet: UIButton!
    
    let context = appDelegate.persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameView.layer.cornerRadius = 8
        githubView.layer.cornerRadius = 8
        PositionView.layer.cornerRadius = 8
        YearsView.layer.cornerRadius = 8
        
        nameView.layer.borderWidth = 1
        githubView.layer.borderWidth = 1
        PositionView.layer.borderWidth = 1
        YearsView.layer.borderWidth = 1
        
        nameView.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        githubView.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        PositionView.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        YearsView.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        nameText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        githubText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        positionText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        yearsText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        addButtonOutlet.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isInternetAvailable() {
            
        } else {
            addButtonOutlet.isEnabled = false
        }
        
        if !isInternetAvailable() {
            let alert = UIAlertController(title: "Warning", message: "No internet connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func textFieldDidChange() {
        
        guard let name = nameText.text, !name.isEmpty,
              let github = githubText.text, !github.isEmpty,
              let position = positionText.text, !position.isEmpty,
              let years = yearsText.text, !years.isEmpty
        else {
            addButtonOutlet.isEnabled = false
            return
        }
        
        if isInternetAvailable() {
            addButtonOutlet.isEnabled = true

        } else {
            addButtonOutlet.isEnabled = false
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButton(_ sender: Any) {
        
        guard Int(yearsText.text!) != nil else {
            showAlert(title: "Error", message: "Please enter a valid number for years.")
            return
        }
        
        guard let githubUser = githubText.text, !githubUser.isEmpty else {
            showAlert(title: "Error", message: "Please enter GitHub Username.")
            return
        }
        
        let urlString = "https://api.github.com/users/\(githubUser)"
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "Error", message: "Invalid URL.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.showAlert(title: "Error", message: "No data received.")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(MyResponse.self, from: data)
                
                if result.login.lowercased() == githubUser.lowercased() {
                    DispatchQueue.main.async {
                        
                        let addMember = Members(context: self.context)
                        addMember.name = self.nameText.text
                        addMember.github = self.githubText.text
                        
                        let addHipo = Hipo(context: self.context)
                        addMember.hipo = addHipo
                        addHipo.position = self.positionText.text
                        if let years = Int32(self.yearsText.text!) {
                            addHipo.years = years
                            
                        }

                        appDelegate.saveContext()
                        
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error", message: "Username does not match.")
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Username not found.")
                }
            }
        }
        task.resume()
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    struct MyResponse: Codable {
        let login: String
    }
    
}
