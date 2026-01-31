import SwiftUI
import WebKit

// MARK: - WebView for embedding websites
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 Started loading website")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Website loaded successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Failed to load website: \(error.localizedDescription)")
        }
    }
}

// MARK: - Live Updates View
struct LiveUpdatesView: View {
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
    private let imageGalleryURL = "https://www.hamaraprayas.in/our-vision/image-gallery"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Live Updates")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("See the latest from Hamara Prayas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Info Section
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Want to share your images with us?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Send Email") {
                            sendEmail()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                    
                    // WebView Container
                    if hasError {
                        // Error State
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Unable to Load Updates")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Button("Try Again") {
                                hasError = false
                                isLoading = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                    } else {
                        // WebView
                        ZStack {
                            WebView(url: URL(string: imageGalleryURL)!)
                                .onAppear {
                                    // Simulate loading time
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        isLoading = false
                                    }
                                }
                            
                            if isLoading {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                        .scaleEffect(1.5)
                                    
                                    Text("Loading Updates...")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGroupedBackground))
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Check if URL is valid
            guard URL(string: imageGalleryURL) != nil else {
                hasError = true
                errorMessage = "Invalid website URL"
                return
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func sendEmail() {
        let email = "avighnadaruka@gmail.com"
        let subject = "Hamara Prayas - Image Submission"
        let body = "Hi,\n\nI would like to share some images with Hamara Prayas for the Live Updates section.\n\nPlease find the images attached.\n\nThank you!"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback: copy email to clipboard
                UIPasteboard.general.string = email
                print("📧 Email copied to clipboard: \(email)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LiveUpdatesView()
}
