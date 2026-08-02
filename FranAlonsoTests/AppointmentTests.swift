import Foundation
import Testing
@testable import FranAlonso

@Suite("Appointment")
struct AppointmentTests {
    @Test("Creates a scheduled appointment with ordered references")
    func createsAScheduledAppointmentWithOrderedReferences() throws {
        let firstServiceID = appointmentServiceID("10000000-0000-0000-0000-000000000001")
        let secondServiceID = appointmentServiceID("10000000-0000-0000-0000-000000000002")
        let appointment = try scheduledAppointment(
            serviceIDs: [firstServiceID, secondServiceID]
        )

        #expect(appointment.id == appointmentID("10000000-0000-0000-0000-000000000003"))
        #expect(appointment.clientID == appointmentClientID("10000000-0000-0000-0000-000000000004"))
        #expect(appointment.serviceIDs == [firstServiceID, secondServiceID])
        #expect(appointment.startsAt == appointmentDate(0))
        #expect(appointment.endsAt == appointmentDate(3_600))
        #expect(appointment.status == .scheduled)
        requireAppointmentSendable(appointment)
    }

    @Test(
        "Rejects a non-positive appointment duration",
        arguments: [(0.0, 0.0), (1.0, 0.0)]
    )
    func rejectsANonPositiveAppointmentDuration(startsOffset: TimeInterval, endsOffset: TimeInterval) {
        #expect(throws: AppointmentError.invalidSchedule) {
            try Appointment.scheduled(
                id: appointmentID("20000000-0000-0000-0000-000000000001"),
                clientID: appointmentClientID("20000000-0000-0000-0000-000000000002"),
                serviceIDs: [appointmentServiceID("20000000-0000-0000-0000-000000000003")],
                startsAt: appointmentDate(startsOffset),
                endsAt: appointmentDate(endsOffset)
            )
        }
    }

    @Test("Rejects an appointment without service references")
    func rejectsAnAppointmentWithoutServiceReferences() {
        #expect(throws: AppointmentError.missingServiceReferences) {
            try scheduledAppointment(serviceIDs: [])
        }
    }

    @Test("Rejects duplicate service references")
    func rejectsDuplicateServiceReferences() {
        let serviceID = appointmentServiceID("30000000-0000-0000-0000-000000000001")

        #expect(throws: AppointmentError.duplicateServiceReference) {
            try scheduledAppointment(serviceIDs: [serviceID, serviceID])
        }
    }

    @Test("Cancellation is a terminal metadata transition")
    func cancellationIsATerminalMetadataTransition() throws {
        var appointment = try scheduledAppointment()
        let id = appointment.id
        let clientID = appointment.clientID
        let serviceIDs = appointment.serviceIDs
        let startsAt = appointment.startsAt
        let endsAt = appointment.endsAt
        let cancelledAt = appointmentDate(-1_800)

        try appointment.cancel(at: cancelledAt)

        #expect(appointment.status == .cancelled(cancelledAt: cancelledAt))
        #expect(appointment.id == id)
        #expect(appointment.clientID == clientID)
        #expect(appointment.serviceIDs == serviceIDs)
        #expect(appointment.startsAt == startsAt)
        #expect(appointment.endsAt == endsAt)
    }

    @Test("Rejects a second cancellation without changing metadata")
    func rejectsASecondCancellationWithoutChangingMetadata() throws {
        var appointment = try scheduledAppointment()
        let firstCancellation = appointmentDate(-1_800)
        try appointment.cancel(at: firstCancellation)

        #expect(throws: AppointmentError.invalidTransition) {
            try appointment.cancel(at: appointmentDate(-900))
        }
        #expect(appointment.status == .cancelled(cancelledAt: firstCancellation))
    }

    @Test("Preserves scheduled and cancelled appointments through Codable")
    func preservesAppointmentsThroughCodable() throws {
        let scheduled = try scheduledAppointment()
        var cancelled = scheduled
        try cancelled.cancel(at: appointmentDate(-1_800))

        #expect(try appointmentRoundTrip(scheduled) == scheduled)
        #expect(try appointmentRoundTrip(cancelled) == cancelled)
    }

    @Test(
        "Decoding cannot bypass schedule validation",
        arguments: [
            AppointmentStatus.scheduled,
            .cancelled(cancelledAt: appointmentDate(-1_800))
        ]
    )
    func decodingCannotBypassScheduleValidation(status: AppointmentStatus) throws {
        let payload = AppointmentPayload(
            id: appointmentID("40000000-0000-0000-0000-000000000001"),
            clientID: appointmentClientID("40000000-0000-0000-0000-000000000002"),
            serviceIDs: [appointmentServiceID("40000000-0000-0000-0000-000000000003")],
            startsAt: appointmentDate(0),
            endsAt: appointmentDate(0),
            status: status
        )

        #expect(throws: AppointmentError.invalidSchedule) {
            try JSONDecoder().decode(
                Appointment.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test(
        "Decoding cannot bypass service-reference validation",
        arguments: [InvalidAppointmentReferences.empty, .duplicate]
    )
    func decodingCannotBypassServiceReferenceValidation(invalidReferences: InvalidAppointmentReferences) throws {
        let payload = AppointmentPayload(
            id: appointmentID("50000000-0000-0000-0000-000000000001"),
            clientID: appointmentClientID("50000000-0000-0000-0000-000000000002"),
            serviceIDs: invalidReferences.serviceIDs,
            startsAt: appointmentDate(0),
            endsAt: appointmentDate(3_600),
            status: .scheduled
        )

        #expect(throws: invalidReferences.expectedError) {
            try JSONDecoder().decode(
                Appointment.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }
}

enum InvalidAppointmentReferences {
    case empty
    case duplicate

    var serviceIDs: [ServiceID] {
        switch self {
        case .empty:
            []
        case .duplicate:
            [
                appointmentServiceID("60000000-0000-0000-0000-000000000001"),
                appointmentServiceID("60000000-0000-0000-0000-000000000001")
            ]
        }
    }

    var expectedError: AppointmentError {
        switch self {
        case .empty:
            .missingServiceReferences
        case .duplicate:
            .duplicateServiceReference
        }
    }
}

private struct AppointmentPayload: Codable {
    let id: AppointmentID
    let clientID: ClientID
    let serviceIDs: [ServiceID]
    let startsAt: Date
    let endsAt: Date
    let status: AppointmentStatus
}

private func scheduledAppointment(
    serviceIDs: [ServiceID] = [appointmentServiceID("00000000-0000-0000-0000-000000000001")]
) throws -> Appointment {
    try Appointment.scheduled(
        id: appointmentID("10000000-0000-0000-0000-000000000003"),
        clientID: appointmentClientID("10000000-0000-0000-0000-000000000004"),
        serviceIDs: serviceIDs,
        startsAt: appointmentDate(0),
        endsAt: appointmentDate(3_600)
    )
}

private func appointmentRoundTrip(_ appointment: Appointment) throws -> Appointment {
    try JSONDecoder().decode(
        Appointment.self,
        from: JSONEncoder().encode(appointment)
    )
}

private func appointmentID(_ value: String) -> AppointmentID {
    AppointmentID(rawValue: UUID(uuidString: value)!)
}

private func appointmentClientID(_ value: String) -> ClientID {
    ClientID(rawValue: UUID(uuidString: value)!)
}

private func appointmentServiceID(_ value: String) -> ServiceID {
    ServiceID(rawValue: UUID(uuidString: value)!)
}

private func appointmentDate(_ offset: TimeInterval) -> Date {
    Date(timeIntervalSince1970: 1_800_000_000 + offset)
}

private func requireAppointmentSendable<Value: Sendable>(_ value: Value) {}
