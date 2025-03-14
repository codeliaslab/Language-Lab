import SwiftUI
import SwiftData

struct LanguageLabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ArabicWord.self, isUndoEnabled: true)
    }
} 