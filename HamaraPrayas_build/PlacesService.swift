import Foundation
import CoreLocation

class PlacesService: ObservableObject {
    @Published var nearbyBloodBanks: [BloodBank] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func searchNearbyBloodBanks(location: CLLocationCoordinate2D, radius: Double = 50000) {
        isLoading = true
        errorMessage = nil
        
        print("🔍 NEW API CALL: Searching for hospitals at location: \(location.latitude), \(location.longitude)")
        print("📡 Making fresh request to OpenStreetMap API...")
        
        // Enhanced OpenStreetMap Overpass API query for hospitals and medical facilities
        // First try with radius, then try broader city search
        let query = """
        [out:json][timeout:30];
        (
          node["amenity"="hospital"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="hospital"](around:\(radius),\(location.latitude),\(location.longitude));
          node["healthcare"="hospital"](around:\(radius),\(location.latitude),\(location.longitude));
          way["healthcare"="hospital"](around:\(radius),\(location.latitude),\(location.longitude));
          node["amenity"="clinic"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="clinic"](around:\(radius),\(location.latitude),\(location.longitude));
          node["healthcare"="clinic"](around:\(radius),\(location.latitude),\(location.longitude));
          way["healthcare"="clinic"](around:\(radius),\(location.latitude),\(location.longitude));
          node["amenity"="doctors"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="doctors"](around:\(radius),\(location.latitude),\(location.longitude));
          node["healthcare"="doctors"](around:\(radius),\(location.latitude),\(location.longitude));
          way["healthcare"="doctors"](around:\(radius),\(location.latitude),\(location.longitude));
          node["amenity"="pharmacy"](around:\(radius),\(location.latitude),\(location.longitude));
          way["amenity"="pharmacy"](around:\(radius),\(location.latitude),\(location.longitude));
        );
        out body;
        """
        
        print("📡 Query: \(query)")
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        print("🌐 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL"
                print("❌ Invalid URL")
            }
            return
        }
        
        print("📡 Making network request...")
        
        // Add timeout
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "Unable to load blood banks - check your internet connection"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                    
                    // Handle server errors
                    if httpResponse.statusCode >= 500 {
                        print("❌ Server error: \(httpResponse.statusCode)")
                        self?.nearbyBloodBanks = []
                        self?.errorMessage = "Unable to load blood banks - server temporarily unavailable"
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ No data received")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "No blood banks found in your area"
                    return
                }
                
