//
//  BloodCredits.swift
//  HamaraPrayas_build
//
//  Blood Credit System - Gamification for blood donation
//

import Foundation

// MARK: - Blood Credit Transaction
struct CreditTransaction: Identifiable, Codable {
    let id: String
    let type: CreditType
    let amount: Int
    let description: String
    let date: Date
    let relatedDonationId: String?
    
    init(id: String = UUID().uuidString, type: CreditType, amount: Int, description: String, date: Date = Date(), relatedDonationId: String? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.description = description
        self.date = date
        self.relatedDonationId = relatedDonationId
    }
}

enum CreditType: String, Codable, CaseIterable {
    case donation = "donation"
    case firstTimeDonation = "first_time_donation"
    case urgentDonation = "urgent_donation"
    case streakBonus = "streak_bonus"
    case referral = "referral"
    case helpResponse = "help_response"
    case welcome = "welcome"
    
    var icon: String {
        switch self {
        case .donation: return "drop.fill"
        case .firstTimeDonation: return "star.fill"
        case .urgentDonation: return "bolt.heart.fill"
        case .streakBonus: return "flame.fill"
        case .referral: return "person.badge.plus"
        case .helpResponse: return "hand.raised.fill"
        case .welcome: return "gift.fill"
        }
    }
    
    var color: String {
        switch self {
        case .donation: return "red"
        case .firstTimeDonation: return "yellow"
        case .urgentDonation: return "orange"
        case .streakBonus: return "orange"
        case .referral: return "blue"
        case .helpResponse: return "green"
        case .welcome: return "purple"
        }
    }
}

// MARK: - Donation Record
struct DonationRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    let bloodType: BloodType
    let location: String
    let hospitalName: String
    let unitsdonated: Int
    let wasUrgent: Bool
    let helpRequestId: String?  // If donation was in response to a help request
    let creditsEarned: Int
    let verified: Bool  // Verified by hospital/blood bank
    
    init(id: String = UUID().uuidString, userId: String, date: Date = Date(), bloodType: BloodType, location: String, hospitalName: String, unitsdonated: Int = 1, wasUrgent: Bool = false, helpRequestId: String? = nil, creditsEarned: Int = 100, verified: Bool = false) {
        self.id = id
        self.userId = userId
        self.date = date
        self.bloodType = bloodType
        self.location = location
        self.hospitalName = hospitalName
        self.unitsdonated = unitsdonated
        self.wasUrgent = wasUrgent
        self.helpRequestId = helpRequestId
        self.creditsEarned = creditsEarned
        self.verified = verified
    }
    
    // Check if user is eligible to donate again (56 days gap)
    var nextEligibleDate: Date {
        Calendar.current.date(byAdding: .day, value: 56, to: date) ?? date
    }
    
    var canDonateAgain: Bool {
        Date() >= nextEligibleDate
    }
    
    var daysUntilEligible: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextEligibleDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Badge System
struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let type: BadgeType
    let earnedDate: Date
    
    init(type: BadgeType, earnedDate: Date = Date()) {
        self.id = type.rawValue
        self.type = type
        self.earnedDate = earnedDate
    }
    
    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}

enum BadgeType: String, Codable, CaseIterable {
    case firstDonation = "first_donation"
    case fiveDonations = "five_donations"
    case tenDonations = "ten_donations"
    case twentyFiveDonations = "twenty_five_donations"
    case fiftyDonations = "fifty_donations"
    case hundredDonations = "hundred_donations"
    case lifeSaver = "life_saver"           // Donated to urgent request
    case streakStarter = "streak_starter"    // 2 donations in a row
    case streakMaster = "streak_master"      // 5 donations in a row
    case communityHero = "community_hero"    // Helped 10 requests
    case rareHero = "rare_hero"             // Donated rare blood type
    case earlyAdopter = "early_adopter"      // First 1000 users
    case topDonor = "top_donor"             // Top 10 in leaderboard
    
    var title: String {
        switch self {
        case .firstDonation: return "First Drop"
        case .fiveDonations: return "Regular Donor"
        case .tenDonations: return "Dedicated Donor"
        case .twentyFiveDonations: return "Silver Heart"
        case .fiftyDonations: return "Gold Heart"
        case .hundredDonations: return "Platinum Heart"
        case .lifeSaver: return "Life Saver"
        case .streakStarter: return "Streak Starter"
        case .streakMaster: return "Streak Master"
        case .communityHero: return "Community Hero"
        case .rareHero: return "Rare Hero"
        case .earlyAdopter: return "Early Adopter"
        case .topDonor: return "Top Donor"
        }
    }
    
