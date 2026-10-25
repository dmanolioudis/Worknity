import SwiftUI

struct StoreSettingsView: View {
    @ObservedObject var access: StoreAccessViewModel
    @StateObject private var directory = StoreSettingsMembers()
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var showAddMember = false
    @State private var editingRole: StoreSettingsMembers.Member?
    @State private var removingMember: StoreSettingsMembers.Member?
    @State private var busy = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AccountPageBanner(title: "Ρυθμίσεις καταστήματος", subtitle: "Η ομάδα, τα στοιχεία και τα δικαιώματα πρόσβασης.", symbol: "gearshape")
                    if access.isManager {
                        if access.can(.storeDetails) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Στοιχεία καταστήματος").font(.headline)
                                field("Όνομα καταστήματος", text: $name)
                                field("Διεύθυνση καταστήματος", text: $address)
                                field("Τηλέφωνο καταστήματος", text: $phone, phone: true)
                                Button("Αποθήκευση αλλαγών") {
                                    save(.details(name: name, address: address, phone: phone))
                                }
                                .buttonStyle(StorePrimaryButtonStyle())
                                .disabled(busy || [name, address, phone].contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                            }
                            .padding(20).storeCard()
                        }
                        if access.can(.members) {
                            membersSection
                        }
                        if let feedback {
                            Text(feedback).font(.footnote).foregroundStyle(.secondary)
                        }
                        if busy { ProgressView().frame(maxWidth: .infinity) }
                    } else {
                        Text("Δεν έχεις δικαίωμα διαχείρισης αυτού του καταστήματος.")
                    }
                }
                .padding(20)
            }
            .background { StoreBackdrop() }
            .navigationTitle("Ρυθμίσεις καταστήματος")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Κλείσιμο") { dismiss() } }
            }
            .tint(StoreDesign.ink)
            .onAppear {
                name = access.name; address = access.address; phone = access.phone
            }
            .task(id: access.can(.members) ? access.roles.participants.sorted() : []) {
                if access.can(.members) { directory.load(ids: access.roles.participants.sorted()) }
            }
            .onChange(of: access.isManager) { _, allowed in
                if !allowed { dismiss() }
            }
            .sheet(isPresented: $showAddMember) { AddMembersView(storeID: access.storeID) }
            .sheet(item: $editingRole) { member in
                ManagerPermissionsView(member: member, access: access)
            }
            .confirmationDialog("Αφαίρεση μέλους;", isPresented: Binding(
                get: { removingMember != nil }, set: { if !$0 { removingMember = nil } }
            ), titleVisibility: .visible) {
                if let member = removingMember {
                    Button("Αφαίρεση από το κατάστημα", role: .destructive) { save(.removeMember(member.id)) }
                }
                Button("Ακύρωση", role: .cancel) { removingMember = nil }
            } message: {
                Text("Το μέλος θα χάσει την πρόσβαση στο κατάστημα. Τα προηγούμενα μηνύματα και οι βάρδιες διατηρούνται.")
            }
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Μέλη και ρόλοι").font(.headline)
                Spacer()
                Button { showAddMember = true } label: {
                    Image(systemName: "person.badge.plus").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Προσθήκη μέλους")
            }
            if directory.isLoading { ProgressView() }
            if let error = directory.error {
                Text(error).font(.footnote).foregroundStyle(.red)
                Button("Δοκιμή ξανά") { directory.load(ids: access.roles.participants.sorted()) }
            }
            ForEach(directory.members) { member in
                HStack(spacing: 12) {
                    UserProfileImageView(urlString: member.photoURL, size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name).font(.subheadline.weight(.semibold))
                        Text(access.roles.managers.contains(member.id) ? "Manager" : AppL10n.text("Μέλος"))
                            .font(.caption).foregroundStyle(.secondary)
                        if !member.email.isEmpty {
                            Text(member.email).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Menu {
                        Button("Ρόλος και δικαιώματα") { editingRole = member }
                        Button("Αφαίρεση από το κατάστημα", role: .destructive) { removingMember = member }
                    } label: {
                        Image(systemName: "ellipsis").frame(width: 44, height: 44)
                    }
                    .disabled(busy)
                    .accessibilityLabel("Ρόλος και δικαιώματα")
                }
            }
        }
        .padding(20).storeCard()
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, phone: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium))
            TextField(title, text: text)
                .keyboardType(phone ? .phonePad : .default)
                .storeInput()
        }
    }

    private func save(_ change: StoreAdministration.Change) {
        busy = true; feedback = nil
        StoreAdministration.update(storeID: access.storeID, change: change) { error in
            busy = false
            feedback = error?.localizedDescription ?? AppL10n.text("Αποθηκεύτηκε")
        }
    }
}

private struct ManagerPermissionsView: View {
    let member: StoreSettingsMembers.Member
    @ObservedObject var access: StoreAccessViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var manager = false
    @State private var grants: Set<StorePermission> = []
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(member.name).font(.headline)
                    Toggle("Manager", isOn: $manager)
                }
                if manager {
                    Section("Δικαιώματα manager") {
                        ForEach(StorePermission.allCases) { permission in
                            Toggle(LocalizedStringKey(permission.title), isOn: Binding(
                                get: { grants.contains(permission) },
                                set: { if $0 { grants.insert(permission) } else { grants.remove(permission) } }
                            ))
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
                Text("Πρέπει να παραμείνει τουλάχιστον ένας manager με δικαίωμα διαχείρισης μελών και ρόλων.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Ρόλος και δικαιώματα")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Ακύρωση") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Αποθήκευση") {
                        saving = true; error = nil
                        StoreAdministration.update(storeID: access.storeID, change: .manager(member.id, manager, grants)) { failure in
                            saving = false
                            if let failure { error = failure.localizedDescription } else { dismiss() }
                        }
                    }
                    .disabled(saving || !access.can(.members))
                }
            }
            .onAppear {
                manager = access.roles.managers.contains(member.id)
                grants = Set((access.roles.permissions[member.id] ?? []).compactMap(StorePermission.init(rawValue:)))
            }
            .tint(StoreDesign.ink)
        }
    }
}
