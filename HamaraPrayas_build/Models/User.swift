import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let bloodType: BloodType?
    let dateOfBirth: Date?
    let emergencyContact: EmergencyContact?
    let isDonor: Bool
    let lastDonationDate: Date?
    let createdAt: Date
    var profileImageURL: String?
    var city: String?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(
        id: UUID = UUID(),
        email: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        bloodType: BloodType? = nil,
        dateOfBirth: Date? = nil,
        emergencyContact: EmergencyContact? = nil,
        isDonor: Bool = false,
        lastDonationDate: Date? = nil,
        profileImageURL: String? = nil,
        city: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.bloodType = bloodType
        self.dateOfBirth = dateOfBirth
        self.emergencyContact = emergencyContact
        self.isDonor = isDonor
        self.lastDonationDate = lastDonationDate
        self.profileImageURL = profileImageURL
        self.city = city
        self.createdAt = createdAt
    }
}

struct EmergencyContact: Codable {
    let name: String
    let relationship: String
    let phoneNumber: String
    let email: String?
}

struct LoginCredentials: Codable {
    let email: String
    let password: String
}

struct RegistrationData: Codable {
    let email: String
    let password: String
    let confirmPassword: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let bloodType: BloodType?
    let dateOfBirth: Date?
    let isDonor: Bool
}

