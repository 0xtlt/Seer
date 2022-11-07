//
//  Extensions.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import Foundation

extension String {
    
    func isValidName() -> Bool {
        if self.isEmpty {
            return false
        }
        let nameRegex = #"^[\w+\-]*$"#
        return self.range(of: nameRegex, options: [.regularExpression]) != nil
    }
    
}
