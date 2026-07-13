import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Tabs = .main
    @State private var storeSelectedTab: STabs = .main
    @State private var tabBarMode: TabBarMode = .root
    @State private var showOverlay: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .main:
                    MainView(
                        selectedTab: $selectedTab,
                        storeSelectedTab: $storeSelectedTab,
                        showOverlay: $showOverlay,
                        tabBarMode: $tabBarMode
                    )
                    .tabBarMode(.root)
                case .settings:
                    SettingsView(selectedTab: $selectedTab, tabBarMode: $tabBarMode)
                        .tabBarMode(.root)
                }
            }
        }
        .onPreferenceChange(TabBarModePreferenceKey.self) { newMode in
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8)) {
                tabBarMode = newMode
            }
        }
        .safeAreaInset(edge: .bottom) {
            if tabBarMode != .hidden {
                UnifiedTabBar(
                    tabBarMode: $tabBarMode,
                    selectedTab: $selectedTab,
                    storeSelectedTab: $storeSelectedTab
                )
            }
        }
    }
}
