//
//  PlacesService.swift
//  HamaraPrayas_build
//
//  Blood Bank search service - prioritizes verified blood banks from Firebase,
//  then supplements with OpenStreetMap data for actual blood banks.
//

import Foundation
import CoreLocation
import FirebaseFirestore

class PlacesService: ObservableObject {
    @Published var nearbyBloodBanks: [BloodBank] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // MARK: - Main Search Function
    func searchNearbyBloodBanks(location: CLLocationCoordinate2D, radius: Double = 50000) {
        isLoading = true
        errorMessage = nil
        
        print("🔍 Searching for blood banks at location: \(location.latitude), \(location.longitude)")
        
        // Fetch from all sources in parallel, then combine
        var verifiedBanks: [BloodBank] = []
        var osmBloodBanks: [BloodBank] = []
        var hospitalBanks: [BloodBank] = []
        
        let group = DispatchGroup()
        
        // 1. Fetch verified blood banks from Firebase
        group.enter()
        fetchVerifiedBloodBanks(location: location) { banks in
            verifiedBanks = banks
            group.leave()
        }
        
        // 2. Fetch dedicated blood banks from OSM
        group.enter()
        fetchOSMBloodBanks(location: location, radius: radius) { banks in
            osmBloodBanks = banks
            group.leave()
        }
        
        // 3. Always fetch hospitals as backup (they usually have blood banks)
        group.enter()
        fetchHospitals(location: location, radius: radius) { banks in
            hospitalBanks = banks
            group.leave()
        }
        
        // Combine all results
        group.notify(queue: .main) { [weak self] in
            var allBanks: [BloodBank] = []
            var seenNames = Set<String>()
            
            // Add verified banks first (highest priority)
            for bank in verifiedBanks {
                allBanks.append(bank)
                seenNames.insert(bank.name.lowercased())
            }
            
            // Add OSM blood banks (avoid duplicates)
            for bank in osmBloodBanks {
                if !seenNames.contains(bank.name.lowercased()) {
                    allBanks.append(bank)
                    seenNames.insert(bank.name.lowercased())
                }
            }
            
            // Add hospitals (avoid duplicates)
            for bank in hospitalBanks {
                if !seenNames.contains(bank.name.lowercased()) {
                    allBanks.append(bank)
                    seenNames.insert(bank.name.lowercased())
                }
            }
            
            // Sort by: verified first, then by distance
            allBanks.sort { lhs, rhs in
                if lhs.isVerified != rhs.isVerified {
                    return lhs.isVerified
                }
                return (lhs.distance ?? Double.greatestFiniteMagnitude) < (rhs.distance ?? Double.greatestFiniteMagnitude)
            }
            
            self?.nearbyBloodBanks = allBanks
            self?.isLoading = false
            
            if allBanks.isEmpty {
                self?.errorMessage = "No blood banks found in your area. Try increasing the search radius."
            }
            
            print("✅ Total results: \(allBanks.count) (\(verifiedBanks.count) verified, \(osmBloodBanks.count) blood banks, \(hospitalBanks.count) hospitals)")
        }
    }
    
