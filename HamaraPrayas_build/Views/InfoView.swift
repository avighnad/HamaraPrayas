import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Hamara Prayas")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Hamara Prayas focuses on medical and educational awareness in Begusarai and beyond. We work to support effective management of Leukaemia and Thalassemia in children, encourage blood donation, and promote equitable education aligned with NEP 2020.")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Areas")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Bullet(text: "Blood donation drives and awareness campaigns")
                        Bullet(text: "Support and information for Leukaemia & Thalassemia")
                        Bullet(text: "Educational outreach in rural regions, including Almora, Uttarakhand")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Get Involved")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Hamara Prayas needs your support. Join our initiatives, donate blood, or contribute to educational programs.")
                        Link(destination: URL(string: "https://www.hamaraprayas.in/")!) {
                            HStack {
                                Image(systemName: "link")
                                Text("Visit hamaraprayas.in")
                            }
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Email: avighnadaruka@gmail.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct Bullet: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.body)
    }
}

#Preview {
    InfoView()
}



