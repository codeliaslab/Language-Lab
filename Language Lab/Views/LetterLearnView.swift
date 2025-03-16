import SwiftUI
import AVFoundation

struct LetterLearnView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var letterStore = LetterStore.shared
    @StateObject private var wordStore = WordStore.shared
    @State private var selectedLetter: ArabicLetterItem?
    @State private var isShowingDetail = false
    @State private var currentVoiceIndex = 0
    
    // Voice options - using more reliable identifiers
    let voices = ["ar-SA", "ar-EG", "ar-001"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if letterStore.letters.isEmpty {
                    loadingView
                } else {
                    lettersGridView
                }
            }
            .navigationTitle("Arabic Letters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $isShowingDetail) {
                if let letter = selectedLetter {
                    LetterDetailView(
                        letter: letter,
                        voices: voices,
                        currentVoiceIndex: $currentVoiceIndex,
                        wordStore: wordStore
                    )
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading Arabic letters...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var lettersGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
            ForEach(letterStore.letters.sorted(by: { $0.position < $1.position })) { letter in
                LetterTile(letter: letter)
                    .onTapGesture {
                        selectedLetter = letter
                        isShowingDetail = true
                    }
            }
        }
        .padding()
    }
}

struct LetterTile: View {
    let letter: ArabicLetterItem
    
    var body: some View {
        VStack {
            Text(letter.arabic)
                .font(.system(size: 36))
                .fontWeight(.bold)
                .environment(\.layoutDirection, .rightToLeft) // Ensure proper RTL display
            
            Text(letter.transliteration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LetterDetailView: View {
    let letter: ArabicLetterItem
    let voices: [String]
    @Binding var currentVoiceIndex: Int
    let wordStore: WordStore
    
    // Use a shared speech synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    @State private var isPlaying = false
    
    // Get example words for this letter in different positions
    var exampleWords: [(arabic: String, transliteration: String, position: String)] {
        var result: [(arabic: String, transliteration: String, position: String)] = []
        
        // Find words with this letter in different positions
        for word in wordStore.words {
            if let position = word.letterPositions[letter.arabic] {
                result.append((arabic: word.arabic, transliteration: word.transliteration, position: position))
            }
        }
        
        // Sort by position (beginning, middle, end)
        let positionOrder = ["beginning": 0, "middle": 1, "end": 2]
        result.sort { positionOrder[$0.position] ?? 3 < positionOrder[$1.position] ?? 3 }
        
        // If we don't have examples for all positions, add placeholders
        let positions = result.map { $0.position }
        if !positions.contains("beginning") {
            result.append((arabic: "—", transliteration: "No example available", position: "beginning"))
        }
        if !positions.contains("middle") {
            result.append((arabic: "—", transliteration: "No example available", position: "middle"))
        }
        if !positions.contains("end") {
            result.append((arabic: "—", transliteration: "No example available", position: "end"))
        }
        
        // Sort again to ensure correct order
        result.sort { positionOrder[$0.position] ?? 3 < positionOrder[$1.position] ?? 3 }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Letter display
                VStack(spacing: 15) {
                    Text(letter.arabic)
                        .font(.system(size: 100))
                        .fontWeight(.bold)
                        .environment(\.layoutDirection, .rightToLeft)
                    
                    Text(letter.transliteration)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        pronounceLetter()
                    }) {
                        Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isPlaying ? .gray : .blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    } .disabled(isPlaying)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Example words section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Example Words")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(exampleWords, id: \.position) { word in
                        ExampleWordView(
                            arabicWord: word.arabic,
                            transliteration: word.transliteration,
                            position: word.position,
                            targetLetter: letter.arabic
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Letter Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func pronounceLetter() {
        guard !isPlaying else { return }
        isPlaying = true
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Create utterance with the letter
        let utterance = AVSpeechUtterance(string: letter.arabic)
        
        // Try to use a female voice if available
        if let femaleVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.language.starts(with: "ar") && $0.gender == .female 
        }) {
            utterance.voice = femaleVoice
            print("Using female voice: \(femaleVoice.identifier)")
        } else {
            // Fall back to any Arabic voice
            utterance.voice = AVSpeechSynthesisVoice(language: "ar")
            print("Female voice not available, falling back to default Arabic voice")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Speak
        speechSynthesizer.speak(utterance)
        
        // Reset playing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPlaying = false
        }
    }
}

struct ExampleWordView: View {
    let arabicWord: String
    let transliteration: String
    let position: String
    let targetLetter: String
    
    // Use a shared speech synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Letter at \(position):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                // Use AttributedString to maintain connected form while highlighting
                Text(highlightedAttributedString)
                    .font(.system(size: 30))
                    .environment(\.layoutDirection, .rightToLeft) // Ensure proper RTL display

                Spacer() // Push content to the right for RTL effect
                
                Button(action: {
                    pronounceWord()
                }) {
                    Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title3)
                        .foregroundColor(isSpeaking ? .gray : .blue)
                }
                .disabled(isSpeaking)
            }
            .frame(maxWidth: .infinity)
            
            Text(transliteration)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Simplified pronunciation function
    private func pronounceWord() {
        guard !isSpeaking, arabicWord != "—" else { return }
        isSpeaking = true
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: arabicWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Speak
        speechSynthesizer.speak(utterance)
        
        // Reset speaking state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSpeaking = false
        }
    }
    
