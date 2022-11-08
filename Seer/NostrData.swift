//
//  NostrData.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import Foundation
import NostrKit
import RealmSwift

class NostrData: ObservableObject {

    var nostrRelays: [NostrRelay] = []
    
    let realm: Realm
    static let shared = NostrData()
    
    private init() {
        let config = Realm.Configuration(schemaVersion: 7)
        Realm.Configuration.defaultConfiguration = config
        self.realm = try! Realm()
        self.realm.autorefresh = true
        bootstrapRelays()
    }
    
    func initPreview() -> NostrData {
//        userProfiles = [UserProfile.preview]
//        textNotes = [TextNote.preview]
        return .shared
    }
    
    func bootstrapRelays() {
        self.nostrRelays.append(NostrRelay(urlString: "wss://relay.damus.io", realm: realm))
        //self.nostrRelays.append(NostrRelay(urlString: "wss://nostr-pub.wellorder.net", realm: realm))
        for relay in nostrRelays {
            relay.connect()
        }
    }
    
    func disconnect() {
        for relay in nostrRelays {
            relay.unsubscribe()
            relay.disconnect()
        }
    }
    
    func reconnect() {
        for relay in nostrRelays {
            if !relay.connected {
                relay.connect()
            }
        }
    }
    
    func fetchContactList(forPublicKey publicKey: String) {
        for relay in nostrRelays {
            relay.subscribeContactList(forPublicKey: publicKey)
        }
    }
}
