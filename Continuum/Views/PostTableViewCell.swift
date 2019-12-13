//
//  PostTableViewCell.swift
//  Continuum
//
//  Created by tyson ericksen on 12/10/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

 
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
  
    func updateViews() {
        photoImageView.image = post?.photo
        captionLabel.text = post?.caption
        commentLabel.text = "Comments: \(post?.commentCount ?? 0)"
    }
}