                print("📦 Received \(data.count) bytes of data")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString.prefix(500))...")
                }
                
                                 do {
                     let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
                     print("🔍 Processing \(overpassResponse.elements.count) elements from OpenStreetMap")
                     
                     let bloodBanks = overpassResponse.elements.compactMap { element in
                         self?.convertOverpassElementToBloodBank(element)
                     }
                     
                     print("✅ Successfully converted \(bloodBanks.count) elements to BloodBank objects")
                     
                     if bloodBanks.isEmpty {
                         // No hospitals found in OpenStreetMap, try broader search
                         print("No hospitals found in OpenStreetMap, trying broader search...")
                         self?.searchBroaderArea(location: location)
                     } else {
                         self?.nearbyBloodBanks = bloodBanks
                         print("Found \(bloodBanks.count) hospitals from OpenStreetMap")
                     }
                                  } catch {
                     print("❌ Error parsing OpenStreetMap data: \(error.localizedDescription)")
                     self?.nearbyBloodBanks = []
                     self?.errorMessage = "No blood banks found in your area"
                 }
             }
         }
         
         task.resume()
         
         // Add timeout fallback
         DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
             if self.isLoading {
                 print("⏰ Request timed out")
                 self.isLoading = false
                 self.nearbyBloodBanks = []
                 self.errorMessage = "Request timed out - no blood banks found"
             }
         }
    }
    
    private func searchBroaderArea(location: CLLocationCoordinate2D) {
        print("🔍 Searching broader area (100km radius)...")
        
        // Much broader search - 100km radius
        let broaderQuery = """
        [out:json][timeout:30];
        (
          node["amenity"="hospital"](around:100000,\(location.latitude),\(location.longitude));
          way["amenity"="hospital"](around:100000,\(location.latitude),\(location.longitude));
          node["healthcare"="hospital"](around:100000,\(location.latitude),\(location.longitude));
          way["healthcare"="hospital"](around:100000,\(location.latitude),\(location.longitude));
          node["amenity"="clinic"](around:100000,\(location.latitude),\(location.longitude));
          way["amenity"="clinic"](around:100000,\(location.latitude),\(location.longitude));
          node["healthcare"="clinic"](around:100000,\(location.latitude),\(location.longitude));
          way["healthcare"="clinic"](around:100000,\(location.latitude),\(location.longitude));
          node["amenity"="doctors"](around:100000,\(location.latitude),\(location.longitude));
          way["amenity"="doctors"](around:100000,\(location.latitude),\(location.longitude));
          node["healthcare"="doctors"](around:100000,\(location.latitude),\(location.longitude));
          way["healthcare"="doctors"](around:100000,\(location.latitude),\(location.longitude));
        );
        out body;
        """
        
        let encodedQuery = broaderQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid broader search URL")
            self.nearbyBloodBanks = []
            self.errorMessage = "No blood banks found in the area"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Broader search network error: \(error.localizedDescription)")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "No blood banks found in the area"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 500 {
                    print("❌ Broader search server error: \(httpResponse.statusCode)")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "No blood banks found in the area"
                    return
                }
                
                guard let data = data else {
                    print("❌ No data from broader search")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "No blood banks found in the area"
                    return
                }
                
                do {
                    let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
                    let bloodBanks = overpassResponse.elements.compactMap { element in
                        self?.convertOverpassElementToBloodBank(element)
                    }
                    
                    if bloodBanks.isEmpty {
                        print("No hospitals found even in broader area")
                        self?.nearbyBloodBanks = []
                        self?.errorMessage = "No blood banks found in the area"
                    } else {
                        print("Found \(bloodBanks.count) hospitals in broader area")
                        self?.nearbyBloodBanks = bloodBanks
                    }
                } catch {
                    print("❌ Error parsing broader search data: \(error.localizedDescription)")
                    self?.nearbyBloodBanks = []
                    self?.errorMessage = "No blood banks found in the area"
                }
            }
        }
        
        task.resume()
    }
    
    
    private func convertOverpassElementToBloodBank(_ element: OverpassElement) -> BloodBank? {
        guard let lat = element.lat, let lon = element.lon else { 
            print("❌ Element missing lat/lon: \(element.id)")
            return nil 
        }
        
        let name = element.tags?.name ?? element.tags?.operator_name ?? "Medical Facility"
        
        // Build full address
        let address = buildFullAddress(from: element.tags)
        
        // Get phone number - try multiple sources
        let phone = element.tags?.phone ?? 
                   element.tags?.contact_phone ?? 
                   "Contact facility directly"
        
        // Determine facility type
        let facilityType = element.tags?.amenity ?? "medical"
        let displayName = getDisplayName(name: name, facilityType: facilityType)
        
        // Generate a realistic rating based on facility type
        let rating = generateRating(for: facilityType)
        
        let bloodBank = BloodBank(
            name: displayName,
            address: address,
            phoneNumber: phone,
            email: element.tags?.email,
            website: element.tags?.website,
            location: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            operatingHours: element.tags?.opening_hours ?? "Check with facility",
            isOpen: true,
            bloodInventory: [:],
            rating: rating
        )
        
        print("✅ Created BloodBank: \(displayName) at \(lat), \(lon)")
        return bloodBank
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
    
    private func generateRating(for facilityType: String) -> Double {
        switch facilityType {
        case "hospital":
            return Double.random(in: 3.8...4.8) // Hospitals generally have good ratings
        case "clinic":
            return Double.random(in: 3.5...4.5) // Clinics have decent ratings
        case "doctors":
            return Double.random(in: 3.0...4.2) // Medical offices vary
        case "emergency":
            return Double.random(in: 3.8...4.6) // Emergency centers are usually well-rated
        default:
            return Double.random(in: 3.0...4.0)
        }
    }
    
    private func getDisplayName(name: String, facilityType: String) -> String {
        switch facilityType {
        case "hospital":
            return name.contains("Hospital") ? name : "\(name) Hospital"
        case "clinic":
            return name.contains("Clinic") ? name : "\(name) Medical Clinic"
        case "doctors":
            return name.contains("Doctor") ? name : "\(name) Medical Office"
        case "emergency":
            return name.contains("Emergency") ? name : "\(name) Emergency Center"
        default:
            return name
        }
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
        case name, operator_name, addr_street, addr_full, addr_housenumber, addr_postcode, addr_city
        case phone, contact_phone, email, website, opening_hours, amenity, healthcare, emergency
    }
}
