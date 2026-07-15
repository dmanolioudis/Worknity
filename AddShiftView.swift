//
//  AddShiftView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import SwiftUI

struct AddShiftView: View {
    @ObservedObject var viewModel: StoreScheduleViewModel
    var shiftToEdit: Shift? // Αν είναι nil -> Δημιουργία, αν έχει τιμή -> Επεξεργασία
    
    @Environment(\.dismiss) var dismiss
    
    // Στοιχεία 1ης Βάρδιας
    @State private var selectedEmployee: StoreMember?
    @State private var startTime1: Date = Date()
    @State private var endTime1: Date = Date().addingTimeInterval(3600 * 8)
    @State private var selectedDates: Set<DateComponents> = []
    
    // Στοιχεία Σπαστού Ωραρίου (2η Βάρδια)
    @State private var isSplitShift: Bool = false
    @State private var startTime2: Date = Date().addingTimeInterval(3600 * 4)
    @State private var endTime2: Date = Date().addingTimeInterval(3600 * 8)
    
    let mainColor = Color(hex: "#948979")
    
    // Έλεγχος αν είμαστε σε Edit Mode
    var isEditMode: Bool { shiftToEdit != nil }
    
    var body: some View {
        NavigationView {
            Form {
                // ΕΝΟΤΗΤΑ 1: ΕΠΙΛΟΓΗ ΕΡΓΑΖΟΜΕΝΟΥ
                Section(header: Text("Εργαζόμενος")) {
                    if isEditMode {
                        HStack {
                            UserProfileImageView(urlString: shiftToEdit?.employeePhotoURL, size: 30)
                            Text(shiftToEdit?.employeeName ?? "")
                                .bold()
                            Spacer()
                            Text("Επεξεργασία")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Επιλογή...", selection: $selectedEmployee) {
                            Text("Διάλεξε υπάλληλο...").tag(StoreMember?.none)
                            ForEach(viewModel.storeMembers) { member in
                                Text(member.fullName).tag(StoreMember?.some(member))
                            }
                        }
                    }
                }
                
                // ΕΝΟΤΗΤΑ 2: ΗΜΕΡΟΛΟΓΙΟ (Μόνο κατά τη δημιουργία)
                if !isEditMode {
                    Section(header: Text("Επιλογή Ημερών (Μαζικά για τον μήνα)")) {
                        MultiDatePicker("Ημέρες", selection: $selectedDates)
                            .tint(mainColor)
                    }
                }
                
                // ΕΝΟΤΗΤΑ 3: ΩΡΑΡΙΟ 1ης ΒΑΡΔΙΑΣ
                Section(header: Text(isSplitShift ? "1η Βάρδια (Πρωί)" : "Ωράριο Βάρδιας")) {
                    DatePicker("Έναρξη", selection: $startTime1, displayedComponents: .hourAndMinute)
                    DatePicker("Λήξη", selection: $endTime1, displayedComponents: .hourAndMinute)
                }
                
                // ΕΝΟΤΗΤΑ 4: ΣΠΑΣΤΟ ΩΡΑΡΙΟ (Μόνο κατά τη δημιουργία)
                if !isEditMode {
                    Section {
                        Toggle(isOn: $isSplitShift.animation()) {
                            HStack {
                                Image(systemName: "clock.arrow.2.circlepath")
                                    .foregroundColor(mainColor)
                                Text("Σπαστό Ωράριο (2η Βάρδια)")
                            }
                        }
                        .tint(mainColor)
                    }
                    
                    if isSplitShift {
                        Section(header: Text("2η Βάρδια (Απόγευμα)")) {
                            DatePicker("Έναρξη 2ης", selection: $startTime2, displayedComponents: .hourAndMinute)
                            DatePicker("Λήξη 2ης", selection: $endTime2, displayedComponents: .hourAndMinute)
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Αλλαγή Βάρδιας" : "Μαζικό Πρόγραμμα")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Ακύρωση") { dismiss() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Αποθήκευση") {
                        saveAction()
                    }
                    .bold()
                    .foregroundColor(isSaveDisabled ? .gray : mainColor)
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear {
                // Αν είμαστε σε Edit Mode, κάνουμε pre-populate τα ωράρια της βάρδιας
                if let shift = shiftToEdit {
                    startTime1 = shift.startTime
                    endTime1 = shift.endTime
                }
            }
        }
    }
    
    // Έλεγχος εγκυρότητας κουμπιού αποθήκευσης
    var isSaveDisabled: Bool {
        if isEditMode { return false }
        return selectedEmployee == nil || selectedDates.isEmpty
    }
    
    // Εκτέλεση αποθήκευσης ανάλογα με το Mode
    private func saveAction() {
        if isEditMode, let shift = shiftToEdit {
            // Ενημέρωση υπάρχουσας βάρδιας
            viewModel.updateShift(shiftID: shift.id, originalDate: shift.startTime, newStartTime: startTime1, newEndTime: endTime1)
        } else if let employee = selectedEmployee {
            // Μαζική εγγραφή νέων βαρδιών (Μονή ή Σπαστή)
            viewModel.addMassShifts(
                employee: employee,
                dates: selectedDates,
                startTime1: startTime1,
                endTime1: endTime1,
                isSplit: isSplitShift,
                startTime2: startTime2,
                endTime2: endTime2
            )
        }
        dismiss()
    }
}
