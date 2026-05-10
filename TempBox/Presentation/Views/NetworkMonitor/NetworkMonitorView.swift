//
//  NetworkMonitorView.swift
//  TempBox
//
//  Created by Rishi Singh on 23/04/26.
//

import SwiftUI

struct NetworkMonitorView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            #if os(macOS)
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .padding(.bottom, -10)
            #endif
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(height: 100)
            
            Text("No Internet Connectivity")
                .font(.title3)
            
            Text("Please check your internet connection\nto continue using the app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .lineLimit(2)
            
            Text("Waiting for internet connection...")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .padding(.top, 10)
                .padding(.horizontal, -20)
        }
        .fontDesign(.rounded)
        .frame(height: 310)
    }
}

#Preview {
    let emails = ["temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm",
                  "temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm",
                  "temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm",
                  "temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm",
                  "temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm",
                  "temp_abc123@mail.tm", "disposable_xyz@mail.tm", "burner_456@mail.tm"
    ]
    List {
        ForEach(emails, id: \.self) { email in
            Text(email)
        }
    }
    .sheet(isPresented: .constant(true)) {
        NetworkMonitorView()
            .presentationDetents([.height(310)])
    }
}
