//
//  ViewModifiers.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import Foundation
import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("CardBack"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .listRowSeparator(.hidden)
        #if os(iOS)
            .listRowBackground(Color(UIColor.systemGroupedBackground))
        #endif
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
