import SwiftUI

struct ClientFormFieldsContent: View {
    @Binding var fields: ClientFormFields
    let nameError: LocalizedStringResource?
    let validationAttemptID: UUID?
    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var nameIsAccessibilityFocused: Bool

    private enum Field: Hashable {
        case name, tax, street, postal, city, province
    }

    var body: some View {
        Group {
            FormFieldSection(.clientsFormNameLabel, systemImage: "person") {
                TextField(
                    .clientsFormNameLabel,
                    text: $fields.displayName,
                    prompt: Text(verbatim: ""),
                    axis: .vertical
                )
                    .accessibilityLabel(.clientsFormNameLabel)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .name)
                    .accessibilityFocused($nameIsAccessibilityFocused)
                    .accessibilityHint(.clientsFormErrorName, isEnabled: nameError != nil)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .tax
                    }
                    .frame(minHeight: 44)
                if let nameError {
                    Text(nameError)
                        .foregroundStyle(.errorInk)
                }
            }
            FormFieldSection(.clientsFormTaxLabel, systemImage: "person.text.rectangle") {
                TextField(.clientsFormTaxLabel, text: $fields.taxIdentifier, prompt: Text(verbatim: ""))
                    .accessibilityLabel(.clientsFormTaxLabel)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .tax)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .street
                    }
                    .frame(minHeight: 44)
            }
            FormFieldSection(.clientsFormStreetLabel, systemImage: "mappin.and.ellipse") {
                TextField(
                    .clientsFormStreetLabel,
                    text: $fields.streetLine,
                    prompt: Text(verbatim: ""),
                    axis: .vertical
                )
                    .accessibilityLabel(.clientsFormStreetLabel)
                    .textContentType(.streetAddressLine1)
                    .focused($focusedField, equals: .street)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .postal
                    }
                    .frame(minHeight: 44)
            }
            FormFieldSection(.clientsFormPostalLabel, systemImage: "envelope") {
                TextField(.clientsFormPostalLabel, text: $fields.postalCode, prompt: Text(verbatim: ""))
                    .accessibilityLabel(.clientsFormPostalLabel)
                    .textContentType(.postalCode)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .postal)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .city
                    }
                    .frame(minHeight: 44)
            }
            FormFieldSection(.clientsFormCityLabel, systemImage: "building.2") {
                TextField(
                    .clientsFormCityLabel,
                    text: $fields.city,
                    prompt: Text(verbatim: ""),
                    axis: .vertical
                )
                    .accessibilityLabel(.clientsFormCityLabel)
                    .textContentType(.addressCity)
                    .focused($focusedField, equals: .city)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .province
                    }
                    .frame(minHeight: 44)
            }
            FormFieldSection(.clientsFormProvinceLabel, systemImage: "map") {
                TextField(
                    .clientsFormProvinceLabel,
                    text: $fields.province,
                    prompt: Text(verbatim: ""),
                    axis: .vertical
                )
                    .accessibilityLabel(.clientsFormProvinceLabel)
                    .textContentType(.addressState)
                    .focused($focusedField, equals: .province)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
                    .frame(minHeight: 44)
            }
        }
        .onChange(of: validationAttemptID) {
            guard nameError != nil else { return }
            focusedField = .name
            nameIsAccessibilityFocused = true
        }
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields(AppPreviewFixtures.standard.secondaryClient)

    Form {
        ClientFormFieldsContent(fields: $fields, nameError: nil, validationAttemptID: nil)
    }
}
