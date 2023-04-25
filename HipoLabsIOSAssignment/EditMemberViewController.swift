//
//  EditMemberViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 21.04.2023.
//

import UIKit
import CoreData
import SystemConfiguration

class EditMemberViewController: UIViewController {
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var githubView: UIView!
    @IBOutlet weak var PositionView: UIView!
    @IBOutlet weak var YearsView: UIView!
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var githubText: UITextField!
    @IBOutlet weak var positionText: UITextField!
    @IBOutlet weak var yearsText: UITextField!
    
    @IBOutlet weak var editButtonOutlet: UIButton!
    
    let context = appDelegate.persistentContainer.viewContext
    
    var member: Members?
    
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
        
        if let m = member {
            nameText.text = m.name
            githubText.text = m.github
            positionText.text = m.hipo?.position
            
            if let years = m.hipo?.years {
                yearsText.text = String(years)
            } else {
                yearsText.text = ""
            }
        }
        
        nameText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        githubText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        positionText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        yearsText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        editButtonOutlet.isEnabled = false
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isInternetAvailable() {
            
        } else {
            editButtonOutlet.isEnabled = false
        }
        
        if !isInternetAvailable() {
            let alert = UIAlertController(title: "Warning", message: "No internet connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func textFieldDidChange() {
        guard let name = nameText.text, !name.isEmpty,
              let github = githubText.text, !github.isEmpty,
              let position = positionText.text, !position.isEmpty,
              let years = yearsText.text, !years.isEmpty else {
            editButtonOutlet.isEnabled = false
            return
        }
        
        if isInternetAvailable() {
            editButtonOutlet.isEnabled = true
        } else {
            editButtonOutlet.isEnabled = false
        }
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
    
    @IBAction func editButton(_ sender: Any) {
        self.member!.name = self.nameText.text
        self.member!.github = self.githubText.text
        self.member!.hipo?.position = self.positionText.text
        
        if let yearsInt = Int32(self.yearsText.text!) {
            self.member!.hipo?.years = yearsInt
        }
        
        appDelegate.saveContext()
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
