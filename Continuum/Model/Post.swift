//
//  Post.swift
//  Continuum
//
//  Created by tyson ericksen on 12/10/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import UIKit
import CloudKit

class Post {
    var photoData: Data?
    var caption: String
    var timestamp: Date
    var comments: [Comment]
    var commentCount: Int
    let recordID: CKRecord.ID
    var photo: UIImage? {
        get {
            guard let photoData = photoData else { return nil }
            return UIImage(data: photoData)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.5)
        }
    }
    var imageAssest: CKAsset? {
        get {
            let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            let fileURL = tempDirectoryURL.appendingPathComponent(recordID.recordName).appendingPathExtension("jpg")
            do {
                try photoData?.write(to: fileURL)
            } catch let error {
                print("Error", error.localizedDescription)
            }
            return CKAsset(fileURL: fileURL)
        }
    }
    
    init(photo: UIImage?, caption: String, timestamp: Date = Date(), comments: [Comment] = [], recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), commentCount: Int = 0) {
        self.caption = caption
        self.comments = comments
        self.timestamp = timestamp
        self.recordID = recordID
        self.commentCount = commentCount
    }
}

extension Post {
    convenience init?(ckRecord: CKRecord) {
        guard let caption = ckRecord[PostStrings.captionKey] as? String,
            let timeStamp = ckRecord[PostStrings.timeStampKey] as? Date,
            let photoAsset = ckRecord[PostStrings.photoKey] as? CKAsset,
            let commentCount = ckRecord[PostStrings.commentCountKey] as? Int else { return nil }
        
        var foundPhoto: UIImage?
        if let photoAsset = ckRecord[PostStrings.photoKey] as? CKAsset {
            do {
                if let fileURL = photoAsset.fileURL {
                    let data = try Data(contentsOf: fileURL)
                    foundPhoto = UIImage(data: data)
                }
            } catch {
                print("error", error.localizedDescription)
            }
        }
        self.init(photo: foundPhoto, caption: caption, timestamp: timeStamp, recordID: ckRecord.recordID, commentCount: commentCount)
    }
}

extension CKRecord {
    convenience init(post: Post) {
        self.init(recordType: "Post", recordID: post.recordID)
        self.setValue(post.caption, forKey: PostStrings.captionKey)
        self.setValue(post.timestamp, forKey: PostStrings.timeStampKey)
        self.setValue(post.imageAssest, forKey: PostStrings.photoKey)
        self.setValue(post.commentCount, forKey: PostStrings.commentCountKey)
    }
}

extension Post : SearchableRecord {
    func matches(searchTerm: String) -> Bool {
        if caption.contains(searchTerm) {
            return true
        } else {
            for comment in comments {
                if comment.matches(searchTerm: searchTerm) {
                    return true
                }
            }
        }
        return false
    }
}

enum PostStrings {
    static let postTypeKey = "Post"
    static let captionKey = "caption"
    static let timeStampKey = "timeStamp"
    static let commentsKey = "comments"
    static let photoKey = "photo"
    static let commentCountKey = "commentCount"
}
