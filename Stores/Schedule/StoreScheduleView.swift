//
//  StoreScheduleView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import SwiftUI
import FirebaseAuth

// MARK: - Enum για τον έλεγχο του Sheet
enum ScheduleSheetType: Identifiable {
    case add
    case edit(Shift)
    
    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let shift): return "edit-\(shift.id)"
        }
    }
}

// MARK: - Κεντρική Οθόνη Προγράμματος
struct StoreScheduleView: View {
    let storeID: String
    @StateObject private var viewModel: StoreScheduleViewModel
    @State private var selectedDate: Date = Date()
    @State private var activeSheet: ScheduleSheetType?
    
    let mainColor = StoreDesign.ink

    init(storeID: String) {
        self.storeID = storeID
        _viewModel = StateObject(wrappedValue: StoreScheduleViewModel(storeID: storeID))
    }
    
    var filteredShifts: [Shift] {
        let dailyShifts = viewModel.shifts.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
        
        if viewModel.isManager {
            return dailyShifts
        } else {
            guard let currentUID = Auth.auth().currentUser?.uid else { return [] }
            return dailyShifts.filter { $0.employeeID == currentUID }
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                StorePageHeader(title: "Πρόγραμμα", subtitle: "Η ημέρα σου, οργανωμένη.", symbol: "calendar")
                
                // Let the native calendar determine its full height, including six-week months.
                DatePicker("Επιλογή ημερομηνίας", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(mainColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .storeCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Section(header: stickyHeader) {
                    shiftsList
                }
                .zIndex(1)
            }
        }
        .background { StoreBackdrop() }
        .tint(mainColor)
        .onChange(of: viewModel.isManager) { _, allowed in
            if !allowed { activeSheet = nil }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .add:
                AddShiftView(viewModel: viewModel, shiftToEdit: nil)
            case .edit(let shift):
                AddShiftView(viewModel: viewModel, shiftToEdit: shift)
            }
        }
    }
    
    // MARK: - Components
    
    private var stickyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Βάρδιες ημέρας")
                    .font(.headline)
                Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityAddTraits(.isHeader)

            Spacer()
            
            // Το κουμπί προσθήκης μένει πάντα ορατό
            if viewModel.isManager {
                Button(action: { activeSheet = .add }) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(StoreDesign.actionLabel)
                        .frame(width: 44, height: 44)
                        .background(StoreDesign.actionFill, in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Προσθήκη βάρδιας")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        // A plain backing keeps the pinned title legible without a divider or shadow.
        .background(StoreDesign.canvas)
    }
    
    private var shiftsList: some View {
        VStack {
            if filteredShifts.isEmpty {
                StoreEmptyState(
                    symbol: "calendar.badge.checkmark",
                    title: "Χωρίς βάρδιες",
                    message: viewModel.isManager ? "Δεν υπάρχουν βάρδιες για το κατάστημα αυτήν την ημέρα." : "Δεν έχεις βάρδια αυτήν την ημέρα."
                )
                .padding(.top, 8)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredShifts) { shift in
                        ShiftCardView(shift: shift, isManager: viewModel.isManager, onEdit: {
                            activeSheet = .edit(shift)
                        }, onDelete: {
                            viewModel.deleteShift(shiftID: shift.id)
                        })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Εμφάνιση της Βάρδιας (Card)
struct ShiftCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var shift: Shift
    var isManager: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                UserProfileImageView(urlString: shift.employeePhotoURL, size: 40)
                Text(shift.employeeName)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            Rectangle().fill(StoreDesign.line).frame(height: 1)

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 8))
            layout {
                Label(shift.timeRangeString, systemImage: "clock")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(StoreDesign.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }

                if isManager {
                    HStack(spacing: 6) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundStyle(StoreDesign.ink)
                                .frame(width: 44, height: 44)
                                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Επεξεργασία βάρδιας")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .frame(width: 44, height: 44)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Διαγραφή βάρδιας")
                    }
                }
            }
        }
        .padding(16)
        .storeCard()
    }
}
