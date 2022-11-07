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
            relay.fetchContactList(forPublicKey: publicKey)
        }
    }
}

class NostrRelay: NSObject {
    
    struct SetMetaDataEventData: Codable {
        var name: String?
        var about: String?
        var picture: String?
    }
    
    let urlString: String
    let realm: Realm
    
    var webSocketTask: URLSessionWebSocketTask?
    var connected = false
    var pingTimer: Timer?
    var retryCount = 0
    var maxRetries = 5
    
    var subs: Int = 0
    
    var authors: Set<String> = []
    
    var tempProfiles: [RUserProfile] = []
    var tempTextNotes: [RTextNote] = []
    
    var lastSeenTextNoteTimestamp: Timestamp?
    var bootstrapedProfiles = false
    var bootstrapedTextNotes = false
    
    var textNoteSub: Subscription?
    var profileSub: Subscription?
    
    var contactListSubs: [ContactListSub] = []
    
    let decoder = JSONDecoder()
    
    init(urlString: String, realm: Realm) {
        self.urlString = urlString
        self.realm = realm
    }
    
    func connect() {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.webSocketTask = session.webSocketTask(with: request)
            self.webSocketTask?.resume()
            self.receiveMessage()
        }
    }
    
    func needsProfileSub() -> Bool {
        if !authors.isEmpty {
            if let currentAuthors = self.profileSub?.filters.first.map({ $0.authors }) ?? [] {
                if authors != Set(currentAuthors) {
                    return true
                }
            }
        }
        return false
    }

    func subscribeProfiles() {
//        let posts = self.realm.objects(RTextNote.self).filter({ $0.createdAt > Date().addingTimeInterval(-86400) })
//        self.authors = Set(posts.map({ $0.publicKey }))
        self.authors = Set(Array(self.realm.objects(RUserProfile.self).map({ $0.publicKey })))

        if needsProfileSub() {
            if profileSub != nil {
                unsubscribeProfiles()
            }
            print("Subed profiles of count \(self.authors.count)")
            self.profileSub = Subscription(filters: [
                .init(authors: Array(authors), eventKinds: [.setMetadata])
            ])
            if let profileSub {
                if let cm = try? ClientMessage.subscribe(profileSub).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error = error {
                            print(error)
                        }
                    })
                }
            }
        }
    }

    func unsubscribeProfiles() {
        if let profileSub = profileSub, connected {
            if let cm = try? ClientMessage.unsubscribe(profileSub.id).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error = error {
                        print(error)
                    }
                })
            }
        }
    }
    
    func subscribeTextNotes() {
        if textNoteSub != nil {
            unsubscribeTextNotes()
        }
        
        let since = lastSeenTextNoteTimestamp ?? Timestamp(date: Date().addingTimeInterval(-86400))
        self.textNoteSub = Subscription(filters: [
            .init(eventKinds: [.textNote], since: since, limit: 100)
        ])
        
        if let textNoteSub, connected {
            if let cm = try? ClientMessage.subscribe(textNoteSub).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error {
                        print(error)
                    }
                })
            }
        }
    }
    
    func unsubscribeTextNotes() {
        if let textNoteSub = textNoteSub, connected {
            if let cm = try? ClientMessage.unsubscribe(textNoteSub.id).string() {
                self.webSocketTask?.send(.string(cm), completionHandler: { error in
                    if let error {
                        print(error)
                    }
                })
            }
        }
    }
    
    struct ContactListSub {
        let subscription: Subscription
        let subType: String
        var publicKey: String
        var publicKeys: Set<String>
    }
    
    func fetchContactList(forPublicKey publicKey: String) {
        if connected {
            
            let subs = self.contactListSubs.filter({ $0.publicKey == publicKey })
            
            for sub in subs {
                if let followingSub = try? ClientMessage.unsubscribe(sub.subscription.id).string() {
                    self.webSocketTask?.send(.string(followingSub), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            
            self.contactListSubs.removeAll(where: { $0.publicKey == publicKey })
            
            let followingSub = Subscription(filters: [.init(authors: [publicKey], eventKinds: [.custom(3)])])
            let a = ContactListSub(subscription: followingSub, subType: "following", publicKey: publicKey, publicKeys: [])
            
            let followedSub = Subscription(filters: [.init(eventKinds: [.custom(3)], pubKeyTags: [publicKey])])
            let b = ContactListSub(subscription: followedSub, subType: "followedBy", publicKey: publicKey, publicKeys: [])
            
            self.contactListSubs.append(contentsOf: [a,b])
            
            for sub in self.contactListSubs {
                if let cm = try? ClientMessage.subscribe(sub.subscription).string() {
                    print(cm)
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
        }
    }
    
    func unsubscribeContactList(withId: String) {
        if let indexOf = self.contactListSubs.firstIndex(where: { $0.subscription.id == withId }) {
            let sub = self.contactListSubs[indexOf]
            if connected {
                if let cm = try? ClientMessage.unsubscribe(sub.subscription.id).string() {
                    self.webSocketTask?.send(.string(cm), completionHandler: { error in
                        if let error {
                            print(error)
                        }
                    })
                }
            }
            self.contactListSubs.remove(at: indexOf)
        }
    }
    
    func subscribe() {
        DispatchQueue.main.async {
            self.subscribeProfiles()
            self.subscribeTextNotes()
        }
    }
    
    func unsubscribe() {
        DispatchQueue.main.async {
            self.unsubscribeProfiles()
            self.unsubscribeTextNotes()
        }
    }
    
    func disconnect() {
        self.pingTimer?.invalidate()
        self.webSocketTask?.cancel(with: .goingAway, reason: nil)
        connected = false
    }
    
    private func retryConnect() {
        if !connected {
            print("Websocket Closed")
            if retryCount < maxRetries {
                print("Trying reconnect")
                self.connect()
            } else {
                print("Giving up reconnect")
            }
        }
    }
    
    private func receiveMessage() {
        self.webSocketTask?.receive(completionHandler: { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    self?.receiveMessage()
                case .string(let messageString):
                    if let relayMessage = try? RelayMessage(text: messageString) {
                        DispatchQueue.main.async {
                            self?.parse(relayMessage)
                        }
                    }
                    self?.receiveMessage()
                @unknown default:
                    print("Unknown type received from WebSocket")
                    self?.receiveMessage()
                }
            case .failure(let error):
                self?.retryConnect()
                print(error)
            }
        })
    }
    
    private func startPing() {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
                self?.webSocketTask?.sendPing(pongReceiveHandler: { error in
                    if let error = error {
                        print("Failed with Error \(error.localizedDescription)")
                        self?.retryConnect()
                    } else {
                        // no-op
                    }
                })
            }
        }
    }
    
    private func parse(_ message: RelayMessage) {
        switch message {
        case .event(let id, let event):
            switch event.kind {
            case .setMetadata:
                do {
                    let eventData = try self.decoder.decode(SetMetaDataEventData.self, from: Data(event.content.utf8))
                    let profile = RUserProfile(value: ["publicKey": event.publicKey,
                                                       "name": eventData.name ?? "",
                                                       "about": eventData.about ?? "",
                                                       "picture": eventData.picture ?? "",
                                                       "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])

                    if self.bootstrapedProfiles {
                        realm.writeAsync {
                            self.realm.add(profile, update: .modified)
                        }
                    } else {
                        self.tempProfiles.append(profile)
                    }

                } catch {
                    print(error)
                }
            case .textNote:

                if !event.content.isEmpty {
                    let textNote = RTextNote(value: ["eventId": event.id,
                                                     "publicKey": event.publicKey,
                                                     "content": event.content,
                                                     "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])
                    @ThreadSafe var profile = realm.object(ofType: RUserProfile.self, forPrimaryKey: event.publicKey)
                    if profile != nil {
                        textNote.userProfile = profile
                    } else {
                        textNote.userProfile = RUserProfile.createEmpty(withPublicKey: event.publicKey)
                    }
                    

//                    if let reply = event.tags.first(where: { $0.id == "e" }), reply.otherInformation.count == 3 {
//                        let first = reply.otherInformation.first!
//                        let type = reply.otherInformation.last!
//                        @ThreadSafe var r = realm.object(ofType: RTextNote.self, forPrimaryKey: first)
//                        if type == "reply" {
//                            r?.reply =
//                        } else if type == "root" {
//
//                        }
//                        textNote.reply = r
//                    }

                    if self.bootstrapedTextNotes {
                        realm.writeAsync {
                            self.realm.add(textNote, update: .modified)
                        } onComplete: { err in
                            if let err {
                                print(err)
                            } else {
                                self.subscribeProfiles()
                            }
                        }
                    } else {
                        self.tempTextNotes.append(textNote)
                    }
                    self.lastSeenTextNoteTimestamp = event.createdAt
                }
            case .recommentServer:
                ()
            case .custom(let kind):
                if kind == 3 { // Contact list
                    if let contactSub = self.contactListSubs.first(where: { $0.subscription.id == id }) {
                        if let indexOf = self.contactListSubs.firstIndex(where: { $0.subscription.id == id }) {
                            if contactSub.subType == "following" {
                                self.contactListSubs[indexOf].publicKeys = Set(event.tags.compactMap({ $0.otherInformation.first }))
                            } else if contactSub.subType == "followedBy" {
                                self.contactListSubs[indexOf].publicKeys.update(with: event.publicKey)
                            }
                        }
                    }

                }
            }
        case .notice(let notice):
            print(notice)
        case .other(let others): ()
            if others.count == 2 {
                let op = others[0]
                let subscriptionId = others[1]
                if op == "EOSE" {
                    
                    if var contactSub = self.contactListSubs.first(where: { $0.subscription.id == subscriptionId }) {
                        
                        @ThreadSafe var contactList = self.realm.object(ofType: RContactList.self, forPrimaryKey: contactSub.publicKey)

                        if contactList == nil {
                            try? self.realm.write {
                                contactList = self.realm.create(RContactList.self, value: RContactList.createEmpty(withPublicKey: contactSub.publicKey))
                            }
                        }
                        
                        if let contactList {

                            if contactSub.subType == "following" {

                                self.realm.writeAsync {
                                    
                                    contactList.following.removeAll()

                                    for pubKey in contactSub.publicKeys {
                                        @ThreadSafe var profile = self.realm.object(ofType: RUserProfile.self, forPrimaryKey: pubKey)
                                        if let profile {
                                            contactList.following.append(profile)
                                        } else {
                                            let profile = self.realm.create(RUserProfile.self, value: RUserProfile.createEmpty(withPublicKey: pubKey), update: .modified)
                                            contactList.following.append(profile)
                                        }
                                    }
                                    
                                }


                            } else if contactSub.subType == "followedBy" {

                                self.realm.writeAsync {
                                    
                                    contactList.followedBy.removeAll()

                                    for pubKey in contactSub.publicKeys {
                                        @ThreadSafe var profile = self.realm.object(ofType: RUserProfile.self, forPrimaryKey: pubKey)
                                        if let profile {
                                            contactList.followedBy.append(profile)
                                        } else {
                                            let profile = self.realm.create(RUserProfile.self, value: RUserProfile.createEmpty(withPublicKey: pubKey), update: .modified)
                                            contactList.followedBy.append(profile)
                                        }
                                    }
                                }

                            }

                        }

                        print("Contact List EOSE - Sub ID: \(subscriptionId)")
                        self.unsubscribeContactList(withId: subscriptionId)
                        self.subscribeProfiles()
                        
                    }
                    
                    if subscriptionId == profileSub?.id && !self.bootstrapedProfiles {
                        
                        print("Profiles EOSE - Sub ID: \(subscriptionId)")
                        
                        self.bootstrapedProfiles = true
                        realm.writeAsync {
                            self.realm.add(self.tempProfiles, update: .modified)
                            self.tempProfiles.removeAll()
                        } onComplete: { err in
                            if let err {
                                print(err)
                            }
                        }
                    }
                    
                    if subscriptionId == textNoteSub?.id && !self.bootstrapedTextNotes {
                        
                        print("TextNotes EOSE - Sub ID: \(subscriptionId)")
                        
                        self.bootstrapedTextNotes = true
                        
                        realm.writeAsync {
                            self.realm.add(self.tempTextNotes, update: .modified)
                            self.tempTextNotes.removeAll()
                        } onComplete: { err in
                            if let err {
                                print(err)
                            } else {
                                let profiles = self.realm.objects(RUserProfile.self)
                                self.authors = Set(profiles.map({ $0.publicKey }))
                                self.subscribeProfiles()
                            }
                        }
                    }
                }
            }
        }
    }

}

extension NostrRelay: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connected = true
        authors.removeAll() // TODO:
        startPing()
        subscribe()
        retryCount = 0
        print("Websocket Opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connected = false
        print("Websocket Closed")
        print(closeCode.rawValue)
        if closeCode != .normalClosure || closeCode != .goingAway {
            retryConnect()
        }
    }
}

