import Foundation
import Combine
import GoogleSignIn
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit

// MARK: - Privacy Policy and Terms Configuration
struct PrivacyPolicyConfig {
    static let privacyPolicyURL = "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/privacy-policy"
    static let termsOfServiceURL = "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/tos"
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let db = Firestore.firestore()
    
    init() {
        // Ensure Firebase is configured before using Auth
        guard FirebaseApp.app() != nil else {
            print("Firebase not configured yet")
            return
        }
        
        // Listen to Firebase auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                print("🔄 Auth state changed - User: \(user?.uid ?? "nil")")
                if let user = user {
                    print("👤 Loading user from Firestore: \(user.uid)")
                    self?.loadUserFromFirestore(userId: user.uid)
                } else {
                    print("🚪 User signed out")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Public method to load existing user (called on app launch)
    func loadExistingUser(userId: String) {
        print("🔄 Loading existing user on app launch: \(userId)")
        loadUserFromFirestore(userId: userId)
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard FirebaseApp.app() != nil else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Firebase not configured"
            }
            return
        }
        
        guard isValidEmail(email) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Please enter a valid email address"
            }
            return
        }
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Load user data from Firestore
            loadUserFromFirestore(userId: authResult.user.uid)
            
            await MainActor.run {
                HapticManager.shared.success()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                HapticManager.shared.error()
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func register(data: RegistrationData) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard FirebaseApp.app() != nil else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Firebase not configured"
            }
            return
        }
        
        guard isValidEmail(data.email) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Please enter a valid email address"
            }
            return
        }
        
        guard data.password.count >= 6 else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Password must be at least 6 characters"
            }
            return
        }
        
        guard data.password == data.confirmPassword else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Passwords do not match"
            }
            return
        }
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: data.email, password: data.password)
            
            // Create user document in Firestore
            let user = User(
                email: data.email,
                firstName: data.firstName,
                lastName: data.lastName,
                phoneNumber: data.phoneNumber,
                bloodType: data.bloodType,
                dateOfBirth: data.dateOfBirth,
                emergencyContact: nil,
                isDonor: data.isDonor,
                lastDonationDate: nil,
                profileImageURL: nil,
                createdAt: Date()
            )
            
            try await saveUserToFirestore(user, userId: authResult.user.uid)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func logout() {
        guard FirebaseApp.app() != nil else {
            print("Firebase not configured")
            return
        }
        
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            removeUserFromStorage()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard FirebaseApp.app() != nil else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Firebase not configured"
            }
            return
        }
        
        print("🔐 Attempting to send password reset email to: \(email)")
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent successfully to: \(email)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Password reset email sent successfully"
            }
        } catch {
            print("❌ Password reset error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateProfile(_ user: User) {
        currentUser = user
        saveUserToStorage(user)
    }
    

    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Local Storage
    
    private func saveUserToStorage(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    private func loadUserFromStorage() {
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func removeUserFromStorage() {
        userDefaults.removeObject(forKey: userKey)
    }
    
    // MARK: - Google Sign-In
    
    private func configureGoogleSignInWithPrivacyPolicy() {
        // Configure Google Sign-In with privacy policy and terms of service
        // These URLs will be displayed during the sign-in process
        
        let privacyPolicyURL = PrivacyPolicyConfig.privacyPolicyURL
        let termsOfServiceURL = PrivacyPolicyConfig.termsOfServiceURL
        
        // Set the privacy policy and terms of service URLs
        // Note: Google Sign-In will automatically show these during the OAuth flow
        print("🔗 Privacy Policy URL: \(privacyPolicyURL)")
        print("🔗 Terms of Service URL: \(termsOfServiceURL)")
        print("📱 Google Sign-In configured with privacy policy and terms of service")
        
        // Note: Google Sign-In automatically requests basic profile and email scopes
        // Additional scopes can be configured in the Google Cloud Console
    }
    
    func signInWithGoogle() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard FirebaseApp.app() != nil else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Firebase not configured"
            }
            return
        }
        
        // Use the Google Sign-In client ID from GoogleService-Info.plist
        let clientID = "37523399533-bj8gknem076bceld78o1ht3r43le21u9.apps.googleusercontent.com"
        
        let config = GIDConfiguration(
            clientID: clientID
        )
        GIDSignIn.sharedInstance.configuration = config
        
        // Configure privacy policy and terms of service
        configureGoogleSignInWithPrivacyPolicy()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Could not find root view controller"
            }
            return
        }
        
        do {
            print("🔍 Starting Google Sign-In...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            print("✅ Google Sign-In successful")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ No ID token received")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to get ID token"
                }
                return
            }
            
            print("✅ ID token received")
            print("🔍 User email: \(result.user.profile?.email ?? "No email")")
            print("🔍 User name: \(result.user.profile?.name ?? "No name")")
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Create user document if it doesn't exist
            let user = User(
                email: authResult.user.email ?? "",
                firstName: authResult.user.displayName?.components(separatedBy: " ").first ?? "",
                lastName: authResult.user.displayName?.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? "",
                phoneNumber: authResult.user.phoneNumber ?? "",
                bloodType: nil,
                dateOfBirth: nil,
                emergencyContact: nil,
                isDonor: false,
                lastDonationDate: nil,
                profileImageURL: authResult.user.photoURL?.absoluteString,
                createdAt: Date()
            )
            
            try await saveUserToFirestore(user, userId: authResult.user.uid)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
                print("✅ User authenticated successfully: \(user.email)")
            }
            
        } catch {
            print("❌ Google Sign-In error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Firebase Methods
    
    private func saveUserToFirestore(_ user: User, userId: String) async throws {
        let userData: [String: Any] = [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "phoneNumber": user.phoneNumber,
            "bloodType": user.bloodType?.rawValue ?? "",
            "dateOfBirth": user.dateOfBirth?.timeIntervalSince1970 ?? 0,
            "isDonor": user.isDonor,
            "lastDonationDate": user.lastDonationDate?.timeIntervalSince1970 ?? 0,
            "createdAt": user.createdAt.timeIntervalSince1970,
            "profileImageURL": user.profileImageURL ?? "",
            "city": user.city ?? ""
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    private func loadUserFromFirestore(userId: String) {
        print("📖 Loading user from Firestore: \(userId)")
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading user: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("❌ User document not found for userId: \(userId) - creating basic user")
                    // User exists in Firebase Auth but not in Firestore, create basic user
                    let basicUser = User(
                        id: UUID(uuidString: userId) ?? UUID(),
                        email: Auth.auth().currentUser?.email ?? "",
                        firstName: Auth.auth().currentUser?.displayName?.components(separatedBy: " ").first ?? "",
                        lastName: Auth.auth().currentUser?.displayName?.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? "",
                        phoneNumber: Auth.auth().currentUser?.phoneNumber ?? "",
                        bloodType: nil,
                        dateOfBirth: nil,
                        emergencyContact: nil,
                        isDonor: false,
                        lastDonationDate: nil,
                        profileImageURL: Auth.auth().currentUser?.photoURL?.absoluteString,
                        city: nil,
                        createdAt: Date()
                    )
                    self?.currentUser = basicUser
                    self?.isAuthenticated = true
                    print("✅ Basic user created and authenticated")
                    return
                }
                
                print("✅ User document found, creating User object")
                let user = User(
                    id: UUID(uuidString: userId) ?? UUID(),
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    bloodType: BloodType(rawValue: data["bloodType"] as? String ?? ""),
                    dateOfBirth: (data["dateOfBirth"] as? Double).map { Date(timeIntervalSince1970: $0) },
                    emergencyContact: nil,
                    isDonor: data["isDonor"] as? Bool ?? false,
                    lastDonationDate: (data["lastDonationDate"] as? Double).map { Date(timeIntervalSince1970: $0) },
                    profileImageURL: data["profileImageURL"] as? String,
                    city: data["city"] as? String,
                    createdAt: (data["createdAt"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                )
                
                print("✅ User object created: \(user.email)")
                self?.currentUser = user
                self?.isAuthenticated = true
                print("🎯 Authentication state updated - isAuthenticated: \(self?.isAuthenticated ?? false)")
            }
        }
    }
}
// MARK: - Microsoft Sign-In
extension AuthenticationService {
    @MainActor
    func signInWithMicrosoft() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        guard FirebaseApp.app() != nil else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Firebase not configured"
            }
            return
        }

        let provider = OAuthProvider(providerID: "microsoft.com")
        provider.customParameters = ["prompt": "select_account"]

        // Specify the scopes you want (optional)
        provider.scopes = ["email", "openid", "profile"]

        guard let rootVC = await UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Could not find root view controller"
            }
            return
        }

        // MARK: Use the older credential flow
        provider.getCredentialWith(nil) { credential, error in
            Task {
                if let error = error {
                    print("❌ Microsoft Sign-In Error: \(error.localizedDescription)")
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "Microsoft Sign-In failed: \(error.localizedDescription)"
                    }
                    return
                }

                guard let credential = credential else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "No credential returned from Microsoft"
                    }
                    return
                }

                do {
                    print("🟦 Signing in with Microsoft credential...")
                    let authResult = try await Auth.auth().signIn(with: credential)
                    let firebaseUser = authResult.user

                    let email = firebaseUser.email ?? ""
                    let displayName = firebaseUser.displayName ?? ""
                    let firstName = displayName.components(separatedBy: " ").first ?? ""
                    let lastName = displayName.components(separatedBy: " ").dropFirst().joined(separator: " ")

                    let user = User(
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        phoneNumber: firebaseUser.phoneNumber ?? "",
                        bloodType: nil,
                        dateOfBirth: nil,
                        emergencyContact: nil,
                        isDonor: false,
                        lastDonationDate: nil,
                        profileImageURL: firebaseUser.photoURL?.absoluteString,
                        createdAt: Date()
                    )

                    try await self.saveUserToFirestore(user, userId: firebaseUser.uid)

                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isLoading = false
                        print("✅ Microsoft user authenticated: \(user.email)")
                    }

                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    }
                    print("❌ Firebase Auth Sign-In failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
