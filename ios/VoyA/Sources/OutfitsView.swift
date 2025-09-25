import SwiftUI

struct OutfitsView: View {
    @EnvironmentObject var store: DataStore
    @State private var images: [UIImage] = []
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img).resizable().scaledToFill().frame(height: 120).clipped().cornerRadius(8)
                    }
                }.padding()
            }
            .navigationTitle("Outfits")
            .toolbar { Button(action: { showingPicker = true }) { Image(systemName: "photo") } }
        }
    }
}
