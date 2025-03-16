import Foundation
import SwiftUI

// A simple class to store and provide Arabic words
class WordStore: ObservableObject {
    static let shared = WordStore()
    
    @Published var words: [ArabicWordItem] = []
    private var isInitializing = false
    
    // Remove initialization from init
    init() {
        // Don't initialize here - we'll do it on demand
    }
    
    func initializeWords() {
        // Skip if already initialized or in progress
        if !words.isEmpty || isInitializing {
            print("WordStore: Words already initialized or initializing, skipping")
            return
        }
        
        // Set flag to prevent concurrent initialization
        isInitializing = true
        
        // Add timing for performance tracking
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Move this to a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Create words array
            let newWords = [
                ArabicWordItem(id: UUID(), arabic: "سلام", transliteration: "salaam", translation: "peace", category: "greetings", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "مرحبا", transliteration: "marhaba", translation: "hello", category: "greetings", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "شكرا", transliteration: "shukran", translation: "thank you", category: "common", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "عفوا", transliteration: "afwan", translation: "you're welcome", category: "common", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "نعم", transliteration: "na'am", translation: "yes", category: "common", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "لا", transliteration: "la", translation: "no", category: "common", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "ماء", transliteration: "ma'", translation: "water", category: "food", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "خبز", transliteration: "khubz", translation: "bread", category: "food", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "كتاب", transliteration: "kitaab", translation: "book", category: "objects", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "قلم", transliteration: "qalam", translation: "pen", category: "objects", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "بيت", transliteration: "bayt", translation: "house", category: "places", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "مدرسة", transliteration: "madrasa", translation: "school", category: "places", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "صباح", transliteration: "sabah", translation: "morning", category: "time", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "مساء", transliteration: "masa'", translation: "evening", category: "time", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "كبير", transliteration: "kabir", translation: "big", category: "adjectives", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "صغير", transliteration: "saghir", translation: "small", category: "adjectives", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "جميل", transliteration: "jamil", translation: "beautiful", category: "adjectives", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "واحد", transliteration: "wahid", translation: "one", category: "numbers", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "اثنان", transliteration: "ithnan", translation: "two", category: "numbers", difficulty: "beginner"),
                ArabicWordItem(id: UUID(), arabic: "ثلاثة", transliteration: "thalatha", translation: "three", category: "numbers", difficulty: "beginner")
            ]
            
            // Update on main thread
            DispatchQueue.main.async {
                self.words = newWords
                self.isInitializing = false
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                print("WordStore: Initialized \(self.words.count) Arabic words in \(timeElapsed) seconds")
            }
        }
    }
    
    // Track user progress with words
    func updateWordProgress(wordId: UUID, isCorrect: Bool) {
        // In a real app, you would store this in UserDefaults or a database
        print("Updated progress for word \(wordId): \(isCorrect ? "correct" : "incorrect")")
    }
}

// A simple struct to represent an Arabic word
struct ArabicWordItem: Identifiable {
    var id: UUID
    var arabic: String
    var transliteration: String
    var translation: String
    var category: String
    var difficulty: String
} 