    // Create an AttributedString with the target letter highlighted based on position
    private var highlightedAttributedString: AttributedString {
        var attributedString = AttributedString(arabicWord)
        
        // Skip highlighting for placeholder
        if arabicWord == "—" {
            return attributedString
        }
        
        // Handle special case for alif with hamza
        let lettersToCheck: [String]
        if targetLetter == "ا" {
            // Check for alif and its variations with hamza
            lettersToCheck = ["ا", "أ", "إ", "آ"]
        } else {
            lettersToCheck = [targetLetter]
        }
        
        // Find the range to highlight based on position
        if let rangeToHighlight = findRangeForPosition(position, lettersToCheck: lettersToCheck) {
            // Apply orange color to the target letter at the specified position
            attributedString[rangeToHighlight].foregroundColor = .orange
        }
        
        return attributedString
    }
    
    // Helper function to find the range for the specified position
    private func findRangeForPosition(_ position: String, lettersToCheck: [String]) -> Range<AttributedString.Index>? {
        let attributedString = AttributedString(arabicWord)
        
        // For Arabic (RTL), we need to adjust our understanding of beginning/end
        switch position {
        case "beginning":
            // For beginning in RTL, we want the first letter (rightmost)
            for letter in lettersToCheck {
                if let range = attributedString.range(of: letter) {
                    return range
                }
            }
            
        case "middle":
            // For middle position, we need special handling for specific words
            if arabicWord == "حبيبي" && lettersToCheck.contains("ب") {
                // For "habibi", we want to highlight the first "ba" (second letter)
                if let range = attributedString.range(of: "ب") {
                    return range
                }
            } else {
                // For other words, find the middle occurrence
                for letter in lettersToCheck {
                    var searchRange = attributedString.startIndex..<attributedString.endIndex
                    var foundRanges: [Range<AttributedString.Index>] = []
                    
                    while let range = attributedString[searchRange].range(of: letter) {
                        foundRanges.append(range)
                        searchRange = range.upperBound..<attributedString.endIndex
                    }
                    
                    if foundRanges.count >= 2 {
                        // For words with multiple occurrences, use the first occurrence
                        // unless we have 3+ occurrences, then use the middle one
                        if foundRanges.count >= 3 {
                            return foundRanges[1] // Return the second occurrence
                        } else {
                            return foundRanges[0] // Return the first occurrence
                        }
                    } else if foundRanges.count == 1 {
                        return foundRanges[0] // Only one occurrence
                    }
                }
            }
            
        case "end":
            // For end in RTL, we want the last letter (leftmost)
            for letter in lettersToCheck {
                var searchRange = attributedString.startIndex..<attributedString.endIndex
                var lastRange: Range<AttributedString.Index>? = nil
                
                while let range = attributedString[searchRange].range(of: letter) {
                    lastRange = range
                    searchRange = range.upperBound..<attributedString.endIndex
                }
                
                if let lastRange = lastRange {
                    return lastRange
                }
            }
            
        default:
            break
        }
        
        // If we couldn't find a specific position, try to find any occurrence
        for letter in lettersToCheck {
            if let range = attributedString.range(of: letter) {
                return range
            }
        }
        
        return nil
    }
}

#Preview {
    LetterLearnView()
}