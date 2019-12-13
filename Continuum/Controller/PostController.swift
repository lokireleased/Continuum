//
//  PostController.swift
//  Continuum
//
//  Created by tyson ericksen on 12/10/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import UIKit
import CloudKit

class PostController {
    
    static let shared = PostController()
    var posts: [Post] = []
    private init() {
        subscribeToNewPosts(completion: nil)
    }
    
    func addComment(text: String, post: Post, completion: @escaping (Comment?) -> Void) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        let record = CKRecord(comment: comment)
        CKContainer.default().publicCloudDatabase.save(record) { (record, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion(nil)
                return
            }
            guard let record = record else { completion(nil); return }
            let comment = Comment(ckRecord: record, post: post)
            self.incrementCommentCount(for: post, completion: nil)
            completion(comment)
        }
    }
    
    func createPostWith(photo: UIImage, caption: String, completion: @escaping (Post?) -> Void) {
        let post = Post(photo: photo, caption: caption)
        self.posts.append(post)
        let record = CKRecord(post: post)
        CKContainer.default().publicCloudDatabase.save(record) { (record, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion(nil)
                return
            }
            guard let record = record, let post = Post(ckRecord: record) else { completion(nil); return }
            completion(post)
        }
    }
    
    func fetchPosts(completion: @escaping ([Post]?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PostStrings.postTypeKey, predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion(nil)
                return
            }
            guard let records = records else { completion(nil); return }
            let posts = records.compactMap { Post(ckRecord: $0) }
            self.posts = posts
            completion(posts)
            }
        }
    func fetchComments(for post: Post, completion: @escaping ([Comment]?) -> Void) {
        let postReference = post.recordID
        let predicate = NSPredicate(format: "%K == %@", CommentStrings.postReferenceKey, postReference)
        let commentIDs = post.comments.compactMap({$0.recordID})
        let predicate2 = NSPredicate(format: "Not(recordID in %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        let query = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion(nil)
                return
            }
            guard let records = records else { completion(nil); return }
            let comments = records.compactMap{ Comment(ckRecord: $0, post: post) }
            post.comments.append(contentsOf: comments)
            completion(comments)
        }
    }
    
    func incrementCommentCount(for post: Post, completion: ((Bool) -> Void)?) {
        post.commentCount += 1
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: [CKRecord(post: post)], recordIDsToDelete: nil)
        modifyOperation.savePolicy = .changedKeys
        modifyOperation.modifyRecordsCompletionBlock = { (reords, _, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion?(false)
                return
            } else {
                completion?(true)
            }
        }
        CKContainer.default().publicCloudDatabase.add(modifyOperation)
    }
    func subscribeToNewPosts(completion: ((Bool, Error?) -> Void)?) {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Post", predicate: predicate, options: .firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "post added to app"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion?(false, error)
                
            } else {
                completion?(true, nil)
            }
        }
    }
    func addSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> Void)?) {
        let postRecordID = post.recordID
        let predicate = NSPredicate(format: "%K == %@", CommentStrings.postReferenceKey, postRecordID)
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, options: .firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "comment was added"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = nil
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> Void)?) {
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subscriptionID) { (_, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion?(false)
                return
            } else {
                completion?(true)
            }
        }
    }
    
    func checkForSubscription(to post: Post, completion: ((Bool) -> Void)?) {
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            if let error = error {
                print("error", error.localizedDescription)
                completion?(false)
                return
            }
            if subscription != nil {
                completion?(true)
            } else {
                completion?(false)
            }
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> Void)?) {
        checkForSubscription(to: post) { (isSubscribed) in
            if isSubscribed {
                self.removeSubscriptionTo(commentsForPost: post) { (success) in
                    if success {
                        print("success")
                        completion?(true, nil)
                    } else {
                        print("was not successful")
                        completion?(false, nil)
                    }
                }
            } else {
                self.addSubscriptionTo(commentsForPost: post) { (success, error) in
                    if let error = error {
                        print("error", error.localizedDescription)
                        completion?(false, error)
                        return
                    }
                    if success {
                        print("success")
                        completion?(true, nil)
                    } else {
                        print("was not successful")
                        completion?(false, nil)
                    }
                }
            }
        }
    }
}
