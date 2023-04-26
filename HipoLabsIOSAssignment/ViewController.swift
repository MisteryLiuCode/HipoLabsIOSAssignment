//
//  ViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 15.04.2023.
//

import UIKit
import CoreData
import SystemConfiguration

let appDelegate = UIApplication.shared.delegate as! AppDelegate

class ViewController: UIViewController {
    
    //tableView用于展示下拉框
    @IBOutlet weak var membersTableView: UITableView!
    //搜索框
    @IBOutlet weak var searchBar: UISearchBar!
    //添加按钮
    @IBOutlet weak var addMemberButton: UIButton!
    
    let context = appDelegate.persistentContainer.viewContext
    
    //创建数组
    var memberList = [Members]()
    var hipoList = [Hipo]()
    
    var isSearching = false
    var textSearch: String?
    
    var memberName = [String]()
    var sortedFullName = [String]()
    
    let refreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
        membersTableView.refreshControl = refreshControl
        
        membersTableView.delegate = self
        membersTableView.dataSource = self
        membersTableView.separatorStyle = .none
        membersTableView.showsVerticalScrollIndicator = false
        
        searchBar.delegate = self
        searchBar.showsScopeBar = false
        searchBar.sizeToFit()
        searchBar.scopeButtonTitles = ["Member", "Position"]
        
        jsonToData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
                
        if isSearching {
            searchContent(text: textSearch!)
        }else{
            getMembersData()
        }
        
        membersTableView.reloadData()
        
        if isInternetAvailable() {
            
            addMemberButton.isEnabled = true
            
        } else {
            addMemberButton.isEnabled = false
        }
        
