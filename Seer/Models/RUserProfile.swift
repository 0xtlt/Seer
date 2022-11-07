//
//  RUserProfile.swift
//  Seer
//
//  Created by Jacob Davis on 11/2/22.
//

import Foundation
import RealmSwift

class RUserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var publicKey: String
    @Persisted var name: String
    @Persisted var about: String
    @Persisted var picture: String
    @Persisted var createdAt: Date
    var avatarUrl: URL? {
        if picture.isEmpty {
            return URL(string: "https://avatars.dicebear.com/api/micah/:\(publicKey).png")
        }
        return URL(string: picture)
    }
}

extension RUserProfile {
    
    static func createEmpty(withPublicKey publicKey: String) -> RUserProfile {
        return RUserProfile(value: ["publicKey": publicKey])
    }
    
    static let preview = RUserProfile(value: [
        "publicKey": "lasdfjenandlfieasdnf",
        "name": "Zao",
        "about": "Founder and CEO at Galaxoid Labs. Working on lots of cool stuff around Bitcoin.",
        "picture": "",
        "createdAt": Date(),
    ])
}
