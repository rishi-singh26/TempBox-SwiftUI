//
//  AppIconView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

#if os(iOS)
import SwiftUI

@MainActor
struct AppIconView: View {
    static private let defaultIconName = "AppIcon"
    
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var remoteDataManager: RemoteDataManager
    
    @State private var currentIcon = UIApplication.shared.alternateIconName ?? Self.defaultIconName
    @State private var alternateIconsSupported: Bool = true
    @State private var showTipJarAlert: Bool = false
    
    init() {
        if !UIApplication.shared.supportsAlternateIcons {
            _alternateIconsSupported = State(wrappedValue: false)
        }
    }
    
    private let columns = [GridItem(.adaptive(minimum: 125, maximum: 1024))]
    
    var body: some View {
        List {
            if !alternateIconsSupported {
                Section {
                    Text("Custom Icons are not supported on your device!")
                }
            }
            if alternateIconsSupported && !iapManager.hasTipped {
                Section {
                    Text(KAppIconTipJarMessage)
                }
            }
            ForEach(remoteDataManager.iconPreviews) { preview in
                Button{
                    handleIconSelection(selected: preview)
                } label: {
                    IconTileBuilder(preview: preview)
                }
                .buttonStyle(.plain)
                .disabled(!alternateIconsSupported)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let alternateAppIcon = UIApplication.shared.alternateIconName, let appIcon = remoteDataManager.iconPreviews.first(where: { $0.name == alternateAppIcon }) {
                currentIcon = appIcon.name
            } else {
                currentIcon = Self.defaultIconName
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    setAppIcon(nil)
                    currentIcon = Self.defaultIconName
                }
            }
        }
        .alert("Alert!", isPresented: $showTipJarAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(KAppIconTipJarMessage)
        }

    }
    
    private func handleIconSelection(selected: IconPreview) {
        guard iapManager.hasTipped else {
            showTipJarAlert = true
            return
        }
        currentIcon = selected.name
        if selected.name == Self.defaultIconName {
            setAppIcon(nil)
        } else {
            setAppIcon(selected.name)
        }
    }
    
    private func setAppIcon(_ name: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons are not supported")
            return
        }
        
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error = error {
                print("Error changing icon: \(error.localizedDescription)")
            } else {
                print("Icon changed successfully!")
            }
        }
    }
    
    @ViewBuilder
    private func IconTileBuilder(preview: IconPreview) -> some View {
        HStack(alignment: .center) {
            HStack {
                if let url = preview.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 80, height: 80)
                                .padding(.vertical, 6)
                                .shadow(radius: 2)
                        case .success(let image):
                            ImagePreviewBuilder(image: image)
                        case .failure:
                            ImagePreviewBuilder(image: Image(systemName: "photo"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    ImagePreviewBuilder(image: Image(systemName: "photo"))
                }
                Text(preview.name == Self.defaultIconName ? "Default" : preview.title)
                    .padding(.leading, 4)
            }
            Spacer()
            if preview.name == currentIcon {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
    }
    
    @ViewBuilder
    private func ImagePreviewBuilder(image: Image) -> some View {
        image
            .resizable()
            .frame(width: 80, height: 80)
            .cornerRadius(18)
            .padding(.vertical, 6)
            .shadow(radius: 3)
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
#endif