        if !isInternetAvailable() {
            let alert = UIAlertController(title: "Warning", message: "No internet connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func refreshList(_ sender: Any) {
        
        if isInternetAvailable() {
            addMemberButton.isEnabled = true
        }
        
        refreshControl.endRefreshing()
    }
    
    func getMembersData() {
        
        do {
            memberList = try context.fetch(Members.fetchRequest())
            
        } catch {
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let index = sender as? Int
        
        if segue.identifier == "toSecondVC" {
            let secondVC = segue.destination as! DetailViewController
            secondVC.member = memberList[index!]
        }
        
        if segue.identifier == "toEditVC" {
            let toEditVC = segue.destination as! EditMemberViewController
            toEditVC.member = memberList[index!]
        }
    }
    
    func jsonToData() {
        
        guard let fileUrl = Bundle.main.url(forResource: "hipo", withExtension: "json"),
              let data = try? Data(contentsOf: fileUrl) else {
            return
        }
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        guard let dictionary = json as? [String: Any],
              let members = dictionary["members"] as? [[String: Any]]
        else {
            return
        }
        
        let fetchRequest: NSFetchRequest<Members> = Members.fetchRequest()
        
        do {
            let memberData = try context.fetch(fetchRequest)
            
            if memberData.count == 0 {
                
                let newCompany = Team(context: context)
                    newCompany.company = dictionary["company"] as? String
                    newCompany.team = dictionary["team"] as? String

                print("comp: \(newCompany.company ?? "")")
                
                for member in members {
                    guard let name = member["name"] as? String,
                          let github = member["github"] as? String,
                          let hipo = member["hipo"] as? [String: Any],
                          let position = hipo["position"] as? String,
                          let yearsInHipo = hipo["years_in_hipo"] as? Int
                            
                    else {
                        continue
                    }
                    
                    let teamMember = Members(context: context)
                    teamMember.name = name
                    teamMember.github = github
                    
                    let teamHipo = Hipo(context: context)
                    teamMember.hipo = teamHipo
                    teamHipo.position = position
                    teamHipo.years = Int32(yearsInHipo)
                }
                
                do {
                    try context.save()
                    
                } catch {
                    print("Error saving context: \(error)")
                }
            }
            
        } catch {
            print("Error fetching results: \(error)")
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
    
    func memberNameData() {
        memberName.removeAll()
        let fetchRequest = NSFetchRequest<Members>(entityName: "Members")
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results as [NSManagedObject] {
                
                if let name = result.value(forKey: "name") as? String {
                    self.memberName.append(name)
                }
            }
            
        } catch {
            print("error")
        }
    }
    
    
    func countCharacterOccurrences(in strings: [String], character: Character) -> Int {
        var count = 0
        for str in strings {
            count += str.countOccurrences(of: character)
        }
        return count
    }
    
    func sortByCharacterOccurrencesInLastNames(for character: Character) -> [String] {
        let lastNames = memberName.map { $0.components(separatedBy: " ").last! }
        let sortedLastNames = lastNames.sorted(by: {
            if $0.countOccurrences(of: character) == $1.countOccurrences(of: character) {
                if $0.count == $1.count {
                    return $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
                } else {
                    return $0.count < $1.count
                }
            } else {
                return $0.countOccurrences(of: character) > $1.countOccurrences(of: character)
            }
        })
        return sortedLastNames
    }
    
    @IBAction func sortMembersButton(_ sender: Any) {
        memberNameData()
        let character: Character = "a"
        let sortedLastNames = sortByCharacterOccurrencesInLastNames(for: character)
        var sortedFullName = memberName.sorted(by: { sortedLastNames.firstIndex(of: $0.components(separatedBy: " ").last!)! < sortedLastNames.firstIndex(of: $1.components(separatedBy: " ").last!)! })
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sortMemberVC = storyboard.instantiateViewController(withIdentifier: "SortMemberViewController") as? SortMemberViewController
        sortMemberVC?.sortedFullName = sortedFullName
        self.present(sortMemberVC!, animated: true, completion: nil)
    }
    
//    @IBAction func addNewMemberButton(_ sender: Any) {
//        performSegue(withIdentifier: "toAddMembersVC", sender: nil)
//
//    }
    
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let member = memberList[indexPath.row]
        
        let cell = membersTableView.dequeueReusableCell(withIdentifier: "memberCell") as! MembersTableViewCell
        
        cell.nameLabel.text = member.name
        cell.positionLabel.text = member.hipo?.position
        cell.yearsLabel.text = String(",  \(member.hipo!.years) years")
        
        cell.view.layer.cornerRadius = 8
        cell.view.layer.borderWidth = 1
        cell.view.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toSecondVC", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            
            let member = self.memberList[indexPath.row]
            self.context.delete(member)
            appDelegate.saveContext()
                        
            if self.isSearching {
                self.searchContent(text: self.textSearch!)

            }else{
                self.getMembersData()
            }
            
            self.membersTableView.reloadData()
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            self.performSegue(withIdentifier: "toEditVC", sender: indexPath.row)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
}


extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search: \(searchText)")
        
        textSearch = searchText
        
        if searchText.isEmpty {
                isSearching = false
                getMembersData()
            } else {
                isSearching = true
                searchContent(text: textSearch!)
            }
        
        membersTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = false
    }
    
    func searchContent(text: String) {
        
        if searchBar.selectedScopeButtonIndex == 0 {
            let fetchRequest: NSFetchRequest<Members> = Members.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
            
            do {
                memberList = try context.fetch(fetchRequest)
            } catch let error {
                print("Error: \(error.localizedDescription)")
            }
            
        } else if searchBar.selectedScopeButtonIndex == 1 {
            let fetchRequest: NSFetchRequest<Members> = Members.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "hipo.position CONTAINS[cd] %@", text)
            
            do {
                memberList = try context.fetch(fetchRequest)
            } catch let error {
                print("Error: \(error.localizedDescription)")
            }
            
        } else {
            return
        }
    }
    
}


extension String {
    func countOccurrences(of character: Character) -> Int {
        var count = 0
        for char in self {
            if char == character {
                count += 1
            }
        }
        return count
    }
    
}
