//
//  RContactList.swift
//  Seer
//
//  Created by Jacob Davis on 11/5/22.
//

import Foundation
import RealmSwift

class RContactList: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var publicKey: String
    @Persisted var following: List<RUserProfile>
    @Persisted var followedBy: List<RUserProfile>
}

extension RContactList {
    
    static func createEmpty(withPublicKey publicKey: String) -> RContactList {
        return RContactList(value: ["publicKey": publicKey])
    }
    
    static let preview = RContactList(value: [
        "publicKey": "lasdfjenandlfieasdnf",
        "following": [RUserProfile.preview],
        "followedBy": [RUserProfile.preview]
    ])

}
