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
    
    var title: String {
        switch self {
        case .newAddress: return "Add Address"
        case .newFolder: return "New Folder"
        case .quickAddress: return "Quick Address"
        }
    }
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
                RowView("plus.circle", "New Address", "Create or Login to new Address", .newAddress)
                RowView("folder.badge.plus", "New Folder", "Create new Folder", .newFolder)
                RowView("bolt", "Quick Address", "Create an address and copy", .quickAddress)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
        } expandedContent: { dismiss in
            VStack {
                BuildExpandedHeader()
                
                switch selectedActionPage {
                case .newAddress:
                    AddAddressView {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showExpandedContent = false
                        }
                    }
                case .newFolder:
                    Text("New Folder")
                case .quickAddress:
                    Text("Quick Address")
                }
            }
            .environment(\EnvironmentValues.refresh as! WritableKeyPath<EnvironmentValues, RefreshAction?>, nil)
            .padding(.top, 15)
        }
        .sensoryFeedback(.impact, trigger: actionMenuHaptic)
    }
    
    @ViewBuilder
    private func BuildExpandedHeader() -> some View {
        HStack {
            Text(selectedActionPage.title)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer(minLength: 0)
            Button {
                actionMenuHaptic.toggle()
                showExpandedContent = false
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 25)
    }
    
    @ViewBuilder
    private func RowView(_ image: String, _ title: String, _ desc: String, _ page: ActionPage) -> some View {
        HStack(spacing: 18) {
            Image(systemName: image)
                .foregroundStyle(.primary)
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

