import SwiftUI

struct Toast: Equatable {
    var message: String
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var toast: Toast?
    private var workItem: DispatchWorkItem?
    
    func showToast(message: String) {
        workItem?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toast = Toast(message: message)
        }
        
        let newWorkItem = DispatchWorkItem { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self?.toast = nil
            }
        }
        
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: newWorkItem)
    }
}
