import SwiftUI

struct UnifiedTabBar: View {
    @Binding var tabBarMode: TabBarMode
    @Binding var selectedTab: Tabs
    @Binding var storeSelectedTab: STabs
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 350
    
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")
    
    var tabCount: CGFloat { tabBarMode == .root ? 2 : 3 }
    var tabWidth: CGFloat { containerWidth  / tabCount }

    var body: some View {
        ZStack(alignment: .leading) {
            backgroundCapsule
                .frame(width: containerWidth, height: 64)

            HStack(spacing: 0) {
                tabButton(0, icon: tabBarMode == .root ? "tray.full" : "newspaper")
                tabButton(1, icon: tabBarMode == .root ? "line.3.horizontal.decrease" : "captions.bubble")
                if tabBarMode == .store {
                    tabButton(2, icon: "calendar.day.timeline.left")
                }
            }
            .frame(width: containerWidth)
            
            backgroundCapsule
                .frame(width: tabWidth - 10, height: 45)
                .offset(x: getBaseOffset() + dragOffset)
                .padding(.horizontal, 5)
                .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.7), value: activeTabIndex)

        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    let velocity = value.predictedEndLocation.x
                    let index = Int(max(0, min(Int(velocity / tabWidth), Int(tabCount - 1))))
                    updateSelection(index)
                }
        )
        .padding(.bottom, 12)
    }

    private var activeTabIndex: Int {
        if tabBarMode == .root { return selectedTab == .main ? 0 : 1 }
        return storeSelectedTab == .main ? 0 : (storeSelectedTab == .messages ? 1 : 2)
    }

    private func getBaseOffset() -> CGFloat {
        CGFloat(activeTabIndex) * tabWidth
    }

    private func updateSelection(_ index: Int) {
        if tabBarMode == .root {
            selectedTab = (index == 0) ? .main : .settings
        } else {
            if index == 0 { storeSelectedTab = .main }
            else if index == 1 { storeSelectedTab = .messages }
            else { storeSelectedTab = .schedule }
        }
    }

    @ViewBuilder
    var backgroundCapsule: some View {
        if #available(iOS 26.0, *) {
            Capsule(style: .continuous).glassEffect(.clear.tint(Color.colorBar.opacity(0.5)).interactive())
        } else {
            Capsule(style: .continuous).fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    func tabButton(_ index: Int, icon: String) -> some View {
        // Επιλέγουμε το όνομα του εικονιδίου
        let iconName = getIconName(for: icon, isSelected: activeTabIndex == index)
        
        Image(systemName: iconName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(activeTabIndex == index ? mainColor : .secondary)
            .frame(width: tabWidth)
            .contentShape(Rectangle())
            .onTapGesture { updateSelection(index) }
    }

    private func getIconName(for icon: String, isSelected: Bool) -> String {
        guard isSelected else { return icon }
        
        let filledIcon = "\(icon).fill"
        
        // Ελέγχουμε αν υπάρχει το .fill σύμβολο στο system
        if let _ = UIImage(systemName: filledIcon) {
            return filledIcon
        } else {
            // Αν δεν υπάρχει, επιστρέφουμε το αρχικό (χωρίς .fill)
            return icon
        }
    }
}
