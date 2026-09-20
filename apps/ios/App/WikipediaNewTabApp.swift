import SwiftUI

@main
struct WikipediaNewTabApp: App {
    @StateObject private var store = AppStore()

    private var colorScheme: ColorScheme? {
        switch store.settings.theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
                .onOpenURL { store.handleOpenURL($0) }
        }
    }
}
