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
        let icon: Icon
        
        static let items = [
            IconSelector(
                title: "White on Red".localized,
                icon: .primary),
            IconSelector(
                title: "\("Red on White".localized)",
                icon: .alt1),
//            IconSelector(
//                title: "\("Blue on White".localized)",
//                icon: .alt2),
            IconSelector(
                title: "\("White on Red - Classic".localized)",
                icon: .alt3),
            IconSelector(
                title: "\("Green".localized)",
                icon: .alt4),
//            IconSelector(
//                title: "\("Blue".localized)",
//                icon: .alt5),
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
            ForEach(IconSelector.items) { item in
                Button{
                    currentIcon = item.icon.appIconName
                    if item.icon.rawValue == Icon.primary.rawValue {
                        setAppIcon(nil)
                    } else {
                        setAppIcon(item.icon.appIconName)
                    }
                } label: {
                    HStack(alignment: .center) {
                        Label {
                            Text(item.title)
                        } icon: {
                            Image(item.icon.previewImageName)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        Spacer()
                        if item.icon.appIconName == currentIcon {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
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

