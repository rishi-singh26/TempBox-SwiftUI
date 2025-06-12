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
    @EnvironmentObject var appController: AppController
    
    @State private var currentIcon = UIApplication.shared.alternateIconName ?? Icon.primary.appIconName
    
    private let columns = [GridItem(.adaptive(minimum: 125, maximum: 1024))]
    
    enum Icon: Int, CaseIterable, Identifiable {
        var id: String {
            "\(rawValue)"
        }
        
        init(string: String) {
            if string == "AppIcon" {
                self = .primary
            } else {
                self = .init(rawValue: Int(String(string.replacing("AppIcon", with: "")))!)!
            }
        }
        
        case primary = 0
        case alt1, alt2, alt3, alt4, alt5, alt6, alt7
        
        var appIconName: String {
            return "AppIcon\(rawValue)"
        }
        
        var previewImageName: String {
            return "AppIcon\(rawValue)-image"
        }
    }
    
    struct IconSelector: Identifiable {
        var id = UUID()
        let title: String
        let icons: [Icon]
        
        static let items = [
            IconSelector(
                title: "White on Red".localized,
                icons: [.primary]),
            IconSelector(
                title: "\("Red on White".localized)",
                icons: [.alt1]),
            IconSelector(
                title: "\("Blue on White".localized)",
                icons: [.alt2]),
            IconSelector(
                title: "\("White on Red - Classic".localized)",
                icons: [.alt3]),
            IconSelector(
                title: "\("Green".localized)",
                icons: [.alt4]),
            IconSelector(
                title: "\("Blue".localized)",
                icons: [.alt5]),
            IconSelector(
                title: "White on Orange".localized,
                icons: [.alt6]),
            IconSelector(
                title: "\("Orange on White".localized)",
                icons: [.alt7]),
        ]
    }
    
    var body: some View {
        List {
            ForEach(IconSelector.items) { item in
                Section {
                    makeIconGridView(icons: item.icons)
                } header: {
                    Text(item.title)
                }
            }
        }
        .listStyle(.plain)
        .onAppear {
            if let alternateAppIcon = UIApplication.shared.alternateIconName, let appIcon = Icon.allCases.first(where: { $0.appIconName == alternateAppIcon }) {
                currentIcon = appIcon.appIconName
            } else {
                currentIcon = Icon.primary.appIconName
            }
        }
    }
    
    private func makeIconGridView(icons: [Icon]) -> some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(icons) { icon in
                Button {
                    currentIcon = icon.appIconName
                    if icon.rawValue == Icon.primary.rawValue {
                        setAppIcon(nil)
                    } else {
                        setAppIcon(icon.appIconName)
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Image(icon.previewImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(minHeight: 125, maxHeight: 512)
                            .cornerRadius(6)
                            .shadow(radius: 3)
                        if icon.appIconName == currentIcon {
                            Image(systemName: "checkmark.seal.fill")
                                .padding(4)
                                .tint(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    func setAppIcon(_ name: String?) {
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
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
#endif

