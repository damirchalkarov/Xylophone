//
//  RecordTableViewCell.swift
//  Xylophone
//
//  Created by Damir Chalkarov on 04.11.2024.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    @IBOutlet weak var recordTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
