//
//  DisclaimerView.swift
//  TempBox
//
//  Created by Rishi Singh on 07/04/26.
//

import SwiftUI

/// Disclaimer Card
struct DisclaimerCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
    var isHighlighted: Bool = false
}

struct DisclaimerView: View {
    var tint: Color
    var onAccept: () -> ()
    
    init(tint: Color, onAccept: @escaping () -> Void) {
        self.tint = tint
        self.onAccept = onAccept
        self._animateCards = .init(initialValue: Array(repeating: false, count: Self.cards.count))
    }
    
    // View properties
    @State private var animateIcon: Bool = false
    @State private var animateTitle: Bool = false
    @State private var animateCards: [Bool]
    @State private var animateFooter: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                        .blurSlide(animateIcon)
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("Important Notice")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("This app is powered by **mail.tm**, a free third-party service. By using this app, you acknowledge and accept the following.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                    .blurSlide(animateTitle)
                    
                    CardsBuilder()
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            
            BottomBtnsBuilder()
        }
        .frame(maxWidth: DeviceType.isIphone ? 350 : 400)
        .interactiveDismissDisabled()
        .allowsHitTesting(animateFooter)
        .task {
            guard !animateIcon else { return }
            
            await delayedAnimation(0.35) { animateIcon = true }
            await delayedAnimation(0.2)  { animateTitle = true }
            
            try? await Task.sleep(for: .seconds(0.2))
            
            for index in animateCards.indices {
                let delay = Double(index) * 0.1
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }
            
            await delayedAnimation(0.2) { animateFooter = true }
        }
        .setUpOnboarding()
        .presentationCornerRadius(45)
    }
    
    @ViewBuilder
    private func CardsBuilder() -> some View {
        ForEach(Self.cards.indices, id: \.self) { index in
            let card = Self.cards[index]
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: card.symbol)
                    .font(.title2)
                    .foregroundStyle(card.isHighlighted ? .orange : tint)
                    .symbolVariant(.fill)
                    .frame(width: 45)
                    .offset(y: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.title3)
                        .lineLimit(1)
                    
                    Text(card.subTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Highlight the warning card with a tinted background
            .padding(card.isHighlighted ? 12 : 0)
            .background(card.isHighlighted ? Color.orange.opacity(0.1) : Color.clear, in: .rect(cornerRadius: 15))
            .blurSlide(animateCards[index])
        }
    }
    
    @ViewBuilder
    private func BottomBtnsBuilder() -> some View {
        VStack(spacing: 0) {
            MarkdownLinkText(markdownText: "Email services are provided by [mail.tm](https://mail.tm). We have no affiliation with, or control over, mail.tm or its operations.")
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical, 15)
            
            // Accept button
            if #available(iOS 26.0, macOS 26.0, *) {
                Button(action: onAccept) {
                    Text("I Understand")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
#if os(macOS)
                        .padding(.vertical, 8)
#else
                        .padding(.vertical, 4)
#endif
                }
                .tint(tint)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            } else {
                Button(action: onAccept) {
                    Text("I Understand")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
#if os(macOS)
                        .padding(.vertical, 8)
#else
                        .padding(.vertical, 4)
#endif
                }
                .tint(tint)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .blurSlide(animateFooter)
    }
    
    private func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
        try? await Task.sleep(for: .seconds(delay))
        withAnimation(.smooth) { action() }
    }
    
    // Constants — static so init can reference the count before self is available
    static let cards: [DisclaimerCard] = [
        DisclaimerCard(
            symbol: "envelope.badge.minus",
            title: "Emails Are Not Permanent",
            subTitle: "Older messages are automatically removed by mail.tm and cannot be recovered. Do not rely on this app to retain important emails."
        ),
        DisclaimerCard(
            symbol: "lock.trianglebadge.exclamationmark",
            title: "No Password Recovery",
            subTitle: "mail.tm does not support password changes or recovery. Losing your password means permanent loss of access to that address and its messages."
        ),
//        DisclaimerCard(
//            symbol: "person.crop.circle.badge.minus",
//            title: "Addresses May Be Deleted",
//            subTitle: "mail.tm may remove an address if it is inactive, old, or for any other reason at their discretion. This is outside our control."
//        ),
        DisclaimerCard(
            symbol: "exclamationmark.octagon",
            title: "Not for Sensitive Use",
            subTitle: "Do not use this app for financial accounts, legal matters, or any service you depend on. It is intended for temporary, disposable use only.",
            isHighlighted: true
        ),
        DisclaimerCard(
            symbol: "shield.slash",
            title: "No Liability for Loss",
            subTitle: "We are not responsible for any financial or other loss arising from the unavailability, deletion, or inaccessibility of any email address or message. Use at your own risk."
        ),
    ]
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DisclaimerView(tint: .accent) {
                // onAccept
            }
        }
}