    // MARK: - Fetch Verified Blood Banks from Firebase
    private func fetchVerifiedBloodBanks(location: CLLocationCoordinate2D, completion: @escaping ([BloodBank]) -> Void) {
        print("📦 Fetching verified blood banks from Firebase...")
        
        db.collection("verified_blood_banks").getDocuments { [weak self] snapshot, error in
            if let error = error {
                // Silently handle permission errors - collection may not exist yet
                print("ℹ️ Verified blood banks not available: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("📭 No verified blood banks in database")
                completion([])
                return
            }
            
            let bloodBanks = documents.compactMap { doc -> BloodBank? in
                let data = doc.data()
                
                guard let name = data["name"] as? String,
                      let lat = data["latitude"] as? Double,
                      let lon = data["longitude"] as? Double else {
                    return nil
                }
                
                let bankLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                // Calculate distance and filter by radius (100km max)
                let distance = self?.calculateDistance(from: location, to: bankLocation) ?? 0
                guard distance <= 100 else { return nil }
                
                // Parse blood inventory if available
                var inventory: [BloodType: Int] = [:]
                if let inventoryData = data["bloodInventory"] as? [String: Int] {
                    for (key, value) in inventoryData {
                        if let bloodType = BloodType(rawValue: key) {
                            inventory[bloodType] = value
                        }
                    }
                }
                
                var bank = BloodBank(
                    name: name,
                    address: data["address"] as? String ?? "Address not available",
                    phoneNumber: data["phoneNumber"] as? String ?? "Contact facility",
                    email: data["email"] as? String,
                    website: data["website"] as? String,
                    location: bankLocation,
                    operatingHours: data["operatingHours"] as? String ?? "Check with facility",
                    isOpen: data["isOpen"] as? Bool ?? true,
                    bloodInventory: inventory,
                    rating: data["rating"] as? Double ?? 4.5,
                    isVerified: true
                )
                bank.distance = distance
                
                return bank
            }
            
            // Sort by distance
            let sortedBanks = bloodBanks.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
            print("✅ Found \(sortedBanks.count) verified blood banks")
            completion(sortedBanks)
        }
    }
    
    // MARK: - Fetch Blood Banks from OpenStreetMap
    private func fetchOSMBloodBanks(location: CLLocationCoordinate2D, radius: Double, completion: @escaping ([BloodBank]) -> Void) {
        print("🌐 Fetching blood banks from OpenStreetMap...")
        
        // Search specifically for blood banks and blood donation centers
        let query = """
        [out:json][timeout:30];
        (
          node["healthcare"="blood_bank"](around:\(radius),\(location.latitude),\(location.longitude));
          way["healthcare"="blood_bank"](around:\(radius),\(location.latitude),\(location.longitude));
          node["healthcare"="blood_donation"](around:\(radius),\(location.latitude),\(location.longitude));
          way["healthcare"="blood_donation"](around:\(radius),\(location.latitude),\(location.longitude));
          node["amenity"="blood_bank"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="blood_bank"](around:\(radius),\(location.latitude),\(location.longitude));
          node["name"~"[Bb]lood.*[Bb]ank|[Bb]lood.*[Cc]enter|[Bb]lood.*[Cc]entre|Red Cross"](around:\(radius),\(location.latitude),\(location.longitude));
          way["name"~"[Bb]lood.*[Bb]ank|[Bb]lood.*[Cc]enter|[Bb]lood.*[Cc]entre|Red Cross"](around:\(radius),\(location.latitude),\(location.longitude));
        );
        out body;
        """
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid OSM URL")
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ OSM network error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("❌ No OSM data received")
                completion([])
                return
            }
            
            do {
                let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
                print("🔍 OSM returned \(overpassResponse.elements.count) blood bank elements")
                
                let bloodBanks = overpassResponse.elements.compactMap { element -> BloodBank? in
                    self?.convertOverpassElementToBloodBank(element, userLocation: location, isVerified: false, isBloodBank: true)
                }
                
                completion(bloodBanks)
            } catch {
                print("❌ Error parsing OSM data: \(error.localizedDescription)")
                completion([])
            }
        }
        
