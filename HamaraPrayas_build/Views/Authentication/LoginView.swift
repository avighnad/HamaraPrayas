import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseCore


// MARK: - UIKit wrapper for GIDSignInButton
struct GoogleSignInButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .light
        // Add target
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        
        @objc func didTapButton() {
            action()
        }
    }
}

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.5), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 20) {
                            Image("20250903_2341_White Heart Logo_remix_01k48rb1hyfyyvbkh2dcev5gza")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                            
                            Text("Hamara Prayas")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("Blood Bank Locator & Info Services")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Login Form
                        VStack(spacing: 20) {
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
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.password)
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                            }
                            
                            // Login Button
                            Button(action: {
                                Task {
                                    await authService.login(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right")
                                            .font(.headline)
                                    }
                                    
                                    Text(authService.isLoading ? "Signing In..." : "Sign In")
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
                            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
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
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                            
                            Text("OR")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        .padding(.horizontal, 30)
                        
                        // ✅ Google Sign-In Button (UIKit wrapped)
                        // Privacy Policy and Terms of Service will be shown during Google Sign-In
                        GoogleSignInButton {
                            Task {
                                await authService.signInWithGoogle()
                            }
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 30)
                        
                        // Privacy Policy and Terms of Service notice
                        Text("By signing in with Google, you agree to our Privacy Policy and Terms of Service")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        
                        // Register Button
                        Button(action: {
                            showingRegistration = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.headline)
                                Text("Create New Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegistration) {
                RegistrationView()
            }
            .alert("Forgot Password", isPresented: $showingForgotPassword) {
                TextField("Enter your email", text: $email)
                Button("Send Reset Link") {
                    Task {
                        await authService.resetPassword(email: email)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("We'll send you a password reset link to your email address.")
            }
        }
    }
}

#Preview {
    LoginView()
}
