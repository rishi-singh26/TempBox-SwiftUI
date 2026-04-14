//
//  AppUpdateView.swift
//  TempBox
//
//  Created by Rishi Singh on 14/04/26.
//

import SwiftUI

struct AppUpdateView: View {
    var appInfo: VersionCheckService.ReturnResult
    var forcedUpdate: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(.white)
                .padding()
                .background(Color.accentColor.gradient, in: .rect(cornerRadius: 20))
                .padding(.top, 30)

            VStack(spacing: 8) {
                Text("App Update Available")
                    .font(.title.bold())

                Text("There is an update available from \n**`v\(appInfo.currentVersion)`** to **`v\(appInfo.availableVersion)`**!")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 5)

            VStack(spacing: 8) {
                if let _ = URL(string: appInfo.appURL) {
                    if #available(iOS 26.0, macOS 26.0, *) {
                        Button(action: update, label: updateBtnLabel)
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.capsule)
                    } else {
                        Button(action: update, label: updateBtnLabel)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                    }
                }

                if !forcedUpdate {
                    Button {
                        dismiss()
                    } label: {
                        Text("No Thanks!")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .padding(.horizontal, 20)
        .padding(.bottom, isiOS26 ? 10 : 0)
        .presentationDetents(forcedUpdate ? [.height(340)] : [.height(390)])
        .interactiveDismissDisabled(forcedUpdate)
        .scrollContentBackground(.hidden)
        .ignoresSafeArea(.all, edges: isiOS26 ? .all : [])
    }

    private var isiOS26: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }

    private func updateBtnLabel() -> some View {
        Text("Update App")
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }

    private func update() {
        if let appURL = URL(string: appInfo.appURL) {
            openURL(appURL)
        }

        if !forcedUpdate {
            dismiss()
        }
    }
}
