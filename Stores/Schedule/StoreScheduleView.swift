//
//  StoreScheduleView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


//
//  StoreScheduleView.swift
//  Worknity
//

import SwiftUI
import FirebaseAuth

// MARK: - Helper για το Scroll Offset
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Enum για το Sheet
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
    @State private var activeSheet: ScheduleSheetType?
    
    // UI Constants
    @State private var scrollOffset: CGFloat = 0
    private let calendarHeight: CGFloat = 350
    let mainColor = Color(hex: "#948979")
    
    init(storeID: String) {
        self.storeID = storeID
        _viewModel = StateObject(wrappedValue: StoreScheduleViewModel(storeID: storeID))
    }
    
    // Υπολογισμός progress (0 = πάνω, 1 = κρυμμένο)
    private var progress: CGFloat {
        // Όταν το offset είναι 0, progress = 0. Όταν πάει -250, progress = 1
        let maxScroll: CGFloat = 250
        return min(max(0, -scrollOffset / maxScroll), 1)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 1. Το ScrollView
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // Το Ημερολόγιο
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(mainColor)
                        .padding(.horizontal)
                        .frame(height: calendarHeight)
                        // ΕΔΩ ΓΙΝΕΤΑΙ ΤΟ ΜΑΓΙΚΟ:
                        .scaleEffect(1 - (progress * 0.2)) // Μικραίνει
                        .opacity(1 - (progress * 2))       // Σβήνει
                        .offset(y: -progress * 50)         // Ανεβαίνει
                    
                    // Η Λίστα
                    shiftsList
                        .padding(.top, 20)
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: proxy.frame(in: .named("ScrollSpace")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "ScrollSpace")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                self.scrollOffset = value
            }
            
            // 2. Το Sticky Header (Εμφανίζεται πάνω από το ScrollView)
            StickyHeaderView(selectedDate: selectedDate, viewModel: viewModel, action: { activeSheet = .add })
                .opacity(progress > 0.5 ? 1 : 0) // Εμφανίζεται σταδιακά
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .add: AddShiftView(viewModel: viewModel, shiftToEdit: nil)
            case .edit(let shift): AddShiftView(viewModel: viewModel, shiftToEdit: shift)
            }
        }
    }
    
    // MARK: - Logic & Subviews
    var filteredShifts: [Shift] {
        let dailyShifts = viewModel.shifts.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
        return viewModel.isManager ? dailyShifts : dailyShifts.filter { $0.employeeID == Auth.auth().currentUser?.uid }
    }
    
    private var shiftsList: some View {
        LazyVStack(spacing: 12) {
            if filteredShifts.isEmpty {
                Text("Δεν υπάρχουν βάρδιες για αυτή την ημέρα.")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                ForEach(filteredShifts) { shift in
                    ShiftCardView(shift: shift, isManager: viewModel.isManager, onEdit: {
                        activeSheet = .edit(shift)
                    }, onDelete: {
                        viewModel.deleteShift(shiftID: shift.id)
                    })
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 150)
    }
}

// MARK: - Sticky Header
struct StickyHeaderView: View {
    let selectedDate: Date
    let viewModel: StoreScheduleViewModel
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(selectedDate.formatted(.dateTime.day().month().year()))
                .font(.headline)
            Spacer()
            if viewModel.isManager {
                Button(action: action) {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(Color(hex: "#948979"))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Shift Card
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
                    Button(action: onEdit) {
                        Image(systemName: "pencil").foregroundColor(Color(hex: "#948979")).padding(8).background(Color(hex: "#948979").opacity(0.1)).clipShape(Circle())
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash").foregroundColor(.red.opacity(0.8)).padding(8).background(Color.red.opacity(0.1)).clipShape(Circle())
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
