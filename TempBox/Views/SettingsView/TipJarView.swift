//
//  TipJarView.swift
//  TempBox
//
//  Created by Rishi Singh on 20/07/25.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    
    @State private var selectTipId: String = ""
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        Group {
#if os(iOS)
            IOSViewBuilder(accentColor: accentColor)
#elseif os(macOS)
            MacOSViewBuilder(accentColor: accentColor)
#endif
        }
        .navigationTitle("Tip Jar")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if iapManager.isLoading && selectTipId.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Refresh") {
                    selectTipId = ""
                    Task {
                        await iapManager.refreshPurchaseStatus()
                    }
                }
            }
        }
    }
    
#if os(macOS)
    @ViewBuilder
    private func MacOSViewBuilder(accentColor: Color) -> some View {
        List {
            MacCustomSection {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 50, height: 46)
                        .foregroundStyle(accentColor)
                    Text("Donations Welcome")
                        .font(.title2.bold())
                    Text("If you enjoy using TempBox and want to support its continued development, we very much appreciate that! There is some overhead in keeping the app running, help keep TempBox free with kindness.")
                }
            }
            .listRowSeparator(.hidden)
            
            if iapManager.hasTipped {
                MacCustomSection {
                    HStack {
                        Text("Thanks for the tip😄! Your support means a lot and helps us keep improving the app.")
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            MacCustomSection {
                ForEach(iapManager.availableProducts) { product in
                    TipTileBuilder(product: product, accentColor: accentColor)
                }
            }
            .listRowSeparator(.hidden)
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    private func IOSViewBuilder(accentColor: Color) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 50, height: 46)
                        .foregroundStyle(accentColor)
                    Text("Donations Welcome")
                        .font(.title2.bold())
                    Text("If you enjoy using TempBox and want to support its continued development, we very much appreciate that! There is some overhead in keeping the app running, help keep TempBox free with kindness.")
                    
                    Text("**Note: As a thank you, tipping unlocks App Icon and Accent Color customization.**")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
            
            if iapManager.hasTipped {
                Section {
                    Text("Thanks for the tip😄! **App Icon** and **Accent Color** customizations have been enabled for you.")
                }
            }
            
            Section {
                ForEach(iapManager.availableProducts) { product in
                    TipTileBuilder(product: product, accentColor: accentColor)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
#endif
    
    @ViewBuilder
    private func TipTileBuilder(product: Product, accentColor: Color) -> some View {
        let tipStatus: Bool = iapManager.getTipStatus(for: product.id)
        if tipStatus {
            TipTileLabelBuilder(product: product, tipStatus: tipStatus, accentColor: accentColor)
        } else {
            Button {
                guard !tipStatus else { return }
                selectTipId = product.id
                Task {
                    await iapManager.purchase(product: product)
                }
            } label: {
                TipTileLabelBuilder(product: product, tipStatus: tipStatus, accentColor: accentColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func TipTileLabelBuilder(product: Product, tipStatus: Bool, accentColor: Color) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(product.displayName)
                    .font(.body.bold())
                HeartsBuilder(accentColor: accentColor, name: product.id)
            }
            Spacer()
            if tipStatus {
                Text(iapManager.getTipMessage(for: product.id))
                    .font(.body.bold())
                    .foregroundColor(accentColor)
            } else {
                Group {
                    if iapManager.isLoading && selectTipId == product.id {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(accentColor)
                    } else {
                        Text(product.displayPrice)
                    }
                }
                .font(.body.bold())
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .background(accentColor.opacity(0.2))
                .foregroundColor(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    @ViewBuilder
    private func HeartsBuilder(accentColor: Color, name: String) -> some View {
        var numFilledHearts: Int {
            if name.lowercased().contains("small") { return 1 }
            else if name.lowercased().contains("medium") { return 2 }
            else { return 3 }
        }
        
        HStack(spacing: 10) {
            ForEach(1...3, id: \.self) { number in
                Image(systemName: number <= numFilledHearts ? "heart.fill" : "heart")
                    .resizable()
                    .frame(width: 25, height: 23)
                    .foregroundColor(accentColor.opacity(number <= numFilledHearts ? 1 : 0.5))
            }
        }
    }
}

#Preview {
    TipJarView()
}
