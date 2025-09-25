import SwiftUI
import PhotosUI

struct EditOutfitView: View {
    let outfit: Outfit
    let onSave: (Outfit) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var caption: String
    @State private var pinterestURL: String
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSaving = false
    @State private var showingSuccess = false
    
    init(outfit: Outfit, onSave: @escaping (Outfit) -> Void) {
        self.outfit = outfit
        self.onSave = onSave
        self._caption = State(initialValue: outfit.caption)
        self._pinterestURL = State(initialValue: outfit.pinterestURL ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Edit Outfit")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                Form {
                    Section("Image") {
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } else if let pinterestURL = outfit.pinterestURL, !pinterestURL.isEmpty {
                            VStack {
                                Image(systemName: "link")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Pinterest Link")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("No Image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            Text("Change Image")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Section("Details") {
                        TextField("Caption", text: $caption, axis: .vertical)
                        TextField("Pinterest URL (optional)", text: $pinterestURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                }
                
                Spacer()
                
                // Save Button
                VStack(spacing: 16) {
                    Button(action: { Task { await saveOutfit() } }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(isSaving || caption.isEmpty)
                    .opacity((isSaving || caption.isEmpty) ? 0.6 : 1.0)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                imageData = outfit.imageData
            }
            .onChange(of: selectedImage) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
        .alert("Outfit Updated!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your outfit has been successfully updated.")
        }
    }
    
    private func saveOutfit() async {
        await MainActor.run {
            isSaving = true
        }
        
        let updatedOutfit = Outfit(
            id: outfit.id,
            imageFileName: outfit.imageFileName,
            caption: caption,
            pinterestURL: pinterestURL.isEmpty ? nil : pinterestURL,
            imageData: imageData
        )
        
        await MainActor.run {
            onSave(updatedOutfit)
            isSaving = false
            showingSuccess = true
        }
    }
}
