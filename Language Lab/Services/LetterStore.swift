import Foundation
import SwiftUI

// A simple class to store and provide Arabic letters
class LetterStore: ObservableObject {
    static let shared = LetterStore()
    
    @Published var letters: [ArabicLetterItem] = []
    
    init() {
        // Initialize with all Arabic letters
        initializeLetters()
    }
    
    func initializeLetters() {
        letters = [
            ArabicLetterItem(id: UUID(), arabic: "ا", transliteration: "alif", position: 1),
            ArabicLetterItem(id: UUID(), arabic: "ب", transliteration: "ba", position: 2),
            ArabicLetterItem(id: UUID(), arabic: "ت", transliteration: "ta", position: 3),
            ArabicLetterItem(id: UUID(), arabic: "ث", transliteration: "tha", position: 4),
            ArabicLetterItem(id: UUID(), arabic: "ج", transliteration: "jeem", position: 5),
            ArabicLetterItem(id: UUID(), arabic: "ح", transliteration: "haa", position: 6),
            ArabicLetterItem(id: UUID(), arabic: "خ", transliteration: "khaa", position: 7),
            ArabicLetterItem(id: UUID(), arabic: "د", transliteration: "dal", position: 8),
            ArabicLetterItem(id: UUID(), arabic: "ذ", transliteration: "dhal", position: 9),
            ArabicLetterItem(id: UUID(), arabic: "ر", transliteration: "ra", position: 10),
            ArabicLetterItem(id: UUID(), arabic: "ز", transliteration: "zay", position: 11),
            ArabicLetterItem(id: UUID(), arabic: "س", transliteration: "seen", position: 12),
            ArabicLetterItem(id: UUID(), arabic: "ش", transliteration: "sheen", position: 13),
            ArabicLetterItem(id: UUID(), arabic: "ص", transliteration: "saad", position: 14),
            ArabicLetterItem(id: UUID(), arabic: "ض", transliteration: "daad", position: 15),
            ArabicLetterItem(id: UUID(), arabic: "ط", transliteration: "taa", position: 16),
            ArabicLetterItem(id: UUID(), arabic: "ظ", transliteration: "thaa", position: 17),
            ArabicLetterItem(id: UUID(), arabic: "ع", transliteration: "ayn", position: 18),
            ArabicLetterItem(id: UUID(), arabic: "غ", transliteration: "ghayn", position: 19),
            ArabicLetterItem(id: UUID(), arabic: "ف", transliteration: "fa", position: 20),
            ArabicLetterItem(id: UUID(), arabic: "ق", transliteration: "qaf", position: 21),
            ArabicLetterItem(id: UUID(), arabic: "ك", transliteration: "kaf", position: 22),
            ArabicLetterItem(id: UUID(), arabic: "ل", transliteration: "lam", position: 23),
            ArabicLetterItem(id: UUID(), arabic: "م", transliteration: "meem", position: 24),
            ArabicLetterItem(id: UUID(), arabic: "ن", transliteration: "noon", position: 25),
            ArabicLetterItem(id: UUID(), arabic: "ه", transliteration: "ha", position: 26),
            ArabicLetterItem(id: UUID(), arabic: "و", transliteration: "waw", position: 27),
            ArabicLetterItem(id: UUID(), arabic: "ي", transliteration: "ya", position: 28)
        ]
        
        print("Initialized \(letters.count) Arabic letters in LetterStore")
    }
    
    // Track user progress with letters
    func updateLetterProgress(letterId: UUID, isCorrect: Bool) {
        // In a real app, you would store this in UserDefaults or a database
        print("Updated progress for letter \(letterId): \(isCorrect ? "correct" : "incorrect")")
    }
}

// A simple struct to represent an Arabic letter
struct ArabicLetterItem: Identifiable {
    var id: UUID
    var arabic: String
    var transliteration: String
    var position: Int
} 