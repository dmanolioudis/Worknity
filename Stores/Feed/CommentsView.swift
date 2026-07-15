//
//  CommentsView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  CommentsView.swift
//  Worknity
//

import SwiftUI


struct CommentsView: View {
    @StateObject private var viewModel: CommentsViewModel
    @State private var newCommentText: String = ""
    @Environment(\.dismiss) var dismiss
    
    let mainColor = Color(hex: "#948979")
    
    init(storeID: String, postID: String) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(storeID: storeID, postID: postID))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Λίστα Σχολίων
                if viewModel.isLoading && viewModel.comments.isEmpty {
                    Spacer()
                    ProgressView().tint(mainColor)
                    Spacer()
                } else if viewModel.comments.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Δεν υπάρχουν σχόλια ακόμη")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Γίνετε ο πρώτος που θα σχολιάσει!")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.comments) { comment in
                                    CommentRowView(comment: comment, mainColor: mainColor)
                                        .id(comment.id)
                                }
                            }
                            .padding()
                        }
                        // Αυτόματο scroll στο τελευταίο σχόλιο όταν ανοίγει ή προστίθεται νέο
                        .onChange(of: viewModel.comments.count) { _ in
                            if let lastComment = viewModel.comments.last {
                                withAnimation { proxy.scrollTo(lastComment.id, anchor: .bottom) }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Μπάρα Εισαγωγής Σχολίου (Chat Bar)
                HStack(spacing: 12) {
                    TextField("Γράψτε ένα σχόλιο...", text: $newCommentText, axis: .vertical)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...4)
                    
                    Button(action: sendComment) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : mainColor)
                            .padding(10)
                            .background(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : mainColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Σχόλια")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
    
    private func sendComment() {
        viewModel.addComment(content: newCommentText) {
            newCommentText = "" // Καθαρισμός textfield
        }
    }
}

// Υποστηρικτικό View για τη γραμμή του κάθε σχολίου
struct CommentRowView: View {
    let comment: PostComment
    let mainColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            UserProfileImageView(urlString: comment.authorProfilePic, size: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(comment.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.03))
            .cornerRadius(16, corners: [.topRight, .bottomLeft, .bottomRight])
            // Το custom corner radius extension βοηθάει να μοιάζει με chat bubble, αν δεν το έχεις βάλει, απλά άφησε .cornerRadius(16)
        }
    }
}

// Extension για στρογγυλεμένες γωνίες επιλεκτικά (προαιρετικό)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
