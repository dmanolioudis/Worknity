//
//  StoreScheduleView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import SwiftUI
import FirebaseAuth

// MARK: - Helper για το Scroll Progress (Απαραίτητο για το Animation)
struct ScrollProgressKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    
    // Εδώ κρατάμε την πρόοδο του σκρολ (0.0 έως 1.0) για να ελέγχουμε την επικεφαλίδα
    @State private var scrollProgress: CGFloat = 0
    
    let mainColor = Color(hex: "#948979")
    let calendarHeight: CGFloat = 330 // Το σταθερό ύψος του DatePicker
    
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
    
    // Εμφάνιση της ημερομηνίας: 0% όταν φαίνεται το ημερολόγιο, 100% όταν εξαφανιστεί (πάνω από το 50% του scroll)
    var headerTextOpacity: Double {
        let p = max(0, (scrollProgress - 0.5) * 2)
        return Double(p)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                
                // 1. ΤΟ ΗΜΕΡΟΛΟΓΙΟ ΜΕ ΤΟ ANIMATION (Collapsing Header)
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .named("scroll")).minY
                    let isScrollingUp = minY < 0
                    
                    // Υπολογισμοί για το πόσο συρρικνώνεται
                    let shrinkAmount = isScrollingUp ? -minY : 0
                    let currentHeight = isScrollingUp ? max(0, calendarHeight - shrinkAmount) : calendarHeight
                    let progress = min(1, max(0, shrinkAmount / calendarHeight))
                    
                    // Κρατάμε το ημερολόγιο οπτικά κολλημένο στην κορυφή της οθόνης
                    let offset: CGFloat = isScrollingUp ? shrinkAmount : 0
                    
                    ZStack(alignment: .top) {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(mainColor)
                            .padding(.horizontal)
                            .background(Color(UIColor.systemBackground))
                            // Το DatePicker έχει πάντα σταθερό ύψος εσωτερικά για να μην «σπάει» το layout του
                            .frame(height: calendarHeight, alignment: .top)
                            .opacity(Double(1.0 - (progress * 1.5))) // Ξεθωριάζει ομαλά όσο μικραίνει
                    }
                    // Το εξωτερικό container συρρικνώνεται και κόβει (clip) το ημερολόγιο
                    .frame(height: currentHeight, alignment: .top)
                    .clipped()
                    .offset(y: offset)
                    
                    // Στέλνουμε την πρόοδο στο View για να τη διαβάσει η επικεφαλίδα
                    .preference(key: ScrollProgressKey.self, value: progress)
                }
                .frame(height: calendarHeight) // Διατηρεί τον απαραίτητο χώρο στο layout
                .zIndex(0)
                
                // 2. STICKY HEADER & ΛΙΣΤΑ ΚΑΡΤΩΝ
                // Οι κάρτες πλέον ακολουθούν ακριβώς από κάτω το ημερολόγιο
                Section(header: stickyHeader) {
                    shiftsList
                }
                .zIndex(1)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollProgressKey.self) { progress in
            self.scrollProgress = progress
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
            // Η ημερομηνία εμφανίζεται ΜΟΝΟ όταν το ημερολόγιο κλείνει
            Text(selectedDate.formatted(.dateTime.day().month().year()))
                .font(.headline)
                .foregroundColor(.primary)
                .opacity(headerTextOpacity)
            
            Spacer()
            
            // Το κουμπί προσθήκης μένει πάντα ορατό
            if viewModel.isManager {
                Button(action: { activeSheet = .add }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(mainColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        // Σταθερό background για να μην φαίνονται οι κάρτες από πίσω όταν κολλήσει
        .background(Color(UIColor.systemBackground))
        // Εμφάνιση σκιάς μόνο όταν η επικεφαλίδα καρφωθεί πάνω
        .shadow(color: .black.opacity(scrollProgress >= 0.95 ? 0.05 : 0), radius: 3, y: 3)
    }
    
    private var shiftsList: some View {
        VStack {
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
                .padding(.top, 10)
            }
        }
        .padding(.bottom, 150) // Ασφάλεια για το TabBar
    }
}

// MARK: - Εμφάνιση της Βάρδιας (Card)
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
                        Image(systemName: "pencil")
                            .foregroundColor(Color(hex: "#948979"))
                            .padding(8)
                            .background(Color(hex: "#948979").opacity(0.1))
                            .clipShape(Circle())
                    }
                    
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
