//
//  FolderCell.swift
//  TableView_part_3
//
//  Created by Harbros47 on 5.02.21.
//

import UIKit

class FolderCell: UITableViewCell {
    
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var folderSizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