    var description: String {
        switch self {
        case .firstDonation: return "Made your first blood donation"
        case .fiveDonations: return "Completed 5 blood donations"
        case .tenDonations: return "Completed 10 blood donations"
        case .twentyFiveDonations: return "Completed 25 blood donations"
        case .fiftyDonations: return "Completed 50 blood donations"
        case .hundredDonations: return "Completed 100 blood donations"
        case .lifeSaver: return "Donated blood to an urgent request"
        case .streakStarter: return "Donated 2 times consecutively"
        case .streakMaster: return "Donated 5 times consecutively"
        case .communityHero: return "Responded to 10 help requests"
        case .rareHero: return "Donated a rare blood type"
        case .earlyAdopter: return "Among the first 1000 users"
        case .topDonor: return "Ranked in top 10 donors"
        }
    }
    
    var icon: String {
        switch self {
        case .firstDonation: return "drop.fill"
        case .fiveDonations: return "drop.fill"
        case .tenDonations: return "drop.fill"
        case .twentyFiveDonations: return "heart.fill"
        case .fiftyDonations: return "heart.fill"
        case .hundredDonations: return "heart.fill"
        case .lifeSaver: return "staroflife.fill"
        case .streakStarter: return "flame.fill"
        case .streakMaster: return "flame.fill"
        case .communityHero: return "person.3.fill"
        case .rareHero: return "sparkles"
        case .earlyAdopter: return "star.fill"
        case .topDonor: return "trophy.fill"
        }
    }
    
    var color: String {
        switch self {
        case .firstDonation: return "red"
        case .fiveDonations: return "red"
        case .tenDonations: return "red"
        case .twentyFiveDonations: return "gray"
        case .fiftyDonations: return "yellow"
        case .hundredDonations: return "purple"
        case .lifeSaver: return "green"
        case .streakStarter: return "orange"
        case .streakMaster: return "orange"
        case .communityHero: return "blue"
        case .rareHero: return "pink"
        case .earlyAdopter: return "yellow"
        case .topDonor: return "yellow"
        }
    }
    
    var requiredDonations: Int? {
        switch self {
        case .firstDonation: return 1
        case .fiveDonations: return 5
        case .tenDonations: return 10
        case .twentyFiveDonations: return 25
        case .fiftyDonations: return 50
        case .hundredDonations: return 100
        default: return nil
        }
    }
}

// MARK: - User Blood Profile (Extended)
struct BloodProfile: Codable {
    var totalCredits: Int
    var lifetimeDonations: Int
    var livesSaved: Int  // Estimated: 1 donation = 3 lives
    var currentStreak: Int
    var longestStreak: Int
    var badges: [Badge]
    var transactions: [CreditTransaction]
    var donations: [DonationRecord]
    var helpResponseCount: Int
    var referralCount: Int
    var priorityLevel: PriorityLevel
    var lastDonationDate: Date?
    
    init() {
        self.totalCredits = 0
        self.lifetimeDonations = 0
        self.livesSaved = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.badges = []
        self.transactions = []
        self.donations = []
        self.helpResponseCount = 0
        self.referralCount = 0
        self.priorityLevel = .standard
        self.lastDonationDate = nil
    }
    
    var canDonateNow: Bool {
        guard let lastDate = lastDonationDate else { return true }
        let daysSinceLastDonation = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastDonation >= 56
    }
    
    var daysUntilCanDonate: Int {
        guard let lastDate = lastDonationDate else { return 0 }
        let nextDate = Calendar.current.date(byAdding: .day, value: 56, to: lastDate) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        return max(0, days)
    }
}

enum PriorityLevel: String, Codable {
    case standard = "Standard"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    
    var minCredits: Int {
        switch self {
        case .standard: return 0
        case .silver: return 200
        case .gold: return 500
        case .platinum: return 1000
        }
    }
    
    var color: String {
        switch self {
        case .standard: return "gray"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "purple"
        }
    }
    
    var benefits: [String] {
        switch self {
        case .standard:
            return ["Access to blood bank locator", "Submit blood requests"]
        case .silver:
            return ["Priority in request queue", "Badge showcase", "Donation reminders"]
        case .gold:
            return ["Higher priority matching", "Featured on leaderboard", "Early access to features"]
        case .platinum:
            return ["Highest priority requests", "VIP support", "Exclusive badges", "Recognition on app"]
        }
    }
    
    static func level(for credits: Int) -> PriorityLevel {
        if credits >= PriorityLevel.platinum.minCredits {
            return .platinum
        } else if credits >= PriorityLevel.gold.minCredits {
            return .gold
        } else if credits >= PriorityLevel.silver.minCredits {
            return .silver
        } else {
            return .standard
        }
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let rank: Int
    let userId: String
    let userName: String
    let profileImageURL: String?
    let totalCredits: Int
    let lifetimeDonations: Int
    let livesSaved: Int
    let priorityLevel: PriorityLevel
    let badgeCount: Int
}
