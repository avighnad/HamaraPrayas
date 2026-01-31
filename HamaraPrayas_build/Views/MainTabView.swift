import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @StateObject private var viewModel = BloodBankViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    // Blood Banks Tab - First tab users see
                    BloodBankListView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "building.2")
                            Text("Blood Banks")
                        }
                        .tag(0)
                    
                    // Live Updates Tab
                    LiveUpdatesView()
                        .tabItem {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Live")
                        }
                        .tag(1)
                    
                    // Blood Requests Tab
                    BloodRequestsView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "heart.text.square")
                            Text("My Requests")
                        }
                        .tag(2)
                    
                    // Community Tab
                    CommunityView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "person.3")
                            Text("Community")
                        }
                        .tag(3)
                    
                    // More Tab
                    MoreView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "ellipsis.circle")
                            Text("More")
                        }
                        .tag(4)
                }
                .accentColor(.red)
                .onChange(of: selectedTab) { _, _ in
                    HapticManager.shared.selectionChanged()
                }
                .onAppear {
                    // Delay heavy operations to prevent UI freezing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Request location permission when app launches
                        viewModel.requestLocationPermission()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Set up blood requests listener when user is authenticated
                        viewModel.setupBloodRequestsListener()
                    }
                }

                // Footer credit
               
            }

        }
    }
}

struct MoreView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Emergency")) {
                    NavigationLink(destination: EmergencyView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Emergency Blood Request")
                                    .font(.headline)
                                Text("Submit urgent blood requests")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Profile")
                                    .font(.headline)
                                Text("Settings and account info")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct EmergencyView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var showingBloodRequestForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Emergency Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                    
                    Text("Emergency Blood Request")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Need blood urgently? Submit a request and we'll notify nearby blood banks immediately.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Quick Actions
                VStack(spacing: 20) {
                    Button(action: {
                        HapticManager.shared.emergency()
                        showingBloodRequestForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Submit Blood Request")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                }
                .padding(.horizontal)
                
                // Recent Requests
                if !viewModel.bloodRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Requests")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.bloodRequests.prefix(3)) { request in
                                    EmergencyRequestCard(request: request)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Emergency")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBloodRequestForm) {
                BloodRequestFormView(viewModel: viewModel)
            }
        }
    }
}

struct EmergencyRequestCard: View {
    let request: BloodRequest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.patientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(request.hospital)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(request.requestDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(request.bloodType.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("\(request.unitsNeeded) units")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Circle()
                        .fill(Color(request.status.color))
                        .frame(width: 8, height: 8)
                    Text(request.status.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(request.status.color))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingLocationSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(Auth.auth().currentUser?.email ?? "Not available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Location")) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        Text("Location Services")
                        Spacer()
                        if viewModel.userLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingLocationSettings = true
                    }
                    
                    if let location = viewModel.userLocation {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.blue)
                            Text("Current Location")
                            Spacer()
                            Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundColor(.red)
                        Text("Total Requests")
                        Spacer()
                        Text("\(viewModel.bloodRequests.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                        Text("Nearby Blood Banks")
                        Spacer()
                        Text("\(viewModel.bloodBanks.count)")
                            .fontWeight(.semibold)
                    }
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Blood Bank Locator")
                        Spacer()
                    }
                }
                
                Section {
                    Button(action: {
                        // Clear all requests from Firebase
                        viewModel.clearAllRequests()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Requests")
                                .foregroundColor(.red)
                        }
                    }
                }
                Section(header: Text("Other")) {
                    Link(destination: URL(string: "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/tos")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                        }
                    }

                    Link(destination: URL(string: "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/privacy-policy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Clean up listeners before logout
                        viewModel.removeBloodRequestsListener()
                        authService.logout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Location Services", isPresented: $showingLocationSettings) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location services to find nearby blood banks.")
            }
        }
    }
}

#Preview {
    MainTabView()
}

