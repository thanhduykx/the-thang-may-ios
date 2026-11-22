import SwiftUI

@main
struct TheThangMayApp: App {
    @StateObject private var store = CardStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .tint(Color(hex: 0x0F766E))
        }
    }
}
