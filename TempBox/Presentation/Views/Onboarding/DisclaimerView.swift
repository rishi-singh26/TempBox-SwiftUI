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
                    // Info icon
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(tint)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                        .blurSlide(animateIcon)
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("A Few Things to Know")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("TempBox is powered by **mail.tm**, a free third-party service. Here's what that means for you.")
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
                    .foregroundStyle(tint)
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
            .padding(.vertical, 12)
            .background(card.isHighlighted ? .yellow.opacity(0.1) : Color.clear, in: .rect(cornerRadius: 15))
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
                    Text("Got It")
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
                    Text("Got It")
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
            title: "Messages Don't Last Forever",
            subTitle: "mail.tm automatically removes older messages. Save anything important before it disappears."
        ),
        DisclaimerCard(
            symbol: "lock.trianglebadge.exclamationmark",
            title: "Passwords Can't Be Recovered",
            subTitle: "mail.tm does not support password change or recovery. Losing a password means losing access to that address."
        ),
        DisclaimerCard(
            symbol: "exclamationmark.octagon",
            title: "For Temporary Use Only",
            subTitle: "TempBox is designed for sign-ups and one-time verifications — not for accounts you rely on, like banking or legal services.",
            isHighlighted: true
        ),
        DisclaimerCard(
            symbol: "shield.slash",
            title: "No Liability for Lost Emails",
            subTitle: "TempBox and mail.tm aren't responsible for loss resulting from unavailable or deleted emails. By continuing, you accept these terms."
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
