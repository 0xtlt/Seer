//
//  ProfileDetailView.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct ProfileDetailView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @EnvironmentObject var navigation: Navigation
    
    @ObservedRealmObject var userProfile: RUserProfile
    
    @ObservedResults(RContactList.self) var contactLists

    @State private var showTitle: Bool = false
    
    var contactList: RContactList? {
        return contactLists.filter("publicKey = %@", userProfile.publicKey).first
    }
    
    var body: some View {
        
        ScrollViewReader { reader in
            
            List {
                
                LazyVStack {
                    HStack(alignment: .top) {
                        AnimatedImage(url: userProfile.avatarUrl)
                            .placeholder {
                                Color.secondary.opacity(0.2)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .imageScale(.large)
                                    )
                            }
                            .resizable()
                            .background(
                                Color.secondary.opacity(0.2)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .imageScale(.large)
                                    )
                            )
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let name = userProfile.name, name.isValidName() {
                                Text("@"+name)
                                    .font(.system(.title3, weight: .bold))
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "key.fill")
                                Text(userProfile.publicKey)
                            }
                            .font(.system(.caption))
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer(minLength: 16)
                    
//                    Divider()
//                        .padding(.vertical, 4)
                    
                    HStack {
                        Button(action: {}) {
                            Text("Follow")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {}) {
                            Image(systemName: "text.bubble")
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding(.leading, 72)

                    if let about = userProfile.about, !about.isEmpty, let markdown = try? AttributedString(markdown: about) {
                        
                        Spacer(minLength: 16)
//                        Divider()
//                            .padding(.vertical, 4)
                        
                        Text(markdown)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .font(.body)
                    }

    
                    Divider()
                        .padding(.vertical, 4)

                    if let contactList {
                        HStack(spacing: 12) {
                            Button(action: {
                                if contactList.following.count > 0 {
                                    self.navigation.homePath.append(Navigation.NavFollowing(userProfile: userProfile))
                                }
                            }) {
                                Text("Following")
                                    .foregroundColor(.secondary)
                                +
                                Text(" \(contactList.following.count)")
                                
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                if contactList.followedBy.count > 0 {
                                    self.navigation.homePath.append(Navigation.NavFollowers(userProfile: userProfile))
                                }
                            }) {
                                Text("Followers")
                                    .foregroundColor(.secondary)
                                +
                                Text(" \(contactList.followedBy.count)")
                                Spacer()
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        
                    }

                }
                .padding()
                .cardStyle()
                .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                    value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                .onPreferenceChange(ViewOffsetKey.self) {
                    if $0 > -50 {
                        showTitle = true
                    } else {
                        showTitle = false
                    }
                }

            }
            .listStyle(.plain)
#if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("")
#endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    UserProfileNavigationTitle(userProfile: userProfile)
                        .opacity(showTitle ? 1.0 : 0)
                }
            }
            .coordinateSpace(name: "scroll")
            
        }
        .task {
            nostrData.fetchContactList(forPublicKey: userProfile.publicKey)
        }
        
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileDetailView(userProfile: RUserProfile.preview)
                .environmentObject(NostrData.shared)
                .environmentObject(Navigation())
        }
        
    }
}
