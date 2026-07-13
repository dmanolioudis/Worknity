import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var userName = "Dimitrios"
    
    // Bindings για το UnifiedTabBar
    @Binding var selectedTab: Tabs
    @Binding var storeSelectedTab: STabs
    @Binding var showOverlay: Bool
    @Binding var tabBarMode: TabBarMode
    
    @State private var stores: [Store] = []
    @State private var isLoading = false
    
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")
    
    var body: some View {
        ZStack {
            AnimatedBlobBackground()
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Hello, \(userName)")
                    .font(.largeTitle.weight(.semibold))
                    .padding(.horizontal)
                    .padding(.top, 40)
                
                if isLoading {
                    PlaceholderGrid()
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(stores) { store in
                                NavigationLink {
                                    StoreView(
                                        storename: store.name,
                                        storeID: store.id,
                                        tabBarMode: $tabBarMode,
                                        selectedTab: $storeSelectedTab
                                    )
                                } label: {
                                    StoreCard(store: store, mainColor: mainColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            tabBarMode = .root
            fetchStores()
        }
    }
    
    private func fetchStores() {
        guard let user = Auth.auth().currentUser else { return }
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
    let mainColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(mainColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(store.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(store.address)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1))
        )
    }
}

private struct PlaceholderGrid: View {
    var body: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15))
                    )
                    .frame(height: 120)
                    .redacted(reason: .placeholder)
            }
        }
    }
}


