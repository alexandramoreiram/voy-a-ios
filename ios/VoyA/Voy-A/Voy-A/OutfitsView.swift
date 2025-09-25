import SwiftUI
import PhotosUI

struct OutfitsView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingPinterestInput = false
    @State private var pinterestURL = ""
    @State private var pinterestCaption = ""
    @State private var editingOutfit: Outfit?
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            VStack {
                if store.outfits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No outfit inspiration yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Add photos from your camera or paste Pinterest URLs for outfit ideas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                            ForEach(store.outfits) { outfit in
                                OutfitCard(outfit: outfit) {
                                    deleteOutfit(outfit)
                                } onEdit: { outfit in
                                    editOutfit(outfit)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Outfits")
            .toolbar {
                HStack {
                    Button(action: { showingPinterestInput = true }) {
                        Image(systemName: "link")
                    }
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        Image(systemName: "camera")
                    }
                }
            }
            .onChange(of: selectedItems) {
                Task {
                    await loadImages(from: selectedItems)
                }
            }
            .sheet(isPresented: $showingPinterestInput) {
                PinterestInputView(pinterestURL: $pinterestURL, caption: $pinterestCaption) { url, caption in
                    addPinterestOutfit(url: url, caption: caption)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let outfit = editingOutfit {
                    EditOutfitSheet(outfit: outfit) { updatedOutfit in
                        updateOutfit(updatedOutfit)
                    }
                    .environmentObject(store)
                }
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let outfit = Outfit(
                    imageFileName: "photo_\(UUID().uuidString)",
                    caption: "Photo from camera",
                    imageData: data
                )
                await MainActor.run {
                    store.outfits.append(outfit)
                }
            }
        }
    }
    
    private func addPinterestOutfit(url: String, caption: String) {
        let outfit = Outfit(
            imageFileName: "pinterest_\(UUID().uuidString)",
            caption: caption.isEmpty ? "Pinterest inspiration" : caption,
            pinterestURL: url
        )
        store.outfits.append(outfit)
        pinterestURL = ""
        pinterestCaption = ""
    }
    
    private func deleteOutfit(_ outfit: Outfit) {
        store.outfits.removeAll { $0.id == outfit.id }
    }
    
    private func editOutfit(_ outfit: Outfit) {
        editingOutfit = outfit
        showingEditSheet = true
    }
    
    private func updateOutfit(_ updatedOutfit: Outfit) {
        if let index = store.outfits.firstIndex(where: { $0.id == updatedOutfit.id }) {
            store.outfits[index] = updatedOutfit
        }
        editingOutfit = nil
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    let onDelete: () -> Void
    let onEdit: (Outfit) -> Void
    @State private var image: UIImage?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else if outfit.pinterestURL != nil {
                    VStack {
                        Image(systemName: "link")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Pinterest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                        // Action buttons
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Button(action: { 
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        onEdit(outfit) 
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.blue))
                                            .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: { 
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        showingDeleteAlert = true 
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                            .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
            }
            
            Text(outfit.caption)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if let pinterestURL = outfit.pinterestURL {
                Link("View on Pinterest", destination: URL(string: pinterestURL)!)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
            loadImage()
        }
        .alert("Delete Outfit", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this outfit?")
        }
    }
    
    private func loadImage() {
        if let imageData = outfit.imageData {
            image = UIImage(data: imageData)
        }
    }
}

struct PinterestInputView: View {
    @Binding var pinterestURL: String
    @Binding var caption: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pinterest URL") {
                    TextField("https://pinterest.com/pin/...", text: $pinterestURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled(true)
                }
                Section("Caption (optional)") {
                    TextField("Outfit description", text: $caption)
                }
            }
            .navigationTitle("Add Pinterest Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(pinterestURL, caption)
                        dismiss()
                    }
                    .disabled(pinterestURL.isEmpty)
                }
            }
        }
    }
}

struct EditOutfitSheet: View {
    let outfit: Outfit
    let onSave: (Outfit) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var caption: String
    @State private var pinterestURL: String
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
            VStack(spacing: 20) {
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
                
                Form {
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Outfit Updated!", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
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
            imageData: outfit.imageData
        )
        
        await MainActor.run {
            onSave(updatedOutfit)
            isSaving = false
            showingSuccess = true
        }
    }
}