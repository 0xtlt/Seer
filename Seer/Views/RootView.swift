//
//  RootView.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @State private var selection = 0
    
    var selectionHandler: Binding<Int> { Binding(
        get: { self.selection },
        set: {
            if $0 == self.selection {
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("HomeTapped"), object: nil)
            }
            self.selection = $0
        }
    )}
    
    var body: some View {

        TabView(selection: selectionHandler) {
            
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
                .tag(0)
//                .badge(appState.updatedPosts.count)

            Text("Messages")
                .tabItem {
                    Image(systemName: "envelope")
                }
                .tag(1)
            
            Text("Notifications")
                .tabItem {
                    Image(systemName: "bell")
                }
                .tag(2)
            
            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape")
                }
                .tag(3)
            
        }
        
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
