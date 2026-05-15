import SwiftUI

struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
}

struct ToastModifier: ViewModifier {
    @Binding var item: ToastItem?

    func body(content: Content) -> some View {
        content.overlay {
            if let item {
                VStack {
                    Spacer().frame(height: 60)
                    Text(item.message)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: item)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.item = nil
                    }
                }
            }
        }
    }
}

extension View {
    func toast(_ item: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(item: item))
    }
}