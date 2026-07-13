//
//  TabBar.swift
//  Worknity
//
//  Created by Dee Manolioudis on 6/6/25.
//

/*import SwiftUI

enum STabs: Int {
    case main = 0
    case messages = 1
    case schedule = 2
}

struct StoreTabBar: View {
    @Binding var selectedTab: STabs
    @Namespace private var animation
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")
    
    @State private var triggerSymbolAnimation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background blur layer to enhance glass feel behind the bar
            Color.clear
                .background(.ultraThinMaterial)
                .opacity(0.0001) // keeps the material active without painting
                .ignoresSafeArea()

            VStack {
                ZStack(alignment: .center) {
                    // Cylindrical glass container
                    Capsule(style: .continuous)
                        .fill(.thinMaterial)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    .linearGradient(
                                        colors: [Color.secondary.opacity(0.35), Color.secondary.opacity(0.10)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1
                                )
                        )
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.secondary.opacity(0.05))
                                .blur(radius: 16)
                        )
                        .shadow(color: .primary.opacity(0.25), radius: 20, x: 0, y: 0)
                        .frame(maxWidth: 380, minHeight: 64, maxHeight: 64)
                        .overlay(alignment: .leading) {
                            GeometryReader { geo in
                                let tabCount: CGFloat = 3
                                let tabWidth = geo.size.width / tabCount
                                let pillWidth: CGFloat = 92  // smaller fixed width so equal space around icon
                                let pillHeight: CGFloat = 50 // smaller height to match icon size better

                                // Compute the center X for the selected tab
                                let centerX: CGFloat = {
                                    switch selectedTab {
                                    case .main:
                                        return tabWidth * 0.5
                                    case .messages:
                                        return tabWidth * 1.5
                                    case .schedule:
                                        return tabWidth * 2.5
                                    }
                                }()

                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(colors: [
                                            Color.secondary.opacity(0.25),
                                            Color.secondary.opacity(0.02)
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                                            .blendMode(.overlay)
                                    )
                                    .frame(width: pillWidth, height: pillHeight)
                                    .position(x: centerX, y: geo.size.height / 2)
                                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedTab)
                            }
                        }

                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        // Main tab
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                selectedTab = .main
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: selectedTab == .main ? "newspaper.fill" : "newspaper")
                                    .ifAvailableSymbolEffect(triggerSymbolAnimation)
                                    .font(.system(size: 18, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(selectedTab == .main ? mainColor : Color.primary.opacity(1))
                                    .scaleEffect(selectedTab == .main ? 1.05 : 1.0)
                                    .opacity(selectedTab == .main ? 1.0 : 0.9)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        // Settings tab
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                selectedTab = .messages
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName:selectedTab == .messages ? "captions.bubble.fill" : "captions.bubble")
                                    .ifAvailableSymbolEffect(triggerSymbolAnimation)
                                    .font(.system(size: 18, weight: .semibold))
                                    .rotationEffect(.degrees(selectedTab == .messages ? 180 : 0))
                                    .scaleEffect(selectedTab == .messages ? 1.05 : 1.0)
                                    .foregroundStyle(selectedTab == .messages ? mainColor : Color.primary.opacity(1))
                                    .opacity(selectedTab == .messages ? 1.0 : 0.9)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                        
                        // Settings tab
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                selectedTab = .schedule
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar.day.timeline.left")
                                    .ifAvailableSymbolEffect(triggerSymbolAnimation)
                                    .font(.system(size: 18, weight: .semibold))
                                    .scaleEffect(selectedTab == .schedule ? 1.05 : 1.0)
                                    .foregroundStyle(selectedTab == .schedule ? mainColor : Color.primary.opacity(1))
                                    .opacity(selectedTab == .schedule ? 1.0 : 0.9)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                    //.padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            triggerSymbolAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                triggerSymbolAnimation = false
            }
        }
    }
}

struct StoreTabBarPreviewWrapper: View {
    @State private var selectedTab: STabs = .main

    var body: some View {
        StoreTabBar(selectedTab: $selectedTab)
    }
}

#Preview {
    StoreTabBarPreviewWrapper()
} */
