//
//  RemoteDataManager.swift
//  TempBox
//
//  Created by Rishi Singh on 20/07/25.
//

import Foundation
import Combine

// Data models
struct IconPreviewData: Codable {
    let iconCount: Int
    let icons: [IconPreview]
}

struct IconPreview: Codable, Identifiable {
    let id: Int
    let name: String
    let title: String
    let path: String

    var imageURL: URL? {
        URL(string: path)
    }
}

struct AppUpdate: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
}

class RemoteDataManager: ObservableObject {
    @Published var iconPreviews: [IconPreview] = []
    @Published var appUpdates: [AppUpdate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - URLs
    private let iconPreviewsURL = URL(string: "https://raw.githubusercontent.com/rishi-singh26/TempBox-SwiftUI/refs/heads/database/database/iconpreviews/content.json")!
    private let appUpdatesURL = URL(string: "https://raw.githubusercontent.com/rishi-singh26/TempBox-SwiftUI/refs/heads/database/database/notifications/appUpdates.json")!
    
    // MARK: - Generic Fetcher
    // MARK: - Generic Async Fetcher
    private func fetch<T: Decodable>(from url: URL, as type: T.Type) async throws -> T {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(T.self, from: data)

            await MainActor.run {
                isLoading = false
            }

            return decoded
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func getRemoteData() {
        Task {
            await fetchIconPreviews()
            await fetchAppUpdates()
        }
    }
    
    // MARK: - Public Fetch Methods
    private func fetchIconPreviews() async {
        do {
            let previewData: IconPreviewData = try await fetch(from: iconPreviewsURL, as: IconPreviewData.self)
            await MainActor.run {
                self.iconPreviews = previewData.icons
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("Error fetching icon previews: \(error)")
        }
    }
    
    private func fetchAppUpdates() async {
        do {
            let updates: [AppUpdate] = try await fetch(from: appUpdatesURL, as: [AppUpdate].self)
            await MainActor.run {
                self.appUpdates = updates
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("Error fetching app updates: \(error)")
        }
    }
}
