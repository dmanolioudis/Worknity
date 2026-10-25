import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    let onSelectStore: (Store) -> Void
    
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var hasFetchedStores = false
    @State private var showCreateStore = false
    @State private var newStoreName = ""
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AccountPageBanner(
                    title: "Ο χώρος σου",
                    subtitle: "Η ομάδα, τα νέα και το πρόγραμμά σου. Όλα ξεκινούν εδώ.",
                    symbol: "building.2"
                )

                Button {
                    newStoreName = ""
                    showCreateStore = true
                } label: {
                    Label("Νέο κατάστημα", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(StorePrimaryButtonStyle())
                .disabled(isLoading || !hasFetchedStores)

                HStack {
                    Text("Τα καταστήματά σου")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if hasFetchedStores && !isLoading {
                        Text(stores.count, format: .number)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(StoreDesign.softAccent, in: Capsule())
                            .accessibilityLabel("\(stores.count) καταστήματα")
                    }
                }

                if isLoading || !hasFetchedStores {
                    PlaceholderGrid(columns: columns)
                } else if stores.isEmpty {
                    VStack(spacing: 14) {
                        StoreIcon(symbol: "building.2")
                        Text("Ο χώρος σου περιμένει την ομάδα")
                            .font(.headline)
                        Text("Τα καταστήματα στα οποία συμμετέχεις θα εμφανίζονται εδώ.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .storeCard()
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(stores) { store in
                            Button {
                                onSelectStore(store)
                            } label: {
                                StoreCard(store: store)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Ανοίγει τα νέα, τα μηνύματα και το πρόγραμμα του καταστήματος")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background { StoreBackdrop() }
        .sheet(isPresented: $showCreateStore) {
            AddStoreView(storeName: $newStoreName) { store in
                stores.removeAll { $0.id == store.id }
                stores.insert(store, at: 0)
                showCreateStore = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Preserve the grid when returning from a store.
            if !hasFetchedStores && !isLoading {
                fetchStores()
            }
        }
    }

    private func fetchStores() {
        guard let user = Auth.auth().currentUser else { return }
        hasFetchedStores = true
        isLoading = true
        let db = Firestore.firestore()
        let userID = user.uid
        
        // Query 1: Καταστήματα όπου ο χρήστης είναι manager
        let managerQuery = db.collection("stores").whereField("manager", isEqualTo: userID)
        
        // Query 2: Καταστήματα όπου ο χρήστης είναι στα participants
        let participantQuery = db.collection("stores").whereField("participants", arrayContains: userID)
        
        // Εκτελούμε και τα δύο ταυτόχρονα
        let group = DispatchGroup()
        var fetchedStores: [Store] = []
        
        group.enter()
        managerQuery.getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                fetchedStores.append(contentsOf: self.mapDocuments(docs))
            }
            group.leave()
        }
        
        group.enter()
        participantQuery.getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                fetchedStores.append(contentsOf: self.mapDocuments(docs))
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Αφαιρούμε διπλότυπα (αν κάποιος είναι και manager και participant)
            let uniqueStores = Array(NSOrderedSet(array: fetchedStores)) as! [Store]
            self.stores = uniqueStores
            self.isLoading = false
        }
    }
    
    // Βοηθητική συνάρτηση για το mapping
    private func mapDocuments(_ documents: [QueryDocumentSnapshot]) -> [Store] {
        return documents.map { doc in
            let data = doc.data()
            return Store(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                address: data["address"] as? String ?? "",
                phone: data["phone"] as? String ?? "",
                manager: data["manager"] as? String ?? "",
                participants: data["participants"] as? [String] ?? []
            )
        }
    }
}
// MARK: - Components
private struct StoreCard: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StoreIcon(symbol: "building.2")
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StoreDesign.ink)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(store.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if !store.address.isEmpty {
                    Text(store.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .topLeading)
        .storeCard()
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

private struct PlaceholderGrid: View {
    let columns: [GridItem]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<4) { _ in
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 16).fill(StoreDesign.softAccent)
                        .frame(width: 48, height: 48)
                    RoundedRectangle(cornerRadius: 5).fill(StoreDesign.softAccent)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 5).fill(StoreDesign.softAccent)
                        .frame(width: 70, height: 10)
                    Spacer(minLength: 0)
                }
                .padding(18)
                .frame(minHeight: 174)
                .storeCard()
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Φόρτωση καταστημάτων")
    }
}
