//
//  MembersTableViewCell.swift
//  HipoLabsIOSAssignment
//
//  Created by Cengizhan Tomak on 19.04.2023.
//

import UIKit

class MembersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var view: UIView!
    //名称label
    @IBOutlet weak var nameLabel: UILabel!
    //地点label
    @IBOutlet weak var positionLabel: UILabel!
    //年label
    @IBOutlet weak var yearsLabel: UILabel!
    //背景色
    var originalBackgroundColor: UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = UIColor.systemGray4
        })
        
        if let tableView = superview as? UITableView,
           let indexPath = tableView.indexPath(for: self) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor.systemGray4
            })
            
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = self.originalBackgroundColor
            })
        }
    }
    
}
