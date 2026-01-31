import SwiftUI

struct OfferHelpView: View {
    let helpRequest: HelpRequest
    @ObservedObject var viewModel: BloodBankViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var helperName: String = ""
    @State private var helperPhone: String = ""
    @State private var message: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Offer Help")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help \(helpRequest.isAnonymous ? "someone" : helpRequest.patientName) in need")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Request Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Blood Type:")
                        Spacer()
                        Text(helpRequest.bloodType.displayName)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Units Needed:")
                        Spacer()
                        Text("\(helpRequest.unitsNeeded)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Hospital:")
                        Spacer()
                        Text(helpRequest.hospital)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("City:")
                        Spacer()
                        Text(helpRequest.city)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Your Name", text: $helperName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.next)
                        
                        TextField("Phone Number (with country code)", text: $helperPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                            .submitLabel(.next)
                        
                        TextField("Optional Message", text: $message, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .submitLabel(.done)
                    }
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitHelpOffer) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                        }
                        
                        Text(isSubmitting ? "Submitting..." : "Submit Help Offer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canSubmit || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Offer Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .alert("Help Offer Submitted!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your help offer has been submitted successfully. The requester will be able to contact you.")
            }
        }
    }
    
    private var canSubmit: Bool {
        !helperName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !helperPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitHelpOffer() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        Task {
            await viewModel.offerHelp(
                for: helpRequest,
                helperName: helperName.trimmingCharacters(in: .whitespacesAndNewlines),
                helperPhone: helperPhone.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            DispatchQueue.main.async {
                self.isSubmitting = false
                self.showSuccessAlert = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    OfferHelpView(
        helpRequest: HelpRequest(
            patientName: "John Doe",
            bloodType: .aPositive,
            unitsNeeded: 2,
            urgency: .high,
            hospital: "City Hospital",
            city: "Mumbai",
            requesterUserId: "test-user-id"
        ),
        viewModel: BloodBankViewModel()
    )
}
