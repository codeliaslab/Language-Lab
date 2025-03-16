import Foundation
import SwiftData

class LettersManager {
    static let shared = LettersManager()
    private var isInitializing = false
    
    // Initialize Arabic letters if not already in database
    func initializeLetters(modelContext: ModelContext) {
        // Skip if already initializing
        if isInitializing {
            print("LettersManager: Already initializing, skipping")
            return
        }
        
        isInitializing = true
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Move database operations to background
        Task {
            do {
                var descriptor = FetchDescriptor<ArabicLetter>()
                descriptor.fetchLimit = 1
                
                let count = try modelContext.fetchCount(descriptor)
                if count == 0 {
                    // No letters in database, add them
                    let letters = createArabicLetters()
                    
                    // Batch insert for better performance
                    for letter in letters {
                        modelContext.insert(letter)
                    }
                    
                    try modelContext.save()
                    
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("LettersManager: Successfully initialized \(letters.count) Arabic letters in \(timeElapsed) seconds")
                } else {
                    print("LettersManager: Letters already initialized, found \(count) letters")
                }
            } catch {
                print("LettersManager: Error checking for letters: \(error)")
            }
            
            isInitializing = false
        }
    }
    
    // Force reinitialize letters (for debugging)
    func forceInitializeLetters(modelContext: ModelContext) {
        do {
            // Delete all existing letters
            let descriptor = FetchDescriptor<ArabicLetter>()
            let existingLetters = try modelContext.fetch(descriptor)
            
            for letter in existingLetters {
                modelContext.delete(letter)
            }
            
            try modelContext.save()
            print("Deleted \(existingLetters.count) existing letters")
            
            // Add new letters
            let letters = createArabicLetters()
            for letter in letters {
                modelContext.insert(letter)
            }
            
            try modelContext.save()
            print("Successfully reinitialized \(letters.count) Arabic letters")
        } catch {
            print("Error reinitializing letters: \(error)")
        }
    }
    
    // Create the Arabic alphabet
    private func createArabicLetters() -> [ArabicLetter] {
        return [
            ArabicLetter(arabic: "ا", transliteration: "alif", position: 1),
            ArabicLetter(arabic: "ب", transliteration: "ba", position: 2),
            ArabicLetter(arabic: "ت", transliteration: "ta", position: 3),
            ArabicLetter(arabic: "ث", transliteration: "tha", position: 4),
            ArabicLetter(arabic: "ج", transliteration: "jeem", position: 5),
            ArabicLetter(arabic: "ح", transliteration: "haa", position: 6),
            ArabicLetter(arabic: "خ", transliteration: "khaa", position: 7),
            ArabicLetter(arabic: "د", transliteration: "dal", position: 8),
            ArabicLetter(arabic: "ذ", transliteration: "dhal", position: 9),
            ArabicLetter(arabic: "ر", transliteration: "ra", position: 10),
            ArabicLetter(arabic: "ز", transliteration: "zay", position: 11),
            ArabicLetter(arabic: "س", transliteration: "seen", position: 12),
            ArabicLetter(arabic: "ش", transliteration: "sheen", position: 13),
            ArabicLetter(arabic: "ص", transliteration: "saad", position: 14),
            ArabicLetter(arabic: "ض", transliteration: "daad", position: 15),
            ArabicLetter(arabic: "ط", transliteration: "taa", position: 16),
            ArabicLetter(arabic: "ظ", transliteration: "thaa", position: 17),
            ArabicLetter(arabic: "ع", transliteration: "ayn", position: 18),
            ArabicLetter(arabic: "غ", transliteration: "ghayn", position: 19),
            ArabicLetter(arabic: "ف", transliteration: "fa", position: 20),
            ArabicLetter(arabic: "ق", transliteration: "qaf", position: 21),
            ArabicLetter(arabic: "ك", transliteration: "kaf", position: 22),
            ArabicLetter(arabic: "ل", transliteration: "lam", position: 23),
            ArabicLetter(arabic: "م", transliteration: "meem", position: 24),
            ArabicLetter(arabic: "ن", transliteration: "noon", position: 25),
            ArabicLetter(arabic: "ه", transliteration: "ha", position: 26),
            ArabicLetter(arabic: "و", transliteration: "waw", position: 27),
            ArabicLetter(arabic: "ي", transliteration: "ya", position: 28)
        ]
    }
    
    // Update letter progress
    func updateLetterProgress(modelContext: ModelContext, letterId: UUID, isCorrect: Bool) {
        // Find existing progress or create new
        let descriptor = FetchDescriptor<LetterProgress>(predicate: #Predicate { $0.letterId == letterId })
        
        do {
            let existingProgress = try modelContext.fetch(descriptor)
            let progress: LetterProgress
            
            if let existing = existingProgress.first {
                progress = existing
            } else {
                progress = LetterProgress(letterId: letterId)
                modelContext.insert(progress)
            }
            
            // Update progress
            if isCorrect {
                progress.correctAttempts += 1
            } else {
                progress.incorrectAttempts += 1
            }
            progress.lastPracticed = Date()
            
            try modelContext.save()
        } catch {
            print("Error updating letter progress: \(error)")
        }
    }
} 