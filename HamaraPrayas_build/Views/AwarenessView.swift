import SwiftUI
import WebKit

struct AwarenessView: View {
    var body: some View {
        NavigationView {
            AwarenessWebView(url: "https://www.hamaraprayas.in/our-vision/hamara-prayas-app")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Awareness")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AwarenessWebView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 Started loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Finished loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Failed to load: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AwarenessView()
}



