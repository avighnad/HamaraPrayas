import SwiftUI

struct BloodBankListView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var selectedBloodType: BloodType?
    @State private var showingFilter = false
    @State private var searchText = ""
    @State private var showingInfo = false
    
    var filteredBloodBanks: [BloodBank] {
        var filtered = viewModel.bloodBanks
        
        // Filter by blood type
        if let bloodType = selectedBloodType {
            filtered = filtered.filter { $0.hasBloodType(bloodType) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { bloodBank in
                bloodBank.name.localizedCaseInsensitiveContains(searchText) ||
                bloodBank.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding nearby blood banks...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredBloodBanks.isEmpty {
                    EmptyStateView(
                        searchText: searchText,
                        selectedBloodType: selectedBloodType
                    )
                } else {
                    List(filteredBloodBanks) { bloodBank in
                        NavigationLink(destination: BloodBankDetailView(bloodBank: bloodBank, viewModel: viewModel)) {
                            EnhancedBloodBankRowView(bloodBank: bloodBank)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        HapticManager.shared.lightImpact()
                        viewModel.refreshBloodBanks()
                    }
                }
            }
            .navigationTitle("Blood Banks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingInfo = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: { showingFilter = true }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                EnhancedBloodTypeFilterView(selectedBloodType: $selectedBloodType)
            }
            .sheet(isPresented: $showingInfo) {
                BloodBankInfoView()
            }
            .onAppear {
                if viewModel.userLocation == nil {
                    viewModel.getCurrentLocation()
                }
            }
        }
    }
    
    
    struct SearchBar: View {
        @Binding var text: String
        
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search blood banks...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    struct EnhancedBloodBankRowView: View {
        let bloodBank: BloodBank
        
        var body: some View {
            VStack(spacing: 0) {
                // Main content
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(bloodBank.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                // Verified badge
                                if bloodBank.isVerified {
                                    HStack(spacing: 2) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("Verified")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Text(bloodBank.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            // Distance
                            if let distance = bloodBank.distance {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(String(format: "~%.1f km", distance))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(String(format: "%.1f", bloodBank.rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Status and hours
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(bloodBank.isOpen ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(bloodBank.isOpen ? "Open Now" : "Closed")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(bloodBank.isOpen ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Text(bloodBank.operatingHours)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Blood type availability
                    if !bloodBank.bloodInventory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Blood Types")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                                ForEach(BloodType.allCases, id: \.self) { bloodType in
                                    if let units = bloodBank.bloodInventory[bloodType], units > 0 {
                                        VStack(spacing: 2) {
                                            Text(bloodType.displayName)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            Text("\(units)")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    struct EmptyStateView: View {
        let searchText: String
        let selectedBloodType: BloodType?
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "building.2")
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
            if !searchText.isEmpty {
                return "No Results Found"
            } else if selectedBloodType != nil {
                return "No \(selectedBloodType?.displayName ?? "") Available"
            } else {
                return "No Blood Banks Nearby"
            }
        }
        
        private var emptyStateMessage: String {
            if !searchText.isEmpty {
                return "Try adjusting your search terms or removing filters"
            } else if selectedBloodType != nil {
                return "No blood banks have \(selectedBloodType?.displayName ?? "") blood available nearby"
            } else {
                return "We couldn't find any blood banks in your area. Please check your location settings."
            }
        }
    }
    
    struct EnhancedBloodTypeFilterView: View {
        @Binding var selectedBloodType: BloodType?
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                List {
                    Section(header: Text("Filter by Blood Type")) {
                        Button(action: {
                            selectedBloodType = nil
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(selectedBloodType == nil ? .red : .secondary)
                                Text("Show All Blood Banks")
                                    .foregroundColor(selectedBloodType == nil ? .red : .primary)
                                Spacer()
                                if selectedBloodType == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        ForEach(BloodType.allCases, id: \.self) { bloodType in
                            Button(action: {
                                selectedBloodType = bloodType
                                dismiss()
                            }) {
                                HStack {
                                    Text("🩸")
                                    Text(bloodType.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedBloodType == bloodType {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(footer: Text("Filtering will show only blood banks that have the selected blood type available")) {
                        EmptyView()
                    }
                }
                .navigationTitle("Filter Blood Banks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
}

struct BloodBankInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Blood Bank Locator")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("How it works")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // How it works section
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            icon: "location.fill",
                            title: "Location-Based Search",
                            description: "We use your current location to find blood banks within a 50km radius. Make sure location services are enabled for the best results."
                        )
                        
                        InfoSection(
                            icon: "globe",
                            title: "Real-Time Data",
                            description: "Blood bank information is fetched from OpenStreetMap, providing up-to-date locations and contact details."
                        )
                        
                        InfoSection(
                            icon: "magnifyingglass",
                            title: "Smart Filtering",
                            description: "Filter by blood type to see only blood banks that have your required blood type in stock. Use the search bar to find specific hospitals or areas."
                        )
                        
                        InfoSection(
                            icon: "phone.fill",
                            title: "Direct Contact",
                            description: "Tap on any blood bank to see contact information and call them directly to confirm availability before visiting."
                        )
                        
                        InfoSection(
                            icon: "checkmark.seal.fill",
                            title: "Verified Blood Banks",
                            description: "Look for the blue 'Verified' badge! These are confirmed blood banks in our database. Other results are from OpenStreetMap and may include hospitals with blood bank facilities."
                        )
                        
                        InfoSection(
                            icon: "arrow.clockwise",
                            title: "Always Updated",
                            description: "Pull down to refresh and get the latest blood bank information. The list updates automatically when you move to a new location."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 Pro Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Call ahead to confirm blood availability")
                            TipRow(text: "Bring a valid ID when visiting blood banks")
                            TipRow(text: "Check operating hours before visiting")
                            TipRow(text: "Some blood banks may require appointments")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("How It Works")
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

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.red)
                .fontWeight(.bold)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    BloodBankListView(viewModel: BloodBankViewModel())
}
