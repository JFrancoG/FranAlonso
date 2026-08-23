import SwiftUI

private struct PrimaryActionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.onBrandPrimary)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.brandPrimary)
    }
}

extension View {
    func primaryActionStyle() -> some View {
        modifier(PrimaryActionModifier())
    }
}
