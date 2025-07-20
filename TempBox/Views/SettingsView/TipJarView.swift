//
//  TipJarView.swift
//  TempBox
//
//  Created by Rishi Singh on 20/07/25.
//

#if os(iOS)
import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    
    @State private var selectTipId: String = ""
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
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
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") {
                    Task {
                        await iapManager.refreshPurchaseStatus()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func TipTileBuilder(product: Product, accentColor: Color) -> some View {
        Button {
            selectTipId = product.id
            Task {
                await iapManager.purchase(product: product)
            }
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.displayName)
                        .font(.body.bold())
                    HeartsBuilder(accentColor: accentColor, name: product.id)
                }
                Spacer()
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
                //                                .frame(height: 20)
            }
        }
        .buttonStyle(.plain)
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
#endif
