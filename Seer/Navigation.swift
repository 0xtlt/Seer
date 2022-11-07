//
//  Navigation.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import Foundation
import SwiftUI

class Navigation: ObservableObject {
    
    @Published var homePath = NavigationPath()
    
    struct NavUserProfile: Hashable {
        let userProfile: RUserProfile
    }
    
    struct NavFollowing: Hashable {
        let userProfile: RUserProfile
    }
    
    struct NavFollowers: Hashable {
        let userProfile: RUserProfile
    }
    
}
