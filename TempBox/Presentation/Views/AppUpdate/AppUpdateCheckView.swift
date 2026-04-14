//
//  AppUpdateCheckView.swift
//  TempBox
//
//  Created by Rishi Singh on 14/04/26.
//

import SwiftUI

struct AppUpdateCheckView: View {
    @State private var updateAppInfo: VersionCheckService.ReturnResult?
    @State private var forcedUpdate: Bool = false

    var body: some View {
        ContentView()
            .sheet(item: $updateAppInfo) { info in
                AppUpdateView(appInfo: info, forcedUpdate: forcedUpdate)
            }
            .task {
                if let result = await VersionCheckService.shared.checkIfAppUpdateAvailable() {
                    updateAppInfo = result
                }
            }
    }
}
