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
    
    let storeID: String
    
    init(storeID: String) {
        self.storeID = storeID
        checkIfManagerAndFetchMembers()
        listenToShifts()
    }
    
    deinit {
        shiftsListener?.remove()
    }
    
    private func checkIfManagerAndFetchMembers() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("stores").document(storeID).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            
            let managerUID = data["manager"] as? String ?? ""
            DispatchQueue.main.async {
                self.isManager = (currentUID == managerUID)
            }
            
            var participantUIDs = data["participants"] as? [String] ?? []
            if !participantUIDs.contains(managerUID) && !managerUID.isEmpty {
                participantUIDs.append(managerUID)
            }
            
            self.fetchMembersData(uids: participantUIDs)
        }
    }
    
    private func fetchMembersData(uids: [String]) {
        guard !uids.isEmpty else { return }
        let chunkedUIDs = Array(uids.prefix(10))
        
        db.collection("users").whereField("uid", in: chunkedUIDs).getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents else { return }
            
            let members = documents.compactMap { doc -> StoreMember? in
                let data = doc.data()
                let uid = doc.documentID
                let name = data["fullName"] as? String ?? "Άγνωστος"
                let photo = data["photoURL"] as? String
                return StoreMember(id: uid, fullName: name, photoURL: photo)
            }
            
            DispatchQueue.main.async {
                self.storeMembers = members
            }
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
        db.collection("stores").document(storeID).collection("shifts").document(shiftID).delete()
    }
}
