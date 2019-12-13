//
//  PostDetailTableViewController.swift
//  Continuum
//
//  Created by tyson ericksen on 12/10/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var followPostButton: UIButton!
    @IBOutlet weak var buttonStackView:  UIStackView!
    
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let post = post else { return }
        PostController.shared.fetchComments(for: post) { (_) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func commentButtonTapped(_ sender: UIButton) {
        presentCommentAlert()
    }
        
    func presentCommentAlert() {
        let alertController = UIAlertController(title: "Comment", message: "Would you like to leave a comment?", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.autocorrectionType = .yes
            textField.placeholder = "comments digested here."
        }
        
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        alertController.addAction(cancelAction)
            
            let commentAction = UIAlertAction(title: "Comment", style: .default) { (_) in
                guard let commentText = alertController.textFields?.first?.text, !commentText.isEmpty, let post = self.post else { return }
                PostController.shared.addComment(text: commentText, post: post) { (comment) in }
                self.tableView.reloadData()
            }
            alertController.addAction(commentAction)
            self.present(alertController, animated: true)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let comment = post?.caption else { return }
        let shareSheet = UIActivityViewController(activityItems: [comment], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
    }
    @IBAction func followButtonTapped(_ sender: UIButton) {
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (success, error) in
            if let error = error {
                print("error", error.localizedDescription)
                return
            }
            self.updateFollowPostButtonText()
        }
    }
    
    func updateViews() {
        guard let post = post else { return }
        photoImageView.image = post.photo
        tableView.reloadData()
        updateFollowPostButtonText()
    }
    
    func updateFollowPostButtonText() {
        guard let post = post else { return }
        PostController.shared.checkForSubscription(to: post) { (found) in
            DispatchQueue.main.async {
                let followPostButtonText = found ? "Unfollow Post" : "Follow Post"
                self.followPostButton.setTitle(followPostButtonText, for: .normal)
                self.buttonStackView.layoutIfNeeded()
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postDetailCell", for: indexPath)

        let comment = post?.comments[indexPath.row]
        cell.textLabel?.text = comment?.text
        cell.detailTextLabel?.text = comment?.timeStamp.formattedString()

        return cell
    }
}
