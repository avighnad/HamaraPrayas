import Foundation
import SwiftUI
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

final class BloodBankViewModel: NSObject, ObservableObject, @unchecked Sendable {
    // MARK: - Published State
    @Published var bloodBanks: [BloodBank] = []
    @Published var bloodRequests: [BloodRequest] = []
    @Published var helpRequests: [HelpRequest] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isLoading: Bool = false
    @Published var userCity: String?
    
    // MARK: - Computed Properties
    var localHelpRequests: [HelpRequest] {
        guard let userCity = userCity else {
            return helpRequests // Show all if no city set
        }
        return helpRequests.filter { $0.city.lowercased() == userCity.lowercased() }
    }

    // MARK: - Private
    private let locationManager = CLLocationManager()
    private let placesService = PlacesService()
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private var bloodRequestsListener: ListenerRegistration?
    private var helpRequestsListener: ListenerRegistration?
    private var sentNotifications: Set<String> = []
    private var isHelpRequestsListenerActive: Bool = false
    private var lastNotificationCheck: Date = Date()
    
    private func loadSentNotifications() {
        if let data = UserDefaults.standard.data(forKey: "sentNotifications"),
           let notifications = try? JSONDecoder().decode(Set<String>.self, from: data) {
            sentNotifications = notifications
            print("📱 Loaded \(notifications.count) previously sent notifications")
        }
    }
    
    private func saveSentNotifications() {
        // Clean up old notifications (keep only last 100)
        if sentNotifications.count > 100 {
            let notificationsArray = Array(sentNotifications)
            sentNotifications = Set(notificationsArray.suffix(100))
            print("📱 Cleaned up old notifications, keeping \(sentNotifications.count)")
        }
        
        if let data = try? JSONEncoder().encode(sentNotifications) {
            UserDefaults.standard.set(data, forKey: "sentNotifications")
            print("📱 Saved \(sentNotifications.count) sent notifications")
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Load previously sent notifications
        loadSentNotifications()
        
        // Observe changes in PlacesService
        placesService.$nearbyBloodBanks
            .sink { [weak self] hospitals in
                guard let self = self else { return }
                print("🔄 PlacesService updated with \(hospitals.count) hospitals")
                
                // Always update the bloodBanks array when PlacesService updates
                DispatchQueue.main.async {
                    if let location = self.userLocation {
                        // If we have location, calculate distances and sort
                        self.bloodBanks = hospitals.map { bank in
                            var mutable = bank
                            mutable.distance = bank.distanceFrom(location)
                            return mutable
                        }.sorted { (lhs, rhs) -> Bool in
                            (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
                        }
                        print("✅ Updated bloodBanks array with \(self.bloodBanks.count) hospitals (with location)")
                    } else {
                        // If no location yet, just update with the hospitals as-is
                        self.bloodBanks = hospitals
                        print("✅ Updated bloodBanks array with \(hospitals.count) hospitals (no location)")
                    }
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        // Don't automatically request location - let MainTabView handle it
        // This prevents multiple location requests and improves performance
    }

    // MARK: - Location
    func requestLocationPermission() {
        // Only request if not already authorized to prevent multiple requests
        guard locationManager.authorizationStatus == .notDetermined else {
            return
        }
        locationManager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if location services are enabled
            guard CLLocationManager.locationServicesEnabled() else {
                DispatchQueue.main.async {
                    print("Location services are disabled")
                    self.isLoading = false
                }
                return
            }
            
            // Check authorization status
            switch self.locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationManager.requestLocation()
            case .denied, .restricted:
                DispatchQueue.main.async {
                    print("Location access denied or restricted")
                    self.isLoading = false
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    print("Location permission not determined")
                    self.locationManager.requestWhenInUseAuthorization()
                }
            @unknown default:
                DispatchQueue.main.async {
                    print("Unknown authorization status")
                    self.isLoading = false
                }
            }
        }
    }

    private func updateDistances(using location: CLLocationCoordinate2D) {
        // Search for real nearby hospitals using OpenStreetMap API
        print("🔍 Starting hospital search for location: \(location.latitude), \(location.longitude)")
        placesService.searchNearbyBloodBanks(location: location)
    }
    
    func refreshBloodBanks() {
        print("🔄 Manual refresh requested")
        if let location = userLocation {
            print("📍 Using existing location for refresh: \(location.latitude), \(location.longitude)")
            isLoading = true
            placesService.searchNearbyBloodBanks(location: location)
        } else {
            print("📍 No location available, requesting new location")
            getCurrentLocation()
        }
    }
    
    func setupBloodRequestsListener() {
        // Only set up listener if user is authenticated
        if Auth.auth().currentUser != nil {
            print("🔧 Setting up blood requests listener for authenticated user")
            loadBloodRequestsFromFirestore()
        } else {
            print("🔧 No authenticated user - skipping blood requests listener setup")
        }
    }
    
    func removeBloodRequestsListener() {
        print("🔧 Removing blood requests listener")
        bloodRequestsListener?.remove()
        bloodRequestsListener = nil
        bloodRequests = []
    }
    

    // MARK: - Requests
    func submitBloodRequest(_ request: BloodRequest) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for blood request")
            return
        }
        
        print("📝 Submitting blood request to Firebase: \(request.patientName)")
        
        let requestData: [String: Any] = [
            "patientName": request.patientName,
            "bloodType": request.bloodType.rawValue,
            "unitsNeeded": request.unitsNeeded,
            "urgency": request.urgency.rawValue,
            "hospital": request.hospital,
            "contactNumber": request.contactNumber,
            "additionalNotes": request.additionalNotes,
            "status": request.status.rawValue,
            "requestDate": request.requestDate.timeIntervalSince1970,
            "userId": userId
        ]
        
        do {
            let docRef = try await db.collection("blood_requests").addDocument(data: requestData)
            print("✅ Blood request saved to Firebase with ID: \(docRef.documentID)")
            
            // Don't update local array here - the Firebase listener will handle it
            // This prevents duplicates
        } catch {
            print("❌ Error saving blood request: \(error.localizedDescription)")
        }
    }

