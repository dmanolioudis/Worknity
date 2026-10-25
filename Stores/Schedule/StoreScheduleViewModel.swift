//
//  StoreScheduleViewModel.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class StoreScheduleViewModel: ObservableObject {
    @Published var shifts: [Shift] = []
    @Published var storeMembers: [StoreMember] = []
    @Published var isManager: Bool = false
    
    private var db = Firestore.firestore()
    private var shiftsListener: ListenerRegistration?
    private var roleListener: ListenerRegistration?
    private var membersGeneration = UUID()
    
    let storeID: String
    
    init(storeID: String) {
        self.storeID = storeID
        checkIfManagerAndFetchMembers()
        listenToShifts()
    }
    
    deinit {
        shiftsListener?.remove()
        roleListener?.remove()
    }
    
    private func checkIfManagerAndFetchMembers() {
        roleListener?.remove()
        roleListener = db.collection("stores").document(storeID).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            let roles = StoreAdministration.roles(from: error == nil ? snapshot?.data() ?? [:] : [:])
            DispatchQueue.main.async {
                self.isManager = roles.can(.schedule, uid: Auth.auth().currentUser?.uid ?? "")
                self.fetchMembersData(uids: roles.participants.sorted())
            }
        }
    }

    private func fetchMembersData(uids: [String]) {
        let generation = UUID()
        membersGeneration = generation
        guard !uids.isEmpty else { storeMembers = []; return }
        let group = DispatchGroup()
        var members: [StoreMember] = []
        for uid in uids {
            group.enter()
            db.collection("users").document(uid).getDocument { snapshot, _ in
                DispatchQueue.main.async {
                    defer { group.leave() }
                    guard let data = snapshot?.data() else { return }
                    members.append(StoreMember(id: uid, fullName: data["fullName"] as? String ?? AppL10n.text("Μέλος"), photoURL: data["photoURL"] as? String))
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self, self.membersGeneration == generation else { return }
            self.storeMembers = members.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }
    }

    private func listenToShifts() {
        shiftsListener = db.collection("stores").document(storeID).collection("shifts")
            .order(by: "startTime")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                let fetchedShifts = documents.compactMap { doc -> Shift? in
                    let data = doc.data()
                    guard let employeeID = data["employeeID"] as? String,
                          let employeeName = data["employeeName"] as? String,
                          let startTimestamp = data["startTime"] as? Timestamp,
                          let endTimestamp = data["endTime"] as? Timestamp else { return nil }
                    
                    let photoURL = data["employeePhotoURL"] as? String
                    
                    return Shift(
                        id: doc.documentID,
                        employeeID: employeeID,
                        employeeName: employeeName,
                        employeePhotoURL: photoURL,
                        startTime: startTimestamp.dateValue(),
                        endTime: endTimestamp.dateValue()
                    )
                }
                
                DispatchQueue.main.async {
                    self.shifts = fetchedShifts
                }
            }
    }
    
    // ΜΑΖΙΚΗ ΕΓΓΡΑΦΗ (Υποστηρίζει και Μονή και Σπαστή Βάρδια)
    func addMassShifts(employee: StoreMember, dates: Set<DateComponents>, startTime1: Date, endTime1: Date, isSplit: Bool, startTime2: Date, endTime2: Date) {
        guard isManager else { return }
        let batch = db.batch()
        let calendar = Calendar.current
        
        let start1Comp = calendar.dateComponents([.hour, .minute], from: startTime1)
        let end1Comp = calendar.dateComponents([.hour, .minute], from: endTime1)
        let start2Comp = calendar.dateComponents([.hour, .minute], from: startTime2)
        let end2Comp = calendar.dateComponents([.hour, .minute], from: endTime2)
        
        for dateComp in dates {
            guard let baseDate = calendar.date(from: dateComp) else { continue }
            
            // 1η Βάρδια
            if let finalStart1 = calendar.date(bySettingHour: start1Comp.hour ?? 0, minute: start1Comp.minute ?? 0, second: 0, of: baseDate),
               let finalEnd1 = calendar.date(bySettingHour: end1Comp.hour ?? 0, minute: end1Comp.minute ?? 0, second: 0, of: baseDate) {
                
                let docRef1 = db.collection("stores").document(storeID).collection("shifts").document()
                let shiftData1: [String: Any] = [
                    "employeeID": employee.id,
                    "employeeName": employee.fullName,
                    "employeePhotoURL": employee.photoURL ?? "",
                    "startTime": Timestamp(date: finalStart1),
                    "endTime": Timestamp(date: finalEnd1)
                ]
                batch.setData(shiftData1, forDocument: docRef1)
            }
            
            // 2η Βάρδια (Αν ορίστηκε σπαστό)
            if isSplit {
                if let finalStart2 = calendar.date(bySettingHour: start2Comp.hour ?? 0, minute: start2Comp.minute ?? 0, second: 0, of: baseDate),
                   let finalEnd2 = calendar.date(bySettingHour: end2Comp.hour ?? 0, minute: end2Comp.minute ?? 0, second: 0, of: baseDate) {
                    
                    let docRef2 = db.collection("stores").document(storeID).collection("shifts").document()
                    let shiftData2: [String: Any] = [
                        "employeeID": employee.id,
                        "employeeName": employee.fullName,
                        "employeePhotoURL": employee.photoURL ?? "",
                        "startTime": Timestamp(date: finalStart2),
                        "endTime": Timestamp(date: finalEnd2)
                    ]
                    batch.setData(shiftData2, forDocument: docRef2)
                }
            }
        }
        
        batch.commit { error in
            if let error = error { print("Error writing batch shifts: \(error)") }
        }
    }
    
    // ΕΠΕΞΕΡΓΑΣΙΑ ΥΠΑΡΧΟΥΣΑΣ ΒΑΡΔΙΑΣ
    func updateShift(shiftID: String, originalDate: Date, newStartTime: Date, newEndTime: Date) {
        guard isManager else { return }
        let calendar = Calendar.current
        
        // Κρατάμε το έτος/μήνα/μέρα της αρχικής βάρδιας
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: originalDate)
        let startComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        
        var mergedStart = dayComponents
        mergedStart.hour = startComponents.hour
        mergedStart.minute = startComponents.minute
        
        var mergedEnd = dayComponents
        mergedEnd.hour = endComponents.hour
        mergedEnd.minute = endComponents.minute
        
        guard let finalStart = calendar.date(from: mergedStart),
              let finalEnd = calendar.date(from: mergedEnd) else { return }
        
        db.collection("stores").document(storeID).collection("shifts").document(shiftID).updateData([
            "startTime": Timestamp(date: finalStart),
            "endTime": Timestamp(date: finalEnd)
        ])
    }
    
    func deleteShift(shiftID: String) {
        guard isManager else { return }
        db.collection("stores").document(storeID).collection("shifts").document(shiftID).delete()
    }
}
