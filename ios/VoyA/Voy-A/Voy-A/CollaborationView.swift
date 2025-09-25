import SwiftUI

struct CollaborationView: View {
    @EnvironmentObject var store: DataStore
    @State private var inviteCode = ""
    @State private var showingInviteSheet = false
    @State private var collaborators: [Collaborator] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                if store.trip == nil {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No trip selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Create a trip first to invite collaborators")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Trip Owner") {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("You")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Owner")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section("Collaborators") {
                            if collaborators.isEmpty {
                                Text("No collaborators yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(collaborators) { collaborator in
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text(collaborator.name)
                                                .fontWeight(.medium)
                                            Text(collaborator.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(collaborator.role)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Section("Invite Code") {
                            HStack {
                                Text(inviteCode.isEmpty ? "Generating..." : inviteCode)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                Spacer()
                                Button("Copy") {
                                    UIPasteboard.general.string = inviteCode
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Collaborate")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Invite") {
                        showingInviteSheet = true
                    }
                    .disabled(store.trip == nil)
                }
            }
            .onAppear {
                generateInviteCode()
                loadCollaborators()
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteSheetView(inviteCode: inviteCode)
            }
        }
    }
    
    private func generateInviteCode() {
        if inviteCode.isEmpty {
            inviteCode = "VOY-\(UUID().uuidString.prefix(8).uppercased())"
        }
    }
    
    private func loadCollaborators() {
        // In a real app, this would load from a server
        collaborators = []
    }
}

struct Collaborator: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let role: String
}

struct InviteSheetView: View {
    let inviteCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var message = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Invite Collaborators")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Share your trip with family and friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(.headline)
                        HStack {
                            Text(inviteCode)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                            Spacer()
                            Button("Copy") {
                                UIPasteboard.general.string = inviteCode
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email (optional)")
                            .font(.headline)
                        TextField("friend@example.com", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        TextField("Join my trip to...", text: $message, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Send Invite") {
                        sendInvite()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(email.isEmpty)
                    
                    Button("Share Invite Code") {
                        shareInviteCode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func sendInvite() {
        // In a real app, this would send an email invitation
        dismiss()
    }
    
    private func shareInviteCode() {
        let activityVC = UIActivityViewController(
            activityItems: ["Join my trip! Use invite code: \(inviteCode)"],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}
