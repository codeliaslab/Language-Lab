import Foundation
import SwiftData

@Model
final class ArabicWord {
    var id: UUID
    var arabic: String
    var transliteration: String
    var translation: String
    var difficultyRaw: String
    var categoryRaw: String
    
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .beginner }
        set { difficultyRaw = newValue.rawValue }
    }
    
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .common }
        set { categoryRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), arabic: String, transliteration: String, translation: String, difficulty: Difficulty, category: Category) {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.translation = translation
        self.difficultyRaw = difficulty.rawValue
        self.categoryRaw = category.rawValue
    }
    
    enum Difficulty: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced
    }
    
    enum Category: String, Codable, CaseIterable {
        case greeting
        case food
        case family
        case numbers
        case colors
        case animals
        case common
        case phrases
        // Add more categories as needed
    }
} 