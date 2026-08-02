import Foundation

/// A violation of an appointment's schedule, references, or lifecycle.
enum AppointmentError: Error, Equatable {
    /// The appointment does not end after it starts.
    case invalidSchedule

    /// A saved appointment must reference at least one service.
    case missingServiceReferences

    /// The same service cannot appear more than once without an explicit quantity model.
    case duplicateServiceReference

    /// The requested lifecycle change is unavailable from the current state.
    case invalidTransition
}

/// The finite lifecycle state of a local demo appointment.
enum AppointmentStatus: Codable, Equatable {
    /// The appointment remains scheduled.
    case scheduled

    /// The appointment was cancelled and retains when that transition occurred.
    case cancelled(cancelledAt: Date)
}

/// A local demo appointment linked to one client and an ordered set of services.
///
/// The entity validates its own time bounds and reference shape. Catalog activity,
/// overlap policy, daily grouping, and persistence remain outside this aggregate.
struct Appointment: Identifiable, Codable, Equatable {
    let id: AppointmentID
    let clientID: ClientID
    private let storedServiceIDs: [ServiceID]
    let startsAt: Date
    let endsAt: Date
    private var storedStatus: AppointmentStatus

    var serviceIDs: [ServiceID] {
        storedServiceIDs
    }

    var status: AppointmentStatus {
        storedStatus
    }

    /// Cancels a scheduled appointment without changing its client, services, or time bounds.
    ///
    /// - Parameter cancelledAt: The timestamp at which cancellation occurred.
    /// - Throws: `AppointmentError.invalidTransition` if the appointment is already cancelled.
    mutating func cancel(at cancelledAt: Date) throws {
        guard status == .scheduled else { throw AppointmentError.invalidTransition }

        storedStatus = .cancelled(cancelledAt: cancelledAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case clientID
        case serviceIDs
        case startsAt
        case endsAt
        case status
    }
}

extension Appointment {
    /// Creates a scheduled appointment for a client and ordered service references.
    ///
    /// - Parameters:
    ///   - id: The appointment's stable identity.
    ///   - clientID: The referenced client's stable identity.
    ///   - serviceIDs: One or more unique service identities in display order.
    ///   - startsAt: The inclusive start instant.
    ///   - endsAt: The end instant, which must follow `startsAt`.
    /// - Returns: An appointment in `AppointmentStatus.scheduled`.
    /// - Throws: `AppointmentError.invalidSchedule` for non-positive duration,
    ///   `AppointmentError.missingServiceReferences` for an empty service list,
    ///   or `AppointmentError.duplicateServiceReference` for repeated identities.
    static func scheduled(
        id: AppointmentID,
        clientID: ClientID,
        serviceIDs: [ServiceID],
        startsAt: Date,
        endsAt: Date
    ) throws -> Appointment {
        try ensureValid(
            serviceIDs: serviceIDs,
            startsAt: startsAt,
            endsAt: endsAt
        )

        return Appointment(
            id: id,
            clientID: clientID,
            storedServiceIDs: serviceIDs,
            startsAt: startsAt,
            endsAt: endsAt,
            storedStatus: .scheduled
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serviceIDs = try container.decode([ServiceID].self, forKey: .serviceIDs)
        let startsAt = try container.decode(Date.self, forKey: .startsAt)
        let endsAt = try container.decode(Date.self, forKey: .endsAt)

        try Self.ensureValid(
            serviceIDs: serviceIDs,
            startsAt: startsAt,
            endsAt: endsAt
        )

        self.init(
            id: try container.decode(AppointmentID.self, forKey: .id),
            clientID: try container.decode(ClientID.self, forKey: .clientID),
            storedServiceIDs: serviceIDs,
            startsAt: startsAt,
            endsAt: endsAt,
            storedStatus: try container.decode(AppointmentStatus.self, forKey: .status)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(serviceIDs, forKey: .serviceIDs)
        try container.encode(startsAt, forKey: .startsAt)
        try container.encode(endsAt, forKey: .endsAt)
        try container.encode(status, forKey: .status)
    }

    private static func ensureValid(serviceIDs: [ServiceID], startsAt: Date, endsAt: Date) throws {
        guard startsAt < endsAt else { throw AppointmentError.invalidSchedule }
        guard !serviceIDs.isEmpty else { throw AppointmentError.missingServiceReferences }
        guard Set(serviceIDs).count == serviceIDs.count else {
            throw AppointmentError.duplicateServiceReference
        }
    }
}