        task.resume()
    }
    
    // MARK: - Fetch Hospitals (they usually have blood banks)
    private func fetchHospitals(location: CLLocationCoordinate2D, radius: Double, completion: @escaping ([BloodBank]) -> Void) {
        print("🏥 Fetching hospitals...")
        
        let query = """
        [out:json][timeout:30];
        (
          node["amenity"="hospital"]["name"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="hospital"]["name"](around:\(radius),\(location.latitude),\(location.longitude));
        );
        out body;
        """
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
                
                let bloodBanks = overpassResponse.elements.compactMap { element -> BloodBank? in
                    guard element.tags?.amenity == "hospital",
                          element.tags?.name != nil else {
                        return nil
                    }
                    return self?.convertOverpassElementToBloodBank(element, userLocation: location, isVerified: false, isBloodBank: false)
                }
                
                print("🏥 Found \(bloodBanks.count) hospitals")
                completion(bloodBanks)
            } catch {
                completion([])
            }
        }
        
        task.resume()
    }
    
    // MARK: - Convert OSM Element to BloodBank
    private func convertOverpassElementToBloodBank(_ element: OverpassElement, userLocation: CLLocationCoordinate2D, isVerified: Bool, isBloodBank: Bool = true) -> BloodBank? {
        guard let lat = element.lat, let lon = element.lon else {
            print("❌ Element missing lat/lon: \(element.id)")
            return nil
        }
        
        let name = element.tags?.name ?? element.tags?.operator_name ?? "Blood Bank"
        let address = buildFullAddress(from: element.tags)
        let phone = element.tags?.phone ?? element.tags?.contact_phone ?? "Contact facility directly"
        
        // Format display name based on whether it's a dedicated blood bank or hospital
        let displayName: String
        if isBloodBank {
            displayName = name
        } else {
            // It's a hospital - add indicator that it may have blood bank
            displayName = name.lowercased().contains("blood") ? name : "\(name) - Blood Bank"
        }
        
        let bankLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let distance = calculateDistance(from: userLocation, to: bankLocation)
        
        var bloodBank = BloodBank(
            name: displayName,
            address: address,
            phoneNumber: phone,
            email: element.tags?.email,
            website: element.tags?.website,
            location: bankLocation,
            operatingHours: element.tags?.opening_hours ?? "Check with facility",
            isOpen: true,
            bloodInventory: [:],
            rating: isVerified ? 4.5 : Double.random(in: 3.5...4.5),
            isVerified: isVerified
        )
        bloodBank.distance = distance
        
        print("✅ Created BloodBank: \(displayName) at \(lat), \(lon)")
        return bloodBank
    }
    
    // MARK: - Helper Methods
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to km
    }
    
    private func buildFullAddress(from tags: OverpassTags?) -> String {
        guard let tags = tags else { return "Address not available" }
        
        var addressComponents: [String] = []
        
        if let housenumber = tags.addr_housenumber {
            addressComponents.append(housenumber)
        }
        if let street = tags.addr_street {
            addressComponents.append(street)
        }
        if let city = tags.addr_city {
            addressComponents.append(city)
        }
        if let postcode = tags.addr_postcode {
            addressComponents.append(postcode)
        }
        
        if addressComponents.isEmpty {
            return tags.addr_full ?? "Address not available"
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    private func formatDisplayName(name: String, facilityType: String) -> String {
        // If it's a hospital being used as fallback, indicate it may have a blood bank
        if facilityType == "hospital" && !name.lowercased().contains("blood") {
            return "\(name) (Blood Bank)"
        }
        return name
    }
}

// MARK: - OpenStreetMap Data Models
struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: OverpassTags?
}

struct OverpassTags: Codable {
    let name: String?
    let operator_name: String?
    let addr_street: String?
    let addr_full: String?
    let addr_housenumber: String?
    let addr_postcode: String?
    let addr_city: String?
    let phone: String?
    let contact_phone: String?
    let email: String?
    let website: String?
    let opening_hours: String?
    let amenity: String?
    let healthcare: String?
    let emergency: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case operator_name = "operator"
        case addr_street = "addr:street"
        case addr_full = "addr:full"
        case addr_housenumber = "addr:housenumber"
        case addr_postcode = "addr:postcode"
        case addr_city = "addr:city"
        case phone
        case contact_phone = "contact:phone"
        case email
        case website
        case opening_hours
        case amenity
        case healthcare
        case emergency
    }
}
