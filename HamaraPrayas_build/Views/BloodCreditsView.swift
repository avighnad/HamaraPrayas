//
//  BloodCreditsView.swift
//  HamaraPrayas_build
//
//  Main view for the Blood Credit System
//

import SwiftUI

struct BloodCreditsView: View {
    @StateObject private var creditsService = BloodCreditsService.shared
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var selectedTab = 0
    @State private var showRecordDonation = false
    @State private var showNewBadgeAlert = false
    @State private var animateCredits = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Credit Card
                    creditCardView
                    
                    // Quick Stats
                    statsGridView
                    
                    // Tab Selector
                    Picker("View", selection: $selectedTab) {
                        Text("Badges").tag(0)
                        Text("History").tag(1)
                        Text("Leaderboard").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Content based on tab
                    switch selectedTab {
                    case 0:
                        badgesView
                    case 1:
                        transactionHistoryView
                    case 2:
                        leaderboardView
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Blood Credits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRecordDonation = true
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $showRecordDonation) {
                RecordDonationView()
                    .environmentObject(authService)
            }
            .alert("New Badge Earned! 🎉", isPresented: $showNewBadgeAlert) {
                Button("Awesome!", role: .cancel) {
                    creditsService.clearNewBadge()
                }
            } message: {
                if let badge = creditsService.newBadgeEarned {
                    Text("You earned the '\(badge.type.title)' badge!\n\(badge.type.description)")
                }
            }
            .onChange(of: creditsService.newBadgeEarned) { _, newBadge in
                if newBadge != nil {
                    showNewBadgeAlert = true
                }
            }
            .task {
                if let userId = authService.user?.id {
                    try? await creditsService.loadBloodProfile(for: userId)
                    try? await creditsService.loadLeaderboard()
                }
            }
        }
    }
    
    // MARK: - Credit Card View
    private var creditCardView: some View {
        VStack(spacing: 0) {
            // Main card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Credits")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text("\(creditsService.bloodProfile.totalCredits)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(animateCredits ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3), value: animateCredits)
                    }
                    
                    Spacer()
                    
                    // Priority Level Badge
                    VStack(spacing: 4) {
                        Image(systemName: priorityIcon)
                            .font(.system(size: 32))
                            .foregroundStyle(priorityColor)
                        
                        Text(creditsService.bloodProfile.priorityLevel.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                // Lives saved
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    
                    Text("\(creditsService.bloodProfile.livesSaved) Lives Saved")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if !creditsService.bloodProfile.canDonateNow {
                        Text("\(creditsService.bloodProfile.daysUntilCanDonate) days until next")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("Ready to donate!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.red, .red.opacity(0.8), Color(red: 0.8, green: 0.1, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Progress to next level
            if creditsService.bloodProfile.priorityLevel != .platinum {
                nextLevelProgressView
            }
        }
        .padding(.horizontal)
        .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                animateCredits = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateCredits = false
            }
        }
    }
    
    private var nextLevelProgressView: some View {
        let currentLevel = creditsService.bloodProfile.priorityLevel
        let nextLevel: PriorityLevel = {
            switch currentLevel {
            case .standard: return .silver
            case .silver: return .gold
            case .gold: return .platinum
            case .platinum: return .platinum
            }
        }()
        
        let progress = Double(creditsService.bloodProfile.totalCredits - currentLevel.minCredits) /
                       Double(nextLevel.minCredits - currentLevel.minCredits)
        let creditsNeeded = nextLevel.minCredits - creditsService.bloodProfile.totalCredits
        
        return VStack(spacing: 8) {
            HStack {
                Text("Next: \(nextLevel.rawValue)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(creditsNeeded) credits to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1, max(0, progress)))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .offset(y: -10)
    }
    
    private var priorityIcon: String {
        switch creditsService.bloodProfile.priorityLevel {
        case .standard: return "circle"
        case .silver: return "shield.fill"
        case .gold: return "shield.fill"
        case .platinum: return "crown.fill"
        }
    }
    
    private var priorityColor: Color {
        switch creditsService.bloodProfile.priorityLevel {
        case .standard: return .white
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
    
    // MARK: - Stats Grid
    private var statsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                icon: "drop.fill",
                value: "\(creditsService.bloodProfile.lifetimeDonations)",
                label: "Donations",
                color: .red
            )
            
            StatCard(
                icon: "flame.fill",
                value: "\(creditsService.bloodProfile.currentStreak)",
                label: "Streak",
                color: .orange
            )
            
            StatCard(
                icon: "medal.fill",
                value: "\(creditsService.bloodProfile.badges.count)",
                label: "Badges",
                color: .yellow
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Badges View
    private var badgesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Earned Badges
            if !creditsService.bloodProfile.badges.isEmpty {
                Text("Earned Badges")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(creditsService.bloodProfile.badges) { badge in
                        BadgeCard(badge: badge, isEarned: true)
                    }
                }
                .padding(.horizontal)
            }
            
            // Locked Badges
            let earnedTypes = Set(creditsService.bloodProfile.badges.map { $0.type })
            let lockedBadges = BadgeType.allCases.filter { !earnedTypes.contains($0) }
            
            if !lockedBadges.isEmpty {
                Text("Badges to Unlock")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(lockedBadges, id: \.self) { badgeType in
                        BadgeCard(badge: Badge(type: badgeType), isEarned: false)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Transaction History
    private var transactionHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Credit History")
                .font(.headline)
                .padding(.horizontal)
            
            if creditsService.bloodProfile.transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions Yet",
                    systemImage: "clock",
                    description: Text("Your credit history will appear here")
                )
                .padding(.top, 40)
            } else {
                ForEach(creditsService.bloodProfile.transactions.prefix(20)) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
    
    // MARK: - Leaderboard
    private var leaderboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Donors")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    Task {
                        try? await creditsService.loadLeaderboard()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            
            if creditsService.leaderboard.isEmpty {
                ContentUnavailableView(
                    "Loading Leaderboard",
                    systemImage: "trophy",
                    description: Text("Fetching top donors...")
                )
                .padding(.top, 40)
            } else {
                ForEach(creditsService.leaderboard) { entry in
                    LeaderboardRow(entry: entry, isCurrentUser: entry.userId == authService.user?.id)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BadgeCard: View {
    let badge: Badge
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(isEarned ? 0.2 : 0.05))
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.type.icon)
                    .font(.title)
                    .foregroundStyle(isEarned ? badgeColor : .gray.opacity(0.3))
            }
            
            Text(badge.type.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(isEarned ? .primary : .secondary)
            
            if isEarned {
                Text(badge.earnedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(badge.type.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isEarned ? 1 : 0.6)
    }
    
    private var badgeColor: Color {
        switch badge.type.color {
        case "red": return .red
        case "yellow": return .yellow
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .gray
        }
    }
}

struct TransactionRow: View {
    let transaction: CreditTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.type.icon)
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text(transaction.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("+\(transaction.amount)")
                .font(.headline)
                .foregroundStyle(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var iconColor: Color {
        switch transaction.type.color {
        case "red": return .red
        case "yellow": return .yellow
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        default: return .gray
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                
                Text("\(entry.rank)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName)
                    .font(.subheadline.bold())
                    .foregroundStyle(isCurrentUser ? .red : .primary)
                
                HStack(spacing: 8) {
                    Label("\(entry.lifetimeDonations)", systemImage: "drop.fill")
                    Label("\(entry.badgeCount)", systemImage: "medal.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalCredits)")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Text(entry.priorityLevel.rawValue)
                    .font(.caption2)
                    .foregroundStyle(levelColor)
            }
        }
        .padding()
        .background(isCurrentUser ? Color.red.opacity(0.1) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.red : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal)
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var levelColor: Color {
        switch entry.priorityLevel {
        case .standard: return .gray
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
}

// MARK: - Record Donation View
struct RecordDonationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var creditsService = BloodCreditsService.shared
    
    @State private var selectedBloodType: BloodType = .oPositive
    @State private var hospitalName = ""
    @State private var location = ""
    @State private var wasUrgent = false
    @State private var donationDate = Date()
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Blood Type", selection: $selectedBloodType) {
                        ForEach(BloodType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Hospital/Blood Bank Name", text: $hospitalName)
                    
                    TextField("City/Location", text: $location)
                    
                    DatePicker("Donation Date", selection: $donationDate, in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("Donation Details")
                }
                
                Section {
                    Toggle(isOn: $wasUrgent) {
                        HStack {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundStyle(.orange)
                            Text("This was an urgent donation")
                        }
                    }
                } footer: {
                    Text("Urgent donations to emergency requests earn bonus credits!")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Credits You'll Earn")
                            .font(.headline)
                        
                        HStack {
                            Text("Base donation")
                            Spacer()
                            Text("+100")
                                .foregroundStyle(.green)
                        }
                        
                        if creditsService.bloodProfile.lifetimeDonations == 0 {
                            HStack {
                                Text("First donation bonus")
                                Spacer()
                                Text("+50")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        if wasUrgent {
                            HStack {
                                Text("Urgent donation bonus")
                                Spacer()
                                Text("+50")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text("+\(calculateCredits())")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Record Donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitDonation()
                    }
                    .disabled(hospitalName.isEmpty || location.isEmpty || isSubmitting)
                }
            }
            .alert("Donation Recorded! 🎉", isPresented: $showSuccess) {
                Button("Awesome!") {
                    dismiss()
                }
            } message: {
                Text("Thank you for donating blood! You've earned \(calculateCredits()) credits and potentially saved 3 lives.")
            }
        }
    }
    
    private func calculateCredits() -> Int {
        var credits = 100
        if creditsService.bloodProfile.lifetimeDonations == 0 {
            credits += 50
        }
        if wasUrgent {
            credits += 50
        }
        return credits
    }
    
    private func submitDonation() {
        guard let userId = authService.user?.id else { return }
        
        isSubmitting = true
        HapticManager.shared.mediumImpact()
        
        Task {
            do {
                try await creditsService.recordDonation(
                    userId: userId,
                    bloodType: selectedBloodType,
                    location: location,
                    hospitalName: hospitalName,
                    wasUrgent: wasUrgent
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                print("Error recording donation: \(error)")
            }
        }
    }
}

#Preview {
    BloodCreditsView()
        .environmentObject(AuthenticationService())
}