    func updateRequestStatus(_ id: UUID, status: RequestStatus) {
        guard Auth.auth().currentUser?.uid != nil else { return }
        
        // Update in Firebase
        let documentId = id.uuidString
        db.collection("blood_requests").document(documentId).updateData([
            "status": status.rawValue
        ]) { [weak self] error in
            if let error = error {
                print("❌ Error updating request status: \(error.localizedDescription)")
            } else {
                print("✅ Request status updated to \(status.rawValue) in Firebase")
                // Update local array
                DispatchQueue.main.async {
                    if let index = self?.bloodRequests.firstIndex(where: { $0.id == id }) {
                        self?.bloodRequests[index].status = status
                    }
                }
            }
        }
    }
    
    func clearAllRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Delete all requests from Firebase
        db.collection("blood_requests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error getting requests to delete: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let batch = self?.db.batch()
                documents.forEach { doc in
                    batch?.deleteDocument(doc.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("❌ Error deleting requests: \(error.localizedDescription)")
                    } else {
                        print("✅ All requests deleted from Firebase")
                    }
                }
            }
    }

    func getNearbyBloodBanks(for bloodType: BloodType, units: Int) -> [BloodBank] {
        let filtered = bloodBanks.filter { $0.bloodInventory[bloodType, default: 0] >= units }
        return filtered.sorted { (lhs, rhs) -> Bool in
            (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
        }
    }
    
    // MARK: - Firebase Methods
    func loadBloodRequestsFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for loading blood requests")
            return
        }
        
        // Remove existing listener to prevent duplicates
        bloodRequestsListener?.remove()
        
        print("📖 Setting up blood requests listener for user: \(userId)")
        
        bloodRequestsListener = db.collection("blood_requests")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading blood requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No blood requests found")
                    return
                }
                
                let requests = documents.compactMap { doc -> BloodRequest? in
                    let data = doc.data()
                    return BloodRequest(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        patientName: data["patientName"] as? String ?? "",
                        bloodType: BloodType(rawValue: data["bloodType"] as? String ?? "") ?? .oPositive,
                        unitsNeeded: data["unitsNeeded"] as? Int ?? 1,
                        urgency: UrgencyLevel(rawValue: data["urgency"] as? String ?? "") ?? .medium,
                        hospital: data["hospital"] as? String ?? "",
                        contactNumber: data["contactNumber"] as? String ?? "",
                        additionalNotes: data["additionalNotes"] as? String ?? "",
                        requestDate: (data["requestDate"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date(),
                        status: RequestStatus(rawValue: data["status"] as? String ?? "") ?? .pending
                    )
                }.sorted { $0.requestDate > $1.requestDate } // Sort by newest first
                
                DispatchQueue.main.async {
                    self?.bloodRequests = requests
                    print("✅ Loaded \(requests.count) blood requests from Firebase")
                }
            }
    }
    
    // MARK: - Help Requests (Community)
    
    func setupHelpRequestsListener() {
        print("🟣 setupHelpRequestsListener() CALLED")
        print("🟣 userCity:", self.userCity ?? "nil")
        print("🟣 isHelpRequestsListenerActive:", self.isHelpRequestsListenerActive)
        // Prevent duplicate listeners
        if isHelpRequestsListenerActive {
            print("🔧 Help requests listener already active, skipping setup")
            return
        }
        
        print("🔧 Setting up help requests listener for community feed")
        
        // Check if we already have a user city
        if let city = userCity, !city.isEmpty {
            print("🏙️ Using existing city: \(city)")
            loadHelpRequestsFromFirestore()
            isHelpRequestsListenerActive = true
            return
        }
        
        // Otherwise, load city from Firestore first
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user; cannot attach help requests listener.")
            return
        }
        
        print("📡 Loading user city before attaching listener...")
        loadUserCityFromFirestore(userId: currentUser.uid)
        
        // Wait a short moment for city to load, then attach listener dynamically
        $userCity
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .first() // only trigger once
            .sink { [weak self] city in
                guard let self = self else { return }
                print("✅ City loaded dynamically as '\(city)', attaching listener now")
                self.loadHelpRequestsFromFirestore()
                self.isHelpRequestsListenerActive = true
            }
            .store(in: &cancellables)
    }
    
    func removeHelpRequestsListener() {
        print("🔧 Removing help requests listener")
        helpRequestsListener?.remove()
        helpRequestsListener = nil
        isHelpRequestsListenerActive = false
        // Don't clear helpRequests array - keep the data for other views
        print("🔧 Help requests listener removed, but keeping data")
    }
    
    func loadHelpRequestsFromFirestore() {
        // Remove existing listener to prevent duplicates
        helpRequestsListener?.remove()
        
        print("📖 Setting up help requests listener for community feed")
        
        guard let city = userCity else {
            print("⚠️ User city not loaded yet, skipping help requests listener.")
            return
        }

        helpRequestsListener = db.collection("help_requests")
            .whereField("city", isEqualTo: city)
            .order(by: "requestDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading help requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No help requests found")
                    return
                }
                
                print("📖 Found \(documents.count) help request documents")
                
                let requests = documents.compactMap { doc -> HelpRequest? in
                    let data = doc.data()
                    print("📖 Parsing document \(doc.documentID): \(data)")
                    
                    // Use Firebase document ID as the request ID
                    let requestId = doc.documentID
                    
                    let helpRequest = HelpRequest(
                        id: requestId,
                        patientName: data["patientName"] as? String ?? "",
                        bloodType: BloodType(rawValue: data["bloodType"] as? String ?? "") ?? .oPositive,
                        unitsNeeded: data["unitsNeeded"] as? Int ?? 1,
                        urgency: UrgencyLevel(rawValue: data["urgency"] as? String ?? "") ?? .medium,
                        hospital: data["hospital"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        additionalNotes: data["additionalNotes"] as? String ?? "",
                        requesterUserId: data["requesterUserId"] as? String ?? "",
                        isAnonymous: data["isAnonymous"] as? Bool ?? false,
                        requestDate: (data["requestDate"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date(),
                        status: RequestStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
                    )
                    
                    // Debug: Check if this is the current user's request
                    if let currentUserId = Auth.auth().currentUser?.uid {
                        if helpRequest.requesterUserId == currentUserId {
                            print("🔍 Found current user's request: \(helpRequest.patientName) (ID: \(helpRequest.id))")
                        }
                    }
                    
                    return helpRequest
                }
                
                DispatchQueue.main.async {
                    // Store old requests for comparison
                    let oldRequests = self?.helpRequests ?? []
                    
                    // Update the help requests
                    self?.helpRequests = requests
                    
                    // Check for new urgent requests that need notifications
                    self?.checkForNewUrgentRequests(newRequests: requests, oldRequests: oldRequests)
                    
                    print("✅ Loaded \(requests.count) help requests from Firebase")
                }
            }
    }
    
    func offerHelp(for helpRequest: HelpRequest, helperName: String, helperPhone: String, message: String = "") async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for offering help")
            return
        }
        
        print("🤝 User \(userId) offering help for request: \(helpRequest.id)")
        print("🤝 Helper name: \(helperName), phone: \(helperPhone)")
        
        // Create a help response document with contact information
        let responseData: [String: Any] = [
            "helpRequestId": helpRequest.id,
            "helperUserId": userId,
            "helperName": helperName,
            "helperPhone": helperPhone,
            "message": message,
            "responseDate": Date().timeIntervalSince1970,
            "status": "pending"
        ]
        
        print("🤝 Creating help response with data: \(responseData)")
        
        do {
            let docRef = try await db.collection("help_responses").addDocument(data: responseData)
            print("✅ Help response saved to Firebase with ID: \(docRef.documentID)")
            print("✅ Help response data: \(responseData)")
            
            // No need to update responseCount - we'll calculate it dynamically
            
        } catch {
            print("❌ Error offering help: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Dynamic Response Count
    
    func getResponseCount(for helpRequestId: String) async -> Int {
        do {
            let snapshot = try await db.collection("help_responses")
                .whereField("helpRequestId", isEqualTo: helpRequestId)
                .getDocuments()
            
            return snapshot.documents.count
        } catch {
            print("❌ Error getting response count: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getHelpOffersForUser(userId: String) async -> [HelpRequest] {
        do {
            print("📋 Searching for help offers for user: \(userId)")
            
            // Get all help responses where this user offered help
            let responsesSnapshot = try await db.collection("help_responses")
                .whereField("helperUserId", isEqualTo: userId)
                .getDocuments()
            
            print("📋 Found \(responsesSnapshot.documents.count) help responses for user \(userId)")
            
            // Extract help request IDs from responses
            let helpRequestIds = responsesSnapshot.documents.compactMap { doc in
                let data = doc.data()
                let helpRequestId = data["helpRequestId"] as? String
                print("📋 Help response document \(doc.documentID): helpRequestId = \(helpRequestId ?? "nil")")
                return helpRequestId
            }
            
            print("📋 Extracted \(helpRequestIds.count) help request IDs")
            
            // Get the actual help requests
            var helpOffers: [HelpRequest] = []
            for requestId in helpRequestIds {
                if let helpRequest = helpRequests.first(where: { $0.id == requestId }) {
                    helpOffers.append(helpRequest)
                    print("📋 Found matching help request: \(helpRequest.patientName)")
                } else {
                    print("📋 No matching help request found for ID: \(requestId)")
                }
            }
            
            print("📋 Found \(helpOffers.count) help offers for user \(userId)")
            return helpOffers
        } catch {
            print("❌ Error getting help offers: \(error.localizedDescription)")
            return []
        }
    }
    
    func getHelpOffersForRequest(helpRequestId: String) async -> [HelpOffer] {
        do {
            print("📋 Searching for help offers for request ID: \(helpRequestId)")
            
            let snapshot = try await db.collection("help_responses")
                .whereField("helpRequestId", isEqualTo: helpRequestId)
                .getDocuments()
            
            print("📋 Query returned \(snapshot.documents.count) documents for request \(helpRequestId)")
            
            // Debug: Let's also check what help responses exist in general
            let allResponsesSnapshot = try await db.collection("help_responses").getDocuments()
            print("📋 DEBUG: Total help responses in database: \(allResponsesSnapshot.documents.count)")
            
            var offers: [HelpOffer] = []
            
            for doc in snapshot.documents {
                let data = doc.data()
                print("📋 Processing help response document: \(doc.documentID) with data: \(data)")
                
                let helperUserId = data["helperUserId"] as? String ?? ""
                let helperName = data["helperName"] as? String ?? "Anonymous"
                let helperPhone = data["helperPhone"] as? String ?? ""
                let message = data["message"] as? String ?? ""
                let responseDate = (data["responseDate"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                
                print("📋 Helper user ID: \(helperUserId)")
                print("📋 Helper name: \(helperName), phone: \(helperPhone)")
                
                let offer = HelpOffer(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    helperName: helperName,
                    helperEmail: nil, // Could be fetched from user data if needed
                    helperPhone: helperPhone,
                    message: message,
                    offerDate: responseDate,
                    isContacted: data["isContacted"] as? Bool ?? false
                )
                
                offers.append(offer)
                print("📋 Created help offer for \(helperName)")
            }
            
            print("📋 Found \(offers.count) help offers for request \(helpRequestId)")
            return offers
        } catch {
            print("❌ Error getting help offers for request: \(error.localizedDescription)")
            return []
        }
    }
    
    private func getUserName(userId: String) async -> String {
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let data = userDoc.data(),
               let name = data["name"] as? String {
                return name
            }
            return "Anonymous Helper"
        } catch {
            print("❌ Error getting user name: \(error.localizedDescription)")
            return "Anonymous Helper"
        }
    }
    
    func createHelpRequest(_ helpRequest: HelpRequest) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for creating help request")
            return
        }
        
        print("📝 Creating help request for community: \(helpRequest.patientName)")
        print("📝 Request details: \(helpRequest.bloodType.displayName), \(helpRequest.city), \(helpRequest.urgency.rawValue)")
        print("📝 Current user ID: \(userId)")
        print("📝 Help request requester ID: \(helpRequest.requesterUserId)")
        print("📝 IDs match: \(userId == helpRequest.requesterUserId)")
        
        let requestData: [String: Any] = [
            "patientName": helpRequest.patientName,
            "bloodType": helpRequest.bloodType.rawValue,
            "unitsNeeded": helpRequest.unitsNeeded,
            "urgency": helpRequest.urgency.rawValue,
            "hospital": helpRequest.hospital,
            "city": helpRequest.city,
            "additionalNotes": helpRequest.additionalNotes,
            "requesterUserId": userId,
            "isAnonymous": helpRequest.isAnonymous,
            "requestDate": helpRequest.requestDate.timeIntervalSince1970,
            "status": helpRequest.status.rawValue,
        ]
        
        do {
            let docRef = try await db.collection("help_requests").addDocument(data: requestData)
            print("✅ Help request created in Firebase with ID: \(docRef.documentID)")
            print("✅ Help request data saved: \(requestData)")
            
            // Don't force refresh - the listener will automatically update the UI
            print("📝 Help request created, listener will automatically update UI")
            
            // Send local notification to other users in the same city
            if helpRequest.urgency == .high {
                // FCM temporarily disabled due to permissions issues
                // sendFCMNotificationToCity(for: helpRequest)
                print("🔔 Local notification will be handled by loadHelpRequestsFromFirestore")
            }
        } catch {
            print("❌ Error creating help request: \(error.localizedDescription)")
        }
    }
    
    private func loadUserCityFromFirestore(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("❌ Error loading user city: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let city = data["city"] as? String, !city.isEmpty else {
                print("📭 No city found for user, will use GPS to detect")
                return
            }
            
            print("🏙️ Loaded user city from Firebase: \(city)")
            DispatchQueue.main.async {
                self?.userCity = city
            }
        }
    }
    
    private func checkForNewUrgentRequests(newRequests: [HelpRequest], oldRequests: [HelpRequest]) {
        // TEMPORARY: Disable notifications completely for testing
        print("🔍 Notifications temporarily disabled for testing")
        return
        
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let userCity = userCity else { 
            print("🔍 Cannot check for urgent requests - missing user ID or city")
            return 
        }
        
        // Throttle notification checks to prevent spam (max once per 60 seconds)
        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastNotificationCheck)
        print("🔍 Time since last notification check: \(timeSinceLastCheck) seconds")
        
        if timeSinceLastCheck < 60 {
            print("🔍 Notification check throttled - too soon since last check (need 60s, got \(timeSinceLastCheck)s)")
            return
        }
        
        // Additional check: if no new requests, don't send notifications
        if newRequests.count == oldRequests.count {
            print("🔍 No new requests detected - skipping notification check")
            return
        }
        
        lastNotificationCheck = now
        print("🔍 Notification check allowed - proceeding with check")
        
        // Clean up old notifications to prevent memory buildup
        cleanupOldNotifications()
        
        print("🔍 Checking for new urgent requests...")
        print("🔍 Current user: \(currentUserId)")
        print("🔍 User city: \(userCity)")
        print("🔍 New requests count: \(newRequests.count)")
        print("🔍 Old requests count: \(oldRequests.count)")
        print("🔍 Already sent notifications: \(sentNotifications.count)")
        
        // Find truly new urgent requests (not in old requests and not already notified)
        let newUrgentRequests = newRequests.filter { request in
            let requestId = request.id
            let isUrgent = request.urgency == .high
            let isInSameCity = request.city.lowercased() == userCity.lowercased()
            let isNotOwnRequest = request.requesterUserId != currentUserId
            let isNewRequest = !oldRequests.contains(where: { $0.id == request.id })
            let notAlreadyNotified = !sentNotifications.contains(requestId)
            
            // Only notify for requests that are less than 1 hour old
            let requestAge = Date().timeIntervalSince(request.requestDate)
            let isRecentRequest = requestAge < 3600 // 1 hour in seconds
            
            print("🔍 Request \(request.patientName): urgent=\(isUrgent), sameCity=\(isInSameCity), notOwn=\(isNotOwnRequest), new=\(isNewRequest), notNotified=\(notAlreadyNotified), recent=\(isRecentRequest) (age: \(requestAge/60) minutes)")
            
            return isUrgent && isInSameCity && isNotOwnRequest && isNewRequest && notAlreadyNotified && isRecentRequest
        }
        
        print("🔍 Found \(newUrgentRequests.count) new urgent requests to notify")
        
        // Send notifications for new urgent requests
        for request in newUrgentRequests {
            let requestId = request.id
            
            // Double-check that we haven't already sent this notification
            if sentNotifications.contains(requestId) {
                print("🔔 Skipping notification for \(requestId) - already sent")
                continue
            }
            
            print("🔔 Sending notification for: \(request.patientName) needs \(request.bloodType.displayName) in \(request.city)")
            scheduleUrgentBloodRequestNotification(for: request)
            
            // Mark this notification as sent IMMEDIATELY
            sentNotifications.insert(requestId)
            saveSentNotifications()
            print("🔔 Marked notification as sent for request ID: \(requestId)")
        }
    }
    
    // MARK: - City Detection
    
    private func getCityFromLocation(_ location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { [weak self] placemarks, error in
            if let error = error {
                print("❌ Error getting city from location: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let city = placemark.locality else {
                print("❌ Could not determine city from location")
                return
            }
            
            print("🏙️ Detected city: \(city)")
            
            DispatchQueue.main.async {
                self?.userCity = city
                // Save city to user's profile in Firebase
                self?.updateUserCityInFirebase(city: city)
            }
        }
    }
    
    private func updateUserCityInFirebase(city: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for updating city")
            return
        }
        
        print("💾 Saving city '\(city)' to user profile in Firebase")
        
        db.collection("users").document(userId).updateData([
            "city": city
        ]) { error in
            if let error = error {
                print("❌ Error updating user city: \(error.localizedDescription)")
            } else {
                print("✅ User city updated successfully in Firebase")
            }
        }
    }
    
    // MARK: - Firebase Cloud Messaging (FCM) - Disabled
    
    
    
    // MARK: - Local Notifications
    
    func clearNotificationHistory() {
        sentNotifications.removeAll()
        UserDefaults.standard.removeObject(forKey: "sentNotifications")
        lastNotificationCheck = Date()
        print("📱 Cleared all notification history and reset throttling")
    }
    
    private func cleanupOldNotifications() {
        // Remove notifications older than 24 hours to prevent memory buildup
        let cutoffTime = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        
        // Since we can't easily track notification timestamps, we'll clear all notifications
        // if the set gets too large (more than 100 notifications)
        if sentNotifications.count > 100 {
            print("📱 Cleaning up old notifications (had \(sentNotifications.count) notifications)")
            sentNotifications.removeAll()
            saveSentNotifications()
        }
    }
    
    func debugAllHelpResponses() async {
        do {
            let snapshot = try await db.collection("help_responses").getDocuments()
            print("🔍 DEBUG: Found \(snapshot.documents.count) total help responses in database")
            
            for doc in snapshot.documents {
                let data = doc.data()
                print("🔍 DEBUG: Help response \(doc.documentID): \(data)")
            }
        } catch {
            print("❌ DEBUG: Error getting all help responses: \(error.localizedDescription)")
        }
    }
    
    func debugAllHelpRequests() async {
        do {
            let snapshot = try await db.collection("help_requests").getDocuments()
            print("🔍 DEBUG: Found \(snapshot.documents.count) total help requests in database")
            
            for doc in snapshot.documents {
                let data = doc.data()
                print("🔍 DEBUG: Help request \(doc.documentID): \(data)")
            }
        } catch {
            print("❌ DEBUG: Error getting all help requests: \(error.localizedDescription)")
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    func scheduleUrgentBloodRequestNotification(for helpRequest: HelpRequest) {
        // Only send notifications for high urgency requests
        guard helpRequest.urgency == .high else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🩸 Urgent Blood Request!"
        content.body = "\(helpRequest.isAnonymous ? "Someone" : helpRequest.patientName) needs \(helpRequest.bloodType.displayName) blood urgently in \(helpRequest.city)"
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "helpRequestId": helpRequest.id,
            "bloodType": helpRequest.bloodType.rawValue,
            "city": helpRequest.city
        ]
        
        // Schedule notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "urgent-blood-request-\(helpRequest.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Urgent blood request notification scheduled")
            }
        }
    }
    
    func scheduleBloodRequestFulfilledNotification(for helpRequest: HelpRequest) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Blood Request Fulfilled!"
        content.body = "Great news! The blood request for \(helpRequest.bloodType.displayName) in \(helpRequest.city) has been fulfilled."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "blood-request-fulfilled-\(helpRequest.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling fulfillment notification: \(error.localizedDescription)")
            } else {
                print("✅ Blood request fulfilled notification scheduled")
            }
        }
    }
}


