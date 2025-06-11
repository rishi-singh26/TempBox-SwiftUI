//
//  AppColorView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct AppColorView: View {
    var body: some View {
        HStack {
            Image(systemName: "gear")
            Image(systemName: "wrench")
            Image(systemName: "hammer")
        }
        Text("Under Construction!")
            .font(.body)
    }
}

#Preview {
    AppColorView()
}
