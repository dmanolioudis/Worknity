//
//  TabBarMode.swift
//  Worknity
//
//  Created by Dee Manolioudis on 7/2/26.
//


import SwiftUI

enum TabBarMode: Equatable {
    case root       // normal TabBar
    case store      // StoreTabBar
    case hidden     // nothing
}

struct TabBarModePreferenceKey: PreferenceKey {
    static var defaultValue: TabBarMode = .root

    static func reduce(value: inout TabBarMode, nextValue: () -> TabBarMode) {
        value = nextValue()
    }
}

extension View {
    func tabBarMode(_ mode: TabBarMode) -> some View {
        preference(key: TabBarModePreferenceKey.self, value: mode)
    }
}
