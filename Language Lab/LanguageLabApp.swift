import SwiftUI
import SwiftData

struct LanguageLabApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ArabicWord.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Make sure data is initialized when app starts
                    LetterStore.shared.initializeLetters()
                    WordStore.shared.initializeWords()
                }
        }
        .modelContainer(sharedModelContainer)
    }
} 