//
//  LocalizationHelper.swift
//  SC-Voice
//
//  Created by Visakha on 22/10/2025.
//

import Foundation

extension String {
    /// Localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localized version with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
