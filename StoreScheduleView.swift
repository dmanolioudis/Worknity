//
//  StoreScheduleView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import SwiftUI
import FirebaseAuth


// Enum για τον έλεχχο του Sheet (Προσθήκη ή Επεξεργασία)
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

struct StoreScheduleView: View {
    let storeID: String
    @StateObject private var viewModel: StoreScheduleViewModel
    @State private var selectedDate: Date = Date()
    @State private var activeSheet: ScheduleSheetType? // Έλεγχος Sheet
    
    let mainColor = Color(hex: "#948979")
    
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
        // Όλο το περιεχόμενο μπαίνει σε ένα ScrollView ώστε να συμπτύσσεται το ημερολόγιο κατά το σκρολάρισμα
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                
                // 1. Το Ημερολόγιο (θα ανεβαίνει προς τα πάνω κατά το scroll)
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(mainColor)
                    .padding(.horizontal)
                    .background(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                
                // 2. Η οριζόντια μπάρα πληροφοριών
                HStack {
                    Text("Βάρδιες: \(selectedDate.formatted(.dateTime.day().month()))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    if viewModel.isManager {
                        Button(action: { activeSheet = .add }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(mainColor)
                        }
                    }
                }
                .padding()
                
                // 3. Η Λίστα με τις Βάρδιες/Εργαζόμενους
                if filteredShifts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text(viewModel.isManager ? "Δεν υπάρχουν βάρδιες για το κατάστημα." : "Δεν έχεις βάρδια αυτήν την ημέρα.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    // Προσθήκη padding και στο empty state για ασφάλεια με το tab bar
                    .padding(.bottom, 100)
                    
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
                    .padding(.horizontal)
                    // ΚΡΙΣΙΜΟ: 100pt κενό στο τέλος της λίστας για να βγαίνει ο τελευταίος εργαζόμενος ΠΑΝΩ από το TabBar
                    .padding(.bottom, 100)
                }
            }
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
}

struct ShiftCardView: View {
    var shift: Shift
    var isManager: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            UserProfileImageView(urlString: shift.employeePhotoURL, size: 45)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(shift.employeeName)
                    .font(.headline)
                Text(shift.timeRangeString)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#948979"))
                    .bold()
            }
            
            Spacer()
            
            if isManager {
                HStack(spacing: 12) {
                    // ΚΟΥΜΠΙ ΕΠΕΞΕΡΓΑΣΙΑΣ
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(hex: "#948979"))
                            .padding(8)
                            .background(Color(hex: "#948979").opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // ΚΟΥΜΠΙ ΔΙΑΓΡΑΦΗΣ
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.8))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
