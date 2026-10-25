import SwiftUI

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .system: "Σύμφωνα με το κινητό"
            case .light: "Φωτεινή"
            case .dark: "Σκοτεινή"
            }
        }
        var colorScheme: ColorScheme? {
            switch self { case .system: nil; case .light: .light; case .dark: .dark }
        }
        var interfaceStyle: UIUserInterfaceStyle {
            switch self { case .system: .unspecified; case .light: .light; case .dark: .dark }
        }
    }

    enum Language: String, CaseIterable, Identifiable {
        case system, el, en
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .system: "Σύμφωνα με το κινητό"
            case .el: "Ελληνικά"
            case .en: "English"
            }
        }
        var code: String {
            if self != .system { return rawValue }
            return Locale.preferredLanguages.first(where: { $0.hasPrefix("el") || $0.hasPrefix("en") })
                .map { $0.hasPrefix("el") ? "el" : "en" } ?? "en"
        }
    }

    @Published var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "app.appearance") }
    }
    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app.language") }
    }
    var locale: Locale { Locale(identifier: language.code) }

    private init() {
        appearance = Appearance(rawValue: UserDefaults.standard.string(forKey: "app.appearance") ?? "") ?? .system
        language = Language(rawValue: UserDefaults.standard.string(forKey: "app.language") ?? "") ?? .system
    }

    func reset() {
        appearance = .system
        language = .system
    }
}

enum AppL10n {
    static func text(_ key: String) -> String {
        let code = AppPreferences.shared.language.code
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

private struct AppPreferencesModifier: ViewModifier {
    @ObservedObject private var preferences = AppPreferences.shared
    func body(content: Content) -> some View {
        content
            .environment(\.locale, preferences.locale)
            .preferredColorScheme(preferences.appearance.colorScheme)
    }
}

extension View {
    func appPreferences() -> some View { modifier(AppPreferencesModifier()) }
}
