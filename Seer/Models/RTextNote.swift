//
//  RTextNote.swift
//  Seer
//
//  Created by Jacob Davis on 11/2/22.
//

import Foundation
import RealmSwift

class RTextNote: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var eventId: String
    @Persisted var publicKey: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    
    @Persisted var userProfile: RUserProfile?
    @Persisted var rootReply: RTextNote?
    @Persisted var reply: RTextNote?
}

class TextNoteVM: Projection<RTextNote>, ObjectKeyIdentifiable {
    @Projected(\RTextNote.publicKey) var publicKey
    @Projected(\RTextNote.content) var content
    @Projected(\RTextNote.createdAt) var createdAt
    @Projected(\RTextNote.userProfile) var userProfile
    @Projected(\RTextNote.rootReply) var rootReply
    @Projected(\RTextNote.reply) var reply
}
