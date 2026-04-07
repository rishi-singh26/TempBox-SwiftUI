//
//  URLExtension.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI

extension URL {
    func open() {
#if os(macOS)
        NSWorkspace.shared.open(self)
#else
        UIApplication.shared.open(self)
#endif
    }
}
