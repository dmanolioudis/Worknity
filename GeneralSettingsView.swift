import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var preferences = AppPreferences.shared
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AccountPageBanner(title: "Γενικές ρυθμίσεις", subtitle: "Η εφαρμογή, όπως σε βολεύει.", symbol: "gearshape")

                VStack(alignment: .leading, spacing: 16) {
                    Label("Εμφάνιση", systemImage: "circle.lefthalf.filled")
                        .font(.headline)
                    Picker("Εμφάνιση", selection: $preferences.appearance) {
                        ForEach(AppPreferences.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .padding(20)
                .storeCard()

                VStack(alignment: .leading, spacing: 16) {
                    Label("Γλώσσα εφαρμογής", systemImage: "globe")
                        .font(.headline)
                    Picker("Γλώσσα εφαρμογής", selection: $preferences.language) {
                        ForEach(AppPreferences.Language.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    Text("Η γλώσσα αλλάζει τα μενού της εφαρμογής. Τα μηνύματα και οι δημοσιεύσεις παραμένουν όπως γράφτηκαν.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .storeCard()

                HStack {
                    Label("Έκδοση εφαρμογής", systemImage: "info.circle")
                    Spacer()
                    Text(version).foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(20)
                .storeCard()

                Button { confirmReset = true } label: {
                    Label("Επαναφορά προτιμήσεων", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(StoreDesign.ink)
            }
            .padding(20)
        }
        .background { StoreBackdrop() }
        .navigationTitle("Γενικές ρυθμίσεις")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .confirmationDialog("Επαναφορά προτιμήσεων;", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Επαναφορά") { preferences.reset() }
            Button("Ακύρωση", role: .cancel) {}
        } message: {
            Text("Η εμφάνιση και η γλώσσα θα ακολουθούν το κινητό. Ο λογαριασμός και το περιεχόμενό σου δεν αλλάζουν.")
        }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
