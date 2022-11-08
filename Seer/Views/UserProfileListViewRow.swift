//
//  UserProfileListViewRow.swift
//  Seer
//
//  Created by Jacob Davis on 11/7/22.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct UserProfileListViewRow: View {
    
    @ObservedRealmObject var userProfile: RUserProfile
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            AnimatedImage(url: userProfile.avatarUrl)
                .placeholder {
                    Color.secondary.opacity(0.2)
                        .overlay(
                            Image(systemName: "person.fill")
                                .imageScale(.large)
                        )
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(
                    Color.secondary.opacity(0.2)
                )
                .frame(width: 40, height: 40)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 0) {
                
                HStack(spacing: 8) {
                    if let name = userProfile.name, name.isValidName() {
                        Text("@"+name)
                            .font(.system(.subheadline, weight: .bold))
                    }
                    HStack(alignment: .top, spacing: 2) {
                        Image(systemName: "key.fill")
                            .imageScale(.small)
                        Text(userProfile.publicKey.prefix(8))
                    }
                    .font(.system(.caption))
                    .foregroundColor(.secondary)
                }
                
                if let about = userProfile.aboutFormatted {
                    Text(about)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .font(.subheadline)
                }

            }
        }
        .padding(.top, 8)
    }
}

struct UserProfileNavigationTitle: View {
    
    @ObservedRealmObject var userProfile: RUserProfile
    
    var body: some View {
        HStack {
            AnimatedImage(url: userProfile.avatarUrl)
                .placeholder {
                    Color.secondary.opacity(0.2)
                        .overlay(
                            Image(systemName: "person.fill")
                                .imageScale(.large)
                        )
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(
                    Color.secondary.opacity(0.2)
                )
                .frame(width: 25, height: 25)
                .cornerRadius(4)
            
            HStack(spacing: 4) {
                if let name = userProfile.name, name.isValidName()  {
                    Text(name)
                        .font(.system(.subheadline, weight: .bold))
                }
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "key.fill")
                        .imageScale(.small)
                    Text(userProfile.publicKey.prefix(8))
                }
                .font(.system(.caption, weight: .bold))
                .foregroundColor(.secondary)
            }
        }
    }
}

struct UserProfileListViewRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List {
                UserProfileListViewRow(userProfile: RUserProfile.preview)
            }
            .listStyle(.plain)
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
