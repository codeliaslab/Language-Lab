import SwiftUI
import SwiftData

@main
struct LanguageLabApp: App {
    @State private var isInitialized = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ArabicWord.self,
            ArabicLetter.self,
            LetterProgress.self
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
    
    init() {
        // Start initialization in init
        print("App starting initialization")
        // We'll initialize data in SplashScreen instead
    }
    
    var body: some Scene {
        WindowGroup {
            if !isInitialized {
                SplashScreen {
                    // This closure is called when initialization is complete
                    withAnimation(.easeIn(duration: 0.6)) {
                        isInitialized = true
                    }
                }
            } else {
                ContentView(skipInitialization: true)
            }
        }
        .modelContainer(sharedModelContainer)
    }
} 