//
//  AddNewPostTableViewController.swift
//  Continuum
//
//  Created by tyson ericksen on 12/10/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import UIKit

class AddNewPostTableViewController: UITableViewController {
    
    @IBOutlet weak var captionTextField: UITextField!
    
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captionTextField.text = nil
    }

    @IBAction func addButtonTapped(_ sender: UIButton) {
        
        guard let photo = selectedImage, let caption = captionTextField.text else { return }
        PostController.shared.createPostWith(photo: photo, caption: caption) { (post) in }
        self.tabBarController?.selectedIndex = 0    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.tabBarController?.selectedIndex = 0
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPhotoSelectorVC" {
            let photoSelector = segue.destination as? PhotoSelectorViewController
            photoSelector?.delegate = self
        }
    }
}

extension AddNewPostTableViewController : PhotoSelectorViewControllerDelegate {
    func photoSelectorViewControllerSelected(image: UIImage) {
        selectedImage = image
    }
}
