//
//  GameCell.swift
//  TictactoeApp
//
//  Created by Aleksandr Pavliuk on 9/19/17.
//  Copyright © 2017 AP. All rights reserved.
//

import UIKit

class GameCell: UICollectionViewCell {
    
    var mark: Mark?
    @IBOutlet weak var markImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = UIColor.white
        
    }
}
