//
//  SortMemberViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 23.04.2023.
//

import UIKit

class SortMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var sortMembersTableView: UITableView!
    
    var sortedFullName = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sortMembersTableView.delegate = self
        sortMembersTableView.dataSource = self
        
        sortMembersTableView.separatorStyle = .none
        sortMembersTableView.showsVerticalScrollIndicator = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedFullName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "sortMemberCell") as! SortMemberTableViewCell
        
        cell.textLabel?.font = UIFont(name: "Charter", size: 13)
        cell.textLabel?.text = "   \(sortedFullName[indexPath.row])"
        
        cell.view.layer.cornerRadius = 8
        cell.view.layer.borderWidth = 1
        cell.view.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        
        return cell
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
}
