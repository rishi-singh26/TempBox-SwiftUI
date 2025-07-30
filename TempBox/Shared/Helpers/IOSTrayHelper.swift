//
//  IOSTrayHelper.swift
//  TempBox
//
//  Created by Rishi Singh on 27/07/25.
//

#if os(iOS)
import SwiftUI

struct TrayConfig {
    var maxDetent: PresentationDetent
    var cornerRadius: CGFloat = 30
    var isInteractiveDissmissDisabled: Bool = false
    // Add other properties as needed
    var horizontalPadding: CGFloat = 15
    var bottomPadding: CGFloat = 15
    
    static let defaultConfig = TrayConfig(
        maxDetent: .fraction(0.99),
        cornerRadius: 45,
        horizontalPadding: DeviceType.isIpad ? 50 : 7,
        bottomPadding: DeviceType.isIpad ? 50 : 15
    )
}

extension View {
    @ViewBuilder
    func systemTrayView<Content: View>(
        _ show: Binding<Bool>,
        config: TrayConfig = .defaultConfig,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .sheet(isPresented: show) {
                content()
                    .background(.background)
                    .clipShape(.rect(cornerRadius: config.cornerRadius))
                    .padding(.horizontal, config.horizontalPadding)
                    .padding(.bottom, config.bottomPadding)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    // Presentation Configuration
                    .presentationDetents([config.maxDetent])
                    .presentationCornerRadius(0)
                    .presentationBackground(.clear)
                    .presentationDragIndicator(.hidden)
                    .interactiveDismissDisabled(config.isInteractiveDissmissDisabled)
                    .background(RemoveSheetShadow())
            }
    }
}

fileprivate struct RemoveSheetShadow: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let shadowView = view.dropShadowView {
                shadowView.layer.shadowColor = UIColor.clear.cgColor
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

extension UIView {
    var dropShadowView: UIView? {
        if let superview, String(describing: type(of: superview)) == "UIDropShadowView" {
            return superview
        }
        
        return superview?.dropShadowView
    }
}
#endif
