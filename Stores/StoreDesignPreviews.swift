#if DEBUG
import SwiftUI

/// Local fixtures only: these previews do not start Firebase listeners or write data.
private struct StoreDesignPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StorePageHeader(title: "Πρόγραμμα", subtitle: "Η ημέρα σου, οργανωμένη.", symbol: "calendar")
                ShiftCardView(
                    shift: Shift(id: "preview", employeeID: "preview", employeeName: "Αλεξάνδρα Παπαδοπούλου", employeePhotoURL: nil, startTime: .now, endTime: .now.addingTimeInterval(8 * 3600)),
                    isManager: true,
                    onEdit: {},
                    onDelete: {}
                )
                .padding(.horizontal, 20)
                CommentRowView(
                    comment: PostComment(id: "preview-comment", data: ["authorName": "Μαρία", "content": "Τέλεια, ευχαριστώ για την ενημέρωση!"]),
                    mainColor: StoreDesign.ink
                )
                .padding(.horizontal, 20)
                HStack {
                    Spacer(minLength: 40)
                    Text("Καλημέρα ομάδα! Τα λέμε στη βάρδια ☀️")
                        .padding(16)
                        .foregroundStyle(.primary)
                        .background { StoreBubbleSurface(outgoing: true) }
                }
                .padding(.horizontal, 20)
                Button {} label: {
                    Label("Νέα δημοσίευση", systemImage: "plus")
                }
                .buttonStyle(StorePrimaryButtonStyle())
            }
            .padding(.bottom, 24)
        }
        .background { StoreBackdrop() }
    }
}

#Preview("Store design · Light") {
    StoreDesignPreview().preferredColorScheme(.light)
}

#Preview("Store design · Dark") {
    StoreDesignPreview().preferredColorScheme(.dark)
}

#Preview("Store design · Large text") {
    StoreDesignPreview().environment(\.dynamicTypeSize, .accessibility3)
}
// Reduce Transparency is read-only in EnvironmentValues. Verify that appearance
// using the simulator's Accessibility > Display & Text Size setting instead.
#endif