// MARK: - CLLocationManagerDelegate
extension BloodBankViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location access granted")
            // Automatically request location when permission is granted
            getCurrentLocation()
        case .denied, .restricted:
            print("Location access denied or restricted")
            isLoading = false
        case .notDetermined:
            print("Location permission not determined")
            isLoading = false
        @unknown default:
            print("Unknown authorization status")
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        guard let location = locations.last?.coordinate else { 
            print("No location data received")
            return 
        }
        
        print("Location updated: \(location.latitude), \(location.longitude)")
        userLocation = location
        
        // Get city from location
        getCityFromLocation(location)
        
        // If we already have blood banks from PlacesService, recalculate distances
        if !placesService.nearbyBloodBanks.isEmpty {
            print("🔄 Recalculating distances for existing blood banks with new location")
            DispatchQueue.main.async {
                self.bloodBanks = self.placesService.nearbyBloodBanks.map { bank in
                    var mutable = bank
                    mutable.distance = bank.distanceFrom(location)
                    return mutable
                }.sorted { (lhs, rhs) -> Bool in
                    (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
                }
                print("✅ Recalculated distances for \(self.bloodBanks.count) blood banks")
            }
        }
        
        updateDistances(using: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        print("Location manager failed with error: \(error.localizedDescription)")
        
        // Handle specific location errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied by user")
                // Don't load sample data, just show empty state
            case .locationUnknown:
                print("Location unknown - trying again")
                // Retry after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.getCurrentLocation()
                }
            case .network:
                print("Network error occurred")
                // Don't load sample data, just show empty state
            default:
                print("Other location error: \(clError.code.rawValue)")
                // Don't load sample data, just show empty state
            }
        } else {
            // For any other error, don't load sample data
            print("Unknown error occurred")
        }
    }
    
}



