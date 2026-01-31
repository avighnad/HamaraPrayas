import SwiftUI

struct HelpRequestFormView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var patientName = ""
    @State private var selectedBloodType = BloodType.aPositive
    @State private var unitsNeeded = 1
    @State private var selectedUrgency = UrgencyLevel.medium
    @State private var hospital = ""
    @State private var city = ""
    @State private var additionalNotes = ""
    @State private var isAnonymous = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $patientName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle("Post Anonymously", isOn: $isAnonymous)
                        .onChange(of: isAnonymous) { newValue in
                            if newValue {
                                patientName = "Anonymous Patient"
                            }
                        }
                    
                    Picker("Blood Type", selection: $selectedBloodType) {
                        ForEach(BloodType.allCases, id: \.self) { bloodType in
                            Text(bloodType.displayName).tag(bloodType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Stepper("Units Needed: \(unitsNeeded)", value: $unitsNeeded, in: 1...10)
                    
                    Picker("Urgency Level", selection: $selectedUrgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { urgency in
                            HStack {
                                Circle()
                                    .fill(Color(urgency.color))
                                    .frame(width: 12, height: 12)
                                Text(urgency.rawValue)
                            }
                            .tag(urgency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Location & Hospital")) {
                    // Hospital Dropdown (same as blood request form)
                    if viewModel.bloodBanks.isEmpty {
                        TextField("Hospital Name", text: $hospital)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        // Show count of available hospitals
                        HStack {
                            Text("Available Hospitals")
                            Spacer()
                            Text("\(viewModel.bloodBanks.count) found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Picker("Select Hospital", selection: $hospital) {
                            Text("Select a hospital...").tag("")
                            ForEach(viewModel.bloodBanks, id: \.id) { bloodBank in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bloodBank.name)
                                        .font(.body)
                                    Text(bloodBank.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(bloodBank.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        // Show selected hospital details
                        if !hospital.isEmpty, let selectedBank = viewModel.bloodBanks.first(where: { $0.name == hospital }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text(selectedBank.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let distance = selectedBank.distance {
                                    HStack {
                                        Image(systemName: "location.circle")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text(String(format: "~%.1f km away", distance))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // City field (auto-filled from GPS)
                    HStack {
                        TextField("City", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        if let userCity = viewModel.userCity {
                            Button("Use My Location") {
                                city = userCity
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Additional Notes (Optional)", text: $additionalNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section(footer: Text("This request will be visible to the community. People can offer to help and you'll be notified.")) {
                    Button(action: submitHelpRequest) {
                        HStack {
                            Image(systemName: "person.3")
                                .foregroundColor(.red)
                            Text("Post to Community")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Request Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Help Request", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Set user's city if available
                if let userCity = viewModel.userCity, city.isEmpty {
                    city = userCity
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitHelpRequest() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        let helpRequest = HelpRequest(
            patientName: isAnonymous ? "Anonymous Patient" : patientName.trimmingCharacters(in: .whitespacesAndNewlines),
            bloodType: selectedBloodType,
            unitsNeeded: unitsNeeded,
            urgency: selectedUrgency,
            hospital: hospital.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            additionalNotes: additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            requesterUserId: "", // Will be set by the ViewModel
            isAnonymous: isAnonymous
        )
        
        Task {
            await viewModel.createHelpRequest(helpRequest)
            await MainActor.run {
                alertMessage = "Help request posted successfully! The community can now see it and offer to help."
                showingAlert = true
            }
        }
    }
}

#Preview {
    HelpRequestFormView(viewModel: BloodBankViewModel())
}
