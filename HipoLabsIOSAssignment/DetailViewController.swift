//
//  DetailViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 15.04.2023.
//

import UIKit
import SystemConfiguration

class DetailViewController: UIViewController {
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var following: UILabel!
    @IBOutlet weak var repo: UILabel!
    @IBOutlet weak var repoTableView: UITableView!
    
    var member: Members?
    
    var repoNames = [RepoDetail]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isInternetAvailable() {
            let alert = UIAlertController(title: "Warning", message: "No internet connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        repoTableView.delegate = self
        repoTableView.dataSource = self
        
        github(name: member!.github!)
        
        repo(name: member!.github!) {
            self.repoTableView.reloadData()
        }
        
        repoTableView.allowsSelection = false
        repoTableView.separatorStyle = .none
        repoTableView.showsVerticalScrollIndicator = false
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Charter-Bold", size: 16)!]
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
    
    func github(name: String) {
        
        if let url = URL(string: "https://api.github.com/users/\(name)") {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error == nil {
                    if let incomingData = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: incomingData, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            
                            let resim = json["avatar_url"] as! String
                            if let url = URL(string: resim) {
                                DispatchQueue.global().async {
                                    let data = try? Data(contentsOf: url)
                                    DispatchQueue.main.async {
                                        self.avatar.image = UIImage(data: data!)
                                        self.avatar.layer.cornerRadius = self.avatar.bounds.width / 2
                                        self.avatar.clipsToBounds = true
                                        self.avatar.layer.borderWidth = 1.5
                                        self.avatar.layer.borderColor = UIColor.white.cgColor
                                    }
                                }
                            }
                            
                            if let userName = json["name"] as? String {
                                DispatchQueue.main.async {
                                    self.navigationItem.title = userName
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.navigationItem.title = self.member?.name
                                }
                            }
                            
                            if let followers = json["followers"] as? Int {
                                DispatchQueue.main.sync {
                                    self.followers.text = String(followers)
                                }
                            }

                            if let following = json["following"] as? Int {
                                DispatchQueue.main.sync {
                                    self.following.text = String(following)
                                }
                            }

                            if let repo = json["public_repos"] as? Int {
                                DispatchQueue.main.sync {
                                    self.repo.text = "Repositories: \(repo)"
                                }
                            }
                            
                        }catch {
                            print("hata oluştu")
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func repo(name: String, completed: @escaping () -> ()) {
        
        if let url = URL(string: "https://api.github.com/users/\(name)/repos") {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error == nil {
                    
                    do {
                        self.repoNames = try JSONDecoder().decode([RepoDetail].self, from: data!)
                        DispatchQueue.main.async {
                            completed()
                        }
                        
                    }catch {
                        print("hata oluştu")
                    }
                    
                }
            }
            task.resume()
        }
    }
}


extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repoNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "repoCell") as! RepoTableViewCell
        
        let repo = repoNames[indexPath.row].name
        let lang = repoNames[indexPath.row].language
        let star = repoNames[indexPath.row].stargazers_count
        let date = repoNames[indexPath.row].created_at
        
        let dateString = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString2 = dateFormatter.date(from: dateString!)
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        let dateNew = dateFormatter.string(from: dateString2!)
        
        cell.nameLabel.text = repo
        cell.langLabel.text = lang
        cell.starLabel.text = String(star!)
        cell.dateLabel.text = dateNew
        
        cell.view.layer.cornerRadius = 8
        cell.view.layer.borderWidth = 1
        cell.view.layer.borderColor = UIColor(red: 232/255, green: 232/255, blue: 235/255, alpha: 0.5).cgColor
        
        return cell
    }

}
