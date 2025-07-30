//
//  OnboardingView.swift
//  TempBox
//
//  Created by Rishi Singh on 26/07/25.
//

import SwiftUI

/// Onboarding Cart
struct OnboardingCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
}

/// Onboarding card result builder
@resultBuilder
struct OnboardingCardResultBuilder {
    static func buildBlock(_ components: OnboardingCard...) -> [OnboardingCard] {
        components.compactMap{ $0 }
    }
}

struct OnboardingView: View {
    var tint: Color
    var onContinue: () -> ()
    
    init(tint: Color, onContinue: @escaping () -> Void) {
        self.tint = tint
        self.onContinue = onContinue
        
        // Setup the animateCards property to match with the number of cards
        self._animateCards = .init(initialValue: Array(repeating: false, count: self.cards.count))
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
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.white)
                        .background(tint.gradient, in: .rect(cornerRadius: 25))
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .blurSlide(animateIcon)
                    
                    Text("Welcome to TempBox")
                        .font(.title2.bold())
                        .blurSlide(animateTitle)
                    
                    CardsBuilder()
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0, content: {
                Text("By using TempBox, you agree to\n**[Privacy Policy](https://tempbox.rishisingh.in/privacy-policy.html)** and **[Terms of Service](https://tempbox.rishisingh.in/terms-of-service.html)**")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 15)
                
                // Continue btn
                Button(action: onContinue) {
                    Text("Continue")
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
            })
            .blurSlide(animateFooter)
        }
        // Limiting the width
        .frame(maxWidth: 330)
        // Disable interactive dismiss
        .interactiveDismissDisabled()
        // Disabling interation until footer is animated
        .allowsHitTesting(animateFooter)
        .task {
            guard !animateIcon else { return }
            
            await delayedAnimation(0.35) {
                animateIcon = true
            }
            
            await delayedAnimation(0.2) {
                animateTitle = true
            }
            
            try? await Task.sleep(for: .seconds(0.2))
            
            for index in animateCards.indices {
                let delay = Double(index) * 0.1
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }
            
            await delayedAnimation(0.2) {
                animateFooter = true
            }
        }
        .setUpOnboarding()
        .presentationCornerRadius(45)
    }
    
    @ViewBuilder
    private func CardsBuilder() -> some View {
        Group {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: card.symbol)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .symbolVariant(.fill)
                        .frame(width: 45)
                        .offset(y: 10)
                    
                    VStack(alignment: .leading) {
                        Text(card.title)
                            .font(.title3)
                            .lineLimit(1)
                        
                        Text(card.subTitle)
                            .lineLimit(2)
                    }
                }
                .blurSlide(animateCards[index])
            }
        }
    }
    
    private func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
        try? await Task.sleep(for: .seconds(delay))
        
        withAnimation(.smooth) {
            action()
        }
    }
    
    
    // Constants
    let cards: [OnboardingCard] = [
        OnboardingCard(
            symbol: "envelope",
            title: "Generate Email Addresses",
            subTitle: "Quickly create email addresses, as many as you need."
        ),
        
        OnboardingCard(
            symbol: "tray.2",
            title: "Unified Inbox",
            subTitle: "All your emails, from every address, in one place."
        ),
        
        OnboardingCard(
            symbol: "arrow.up.arrow.down.square",
            title: "Import/Export",
            subTitle: "Easily import or export email addresses whenever you need."
        ),
    ]
    let footerMessage = "By using TempBox, you agree to [Privacy Policy](https://tempbox.rishisingh.in/privacy-policy.html) and [Terms of Service](https://tempbox.rishisingh.in/terms-of-service.html)"
}
