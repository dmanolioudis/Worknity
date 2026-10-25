import SwiftUI
import UIKit

/// A native UIKit tab bar that swaps its destinations when a store is opened.
/// Each destination has a navigation controller, so UIKit owns the edge-swipe pop.
struct NativeTabNavigationContainer: UIViewControllerRepresentable {
    @ObservedObject private var preferences = AppPreferences.shared
    let authViewModel: AuthViewModel

    func makeUIViewController(context: Context) -> UITabBarController {
        context.coordinator.makeTabController()
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = preferences.appearance.interfaceStyle
        context.coordinator.refreshLocalizedTitles()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(authViewModel: authViewModel)
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate, UINavigationControllerDelegate {
        private let authViewModel: AuthViewModel
        private let tabController = UITabBarController()
        private var isShowingStore = false
        private var storeTabs: [UINavigationController] = []
        private var rootMainNavigationController: UINavigationController?
        private var settingsNavigationController: UINavigationController?
        private weak var interactivePopNavigationController: UINavigationController?
        private var hasSwappedTabsDuringPop = false

        init(authViewModel: AuthViewModel) {
            self.authViewModel = authViewModel
        }

        func makeTabController() -> UITabBarController {
            tabController.delegate = self
            tabController.tabBar.tintColor = UIColor(Color(hex: "#948979"))
            tabController.view.backgroundColor = .systemBackground
            rootMainNavigationController = makeMainNavigationController()
            settingsNavigationController = makeSettingsNavigationController()
            installRootTabs(animated: false)
            return tabController
        }

        private func makeMainNavigationController() -> UINavigationController {
            let host = UIHostingController(rootView: MainView { [weak self] store in
                self?.showStoreTabs(for: store)
            }.appPreferences())
            let navigationController = UINavigationController(rootViewController: host)
            navigationController.delegate = self
            navigationController.interactivePopGestureRecognizer?.addTarget(
                self,
                action: #selector(handleInteractivePop(_:))
            )
            navigationController.view.backgroundColor = .systemBackground
            navigationController.setNavigationBarHidden(true, animated: false)
            host.view.backgroundColor = .systemBackground
            navigationController.tabBarItem = UITabBarItem(
                title: AppL10n.text("Καταστήματα"),
                image: UIImage(systemName: "tray.full"),
                selectedImage: UIImage(systemName: "tray.full.fill")
            )
            return navigationController
        }

        private func makeSettingsNavigationController() -> UINavigationController {
            let host = UIHostingController(
                rootView: SettingsView().environmentObject(authViewModel).appPreferences()
            )
            let navigationController = UINavigationController(rootViewController: host)
            navigationController.delegate = self
            navigationController.view.backgroundColor = .systemBackground
            host.view.backgroundColor = .systemBackground
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.tabBarItem = UITabBarItem(
                title: AppL10n.text("Ρυθμίσεις"),
                image: UIImage(systemName: "line.3.horizontal.decrease"),
                selectedImage: UIImage(systemName: "line.3.horizontal.decrease.circle.fill")
            )
            return navigationController
        }

        private func installRootTabs(animated: Bool) {
            guard let main = rootMainNavigationController,
                  let settings = settingsNavigationController else { return }

            isShowingStore = false
            if main.viewControllers.count > 1 {
                main.popToRootViewController(animated: false)
            }
            main.tabBarItem = rootTabBarItems()[0]
            replaceTabs([main, settings], selectedIndex: 0, animated: animated)
            storeTabs.removeAll()
        }

        private func showStoreTabs(for store: Store) {
            guard let main = tabController.selectedViewController as? UINavigationController else { return }

            isShowingStore = true
            hasSwappedTabsDuringPop = false
            rootMainNavigationController = main
            main.tabBarItem = tabBarItem(for: .main)
            storeTabs = [
                main,
                makeStoreNavigationController(for: store, tab: .messages),
                makeStoreNavigationController(for: store, tab: .schedule)
            ]
            replaceTabs(storeTabs, selectedIndex: 0, animated: true)

            let feed = UIHostingController(
                rootView: StoreTabContentView(storeID: store.id, storename: store.name, tab: .main).appPreferences()
            )
            feed.view.backgroundColor = .systemBackground
            main.setNavigationBarHidden(false, animated: true)
            main.pushViewController(feed, animated: true)
        }

        private func makeStoreNavigationController(for store: Store, tab: STabs) -> UINavigationController {
            let navigationController = makeMainNavigationController()
            let content = UIHostingController(
                rootView: StoreTabContentView(
                    storeID: store.id,
                    storename: store.name,
                    tab: tab,
                    onOpenChat: { [weak navigationController] conversation in
                        guard let navigationController,
                              navigationController.transitionCoordinator == nil else { return }
                        let chat = UIHostingController(
                            rootView: StoreConversationView(storeID: store.id, conversation: conversation)
                                .tint(StoreDesign.ink)
                                .appPreferences()
                        )
                        chat.title = AppL10n.text("Ομαδική συνομιλία")
                        chat.navigationItem.largeTitleDisplayMode = .never
                        chat.hidesBottomBarWhenPushed = true
                        chat.view.backgroundColor = .systemBackground
                        navigationController.pushViewController(chat, animated: true)
                    }
                ).appPreferences()
            )
            content.view.backgroundColor = .systemBackground
            navigationController.setNavigationBarHidden(false, animated: false)
            navigationController.pushViewController(content, animated: false)
            navigationController.tabBarItem = tabBarItem(for: tab)
            return navigationController
        }

        private func tabBarItem(for tab: STabs) -> UITabBarItem {
            switch tab {
            case .main:
                UITabBarItem(title: AppL10n.text("Νέα"), image: UIImage(systemName: "newspaper"), selectedImage: UIImage(systemName: "newspaper.fill"))
            case .messages:
                UITabBarItem(title: AppL10n.text("Μηνύματα"), image: UIImage(systemName: "captions.bubble"), selectedImage: UIImage(systemName: "captions.bubble.fill"))
            case .schedule:
                UITabBarItem(title: AppL10n.text("Πρόγραμμα"), image: UIImage(systemName: "calendar.day.timeline.left"), selectedImage: UIImage(systemName: "calendar.day.timeline.left"))
            }
        }

        func tabBarController(
            _ tabBarController: UITabBarController,
            shouldSelect viewController: UIViewController
        ) -> Bool {
            // UIKit can pop a navigation controller to its root when its active
            // tab is tapped again. Store tabs keep MainView as that hidden root,
            // so block only the re-selection while the store is open.
            if isShowingStore, viewController === tabBarController.selectedViewController {
                return false
            }
            return true
        }

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            guard isShowingStore, viewController === navigationController.viewControllers.first else { return }
            rootMainNavigationController = navigationController
            // The root tabs were already shown at 66% of the interactive pop.
            // Reinstall them silently to avoid a delayed second spring bounce.
            installRootTabs(animated: !hasSwappedTabsDuringPop)
            interactivePopNavigationController = nil
            hasSwappedTabsDuringPop = false
        }

        func navigationController(
            _ navigationController: UINavigationController,
            willShow viewController: UIViewController,
            animated: Bool
        ) {
            guard isShowingStore, viewController === navigationController.viewControllers.first else { return }

            // The interactive pop already supplies the animation. A second nav-bar
            // animation here fights it and causes the content to jump.
            navigationController.setNavigationBarHidden(true, animated: false)
            prepareTabBarForInteractivePop()
            interactivePopNavigationController = navigationController
            hasSwappedTabsDuringPop = false
            navigationController.transitionCoordinator?.notifyWhenInteractionChanges { [weak self, weak navigationController] context in
                guard let self, context.isCancelled, let navigationController else { return }
                navigationController.setNavigationBarHidden(false, animated: false)
                self.restoreTabBarAfterCancelledPop()
                self.restoreStoreTabs(afterCancelledPopIn: navigationController)
            }
        }

        @objc private func handleInteractivePop(_ gesture: UIGestureRecognizer) {
            guard isShowingStore,
                  !hasSwappedTabsDuringPop,
                  let navigationController = interactivePopNavigationController,
                  let panGesture = gesture as? UIPanGestureRecognizer,
                  let settings = settingsNavigationController
            else { return }

            let width = navigationController.view.bounds.width
            guard width > 0 else { return }

            let translation = panGesture.translation(in: navigationController.view).x
            let progress = max(0, translation / width)
            let velocity = panGesture.velocity(in: navigationController.view).x
            let isFastForwardSwipe = velocity > 850 && translation > 18
            guard progress >= 0.66 || isFastForwardSwipe else { return }

            hasSwappedTabsDuringPop = true
            rootMainNavigationController = navigationController
            navigationController.tabBarItem = rootTabBarItems()[0]
            replaceTabs([navigationController, settings], selectedIndex: 0, animated: true)
        }

        private func restoreStoreTabs(afterCancelledPopIn navigationController: UINavigationController) {
            guard hasSwappedTabsDuringPop else { return }

            restoreStoreTabItems()
            let selectedIndex = storeTabs.firstIndex(where: { $0 === navigationController }) ?? 0
            replaceTabs(storeTabs, selectedIndex: selectedIndex, animated: true)
            hasSwappedTabsDuringPop = false
        }

        private func restoreStoreTabItems() {
            guard storeTabs.count == 3 else { return }
            storeTabs[0].tabBarItem = tabBarItem(for: .main)
            storeTabs[1].tabBarItem = tabBarItem(for: .messages)
            storeTabs[2].tabBarItem = tabBarItem(for: .schedule)
        }

        private func prepareTabBarForInteractivePop() {
            let tabBar = tabController.tabBar
            tabBar.layer.removeAllAnimations()
            UIView.animate(
                withDuration: 0.12,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseOut, .allowUserInteraction]
            ) {
                tabBar.transform = CGAffineTransform(scaleX: 0.965, y: 0.965)
                tabBar.alpha = 0.88
            }
        }

