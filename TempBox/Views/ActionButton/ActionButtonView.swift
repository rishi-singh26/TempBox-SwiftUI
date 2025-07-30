//
//  ActionButtonView.swift
//  TempBox
//
//  Created by Rishi Singh on 29/07/25.
//

#if os(iOS)
import SwiftUI

enum ActionPage {
    case newAddress
    case newFolder
    case quickAddress
}

struct ActionButtonView: View {
//    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController
    @Environment(\.colorScheme) var colorScheme
    
    @State private var actionMenuHaptic: Bool = false
    @State private var selectedActionPage: ActionPage = .newAddress
    @State var showExpandedContent: Bool = false
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        MorphingButton(backgroundColor: .primary, showExpandedContent: $showExpandedContent) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundStyle(accentColor)
                .frame(width: 45, height: 45)
                .background(.thinMaterial)
                .clipShape(.circle)
                .contentShape(.circle)
        } content: { dismiss in
            VStack(alignment: .leading, spacing: 12) {
                RowView(accentColor, "plus.circle", "New Address", "Create or Login to new Address", .newAddress)
                RowView(accentColor, "folder.badge.plus", "New Folder", "Create new Folder", .newFolder)
                RowView(accentColor, "bolt", "Quick Address", "Create an address and copy", .quickAddress)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
        } expandedContent: { dismiss in
            switch selectedActionPage {
            case .newAddress:
                AddAddressView {
                    showExpandedContent = false
                } dismiss: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showExpandedContent = false
                    }
                }
            case .newFolder:
                IOSNewFolderActionView(accentColor: accentColor) {
                    showExpandedContent = false
                } dismiss: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showExpandedContent = false
                    }
                }
            case .quickAddress:
                QuickAddressView(accentColor: accentColor) {
                    showExpandedContent = false
                } dismiss: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showExpandedContent = false
                    }
                }
            }
        }
        .environment(\EnvironmentValues.refresh as! WritableKeyPath<EnvironmentValues, RefreshAction?>, nil)
        .sensoryFeedback(.impact, trigger: actionMenuHaptic)
    }
    
    @ViewBuilder
    private func RowView(_ accentColor: Color, _ image: String, _ title: String, _ desc: String, _ page: ActionPage) -> some View {
        HStack(spacing: 18) {
            Image(systemName: image)
                .foregroundStyle(accentColor)
                .frame(width: 45, height: 45)
                .background(.background, in: .circle)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(desc)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .contentShape(.rect)
        .onTapGesture {
            selectedActionPage = page
            actionMenuHaptic.toggle()
            showExpandedContent.toggle()
        }
    }
}
#endif

