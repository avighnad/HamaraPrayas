import SwiftUI
import MapKit

struct BloodBankDetailView: View {
    let bloodBank: BloodBank
    @ObservedObject var viewModel: BloodBankViewModel
    @State private var region: MKCoordinateRegion
    @State private var showingDirections = false
    
    init(bloodBank: BloodBank, viewModel: BloodBankViewModel) {
        self.bloodBank = bloodBank
        self.viewModel = viewModel
        self._region = State(initialValue: MKCoordinateRegion(
            center: bloodBank.location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(bloodBank.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        Text(bloodBank.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: bloodBank.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(bloodBank.isOpen ? .green : .red)
                        Text(bloodBank.isOpen ? "Open" : "Closed")
                            .foregroundColor(bloodBank.isOpen ? .green : .red)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", bloodBank.rating))
                        }
                        
                        if let distance = bloodBank.distance {
                            Text(String(format: "~%.1f km", distance))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Map
                Map {
                    Marker(bloodBank.name, coordinate: bloodBank.location)
                        .tint(.red)
                }
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    region = context.region
                }
                .frame(height: 200)
                .cornerRadius(12)
                .onTapGesture {
                    showingDirections = true
                }
                
                // Contact Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ContactRow(icon: "phone.fill", text: bloodBank.phoneNumber, action: {
                        if bloodBank.phoneNumber != "Contact facility directly" {
                            if let url = URL(string: "tel:\(bloodBank.phoneNumber)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    })
                    
                    if let email = bloodBank.email {
                        ContactRow(icon: "envelope.fill", text: email, action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    
                    if let website = bloodBank.website {
                        ContactRow(icon: "globe", text: website, action: {
                            if let url = URL(string: "https://\(website)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    
                    ContactRow(icon: "clock.fill", text: bloodBank.operatingHours, action: nil)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Blood Inventory
                VStack(alignment: .leading, spacing: 12) {
                    Text("Blood Inventory")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(BloodType.allCases, id: \.self) { bloodType in
                            BloodTypeCard(
                                bloodType: bloodType,
                                units: bloodBank.bloodInventory[bloodType] ?? 0
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if bloodBank.phoneNumber != "Contact facility directly" {
                            if let url = URL(string: "tel:\(bloodBank.phoneNumber)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call Blood Bank")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingDirections = true
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Get Directions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Blood Bank Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDirections) {
            DirectionsView(bloodBank: bloodBank)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

struct BloodTypeCard: View {
    let bloodType: BloodType
    let units: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(bloodType.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            Text("\(units) units")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if units > 0 {
                Text("Available")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Text("Out of Stock")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DirectionsView: View {
    let bloodBank: BloodBank
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Opening Maps...")
                    .font(.headline)
                    .padding()
                
                Text("The Maps app will open with directions to \(bloodBank.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("OK") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                openInMaps()
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: bloodBank.location)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = bloodBank.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    NavigationView {
        BloodBankDetailView(
            bloodBank: BloodBank(
                name: "Sample Hospital",
                address: "123 Main St",
                phoneNumber: "+1-555-0123",
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                operatingHours: "24/7"
            ),
            viewModel: BloodBankViewModel()
        )
    }
}

