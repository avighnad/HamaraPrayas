import SwiftUI
import FirebaseAuth

struct BloodRequestsView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var selectedTab: RequestTab = .bloodRequests
    @State private var showingCreateForm = false
    @State private var showingHelpRequestForm = false
    @State private var showingLearnMore = false
    
    enum RequestTab: String, CaseIterable {
        case bloodRequests = "Blood Requests"
        case communityRequests = "Community Requests"
        
        var icon: String {
            switch self {
            case .bloodRequests: return "heart.text.square"
            case .communityRequests: return "person.3"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Request Type", selection: $selectedTab) {
                    ForEach(RequestTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == .bloodRequests {
                    BloodRequestsSection(viewModel: viewModel)
                } else {
                    CommunityRequestsSection(viewModel: viewModel)
                }
            }
            .navigationTitle("My Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedTab == .bloodRequests {
                        Button(action: { 
                            // Add filter functionality here
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingLearnMore = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            if selectedTab == .bloodRequests {
                                showingCreateForm = true
                            } else {
                                showingHelpRequestForm = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Create Request")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                BloodRequestFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHelpRequestForm) {
                HelpRequestFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingLearnMore) {
                BloodRequestsLearnMoreView()
            }
        }
    }
}

// MARK: - Blood Requests Section
struct BloodRequestsSection: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var selectedStatus: RequestStatus?
    @State private var showingFilter = false
    
    var filteredRequests: [BloodRequest] {
        if let status = selectedStatus {
            return viewModel.bloodRequests.filter { $0.status == status }
        }
        return viewModel.bloodRequests
    }
    
    var body: some View {
        VStack {
            if viewModel.bloodRequests.isEmpty {
                EmptyBloodRequestsView()
            } else {
                List {
                    ForEach(filteredRequests.sorted(by: { $0.requestDate > $1.requestDate })) { request in
                        BloodRequestRowView(request: request, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteRequest)
                }
                .refreshable {
                    // Refresh data if needed
                }
            }
        }
        .sheet(isPresented: $showingFilter) {
            RequestStatusFilterView(selectedStatus: $selectedStatus)
        }
    }
    
    private func deleteRequest(at offsets: IndexSet) {
        for index in offsets {
            let request = filteredRequests[index]
            viewModel.updateRequestStatus(request.id, status: .cancelled)
        }
    }
}

// MARK: - Community Requests Section
struct CommunityRequestsSection: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var showingHelpOffers = false
    @State private var selectedHelpRequest: HelpRequest?
    @State private var myHelpOffers: [HelpRequest] = []
    
    // Get user's community requests (requests they posted)
    var myCommunityRequests: [HelpRequest] {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("🔍 No authenticated user for community requests")
            return [] 
        }
        let filtered = viewModel.helpRequests.filter { $0.requesterUserId == userId }
        print("🔍 Found \(filtered.count) community requests for user \(userId)")
        print("🔍 Total help requests: \(viewModel.helpRequests.count)")
        return filtered
    }
    
    var body: some View {
        VStack {
            if myCommunityRequests.isEmpty && myHelpOffers.isEmpty {
                EmptyCommunityRequestsView()
            } else {
                List {
                    // My Posted Requests Section
                    if !myCommunityRequests.isEmpty {
                        Section(header: Text("My Posted Requests")) {
                            ForEach(myCommunityRequests.sorted(by: { $0.requestDate > $1.requestDate })) { request in
                                MyCommunityRequestRow(
                                    request: request,
                                    onViewOffers: {
                                        selectedHelpRequest = request
                                        showingHelpOffers = true
                                    },
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    
                    // My Help Offers Section
                    if !myHelpOffers.isEmpty {
                        Section(header: Text("My Help Offers")) {
                            ForEach(myHelpOffers.sorted(by: { $0.requestDate > $1.requestDate })) { request in
                                MyHelpOfferRow(request: request)
                            }
                        }
                    }
                }
                .refreshable {
                    viewModel.setupHelpRequestsListener()
                    await loadHelpOffers()
                }
                .onAppear {
                    Task {
                        await loadHelpOffers()
                    }
                }
            }
        }
        .sheet(isPresented: $showingHelpOffers) {
            if let request = selectedHelpRequest {
                HelpOffersView(helpRequest: request, viewModel: viewModel)
            }
        }
    }
    
    private func loadHelpOffers() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        myHelpOffers = await viewModel.getHelpOffersForUser(userId: userId)
    }
}

// MARK: - My Community Request Row
struct MyCommunityRequestRow: View {
    let request: HelpRequest
    let onViewOffers: () -> Void
    @State private var responseCount: Int = 0
    @ObservedObject var viewModel: BloodBankViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.isAnonymous ? "Anonymous Request" : request.patientName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(request.bloodType.displayName) • \(request.unitsNeeded) units")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(request.urgency.color))
                            .frame(width: 12, height: 12)
                        Text(request.urgency.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(request.urgency.color))
                    }
                    
                    Text(request.requestDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(request.hospital)
                    .font(.subheadline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("\(responseCount) offers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("View Help Offers") {
                onViewOffers()
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            Task {
                responseCount = await viewModel.getResponseCount(for: request.id)
            }
        }
    }
}

// MARK: - My Help Offer Row
struct MyHelpOfferRow: View {
    let request: HelpRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.isAnonymous ? "Anonymous Patient" : request.patientName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(request.bloodType.displayName) • \(request.unitsNeeded) units")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(request.urgency.color))
                            .frame(width: 12, height: 12)
                        Text(request.urgency.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(request.urgency.color))
                    }
                    
                    Text(request.requestDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(request.hospital)
                    .font(.subheadline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Help Offered")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Help Offers View
struct HelpOffersView: View {
    let helpRequest: HelpRequest
    @ObservedObject var viewModel: BloodBankViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var helpOffers: [HelpOffer] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading help offers...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if helpOffers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Help Offers Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("When people offer to help with your request, they'll appear here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(helpOffers) { offer in
                        HelpOfferRow(offer: offer)
                    }
                }
            }
            .navigationTitle("Help Offers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHelpOffers()
            }
        }
    }
    
    private func loadHelpOffers() {
        Task {
            let offers = await viewModel.getHelpOffersForRequest(helpRequestId: helpRequest.id)
            DispatchQueue.main.async {
                self.helpOffers = offers
                self.isLoading = false
            }
        }
    }
}

// MARK: - Help Offer Row
struct HelpOfferRow: View {
    let offer: HelpOffer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.helperName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Offered to help")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(offer.offerDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !offer.message.isEmpty {
                Text(offer.message)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // Contact information
            HStack {
                if let email = offer.helperEmail {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if let phone = offer.helperPhone {
                    HStack(spacing: 4) {
                        Image(systemName: "phone")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if offer.isContacted {
                    Text("Contacted")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            if let phone = offer.helperPhone, !phone.isEmpty {
                if let url = URL(string: "tel:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Help Offer Model
struct HelpOffer: Identifiable {
    let id: UUID
    let helperName: String
    let helperEmail: String?
    let helperPhone: String?
    let message: String
    let offerDate: Date
    let isContacted: Bool
    
    init(
        id: UUID = UUID(),
        helperName: String,
        helperEmail: String? = nil,
        helperPhone: String? = nil,
        message: String = "",
        offerDate: Date = Date(),
        isContacted: Bool = false
    ) {
        self.id = id
        self.helperName = helperName
        self.helperEmail = helperEmail
        self.helperPhone = helperPhone
        self.message = message
        self.offerDate = offerDate
        self.isContacted = isContacted
    }
}

// MARK: - Empty Views
struct EmptyBloodRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Blood Requests")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You haven't submitted any blood requests yet. Tap the + button to create your first request.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCommunityRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Community Activity")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You haven't posted any community requests or offered help yet. Tap the + button to get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BloodRequestRowView: View {
    let request: BloodRequest
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(request.patientName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Fulfilled indicator
                        if request.status == .fulfilled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    
                    Text(request.hospital)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(request.bloodType.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("\(request.unitsNeeded) units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                HStack {
                    Circle()
                        .fill(Color(request.urgency.color))
                        .frame(width: 12, height: 12)
                    Text(request.urgency.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(request.urgency.color).opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Enhanced Status Indicator
                Button(action: {
                    // Cycle through status options
                    let currentStatus = request.status
                    let allStatuses: [RequestStatus] = [.pending, .inProgress, .fulfilled, .cancelled]
                    if let currentIndex = allStatuses.firstIndex(of: currentStatus) {
                        let nextIndex = (currentIndex + 1) % allStatuses.count
                        let newStatus = allStatuses[nextIndex]
                        viewModel.updateRequestStatus(request.id, status: newStatus)
                    }
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(request.status.color))
                            .frame(width: 10, height: 10)
                        Text(request.status.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(request.status.color))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(request.status.color).opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(request.status.color).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                Text(request.contactNumber)
                    .font(.caption)
                
                Spacer()
                
                Text(request.requestDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !request.additionalNotes.isEmpty {
                Text(request.additionalNotes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("View Details") {
                    showingDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                if request.status == .pending {
                    Button("Cancel") {
                        viewModel.updateRequestStatus(request.id, status: .cancelled)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetail) {
            BloodRequestDetailView(request: request, viewModel: viewModel)
        }
    }
}

struct BloodRequestDetailView: View {
    let request: BloodRequest
    @ObservedObject var viewModel: BloodBankViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(request.patientName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(request.bloodType.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Text(request.hospital)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Request Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Request Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DetailRow(title: "Units Needed", value: "\(request.unitsNeeded)")
                        DetailRow(title: "Urgency Level", value: request.urgency.rawValue, color: request.urgency.color)
                        // Enhanced Status Row
                        HStack {
                            Text("Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Cycle through status options
                                let currentStatus = request.status
                                let allStatuses: [RequestStatus] = [.pending, .inProgress, .fulfilled, .cancelled]
                                if let currentIndex = allStatuses.firstIndex(of: currentStatus) {
                                    let nextIndex = (currentIndex + 1) % allStatuses.count
                                    let newStatus = allStatuses[nextIndex]
                                    viewModel.updateRequestStatus(request.id, status: newStatus)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(request.status.color))
                                        .frame(width: 12, height: 12)
                                    Text(request.status.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(request.status.color))
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(request.status.color).opacity(0.15))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(request.status.color).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        DetailRow(title: "Request Date", value: request.requestDate.formatted(date: .long, time: .shortened))
                        DetailRow(title: "Contact", value: request.contactNumber)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Additional Notes
                    if !request.additionalNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(request.additionalNotes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Nearby Blood Banks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nearby Blood Banks with \(request.bloodType.displayName)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let nearbyBanks = viewModel.getNearbyBloodBanks(for: request.bloodType, units: request.unitsNeeded)
                        
                        if nearbyBanks.isEmpty {
                            Text("No blood banks found with sufficient \(request.bloodType.displayName) blood")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        } else {
                            ForEach(nearbyBanks.prefix(3)) { bank in
                                NearbyBankRow(bank: bank, bloodType: request.bloodType)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Request Details")
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

struct DetailRow: View {
    let title: String
    let value: String
    let color: String?
    
    init(title: String, value: String, color: String? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color != nil ? Color(color!) : .primary)
        }
    }
}

struct NearbyBankRow: View {
    let bank: BloodBank
    let bloodType: BloodType
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(bank.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(bank.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let distance = bank.distance {
                    Text(String(format: "%.1f km", distance))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text("\(bank.bloodInventory[bloodType] ?? 0) units")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Blood Requests")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You haven't submitted any blood requests yet. Tap the + button to create your first request.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RequestStatusFilterView: View {
    @Binding var selectedStatus: RequestStatus?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filter by Status")) {
                    Button("Show All") {
                        selectedStatus = nil
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    ForEach(RequestStatus.allCases, id: \.self) { status in
                        Button(status.rawValue) {
                            selectedStatus = status
                            dismiss()
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter")
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

// MARK: - Blood Requests Learn More View
struct BloodRequestsLearnMoreView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("How Blood Requests Work")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Learn how to create and manage blood donation requests")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Process Steps
                    VStack(alignment: .leading, spacing: 20) {
                        ProcessStepView(
                            stepNumber: 1,
                            title: "Create a Request",
                            description: "When you or someone you know needs blood, create a request with details like blood type, units needed, hospital, and urgency level.",
                            icon: "plus.circle.fill",
                            color: .red
                        )
                        
                        ProcessStepView(
                            stepNumber: 2,
                            title: "Track Your Requests",
                            description: "Monitor the status of your requests, see how many people have offered help, and manage your active requests.",
                            icon: "list.bullet.clipboard",
                            color: .blue
                        )
                        
                        ProcessStepView(
                            stepNumber: 3,
                            title: "Get Help",
                            description: "When someone offers to help, you can contact them directly. Update your request status when you receive the blood you need.",
                            icon: "heart.fill",
                            color: .green
                        )
                        
                        ProcessStepView(
                            stepNumber: 4,
                            title: "Community Support",
                            description: "Your requests also appear in the Community tab where local volunteers can see and offer help.",
                            icon: "person.3.fill",
                            color: .orange
                        )
                    }
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tips for Better Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TipView(
                                icon: "clock.fill",
                                text: "Post requests early - the sooner you post, the more time people have to help"
                            )
                            
                            TipView(
                                icon: "location.fill",
                                text: "Include accurate hospital and city information for local volunteers"
                            )
                            
                            TipView(
                                icon: "exclamationmark.triangle.fill",
                                text: "Use the correct urgency level - urgent requests get more visibility"
                            )
                            
                            TipView(
                                icon: "phone.fill",
                                text: "Keep your contact information updated so helpers can reach you"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
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

struct TipView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    BloodRequestsView(viewModel: BloodBankViewModel())
}
