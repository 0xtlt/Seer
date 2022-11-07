//
//  FollowedByView.swift
//  Seer
//
//  Created by Jacob Davis on 11/7/22.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct FollowersView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @ObservedRealmObject var userProfile: RUserProfile
    @ObservedResults(RContactList.self) var contactLists

    var followedBy: [RUserProfile] {
        if let followedBy = contactLists.filter("publicKey = %@", userProfile.publicKey).first?.followedBy {
            return Array(followedBy.sorted(byKeyPath: "name", ascending: false))
        }
        return  []
    }

    var body: some View {
        List {

            Section("Followers") {
                
                ForEach(followedBy) { userProfile in
                    
                    NavigationLink(value: Navigation.NavUserProfile(userProfile: userProfile)) {
                        UserProfileListViewRow(userProfile: userProfile)
                    }
                    .id(userProfile.publicKey)
                }
                
            }

        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                UserProfileNavigationTitle(userProfile: userProfile)
            }
        }
    }
}

struct FollowersView_Previews: PreviewProvider {
    static var previews: some View {
        FollowersView(userProfile: RUserProfile.createEmpty(withPublicKey: "abc"))
            .environmentObject(NostrData.shared)
    }
}
