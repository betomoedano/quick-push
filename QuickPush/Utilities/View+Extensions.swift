import SwiftUI

extension View {
    @ViewBuilder
    func applying<V: View>(@ViewBuilder _ modifier: (Self) -> V) -> some View {
        modifier(self)
    }

    /// Present content as a `.sheet` when pinned, or `.popover` when in the MenuBarExtra.
    @ViewBuilder
    func adaptivePresentation<Content: View>(
        isPresented: Binding<Bool>,
        isPinned: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if isPinned {
            self.sheet(isPresented: isPresented, content: content)
        } else {
            self.popover(isPresented: isPresented, arrowEdge: .top, content: content)
        }
    }

    /// Present content as a `.sheet` when pinned, or `.popover` when in the MenuBarExtra (item variant).
    @ViewBuilder
    func adaptivePresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        isPinned: Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        if isPinned {
            self.sheet(item: item, content: content)
        } else {
            self.popover(item: item, arrowEdge: .top, content: content)
        }
    }
}
