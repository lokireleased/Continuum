//
//  Comment.swift
//  Continuum
//
//  Created by tyson ericksen on 12/12/19.
//  Copyright © 2019 tyson ericksen. All rights reserved.
//

import Foundation
import CloudKit

class Comment {
    var text: String
    var timeStamp: Date
    weak var post: Post?
    let recordID: CKRecord.ID
    var postReference: CKRecord.Reference? {
        guard let post = post else { return nil }
        return CKRecord.Reference(recordID: post.recordID, action: .deleteSelf)
    }
    
    init(text: String, timeStamp: Date = Date(), post: Post, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.text = text
        self.timeStamp = timeStamp
        self.post = post
        self.recordID = recordID
    }
}

extension Comment {
    convenience init?(ckRecord: CKRecord, post: Post) {
        guard let text = ckRecord[CommentStrings.textKey] as? String, let timeStamp = ckRecord[CommentStrings.timeStampKey] as? Date else { return nil }
        self.init(text: text, timeStamp: timeStamp, post: post, recordID: ckRecord.recordID)
    }
}

extension CKRecord {
    convenience init(comment: Comment) {
        self.init(recordType: CommentStrings.recordType, recordID: comment.recordID)
        self.setValue(comment.postReference, forKey: CommentStrings.postReferenceKey)
        self.setValue(comment.text, forKey: CommentStrings.textKey)
        self.setValue(comment.timeStamp, forKey: CommentStrings.timeStampKey)
    }
}

extension Comment : SearchableRecord {
    func matches(searchTerm: String) -> Bool {
        return text.contains(searchTerm)
    }
}

enum CommentStrings {
    static let recordType = "Comment"
    static let textKey = "text"
    static let timeStampKey = "timeStamp"
    static let postReferenceKey = "post"
}
