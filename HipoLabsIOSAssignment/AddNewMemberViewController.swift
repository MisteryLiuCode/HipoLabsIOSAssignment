//
//  AddNewMemberViewController.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 19.04.2023.
//

import UIKit
import CoreData
import SystemConfiguration
import CoreLocation
import Alamofire
class AddNewMemberViewController: UIViewController {
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var githubView: UIView!
    @IBOutlet weak var PositionView: UIView!
    @IBOutlet weak var YearsView: UIView!
    
    //地点名称
    @IBOutlet weak var nameText: UITextField!
    //提醒半径
    @IBOutlet weak var githubText: UITextField!
    //经纬度信息
    @IBOutlet weak var positionText: UITextField!
    //预留字段
    @IBOutlet weak var yearsText: UITextField!
    
    @IBOutlet weak var addButtonOutlet: UIButton!
    
    var locationManager: CLLocationManager?
    var myCurrentLocation: CLLocationCoordinate2D?
    var updatingLocationValue : CLLocationCoordinate2D?
    let userId=getUserId();
    
    @IBAction func desLocationBt(_ sender: Any) {
        print("点击位置获取")
        //0:更新家方向地铁下车位置 1:获取上班方向地铁下车位置
        guard let unwrappedLocation = updatingLocationValue else { return }
        let latitude=unwrappedLocation.latitude
        let longitude=unwrappedLocation.longitude
        print("获取的位置为：\(longitude),\(latitude)")
        positionText!.text="\(longitude),\(latitude)"
        textFieldDidChange()
    }
    
    
    let context = appDelegate.persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //获取用户位置
        getUserLocation()
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
            let alert = UIAlertController(title: "提示", message: "没有互联网连接", preferredStyle: .alert)
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
    
    //网络是否可用
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
    
    //返回
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //添加按钮,调用接口添加
    @IBAction func addButton(_ sender: Any) {
        //校验字段
        guard Int(yearsText.text!) != nil else {
            showAlert(title: "Error", message: "Please enter a valid number for years.")
            return
        }
        //校验字段
        guard let githubUser = githubText.text, !githubUser.isEmpty else {
            showAlert(title: "Error", message: "Please enter GitHub Username.")
            return
        }
        
        //发送请求，保存信息
        let saveLocationReq: Parameters = [
            "userId": userId,
            "locationDesCn": nameText.text!,
            "locationDes": positionText.text!,
        ]
        AF.request("http://\(kHost):\(kPort)/saveLocation", method: .post, parameters: saveLocationReq)
            .responseJSON { response in
                if case .success(let value) = response.result {
                    if let json = value as? [String: Any],
                       let responseData = try? JSONDecoder().decode(Res<Int>.self, from: JSONSerialization.data(withJSONObject: json)) {
                        // 获取response data
                        if responseData.retCode=="0000"{
                            let saveResult = responseData.busBody
                            print("保存位置状态：\(saveResult)")
                            if(saveResult==1){
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
                            //                            if(distance==0){
                            //                                self.delegate?.updateDestination("距离目的地:请先采集位置信息")
                            //                            }else{
                            //                                self.delegate?.updateDestination("距离目的地:\(distance as! Double/1000)千米")
                            //                            }
                        }
                    }
                }
            }
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
    //初始化位置权限
    func getUserLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.startUpdatingLocation()
    }
    
    
}
extension AddNewMemberViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.updatingLocationValue = locValue
        guard let unwrappedLocation = myCurrentLocation else {
            myCurrentLocation = locValue
            return
        }
        //get distance between locValue and myCurrentLocation
        let currentCoordinates = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        let previousCoordinates = CLLocation(latitude: unwrappedLocation.latitude, longitude: unwrappedLocation.longitude)
        let distance = currentCoordinates.distance(from: previousCoordinates)
    }
}
