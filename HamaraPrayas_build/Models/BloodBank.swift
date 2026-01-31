import Foundation
import CoreLocation

struct BloodBank: Identifiable, Codable {
    var id: UUID
    var name: String
    var address: String
    var phoneNumber: String
    var email: String?
    var website: String?
    var location: CLLocationCoordinate2D
    var operatingHours: String
    var isOpen: Bool
    var bloodInventory: [BloodType: Int]
    var rating: Double
    var distance: Double?
    var isVerified: Bool  // NEW: Indicates if this is a verified blood bank from our database
    
    init(name: String, address: String, phoneNumber: String, email: String? = nil, website: String? = nil, location: CLLocationCoordinate2D, operatingHours: String, isOpen: Bool = true, bloodInventory: [BloodType: Int] = [:], rating: Double = 0.0, isVerified: Bool = false) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.phoneNumber = phoneNumber
        self.email = email
        self.website = website
        self.location = location
        self.operatingHours = operatingHours
        self.isOpen = isOpen
        self.bloodInventory = bloodInventory
        self.rating = rating
        self.isVerified = isVerified
    }
    
    func hasBloodType(_ bloodType: BloodType, units: Int = 1) -> Bool {
        return bloodInventory[bloodType, default: 0] >= units
    }
    
    func distanceFrom(_ userLocation: CLLocationCoordinate2D) -> Double {
        let bankLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return bankLocation.distance(from: userLoc) / 1000 // Convert to kilometers
    }
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case phoneNumber
        case email
        case website
        case location
        case operatingHours
        case isOpen
        case bloodInventory
        case rating
        case distance
        case isVerified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        location = try container.decode(CLLocationCoordinate2D.self, forKey: .location)
        operatingHours = try container.decode(String.self, forKey: .operatingHours)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        let inventoryRaw = try container.decode([String: Int].self, forKey: .bloodInventory)
        bloodInventory = Dictionary(uniqueKeysWithValues: inventoryRaw.compactMap { key, value in
            guard let type = BloodType(rawValue: key) else { return nil }
            return (type, value)
        })
        rating = try container.decode(Double.self, forKey: .rating)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encode(location, forKey: .location)
        try container.encode(operatingHours, forKey: .operatingHours)
        try container.encode(isOpen, forKey: .isOpen)
        let inventoryRaw = Dictionary(uniqueKeysWithValues: bloodInventory.map { ($0.key.rawValue, $0.value) })
        try container.encode(inventoryRaw, forKey: .bloodInventory)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(isVerified, forKey: .isVerified)
    }
}

// Sample blood bank data
extension BloodBank {
    static let sampleBloodBanks = [
        BloodBank(
            name: "City General Hospital Blood Bank",
            address: "123 Main Street, Downtown",
            phoneNumber: "+1-555-0123",
            email: "bloodbank@citygeneral.com",
            website: "www.citygeneral.com",
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            operatingHours: "24/7",
            bloodInventory: [
                .aPositive: 50,
                .aNegative: 25,
                .bPositive: 40,
                .bNegative: 20,
                .abPositive: 15,
                .abNegative: 10,
                .oPositive: 60,
                .oNegative: 30
            ],
            rating: 4.5
        ),
        BloodBank(
            name: "Red Cross Blood Center",
            address: "456 Oak Avenue, Midtown",
            phoneNumber: "+1-555-0456",
            email: "info@redcross.org",
            website: "www.redcross.org",
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            operatingHours: "Mon-Fri: 8AM-6PM, Sat: 9AM-4PM",
            bloodInventory: [
                .aPositive: 75,
                .aNegative: 35,
                .bPositive: 55,
                .bNegative: 25,
                .abPositive: 20,
                .abNegative: 15,
                .oPositive: 80,
                .oNegative: 40
            ],
            rating: 4.8
        ),
        BloodBank(
            name: "Community Blood Services",
            address: "789 Pine Street, Uptown",
            phoneNumber: "+1-555-0789",
            email: "donate@communityblood.org",
            website: "www.communityblood.org",
            location: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
            operatingHours: "Mon-Sun: 7AM-8PM",
            bloodInventory: [
                .aPositive: 30,
                .aNegative: 15,
                .bPositive: 25,
                .bNegative: 12,
                .abPositive: 8,
                .abNegative: 5,
                .oPositive: 35,
                .oNegative: 18
            ],
            rating: 4.2
        )
    ]
}
