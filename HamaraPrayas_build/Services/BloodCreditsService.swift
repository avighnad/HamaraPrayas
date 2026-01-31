//
//  BloodCreditsService.swift
//  HamaraPrayas_build
//
//  Service to manage blood credits, donations, and badges
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BloodCreditsService: ObservableObject {
    static let shared = BloodCreditsService()
    
    private let db = Firestore.firestore()
    
    @Published var bloodProfile: BloodProfile = BloodProfile()
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var newBadgeEarned: Badge?
    
    // MARK: - Credit Values
    struct CreditValues {
        static let donation = 100
        static let firstTimeDonation = 50
        static let urgentDonation = 50
        static let streakBonus = 25
        static let referral = 30
        static let helpResponse = 10
        static let welcome = 25
    }
    
    private init() {}
    
    // MARK: - Load User Profile
    func loadBloodProfile(for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let docRef = db.collection("blood_profiles").document(userId)
        let document = try await docRef.getDocument()
        
        if let data = document.data() {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            bloodProfile = try JSONDecoder().decode(BloodProfile.self, from: jsonData)
        } else {
            // Create new profile
            bloodProfile = BloodProfile()
            try await saveBloodProfile(for: userId)
            
            // Award welcome credits
            try await addCredits(
                userId: userId,
                type: .welcome,
                amount: CreditValues.welcome,
                description: "Welcome to HamaraPrayas! Start your donation journey."
            )
        }
    }
    
    // MARK: - Save Profile
    func saveBloodProfile(for userId: String) async throws {
        let data = try JSONEncoder().encode(bloodProfile)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("blood_profiles").document(userId).setData(dictionary)
    }
    
    // MARK: - Add Credits
    @MainActor
    func addCredits(userId: String, type: CreditType, amount: Int, description: String, relatedDonationId: String? = nil) async throws {
        let transaction = CreditTransaction(
            type: type,
            amount: amount,
            description: description,
            relatedDonationId: relatedDonationId
        )
        
        bloodProfile.totalCredits += amount
        bloodProfile.transactions.insert(transaction, at: 0)
        bloodProfile.priorityLevel = PriorityLevel.level(for: bloodProfile.totalCredits)
        
        try await saveBloodProfile(for: userId)
        
        HapticManager.shared.success()
    }
    
    // MARK: - Record Donation
    @MainActor
    func recordDonation(
        userId: String,
        bloodType: BloodType,
        location: String,
        hospitalName: String,
        wasUrgent: Bool = false,
        helpRequestId: String? = nil
    ) async throws {
        var creditsEarned = CreditValues.donation
        
        // First-time donation bonus
        let isFirstDonation = bloodProfile.lifetimeDonations == 0
        if isFirstDonation {
            creditsEarned += CreditValues.firstTimeDonation
        }
        
        // Urgent donation bonus
        if wasUrgent {
            creditsEarned += CreditValues.urgentDonation
        }
        
        // Streak bonus
        if let lastDate = bloodProfile.lastDonationDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            // If donated within 90 days (reasonable window), continue streak
            if daysSince >= 56 && daysSince <= 90 {
                bloodProfile.currentStreak += 1
                creditsEarned += CreditValues.streakBonus * bloodProfile.currentStreak
            } else if daysSince > 90 {
                bloodProfile.currentStreak = 1
            }
        } else {
            bloodProfile.currentStreak = 1
        }
        
        // Update longest streak
        bloodProfile.longestStreak = max(bloodProfile.longestStreak, bloodProfile.currentStreak)
        
        // Create donation record
        let donation = DonationRecord(
            userId: userId,
            bloodType: bloodType,
            location: location,
            hospitalName: hospitalName,
            wasUrgent: wasUrgent,
            helpRequestId: helpRequestId,
            creditsEarned: creditsEarned
        )
        
        bloodProfile.donations.insert(donation, at: 0)
        bloodProfile.lifetimeDonations += 1
        bloodProfile.livesSaved += 3  // Each donation can save up to 3 lives
        bloodProfile.lastDonationDate = Date()
        
        // Add credits
        var description = "Blood donation at \(hospitalName)"
        if wasUrgent {
            description += " (Urgent)"
        }
        if bloodProfile.currentStreak > 1 {
            description += " - Streak x\(bloodProfile.currentStreak)!"
        }
        
        try await addCredits(
            userId: userId,
            type: wasUrgent ? .urgentDonation : .donation,
            amount: creditsEarned,
            description: description,
            relatedDonationId: donation.id
        )
        
        // Check for new badges
        await checkAndAwardBadges(userId: userId, bloodType: bloodType, wasUrgent: wasUrgent)
        
        HapticManager.shared.celebration()
    }
    
    // MARK: - Record Help Response
    @MainActor
    func recordHelpResponse(userId: String, requestId: String) async throws {
        bloodProfile.helpResponseCount += 1
        
        try await addCredits(
            userId: userId,
            type: .helpResponse,
            amount: CreditValues.helpResponse,
            description: "Responded to blood help request"
        )
        
        // Check for community hero badge
        await checkAndAwardBadges(userId: userId, bloodType: nil, wasUrgent: false)
    }
    
    // MARK: - Record Referral
    @MainActor
    func recordReferral(userId: String, referredUserName: String) async throws {
        bloodProfile.referralCount += 1
        
        try await addCredits(
            userId: userId,
            type: .referral,
            amount: CreditValues.referral,
            description: "Referred \(referredUserName) to donate blood"
        )
    }
    
    // MARK: - Badge System
    @MainActor
    private func checkAndAwardBadges(userId: String, bloodType: BloodType?, wasUrgent: Bool) async {
        var newBadges: [Badge] = []
        let existingBadgeTypes = Set(bloodProfile.badges.map { $0.type })
        
        // Donation count badges
        let donationBadges: [(BadgeType, Int)] = [
            (.firstDonation, 1),
            (.fiveDonations, 5),
            (.tenDonations, 10),
            (.twentyFiveDonations, 25),
            (.fiftyDonations, 50),
            (.hundredDonations, 100)
        ]
        
        for (badgeType, requiredCount) in donationBadges {
            if bloodProfile.lifetimeDonations >= requiredCount && !existingBadgeTypes.contains(badgeType) {
                newBadges.append(Badge(type: badgeType))
            }
        }
        
        // Life saver badge (urgent donation)
        if wasUrgent && !existingBadgeTypes.contains(.lifeSaver) {
            newBadges.append(Badge(type: .lifeSaver))
        }
        
        // Streak badges
        if bloodProfile.currentStreak >= 2 && !existingBadgeTypes.contains(.streakStarter) {
            newBadges.append(Badge(type: .streakStarter))
        }
        if bloodProfile.currentStreak >= 5 && !existingBadgeTypes.contains(.streakMaster) {
            newBadges.append(Badge(type: .streakMaster))
        }
        
        // Community hero badge
        if bloodProfile.helpResponseCount >= 10 && !existingBadgeTypes.contains(.communityHero) {
            newBadges.append(Badge(type: .communityHero))
        }
        
        // Rare hero badge (AB-, B-, O-, A-)
        if let bt = bloodType {
            let rareTypes: [BloodType] = [.abNegative, .bNegative, .oNegative, .aNegative]
            if rareTypes.contains(bt) && !existingBadgeTypes.contains(.rareHero) {
                newBadges.append(Badge(type: .rareHero))
            }
        }
        
        // Award new badges
        for badge in newBadges {
            bloodProfile.badges.append(badge)
            self.newBadgeEarned = badge
            HapticManager.shared.celebration()
        }
        
        if !newBadges.isEmpty {
            try? await saveBloodProfile(for: userId)
        }
    }
    
    // MARK: - Leaderboard
    @MainActor
    func loadLeaderboard() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let snapshot = try await db.collection("blood_profiles")
            .order(by: "totalCredits", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        var entries: [LeaderboardEntry] = []
        
        for (index, document) in snapshot.documents.enumerated() {
            let data = document.data()
            
            // Fetch user details
            let userId = document.documentID
            let userDoc = try? await db.collection("users").document(userId).getDocument()
            let userData = userDoc?.data()
            
            let entry = LeaderboardEntry(
                id: userId,
                rank: index + 1,
                userId: userId,
                userName: userData?["displayName"] as? String ?? "Anonymous Donor",
                profileImageURL: userData?["profileImageURL"] as? String,
                totalCredits: data["totalCredits"] as? Int ?? 0,
                lifetimeDonations: data["lifetimeDonations"] as? Int ?? 0,
                livesSaved: data["livesSaved"] as? Int ?? 0,
                priorityLevel: PriorityLevel.level(for: data["totalCredits"] as? Int ?? 0),
                badgeCount: (data["badges"] as? [[String: Any]])?.count ?? 0
            )
            entries.append(entry)
        }
        
        leaderboard = entries
    }
    
    // MARK: - Get User Rank
    func getUserRank(userId: String) async throws -> Int? {
        // Get all profiles ordered by credits
        let snapshot = try await db.collection("blood_profiles")
            .order(by: "totalCredits", descending: true)
            .getDocuments()
        
        for (index, document) in snapshot.documents.enumerated() {
            if document.documentID == userId {
                return index + 1
            }
        }
        
        return nil
    }
    
    // MARK: - Clear Badge Notification
    func clearNewBadge() {
        newBadgeEarned = nil
    }
}
