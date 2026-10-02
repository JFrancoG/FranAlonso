import SwiftUI

struct SalesHistoryFilters: View {
    @Binding var filter: SalesHistoryFilter
    @Binding var order: SalesHistoryOrder
    let filterIsFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("sales.history.filter").foregroundStyle(.textPrimary)
            Menu {
                Picker("sales.history.filter", selection: $filter) {
                    Text("sales.history.all").tag(SalesHistoryFilter.all)
                    Text("sales.status.closed").tag(SalesHistoryFilter.closed)
                    Text("sales.status.voided").tag(SalesHistoryFilter.voided)
                }
                .pickerStyle(.inline)
            } label: {
                controlValue(filter.localizedTitle)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text("sales.history.filter"))
            .accessibilityValue(Text(filter.localizedTitle))
            .accessibilityFocused(filterIsFocused)
        }
        .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: 6) {
            Text("sales.history.order").foregroundStyle(.textPrimary)
            Menu {
                Picker("sales.history.order", selection: $order) {
                    Text("sales.history.newest").tag(SalesHistoryOrder.newestFirst)
                    Text("sales.history.oldest").tag(SalesHistoryOrder.oldestFirst)
                }
                .pickerStyle(.inline)
            } label: {
                controlValue(order.localizedTitle)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text("sales.history.order"))
            .accessibilityValue(Text(order.localizedTitle))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func controlValue(_ value: LocalizedStringResource) -> some View {
        Label {
            Text(value)
        } icon: {
            Image(systemName: "chevron.up.chevron.down")
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(.interaction, Rectangle())
        .padding(.vertical, 4)
    }
}

#Preview("Queries", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @AccessibilityFocusState var filterIsFocused: Bool
    List {
        Section {
            SalesHistoryFilters(
                filter: .constant(.all),
                order: .constant(.newestFirst),
                filterIsFocused: $filterIsFocused
            )
        }
    }
}
