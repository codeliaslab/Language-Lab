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
        DispatchQueue.global(qos: .userInitiated).async {
            // Create words array with examples for each letter position
            var newWords: [ArabicWordItem] = [
                // ا (alif)
                ArabicWordItem(id: UUID(), arabic: "أكل", translation: "to eat", transliteration: "akala", category: "verbs", letterPositions: ["ا": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "سأل", translation: "to ask", transliteration: "sa'ala", category: "verbs", letterPositions: ["ا": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "قرأ", translation: "to read", transliteration: "qara'a", category: "verbs", letterPositions: ["ا": "end"]),
                
                // ب (ba)
                ArabicWordItem(id: UUID(), arabic: "بيت", translation: "house", transliteration: "bayt", category: "places", letterPositions: ["ب": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "حبيبي", translation: "my beloved", transliteration: "habibi", category: "expressions", letterPositions: ["ب": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "باب", translation: "door", transliteration: "bab", category: "objects", letterPositions: ["ب": "end"]),
                
                // ت (ta)
                ArabicWordItem(id: UUID(), arabic: "تفاح", translation: "apple", transliteration: "tuffah", category: "food", letterPositions: ["ت": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مكتب", translation: "office", transliteration: "maktab", category: "places", letterPositions: ["ت": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "بنت", translation: "girl", transliteration: "bint", category: "people", letterPositions: ["ت": "end"]),
                
                // ث (tha)
                ArabicWordItem(id: UUID(), arabic: "ثلاثة", translation: "three", transliteration: "thalatha", category: "numbers", letterPositions: ["ث": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مثل", translation: "like/as", transliteration: "mithl", category: "common", letterPositions: ["ث": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "حديث", translation: "modern", transliteration: "hadith", category: "adjectives", letterPositions: ["ث": "end"]),
                
                // ج (jim)
                ArabicWordItem(id: UUID(), arabic: "جميل", translation: "beautiful", transliteration: "jamil", category: "adjectives", letterPositions: ["ج": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مجلس", translation: "council", transliteration: "majlis", category: "places", letterPositions: ["ج": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "ثلج", translation: "snow", transliteration: "thalj", category: "nature", letterPositions: ["ج": "end"]),
                
                // ح (ha)
                ArabicWordItem(id: UUID(), arabic: "حب", translation: "love", transliteration: "hub", category: "emotions", letterPositions: ["ح": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "محمد", translation: "Muhammad", transliteration: "muhammad", category: "names", letterPositions: ["ح": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "مفتاح", translation: "key", transliteration: "miftah", category: "objects", letterPositions: ["ح": "end"]),
                
                // خ (kha)
                ArabicWordItem(id: UUID(), arabic: "خبز", translation: "bread", transliteration: "khubz", category: "food", letterPositions: ["خ": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مخرج", translation: "exit", transliteration: "makhraj", category: "places", letterPositions: ["خ": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "مطبخ", translation: "kitchen", transliteration: "matbakh", category: "places", letterPositions: ["خ": "end"]),
                
                // د (dal)
                ArabicWordItem(id: UUID(), arabic: "درس", translation: "lesson", transliteration: "dars", category: "education", letterPositions: ["د": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مدرسة", translation: "school", transliteration: "madrasa", category: "places", letterPositions: ["د": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "جديد", translation: "new", transliteration: "jadid", category: "adjectives", letterPositions: ["د": "end"]),
                
                // ذ (dhal)
                ArabicWordItem(id: UUID(), arabic: "ذهب", translation: "gold", transliteration: "dhahab", category: "objects", letterPositions: ["ذ": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "إذا", translation: "if", transliteration: "idha", category: "common", letterPositions: ["ذ": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "لذيذ", translation: "delicious", transliteration: "ladhidh", category: "adjectives", letterPositions: ["ذ": "end"]),
                
                // ر (ra)
                ArabicWordItem(id: UUID(), arabic: "رجل", translation: "man", transliteration: "rajul", category: "people", letterPositions: ["ر": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مرحبا", translation: "hello", transliteration: "marhaban", category: "greetings", letterPositions: ["ر": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "كبير", translation: "big", transliteration: "kabir", category: "adjectives", letterPositions: ["ر": "end"]),
                
                // ز (zay)
                ArabicWordItem(id: UUID(), arabic: "زيت", translation: "oil", transliteration: "zayt", category: "food", letterPositions: ["ز": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مزرعة", translation: "farm", transliteration: "mazra'a", category: "places", letterPositions: ["ز": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "خبز", translation: "bread", transliteration: "khubz", category: "food", letterPositions: ["ز": "end"]),
                
                // س (sin)
                ArabicWordItem(id: UUID(), arabic: "سلام", translation: "peace", transliteration: "salam", category: "greetings", letterPositions: ["س": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مدرسة", translation: "school", transliteration: "madrasa", category: "places", letterPositions: ["س": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "درس", translation: "lesson", transliteration: "dars", category: "education", letterPositions: ["س": "end"]),
                
                // ش (shin)
                ArabicWordItem(id: UUID(), arabic: "شمس", translation: "sun", transliteration: "shams", category: "nature", letterPositions: ["ش": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مشروب", translation: "drink", transliteration: "mashrub", category: "food", letterPositions: ["ش": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "مش", translation: "not", transliteration: "mish", category: "common", letterPositions: ["ش": "end"]),
                
                // ص (sad)
                ArabicWordItem(id: UUID(), arabic: "صباح", translation: "morning", transliteration: "sabah", category: "time", letterPositions: ["ص": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "فصل", translation: "season", transliteration: "fasl", category: "time", letterPositions: ["ص": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "رخيص", translation: "cheap", transliteration: "rakhis", category: "adjectives", letterPositions: ["ص": "end"]),
                
                // ض (dad)
                ArabicWordItem(id: UUID(), arabic: "ضوء", translation: "light", transliteration: "daw'", category: "nature", letterPositions: ["ض": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "أخضر", translation: "green", transliteration: "akhdar", category: "colors", letterPositions: ["ض": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "بيض", translation: "eggs", transliteration: "bayd", category: "food", letterPositions: ["ض": "end"]),
                
                // ط (ta)
                ArabicWordItem(id: UUID(), arabic: "طالب", translation: "student", transliteration: "talib", category: "people", letterPositions: ["ط": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مطار", translation: "airport", transliteration: "matar", category: "places", letterPositions: ["ط": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "خط", translation: "line", transliteration: "khat", category: "objects", letterPositions: ["ط": "end"]),
                
                // ظ (za)
                ArabicWordItem(id: UUID(), arabic: "ظهر", translation: "noon", transliteration: "zuhr", category: "time", letterPositions: ["ظ": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "نظام", translation: "system", transliteration: "nizam", category: "common", letterPositions: ["ظ": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "حفظ", translation: "to save", transliteration: "hifz", category: "verbs", letterPositions: ["ظ": "end"]),
                
                // ع (ayn)
                ArabicWordItem(id: UUID(), arabic: "عين", translation: "eye", transliteration: "ayn", category: "body", letterPositions: ["ع": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "معلم", translation: "teacher", transliteration: "mu'allim", category: "people", letterPositions: ["ع": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "سريع", translation: "fast", transliteration: "sari'", category: "adjectives", letterPositions: ["ع": "end"]),
                
                // غ (ghayn)
                ArabicWordItem(id: UUID(), arabic: "غرفة", translation: "room", transliteration: "ghurfa", category: "places", letterPositions: ["غ": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "لغة", translation: "language", transliteration: "lugha", category: "education", letterPositions: ["غ": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "فارغ", translation: "empty", transliteration: "farigh", category: "adjectives", letterPositions: ["غ": "end"]),
                
                // ف (fa)
                ArabicWordItem(id: UUID(), arabic: "فم", translation: "mouth", transliteration: "fam", category: "body", letterPositions: ["ف": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مفتاح", translation: "key", transliteration: "miftah", category: "objects", letterPositions: ["ف": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "صيف", translation: "summer", transliteration: "sayf", category: "time", letterPositions: ["ف": "end"]),
                
                // ق (qaf)
                ArabicWordItem(id: UUID(), arabic: "قلب", translation: "heart", transliteration: "qalb", category: "body", letterPositions: ["ق": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مقهى", translation: "cafe", transliteration: "maqha", category: "places", letterPositions: ["ق": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "سوق", translation: "market", transliteration: "suq", category: "places", letterPositions: ["ق": "end"]),
                
                // ك (kaf)
                ArabicWordItem(id: UUID(), arabic: "كتاب", translation: "book", transliteration: "kitab", category: "objects", letterPositions: ["ك": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "مكتب", translation: "office", transliteration: "maktab", category: "places", letterPositions: ["ك": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "سمك", translation: "fish", transliteration: "samak", category: "food", letterPositions: ["ك": "end"]),
                
                // ل (lam)
                ArabicWordItem(id: UUID(), arabic: "ليل", translation: "night", transliteration: "layl", category: "time", letterPositions: ["ل": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "قلم", translation: "pen", transliteration: "qalam", category: "objects", letterPositions: ["ل": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "جمل", translation: "camel", transliteration: "jamal", category: "animals", letterPositions: ["ل": "end"]),
                
                // م (mim)
                ArabicWordItem(id: UUID(), arabic: "ماء", translation: "water", transliteration: "ma'", category: "nature", letterPositions: ["م": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "شمس", translation: "sun", transliteration: "shams", category: "nature", letterPositions: ["م": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "قلم", translation: "pen", transliteration: "qalam", category: "objects", letterPositions: ["م": "end"]),
                
                // ن (nun)
                ArabicWordItem(id: UUID(), arabic: "نار", translation: "fire", transliteration: "nar", category: "nature", letterPositions: ["ن": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "بنت", translation: "girl", transliteration: "bint", category: "people", letterPositions: ["ن": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "عين", translation: "eye", transliteration: "ayn", category: "body", letterPositions: ["ن": "end"]),
                
                // ه (ha)
                ArabicWordItem(id: UUID(), arabic: "هنا", translation: "here", transliteration: "huna", category: "common", letterPositions: ["ه": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "نهر", translation: "river", transliteration: "nahr", category: "nature", letterPositions: ["ه": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "فواكه", translation: "fruits", transliteration: "fawakeh", category: "food", letterPositions: ["ه": "end"]),
                
                // و (waw)
                ArabicWordItem(id: UUID(), arabic: "ولد", translation: "boy", transliteration: "walad", category: "people", letterPositions: ["و": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "لون", translation: "color", transliteration: "lawn", category: "common", letterPositions: ["و": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "حلو", translation: "sweet", transliteration: "hulw", category: "adjectives", letterPositions: ["و": "end"]),
                
                // ي (ya)
                ArabicWordItem(id: UUID(), arabic: "يد", translation: "hand", transliteration: "yad", category: "body", letterPositions: ["ي": "beginning"]),
                ArabicWordItem(id: UUID(), arabic: "بيت", translation: "house", transliteration: "bayt", category: "places", letterPositions: ["ي": "middle"]),
                ArabicWordItem(id: UUID(), arabic: "كرسي", translation: "chair", transliteration: "kursi", category: "objects", letterPositions: ["ي": "end"])
            ]
            
            // Add more common words
            newWords.append(contentsOf: [
                ArabicWordItem(id: UUID(), arabic: "شكرا", translation: "thank you", transliteration: "shukran", category: "greetings"),
                ArabicWordItem(id: UUID(), arabic: "عفوا", translation: "you're welcome", transliteration: "afwan", category: "greetings"),
                ArabicWordItem(id: UUID(), arabic: "صباح الخير", translation: "good morning", transliteration: "sabah al-khayr", category: "greetings"),
                ArabicWordItem(id: UUID(), arabic: "مساء الخير", translation: "good evening", transliteration: "masa' al-khayr", category: "greetings"),
                ArabicWordItem(id: UUID(), arabic: "مع السلامة", translation: "goodbye", transliteration: "ma'a as-salama", category: "greetings"),
                ArabicWordItem(id: UUID(), arabic: "أنا", translation: "I", transliteration: "ana", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "أنت", translation: "you (m)", transliteration: "anta", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "أنتِ", translation: "you (f)", transliteration: "anti", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "هو", translation: "he", transliteration: "huwa", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "هي", translation: "she", transliteration: "hiya", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "نحن", translation: "we", transliteration: "nahnu", category: "pronouns"),
                ArabicWordItem(id: UUID(), arabic: "واحد", translation: "one", transliteration: "wahid", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "اثنان", translation: "two", transliteration: "ithnan", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "أربعة", translation: "four", transliteration: "arba'a", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "خمسة", translation: "five", transliteration: "khamsa", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "ستة", translation: "six", transliteration: "sitta", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "سبعة", translation: "seven", transliteration: "sab'a", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "ثمانية", translation: "eight", transliteration: "thamaniya", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "تسعة", translation: "nine", transliteration: "tis'a", category: "numbers"),
                ArabicWordItem(id: UUID(), arabic: "عشرة", translation: "ten", transliteration: "ashara", category: "numbers")
            ])
            
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
    var translation: String
    var transliteration: String
    var category: String
    var letterPositions: [String: String] = [:]
} 