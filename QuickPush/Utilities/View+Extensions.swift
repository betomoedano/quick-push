import SwiftUI

extension View {
    @ViewBuilder
    func applying<V: View>(@ViewBuilder _ modifier: (Self) -> V) -> some View {
        modifier(self)
    }
}
