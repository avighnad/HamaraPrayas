import SwiftUI

struct BloodRequestFormView: View {
    @ObservedObject var viewModel: BloodBankViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var patientName = ""
    @State private var selectedBloodType = BloodType.aPositive
    @State private var unitsNeeded = 1
    @State private var selectedUrgency = UrgencyLevel.medium
    @State private var hospital = ""
    @State private var contactNumber = ""
    @State private var additionalNotes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showCustomHospitalInput = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $patientName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
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
                
                Section(header: Text("Hospital & Contact")) {
                    // Hospital Dropdown
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
                                
                                if selectedBank.phoneNumber != "Contact facility directly" {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text(selectedBank.phoneNumber)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // Custom hospital input option
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showCustomHospitalInput.toggle()
                                if !showCustomHospitalInput {
                                    hospital = ""
                                }
                            }) {
                                HStack {
                                    Image(systemName: showCustomHospitalInput ? "minus.circle" : "plus.circle")
                                    Text(showCustomHospitalInput ? "Hide custom input" : "Can't find your hospital?")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            if showCustomHospitalInput {
                                TextField("Enter hospital name manually", text: $hospital)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: hospital) { _, newValue in
                                        // Clear selection if user types custom name
                                        if !viewModel.bloodBanks.contains(where: { $0.name == newValue }) {
                                            // Keep the custom value
                                        }
                                    }
                            }
                        }
                    }
                    
                    TextField("Contact Number", text: $contactNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Additional Notes (Optional)", text: $additionalNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: {
                        HapticManager.shared.heavyImpact()
                        submitRequest()
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Submit Blood Request")
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
            .navigationTitle("Blood Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Blood Request", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !contactNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitRequest() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        let request = BloodRequest(
            patientName: patientName.trimmingCharacters(in: .whitespacesAndNewlines),
            bloodType: selectedBloodType,
            unitsNeeded: unitsNeeded,
            urgency: selectedUrgency,
            hospital: hospital.trimmingCharacters(in: .whitespacesAndNewlines),
            contactNumber: contactNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            additionalNotes: additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            await viewModel.submitBloodRequest(request)
            await MainActor.run {
                HapticManager.shared.success()
                alertMessage = "Blood request submitted successfully! We'll notify nearby blood banks."
                showingAlert = true
            }
        }
    }
}

#Preview {
    BloodRequestFormView(viewModel: BloodBankViewModel())
}

