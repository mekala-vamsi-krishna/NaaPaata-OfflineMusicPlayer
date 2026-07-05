import SwiftUI

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toastManager.toast {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                        
                        Text(toast.message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color(AppColors.background)
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .zIndex(100)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: toastManager.toast)
    }
}

extension View {
    func withToast() -> some View {
        self.modifier(ToastModifier())
    }
}
