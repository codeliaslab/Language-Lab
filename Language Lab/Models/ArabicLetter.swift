import Foundation
import SwiftData

@Model
final class ArabicLetter {
    @Attribute(.unique) var id: UUID
    var arabic: String
    var transliteration: String
    var position: Int
    
    init(id: UUID = UUID(), arabic: String, transliteration: String, position: Int) {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.position = position
    }
}

// This class will track user progress with letters
@Model
final class LetterProgress {
    @Attribute(.unique) var id: UUID
    var letterId: UUID
    var correctAttempts: Int
    var incorrectAttempts: Int
    var lastPracticed: Date?
    
    init(id: UUID = UUID(), letterId: UUID, correctAttempts: Int = 0, incorrectAttempts: Int = 0, lastPracticed: Date? = nil) {
        self.id = id
        self.letterId = letterId
        self.correctAttempts = correctAttempts
        self.incorrectAttempts = incorrectAttempts
        self.lastPracticed = lastPracticed
    }
} 