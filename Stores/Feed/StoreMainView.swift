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
    @State private var showCreatePost = false
    @State private var hasRestoredScroll = false
    let mainColor = StoreDesign.ink
    
    init(storeID: String, storename: String) {
        self.storeID = storeID
        self.storename = storename
        _viewModel = StateObject(wrappedValue: StoreFeedViewModel(storeID: storeID))
    }
    
    var body: some View {
        ZStack {
            StoreBackdrop()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        StorePageHeader(title: "Τα νέα της ομάδας", subtitle: "Ενημερώσεις και όσα αξίζει να μοιραστούμε.", symbol: "newspaper")

                        LazyVStack(spacing: 16) {
                        
                            if viewModel.regularPosts.isEmpty && viewModel.pinnedPosts.isEmpty {
                                StoreEmptyState(symbol: "text.bubble", title: "Ο χώρος της ομάδας", message: "Εδώ εμφανίζονται οι δημοσιεύσεις και οι ενημερώσεις του καταστήματος.")
                            }

                            // Regular posts stay in chronological order: older at the top, newest at the bottom.
                            ForEach(viewModel.regularPosts) { post in
                                PostCardView(post: post, mainColor: mainColor, viewModel: viewModel)
                                    .id(post.id)
                                    .onAppear {
                                        viewModel.markPostAsSeen(post)
                                    }
                            }

                            if !viewModel.pinnedPosts.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "pin.fill")
                                    Text("Καρφιτσωμένες δημοσιεύσεις")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(mainColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 12)

                                ForEach(viewModel.pinnedPosts) { post in
                                    PostCardView(post: post, mainColor: mainColor, viewModel: viewModel)
                                }
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("feed-bottom")
                        }
                    }
                    .padding(.bottom, 24)
                }
                .onAppear { restoreScroll(using: proxy) }
                .onChange(of: viewModel.regularPosts.count) { _, _ in
                    restoreScroll(using: proxy)
                }
            }
            
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
            if viewModel.isManager {
                Button { showCreatePost = true } label: {
                    Label("Νέα δημοσίευση", systemImage: "plus")
                }
                .buttonStyle(StorePrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .onChange(of: viewModel.isManager) { _, allowed in
            if !allowed { showCreatePost = false }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(storeID: storeID)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    private func restoreScroll(using proxy: ScrollViewProxy) {
        guard !hasRestoredScroll, !viewModel.regularPosts.isEmpty else { return }
        hasRestoredScroll = true

        DispatchQueue.main.async {
            proxy.scrollTo("feed-bottom", anchor: .bottom)

            guard let firstUnreadPostID = viewModel.initialFirstUnseenPostID else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeInOut(duration: 0.65)) {
                    proxy.scrollTo(firstUnreadPostID, anchor: .top)
                }
            }
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
        VStack(alignment: .leading, spacing: 16) {
            
            // --- 1. HEADER: Στοιχεία & Live Pin ---
            HStack(spacing: 12) {
                UserProfileImageView(urlString: post.authorProfilePic, size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName).font(.headline).foregroundColor(.primary)
                    HStack(spacing: 5) {
                        Text(post.timestamp, style: .date)
                        Text("·")
                        Text(post.timestamp, style: .time)
                    }.font(.caption).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if viewModel.isManager {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.togglePin(postID: post.id, currentPinned: post.isPinned)
                    }) {
                        Image(systemName: post.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 14))
                            .foregroundColor(post.isPinned ? mainColor : .secondary)
                            .frame(width: 44, height: 44)
                            .background(post.isPinned ? StoreDesign.softAccent : Color.clear, in: Circle())
                    }
                    .accessibilityLabel(post.isPinned ? "Ξεκαρφίτσωμα δημοσίευσης" : "Καρφίτσωμα δημοσίευσης")
                } else if post.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14))
                        .foregroundColor(mainColor)
                        .padding(8)
                        .background(StoreDesign.softAccent)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // --- 2. TEXT CONTENT ---
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }
            
            // --- 3. MEDIA CONTENT ---
            if post.mediaType != .none {
                Group {
                    switch post.mediaType {
                    case .image:
                        Button(action: { showFullScreenMedia = true }) {
                            if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                                CachedRemoteImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: 480)
                                    } else {
                                        ZStack {
                                            StoreDesign.softAccent
                                            if phase.error != nil {
                                                Label("Άνοιγμα φωτογραφίας", systemImage: "photo")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                ProgressView().tint(mainColor)
                                            }
                                        }
                                        .frame(height: 200)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .background(StoreDesign.softAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                        .accessibilityLabel("Άνοιγμα φωτογραφίας σε πλήρη οθόνη")
                        
                    case .video:
                        Button(action: { showFullScreenMedia = true }) {
                            if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                                VideoThumbnailView(videoURL: url, preservesAspectRatio: true)
                                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                        .accessibilityLabel("Αναπαραγωγή βίντεο")
                        
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
                                    Text(post.fileName ?? AppL10n.text("Αρχείο / Έγγραφο"))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text(LocalizedStringKey(isDownloadingFile ? "Φόρτωση..." : "Πατήστε για άμεση προεπισκόπηση"))
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
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            
            Rectangle().fill(StoreDesign.line).frame(height: 1)
                .padding(.horizontal, 20)
            
            // --- 4. FOOTER (Likes & Comments Icon Only) ---
            HStack(spacing: 20) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.toggleLike(postID: post.id)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasLiked ? "heart.fill" : "heart").font(.system(size: 18))
                        Text("\(post.likes.count)").font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(hasLiked ? .red : mainColor)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(hasLiked ? Color.red.opacity(0.08) : StoreDesign.softAccent, in: Capsule())
                }
                .accessibilityLabel(hasLiked ? "Αφαίρεση Μου αρέσει" : "Μου αρέσει")
                .accessibilityValue("\(post.likes.count)")

                Button(action: { showCommentsSheet = true }) {
                    Label("Σχόλια", systemImage: "bubble.left")
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: 44)
                        .foregroundColor(mainColor)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
        .storeCard(radius: 26)
        .padding(.horizontal, 20)
        
        // Sheets & FullScreenCovers
        .fullScreenCover(isPresented: $showFullScreenMedia) {
            MediaDetailView(post: post)
        }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(storeID: post.storeID, postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
               // .presentationBackground(.ultraThinMaterial)
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
