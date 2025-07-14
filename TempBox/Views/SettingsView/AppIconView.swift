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
    @EnvironmentObject var iapManager: IAPManager
    
    @State private var currentIcon = UIApplication.shared.alternateIconName ?? Icon.primary.appIconName
    @State private var alternateIconsSupported: Bool = true
    
    init() {
        if !UIApplication.shared.supportsAlternateIcons {
            _alternateIconsSupported = State(wrappedValue: false)
        }
    }
    
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
        let icon: Icon
        
        static let items = [
            IconSelector(
                title: "White on Red".localized,
                icon: .primary),
            IconSelector(
                title: "\("Red on White".localized)",
                icon: .alt1),
            IconSelector(
                title: "\("Inclusion".localized)",
                icon: .alt2),
            IconSelector(
                title: "\("White on Red - Classic".localized)",
                icon: .alt3),
            IconSelector(
                title: "\("Dark Green".localized)",
                icon: .alt4),
            IconSelector(
                title: "\("Light".localized)",
                icon: .alt5),
            IconSelector(
                title: "White on Orange".localized,
                icon: .alt6),
            IconSelector(
                title: "\("Orange on White".localized)",
                icon: .alt7),
        ]
    }
    
    var body: some View {
        List {
            if !alternateIconsSupported {
                Section {
                    Text("Custom Icons are not supported on your device!")
                }
            }
            ForEach(IconSelector.items) { item in
                Button{
                    handleIconSelection(selected: item)
                } label: {
                    HStack(alignment: .center) {
                        Label {
                            Text(item.title)
                                .padding(.leading, 4)
                        } icon: {
                            Image(item.icon.previewImageName)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .shadow(radius: 2)
                        }
                        Spacer()
                        if item.icon.appIconName == currentIcon {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!alternateIconsSupported || !iapManager.hasTipped)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let alternateAppIcon = UIApplication.shared.alternateIconName, let appIcon = Icon.allCases.first(where: { $0.appIconName == alternateAppIcon }) {
                currentIcon = appIcon.appIconName
            } else {
                currentIcon = Icon.primary.appIconName
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    setAppIcon(Icon.primary.appIconName)
                    currentIcon = Icon.primary.appIconName
                }
            }
        }
    }
    
    private func handleIconSelection(selected: IconSelector) {
        guard iapManager.hasTipped else { return }
        currentIcon = selected.icon.appIconName
        if selected.icon.rawValue == Icon.primary.rawValue {
            setAppIcon(nil)
        } else {
            setAppIcon(selected.icon.appIconName)
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
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
#endif

