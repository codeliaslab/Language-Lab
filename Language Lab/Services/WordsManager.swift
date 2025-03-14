import Foundation
import SwiftData

class WordsManager {
    static let shared = WordsManager()
    
    // Import words from JSON file
    func importWordsFromJSON(modelContext: ModelContext) throws {
        guard let url = Bundle.main.url(forResource: "arabic_words", withExtension: "json") else {
            print("JSON file not found - arabic_words.json")
            // Create a placeholder file if needed
            createPlaceholderWordsFile()
            throw NSError(domain: "WordsManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "JSON file not found"])
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // Define a struct that matches our JSON format
            struct WordData: Codable {
                let id: UUID
                let arabic: String
                let transliteration: String
                let translation: String
                let difficulty: String
                let category: String
            }
            
            let wordDataArray = try decoder.decode([WordData].self, from: data)
            
            // Convert to ArabicWord objects and save to SwiftData
            for wordData in wordDataArray {
                let difficulty = ArabicWord.Difficulty(rawValue: wordData.difficulty) ?? .beginner
                let category = ArabicWord.Category(rawValue: wordData.category) ?? .common
                
                let word = ArabicWord(
                    id: wordData.id,
                    arabic: wordData.arabic,
                    transliteration: wordData.transliteration,
                    translation: wordData.translation,
                    difficulty: difficulty,
                    category: category
                )
                
                modelContext.insert(word)
            }
            
            try modelContext.save()
            print("Successfully imported \(wordDataArray.count) words")
        } catch {
            print("Error importing words: \(error)")
            throw error
        }
    }
    
    // Helper method to create a placeholder JSON file
    private func createPlaceholderWordsFile() {
        // This is just for development - in production you'd want to include the actual file
        print("Creating placeholder words file would go here")
        // In a real app, you might create a file in the Documents directory
    }
    
    // Helper method to check if words are already imported
    func hasWords(modelContext: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<ArabicWord>()
        descriptor.fetchLimit = 1
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            print("Error checking for words: \(error)")
            return false
        }
    }
} 