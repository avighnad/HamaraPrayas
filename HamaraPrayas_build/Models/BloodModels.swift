import Foundation

enum BloodType: String, CaseIterable, Codable, Hashable, Identifiable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

enum UrgencyLevel: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

enum RequestStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case fulfilled = "Fulfilled"
    case cancelled = "Cancelled"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .inProgress: return "blue"
        case .fulfilled: return "green"
        case .cancelled: return "red"
        }
    }
}

struct BloodRequest: Identifiable, Codable {
    let id: UUID
    let patientName: String
    let bloodType: BloodType
    let unitsNeeded: Int
    let urgency: UrgencyLevel
    let hospital: String
    let contactNumber: String
    let requestDate: Date
    let additionalNotes: String
    var status: RequestStatus

    init(
        id: UUID = UUID(),
        patientName: String,
        bloodType: BloodType,
        unitsNeeded: Int,
        urgency: UrgencyLevel,
        hospital: String,
        contactNumber: String,
        additionalNotes: String = "",
        requestDate: Date = Date(),
        status: RequestStatus = .pending
    ) {
        self.id = id
        self.patientName = patientName
        self.bloodType = bloodType
        self.unitsNeeded = unitsNeeded
        self.urgency = urgency
        self.hospital = hospital
        self.contactNumber = contactNumber
        self.requestDate = requestDate
        self.additionalNotes = additionalNotes
        self.status = status
    }
}

// MARK: - Community Help Request Model
struct HelpRequest: Identifiable, Codable {
    let id: String
    let patientName: String
    let bloodType: BloodType
    let unitsNeeded: Int
    let urgency: UrgencyLevel
    let hospital: String
    let city: String
    let requestDate: Date
    let additionalNotes: String
    let requesterUserId: String
    let isAnonymous: Bool
    var status: RequestStatus
    
    init(
        id: String = UUID().uuidString,
        patientName: String,
        bloodType: BloodType,
        unitsNeeded: Int,
        urgency: UrgencyLevel,
        hospital: String,
        city: String,
        additionalNotes: String = "",
        requesterUserId: String,
        isAnonymous: Bool = false,
        requestDate: Date = Date(),
        status: RequestStatus = .pending
    ) {
        self.id = id
        self.patientName = patientName
        self.bloodType = bloodType
        self.unitsNeeded = unitsNeeded
        self.urgency = urgency
        self.hospital = hospital
        self.city = city
        self.additionalNotes = additionalNotes
        self.requesterUserId = requesterUserId
        self.isAnonymous = isAnonymous
        self.requestDate = requestDate
        self.status = status
    }
}



