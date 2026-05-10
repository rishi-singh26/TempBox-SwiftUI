//
//  VersionCheckService.swift
//  TempBox
//
//  Created by Rishi Singh on 14/04/26.
//

import SwiftUI

@MainActor
class VersionCheckService {
    static let shared = VersionCheckService()

    func checkIfAppUpdateAvailable() async -> ReturnResult? {
        do {
            guard let bundleId, let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
                return nil
            }

            let data = try await URLSession.shared.data(from: lookupURL).0

            guard let rawJSON = (try JSONSerialization.jsonObject(with: data)) as? Dictionary<String, Any> else {
                return nil
            }

            guard let jsonResult = rawJSON["results"] as? [Any] else { return nil }
            guard let jsonValue = jsonResult.first as? Dictionary<String, Any> else { return nil }

            guard let availableVersion = jsonValue["version"] as? String,
                  let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                  let appLogo = jsonValue["artworkUrl512"] as? String,
                  let appURL = (jsonValue["trackViewUrl"] as? String)?.components(separatedBy: "?").first,
                  let releaseNotes = jsonValue["releaseNotes"] as? String else {
                return nil
            }

            if currentVersion.compare(availableVersion, options: .numeric) == .orderedAscending {
                return .init(
                    currentVersion: currentVersion,
                    availableVersion: availableVersion,
                    releaseNotes: releaseNotes,
                    appLogo: appLogo,
                    appURL: appURL
                )
            }

            return nil
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    private var bundleId: String? {
        Bundle.main.bundleIdentifier
    }

    struct ReturnResult: Identifiable {
        private(set) var id: String = UUID().uuidString
        var currentVersion: String
        var availableVersion: String
        var releaseNotes: String
        var appLogo: String
        var appURL: String
    }
}
