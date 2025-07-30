//
//  MorphingButton.swift
//  TempBox
//
//  Created by Rishi Singh on 29/07/25.
//

#if os(iOS)
import SwiftUI

struct MorphingButton<Label: View, Content: View, ExpandedContent: View>: View {
    var backgroundColor: Color
    @Binding var showExpandedContent: Bool
    @ViewBuilder var label: Label
    @ViewBuilder var content: (_ dismiss: @escaping () -> Void) -> Content
    @ViewBuilder var expandedContent: (_ dismiss: @escaping () -> Void) -> ExpandedContent
    
    // View Properties
    @State private var showFullScreenCover: Bool = false
    @State private var animateContent: Bool = false
    @State private var viewPosition: CGRect = .zero
    @State private var haptics: Bool = false
    @State private var scale: CGFloat = 1
    
    var body: some View {
        label
            .frame(width: 45, height: 45)
            .background(.thinMaterial)
            .clipShape(.circle)
            .contentShape(.circle)
            .onGeometryChange(for: CGRect.self, of: {
                $0.frame(in: .global)
            }, action: { newValue in
                viewPosition = newValue
            })
            .opacity(showFullScreenCover ? 0 : 1)
            .onTapGesture {
                haptics.toggle()
                toggleFullScreenCover(false, status: true)
            }
            .sensoryFeedback(.impact, trigger: haptics)
            .fullScreenCover(isPresented: $showFullScreenCover) {
                ZStack(alignment: .topLeading) {
                    if animateContent {
                        ZStack(alignment: .top) {
                            if showExpandedContent {
                                expandedContent(dismissContent)
                                    .transition(.blurReplace)
                            } else {
                                content(dismissContent)
                                    .transition(.blurReplace)
                            }
                        }
                        .transition(.blurReplace)
                    } else {
                        label
                            .transition(.blurReplace)
                    }
                }
                .frame(maxWidth: maxWidth)
                // limit height to 800 on large screens
                .frame(maxHeight: DeviceType.isIphone ? nil : (animateContent && showExpandedContent ? 800 : nil))
                .geometryGroup()
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.thinMaterial)
                        .ignoresSafeArea(showExpandedContent && DeviceType.isIphone ? .all : [])
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .offset(
                    x: animateContent ? 0 : viewPosition.minX,
                    y: animateContent ? 0 : viewPosition.minY
                )
                .ignoresSafeArea(animateContent ? [] : .all)
                .scaleEffect(scale, anchor: .top)
                //                .background {
                //                    Rectangle()
                //                        .fill(.black.opacity(animateContent ? 0.2 : 0))
                //                        .ignoresSafeArea()
                //                        .onTapGesture {
                //                            haptics.toggle()
                //                            withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0), completionCriteria: .removed) {
                //                                animateContent = false
                //                            } completion: {
                //                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //                                    toggleFullScreenCover(false, status: false)
                //                                }
                //                            }
                //                        }
                //                }
                .presentationBackground {
                    // GeometryReader Required for scanle calculation
                    GeometryReader {
                        let size = $0.size
                        Rectangle()
                            .fill(.black.opacity(animateContent ? 0.2 : 0))
                            .onTapGesture(perform: close)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged({ value in
                                        let height = value.translation.height
                                        let scale = height / size.height
                                        let applyingRatio: CGFloat = 0.1
                                        self.scale = 1 + (scale * applyingRatio)
                                    }).onEnded({ value in
                                        let velocityHeight = value.velocity.height / 5
                                        let height = value.translation.height + velocityHeight
                                        let scale = height / size.height
                                        
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.scale = 1
                                        }
                                        
                                        if scale > 0.5 {
                                            close()
                                        }
                                    })
                            )
                    }
                    .ignoresSafeArea()
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.05))
                    withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0)) {
                        animateContent = true
                    }
                }
                .animation(.interpolatingSpring(duration: 0.2, bounce: 0), value: showExpandedContent)
            }
    }
    
    // Computed property for maxWidth
    var maxWidth: CGFloat {
        if DeviceType.isIphone {
            return animateContent ? .infinity : 45
        } else {
            if showExpandedContent {
                return 600
            } else {
                return animateContent ? 400 : 45
            }
        }
    }
    
    // Computed property for alignment
    var alignment: Alignment {
        if showExpandedContent && DeviceType.isIpad {
            return .center
        } else {
            return animateContent ? .bottomLeading : .topLeading
        }
    }
    
    // Computed property for horizontalPadding
    var horizontalPadding: CGFloat {
        return animateContent && (!showExpandedContent || !DeviceType.isIphone) ? 15 : 0
    }

    // Computed property for bottomPadding
    var bottomPadding: CGFloat {
        return animateContent && (!showExpandedContent || !DeviceType.isIphone) ? 5 : 0
    }
    
    private func close() {
        if showExpandedContent {
            showExpandedContent = false
        } else {
            dismissContent()
        }
    }
    
    private func dismissContent() {
        haptics.toggle()
        withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0), completionCriteria: .removed) {
            animateContent = false
        } completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toggleFullScreenCover(false, status: false)
            }
        }
    }
    
    private func toggleFullScreenCover(_ withAnimation: Bool, status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = !withAnimation
        
        withTransaction(transaction) {
            showFullScreenCover = status
        }
    }
}
#endif
