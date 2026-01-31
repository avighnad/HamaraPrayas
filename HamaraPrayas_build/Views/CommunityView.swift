import SwiftUI
import FirebaseAuth

struct CommunityView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var showingOfferHelpForm = false
    @State private var selectedHelpRequest: HelpRequest?
    @State private var showingHelpRequestForm = false
    @State private var showingLearnMore = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.localHelpRequests.isEmpty {
                    EmptyCommunityView(userCity: viewModel.userCity)
                } else {
                    List(viewModel.localHelpRequests) { helpRequest in
                        HelpRequestCard(
                            helpRequest: helpRequest,
                            onOfferHelp: {
                                selectedHelpRequest = helpRequest
                            },
                            viewModel: viewModel
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        HapticManager.shared.lightImpact()
                        viewModel.setupHelpRequestsListener()
                    }
                    .sheet(item: $selectedHelpRequest) { request in
                        OfferHelpView(helpRequest: request, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        
                        // ⚡️ AI Powered badge with subtle background
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.footnote)
                            Text("AI Powered")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                        
                        // ℹ️ Info button
                        Button {
                            showingLearnMore = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }

                        // ➕ Add button
                        Button {
                            showingHelpRequestForm = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHelpRequestForm) {
                HelpRequestFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingLearnMore) {
                LearnMoreView()
            }
            .onAppear {
                print("📖 CommunityView appeared – attempting to set up listener")
                viewModel.setupHelpRequestsListener()
            }
            .onDisappear {
                // Don't remove the listener - keep it active for other views
                print("🔧 CommunityView disappeared, keeping listener active")
            }
        }
    }
}

struct HelpRequestCard: View {
    let helpRequest: HelpRequest
    let onOfferHelp: () -> Void
    @State private var responseCount: Int = 0
    @ObservedObject var viewModel: BloodBankViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with urgency indicator
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(helpRequest.isAnonymous ? "Anonymous Patient" : helpRequest.patientName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("needs \(helpRequest.bloodType.displayName) blood")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Urgency indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(helpRequest.urgency.color))
                            .frame(width: 12, height: 12)
                        Text(helpRequest.urgency.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(helpRequest.urgency.color))
                    }
                }
                
                // Blood type and units
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Blood Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(helpRequest.bloodType.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Units Needed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(helpRequest.unitsNeeded)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Hospital and location
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(helpRequest.hospital)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(helpRequest.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Additional notes (if any)
                if !helpRequest.additionalNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(helpRequest.additionalNotes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                // Footer with time and response count
                HStack {
                    Text(helpRequest.requestDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("\(responseCount) helping")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Help button - only show if not user's own request
                if let currentUserId = Auth.auth().currentUser?.uid,
                   helpRequest.requesterUserId != currentUserId {
                    Button(action: {
                        HapticManager.shared.success()
                        onOfferHelp()
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                            Text("I Can Help")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Credit indicator
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("+10")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    // Show disabled state for own requests
                    HStack {
                        Image(systemName: "heart.slash")
                            .foregroundColor(.gray)
                        Text("Your Request")
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            Task {
                responseCount = await viewModel.getResponseCount(for: helpRequest.id)
            }
        }
    }
}

struct EmptyCommunityView: View {
    let userCity: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        if let city = userCity {
            return "No Local Requests in \(city)"
        } else {
            return "No Help Requests Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if let city = userCity {
            return "No blood requests found in \(city). Be the first to post a request or check back later for urgent needs in your area."
        } else {
            return "When people need blood urgently, their requests will appear here for the community to help."
        }
    }
}

// MARK: - Learn More View
struct LearnMoreView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("How Community Help Works")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Learn how our community-driven blood donation system helps save lives")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Process Steps
                    VStack(alignment: .leading, spacing: 20) {
                        ProcessStepView(
                            stepNumber: 1,
                            title: "Post a Request",
                            description: "When someone needs blood urgently, they can post a request with details like blood type, units needed, hospital, and urgency level.",
                            icon: "plus.circle.fill",
                            color: .blue
                        )
                        
                        ProcessStepView(
                            stepNumber: 2,
                            title: "Community Sees It",
                            description: "The request appears in the community feed for people in the same city. You'll only see requests from your local area.",
                            icon: "eye.fill",
                            color: .green
                        )
                        
                        ProcessStepView(
                            stepNumber: 3,
                            title: "Offer Help",
                            description: "If you can help, tap 'I Can Help' to let the requester know. You can see how many others have already offered help.",
                            icon: "heart.fill",
                            color: .red
                        )
                        
                        ProcessStepView(
                            stepNumber: 4,
                            title: "Connect & Help",
                            description: "The requester can see all offers and connect with potential donors. You can coordinate directly to save a life!",
                            icon: "person.2.fill",
                            color: .orange
                        )
                    }
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        FeatureRowView(
                            icon: "location.fill",
                            title: "City-Based Filtering",
                            description: "Only see requests from your city for relevant, actionable help"
                        )
                        
                        FeatureRowView(
                            icon: "bell.fill",
                            title: "Urgent Notifications",
                            description: "Get notified immediately when urgent blood requests are posted in your area"
                        )
                        
                        FeatureRowView(
                            icon: "eye.slash.fill",
                            title: "Anonymous Option",
                            description: "Requesters can post anonymously to protect privacy while still getting help"
                        )
                        
                        FeatureRowView(
                            icon: "heart.text.square.fill",
                            title: "Response Tracking",
                            description: "See how many people have offered help for each request"
                        )
                    }
                    
                    // Safety & Privacy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Safety & Privacy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("• All requests are moderated before appearing in the community")
                            Text("• Personal information is protected and only shared when necessary")
                            Text("• You can choose to help anonymously")
                            Text("• All interactions are logged for safety and accountability")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    
                    // Call to Action
                    VStack(spacing: 16) {
                        Text("Ready to Help Save Lives?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Join our community of lifesavers and help people in your city when they need blood urgently.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Start Helping") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Learn More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Process Step View
struct ProcessStepView: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Feature Row View
struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    CommunityView(viewModel: BloodBankViewModel())
}
