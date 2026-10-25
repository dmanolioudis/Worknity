import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NativeTabNavigationContainer(authViewModel: authViewModel)
            // The UIKit controller owns safe areas for its navigation and tab bars.
            .ignoresSafeArea()
    }
}
