//
//  TipJarCardView.swift
//  TempBox
//
//  Created by Rishi Singh on 13/07/25.
//

//#if os(iOS)
//import SwiftUI
//
//struct TipJarCardView: View {
//    @Environment(\.colorScheme) private var colorScheme
//    
//    @EnvironmentObject private var appController: AppController
//    @EnvironmentObject private var iapManager: IAPManager
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack(alignment: .center) {
//                Text("Tip Jar")
//                    .font(.body.bold())
//                Spacer()
//                if iapManager.isLoading {
//                    ProgressView()
//                        .controlSize(.small)
//                }
//                Button {
//                    Task {
//                        await iapManager.refreshPurchaseStatus()
//                    }
//                } label: {
//                    Image(systemName: "arrow.trianglehead.2.clockwise")
//                        .symbolEffect(.rotate, options: .repeat(1), value: iapManager.isLoading)
//                }
//                .buttonStyle(.plain)
//                .help("Restore Purchase")
//            }
//            .frame(height: 30)
//            
//            Text("If you'd like to contribute to ongoing **development and say thanks**, you can leave a tip and you'll also unlock access to the **app icons** and **accent colors** below.")
//                .lineLimit(6, reservesSpace: false)
//
//            TipsTile()
//        }
//        .padding(.bottom)
//    }
//    
//    @ViewBuilder
//    private func TipsTile() -> some View {
//        GeometryReader { geometry in
//            let cardWidth: CGFloat = geometry.size.width / 3 - 6 // 6 for spacing adjustment
//            
//            HStack(spacing: 10) {
//                ForEach(iapManager.availableProducts) { product in
//                    Button {
//                        Task {
//                            await iapManager.purchase(product: product)
//                        }
//                    } label: {
//                        TipBoxLabel(emoji: getTipEmoji(name: product.displayName), priceStr: product.displayPrice, width: cardWidth)
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//        }
//        .frame(height: 60)
//    }
//    
//    @ViewBuilder
//    private func TipBoxLabel(emoji: String, priceStr: String, width: CGFloat) -> some View {
//        let accentColor = appController.accentColor(colorScheme: colorScheme)
//        VStack {
//            Text(emoji)
//                .font(.title)
//            Text(priceStr)
//                .foregroundStyle(accentColor)
//        }
//        .padding(10)
//        .frame(width: width)
//        .background(accentColor.opacity(0.1))
//        .cornerRadius(10)
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(accentColor, lineWidth: 2)
//        )
//    }
//    
//    private func getTipEmoji(name: String) -> String {
//        if name.lowercased().contains("small") {
//            return "🙂"
//        } else if name.lowercased().contains("medium") {
//            return "😄"
//        } else if name.lowercased().contains("large") {
//            return "🥰"
//        } else {
//            return ""
//        }
//    }
//}
//#endif
