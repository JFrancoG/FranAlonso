import SwiftUI

struct SaleHistoryTraceSection: View {
    let sale: Sale

    var body: some View {
        Section {
            reference("sales.history.saleReference", id: sale.id.rawValue)
            date("sales.history.createdAt", value: sale.createdAt)
            switch sale.status {
            case let .closed(paymentID, method, paidAt, documentID, closedAt):
                payment(id: paymentID, method: method, paidAt: paidAt)
                reference("sales.history.documentReference", id: documentID.rawValue)
                date("sales.history.closedAt", value: closedAt)
            case let .voided(paymentID, method, paidAt, documentID, closedAt, reversalID, voidedAt):
                payment(id: paymentID, method: method, paidAt: paidAt)
                reference("sales.history.documentReference", id: documentID.rawValue)
                date("sales.history.closedAt", value: closedAt)
                reference("sales.history.reversalReference", id: reversalID.rawValue)
                date("sales.history.voidedAt", value: voidedAt)
            default:
                EmptyView()
            }
        } header: {
            Text("sales.history.trace").textCase(nil).accessibilityAddTraits(.isHeader)
        }
    }

    private func reference(_ title: LocalizedStringResource, id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(id.uuidString).textSelection(.enabled)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func date(_ title: LocalizedStringResource, value: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(value, format: .dateTime.day().month().year().hour().minute())
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func payment(id: PaymentID, method: PaymentMethod, paidAt: Date) -> some View {
        reference("sales.history.paymentReference", id: id.rawValue)
        VStack(alignment: .leading, spacing: 4) {
            Text("sales.history.paymentMethod").font(.headline)
            Text(method == .cash ? LocalizedStringResource("sales.history.cash") :
                LocalizedStringResource("sales.history.card"))
        }
        .accessibilityElement(children: .combine)
        date("sales.history.paidAt", value: paidAt)
    }
}

#Preview("Compensation trace", traits: .modifier(SalesHistoryPreviewModifier())) {
    Form {
        SaleHistoryTraceSection(sale: SalesPreviewFixtures.history.sales[1])
    }
}