        private func restoreTabBarAfterCancelledPop() {
            let tabBar = tabController.tabBar
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.4,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                tabBar.transform = .identity
                tabBar.alpha = 1
            }
        }

        private func replaceTabs(
            _ controllers: [UIViewController],
            selectedIndex: Int,
            animated: Bool
        ) {
            guard animated else {
                tabController.setViewControllers(controllers, animated: false)
                tabController.selectedIndex = selectedIndex
                return
            }

            let tabBar = tabController.tabBar
            tabBar.layer.removeAllAnimations()
            tabBar.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            tabBar.alpha = 0.72

            tabController.setViewControllers(controllers, animated: false)
            tabController.selectedIndex = selectedIndex
            tabController.view.layoutIfNeeded()

            UIView.animate(
                withDuration: 0.36,
                delay: 0,
                usingSpringWithDamping: 0.64,
                initialSpringVelocity: 0.7,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                tabBar.transform = .identity
                tabBar.alpha = 1
            }
        }

        func refreshLocalizedTitles() {
            if isShowingStore {
                restoreStoreTabItems()
            } else {
                rootMainNavigationController?.tabBarItem.title = AppL10n.text("Καταστήματα")
                settingsNavigationController?.tabBarItem.title = AppL10n.text("Ρυθμίσεις")
            }
        }

        private func rootTabBarItems() -> [UITabBarItem] {
            [
                UITabBarItem(
                    title: AppL10n.text("Καταστήματα"),
                    image: UIImage(systemName: "tray.full"),
                    selectedImage: UIImage(systemName: "tray.full.fill")
                ),
                UITabBarItem(
                    title: AppL10n.text("Ρυθμίσεις"),
                    image: UIImage(systemName: "line.3.horizontal.decrease"),
                    selectedImage: UIImage(systemName: "line.3.horizontal.decrease.circle.fill")
                )
            ]
        }
    }
}
