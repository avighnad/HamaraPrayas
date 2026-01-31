import SwiftUI

struct RegistrationView: View {
    @StateObject private var authService = AuthenticationService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var selectedBloodType: BloodType?
    @State private var dateOfBirth = Date()
    @State private var isDonor = false
    @State private var showingDatePicker = false
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        !firstName.isEmpty && 
        !lastName.isEmpty && 
        !phoneNumber.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("Join Hamara Prayas to help save lives")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Registration Form
                        VStack(spacing: 20) {
                            // Personal Information
                            Group {
                                HStack(spacing: 15) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("First Name")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        TextField("First Name", text: $firstName)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .textContentType(.givenName)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Last Name")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        TextField("Last Name", text: $lastName)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .textContentType(.familyName)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Phone Number")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter your phone number", text: $phoneNumber)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.telephoneNumber)
                                        .keyboardType(.phonePad)
                                }
                            }
                            
                            // Password Section
                            Group {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.newPassword)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.newPassword)
                                }
                                
                                if !password.isEmpty && !confirmPassword.isEmpty {
                                    HStack {
                                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(password == confirmPassword ? .green : .red)
                                        Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                            .font(.caption)
                                            .foregroundColor(password == confirmPassword ? .green : .red)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // Medical Information
                            Group {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Blood Type (Optional)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Menu {
                                        ForEach(BloodType.allCases, id: \.self) { bloodType in
                                            Button(bloodType.displayName) {
                                                selectedBloodType = bloodType
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedBloodType?.displayName ?? "Select Blood Type")
                                                .foregroundColor(selectedBloodType == nil ? .secondary : .primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date of Birth (Optional)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Button(action: {
                                        showingDatePicker = true
                                    }) {
                                        HStack {
                                            Text(dateOfBirth, style: .date)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                Toggle(isOn: $isDonor) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                        Text("I want to be a blood donor")
                                            .font(.headline)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.horizontal, 30)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Register Button
                        Button(action: {
                            Task {
                                let registrationData = RegistrationData(
                                    email: email,
                                    password: password,
                                    confirmPassword: confirmPassword,
                                    firstName: firstName,
                                    lastName: lastName,
                                    phoneNumber: phoneNumber,
                                    bloodType: selectedBloodType,
                                    dateOfBirth: dateOfBirth,
                                    isDonor: isDonor
                                )
                                
                                await authService.register(data: registrationData)
                                
                                if authService.isAuthenticated {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.headline)
                                }
                                
                                Text(authService.isLoading ? "Creating Account..." : "Create Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationTitle("Registration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $dateOfBirth)
            }
        }
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Select Date of Birth")
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

#Preview {
    RegistrationView()
}

