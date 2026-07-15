//
//  StoreMainView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//

//
//  StoreMainView.swift
//  Worknity
//

import SwiftUI
import FirebaseAuth
import QuickLook


struct StoreMainView: View {
    let storeID: String
    let storename: String
    
    @StateObject private var viewModel: StoreFeedViewModel
    @State private var showCreatePost = false // <-- Το State για το νέο Sheet
    
    let mainColor = Color(hex: "#948979")
    
    init(storeID: String, storename: String) {
        self.storeID = storeID
        self.storename = storename
        _viewModel = StateObject(wrappedValue: StoreFeedViewModel(storeID: storeID))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#DFD0B8").opacity(0.1).ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        
                        // 1. Pinned Posts
                        if !viewModel.pinnedPosts.isEmpty {
                            ForEach(viewModel.pinnedPosts) { post in
                                PostCardView(post: post, mainColor: mainColor, viewModel: viewModel)
                            }
                            Divider()
                                .background(mainColor.opacity(0.3))
                                .padding(.horizontal, 30)
                        }
                        
                        // 2. Regular Posts
                        ForEach(viewModel.regularPosts) { post in
                            PostCardView(post: post, mainColor: mainColor, viewModel: viewModel)
                                .id(post.id)
                                .onAppear {
                                    viewModel.lastSeenPostID = post.id
                                }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 80)
                }
                .onAppear {
                    let lastID = viewModel.lastSeenPostID
                    if !lastID.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastID, anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // Το "+ Button" εμφανίζεται ΜΟΝΟ στους Managers
            if viewModel.isManager {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreatePost = true // <-- Ανοίγει το Sheet
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(mainColor)
                                .clipShape(Circle())
                                .shadow(color: mainColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            // Το νέο UI για ανέβασμα post
            CreatePostView(storeID: storeID)
        }
    }
}

// MARK: - Post Card
//
//  PostCardView.swift
//  Worknity
//

struct PostCardView: View {
    let post: StorePost
    let mainColor: Color
    @ObservedObject var viewModel: StoreFeedViewModel
    
    // States προβολής
    @State private var showFullScreenMedia = false
    @State private var showCommentsSheet = false
    
    // States για Direct Document Preview
    @State private var isDownloadingFile = false
    @State private var localDocURL: URL? = nil
    @State private var showDocPreview = false
    
    var hasLiked: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return post.likes.contains(uid)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // --- 1. HEADER: Στοιχεία & Live Pin ---
            HStack(spacing: 12) {
                UserProfileImageView(urlString: post.authorProfilePic, size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName).font(.headline).foregroundColor(.primary)
                    Text(post.timestamp, style: .time).font(.caption).foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.isManager {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.togglePin(postID: post.id, currentPinned: post.isPinned)
                    }) {
                        Image(systemName: post.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 14))
                            .foregroundColor(post.isPinned ? .orange : .secondary)
                            .padding(8)
                            .background(post.isPinned ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                } else if post.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            // --- 2. TEXT CONTENT ---
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            
            // --- 3. MEDIA CONTENT ---
            if post.mediaType != .none {
                Group {
                    switch post.mediaType {
                    case .image:
                        Button(action: { showFullScreenMedia = true }) {
                            if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        ZStack {
                                            Rectangle().fill(Color.gray.opacity(0.1))
                                            ProgressView().tint(mainColor)
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .clipped()
                            }
                        }
                        
                    case .video:
                        Button(action: { showFullScreenMedia = true }) {
                            if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                                VideoThumbnailView(videoURL: url)
                            }
                        }
                        
                    case .file:
                        // ΑΜΕΣΟ ΑΝΟΙΓΜΑ: Πατώντας το έγγραφο κατεβαίνει και προβάλλεται αμέσως
                        Button(action: downloadAndOpenDocument) {
                            HStack(spacing: 12) {
                                if isDownloadingFile {
                                    ProgressView().tint(mainColor)
                                        .frame(width: 30, height: 30)
                                } else {
                                    Image(systemName: "doc.richtext.fill")
                                        .font(.title)
                                        .foregroundColor(mainColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.fileName ?? "Αρχείο / Έγγραφο")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text(isDownloadingFile ? "Φόρτωση..." : "Πατήστε για άμεση προεπισκόπηση")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "eye.fill")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(mainColor.opacity(0.08))
                            .cornerRadius(14)
                        }
                        .disabled(isDownloadingFile)
                        
                    case .none:
                        EmptyView()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // --- 4. FOOTER (Likes & Comments Icon Only) ---
            HStack(spacing: 24) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.toggleLike(postID: post.id)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasLiked ? "heart.fill" : "heart").font(.system(size: 18))
                        Text("\(post.likes.count)").font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(hasLiked ? .red : mainColor)
                }
                
                Button(action: { showCommentsSheet = true }) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18))
                        .foregroundColor(mainColor)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.white.opacity(0.2)))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        
        // Sheets & FullScreenCovers
        .fullScreenCover(isPresented: $showFullScreenMedia) {
            MediaDetailView(post: post)
        }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(storeID: post.storeID, postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // Native QuickLook sheet για άμεση προβολή εγγράφων από την κάρτα
        .sheet(isPresented: $showDocPreview) {
            if let url = localDocURL {
                QuickLookPreviewWrapper(url: url)
            }
        }
    }
    
    // Λειτουργία κατεβάσματος εγγράφου direct από την κάρτα
    private func downloadAndOpenDocument() {
        guard let urlStr = post.mediaURL, let url = URL(string: urlStr) else { return }
        isDownloadingFile = true
        
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            defer { DispatchQueue.main.async { isDownloadingFile = false } }
            
            guard let localURL = localURL else { return }
            let filename = post.fileName ?? url.lastPathComponent
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.copyItem(at: localURL, to: tempURL)
            
            DispatchQueue.main.async {
                self.localDocURL = tempURL
                self.showDocPreview = true
            }
        }.resume()
    }
}
