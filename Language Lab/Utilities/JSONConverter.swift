import Foundation

struct JSONConverter {
    // Define a struct that matches our JSON format
    struct WordData: Codable {
        let id: UUID
        let arabic: String
        let transliteration: String
        let translation: String
        let difficulty: String
        let category: String
    }
    
    static func convertWordsToJSON(words: [WordData], outputPath: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(words)
            try jsonData.write(to: URL(fileURLWithPath: outputPath))
            print("Successfully wrote JSON to \(outputPath)")
        } catch {
            print("Error writing JSON: \(error)")
        }
    }
    
    // Helper method to create sample words (for testing)
    static func createSampleWords() -> [WordData] {
        return [
            WordData(
                id: UUID(),
                arabic: "مرحبا",
                transliteration: "marhaban",
                translation: "hello",
                difficulty: "beginner",
                category: "greeting"
            ),
            WordData(
                id: UUID(),
                arabic: "شكرا",
                transliteration: "shukran",
                translation: "thank you",
                difficulty: "beginner",
                category: "greeting"
            ),
            WordData(
                id: UUID(),
                arabic: "كيف حالك",
                transliteration: "kayf halak",
                translation: "how are you",
                difficulty: "beginner",
                category: "greeting"
            ),
            // Add more sample words as needed
        ]
    }
} 