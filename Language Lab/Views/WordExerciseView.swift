import SwiftUI
import AVFoundation

struct WordExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var wordStore = WordStore.shared
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    @State private var currentWord: ArabicWordItem?
    @State private var options: [String] = []
    @State private var selectedOption: String?
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var remainingWords: [ArabicWordItem] = []
    @State private var sessionCompleted = false
    @State private var isLoading = true
    @State private var exerciseMode: ExerciseMode = .arabicToEnglish
    
    // Stats
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    
    enum ExerciseMode {
        case arabicToEnglish
        case englishToArabic
    }
    
    var body: some View {
        VStack {
            // Header with mode selector and centered score
            VStack(spacing: 12) {
                // Mode selector
                Picker("Mode", selection: $exerciseMode) {
                    Text("Arabic → English").tag(ExerciseMode.arabicToEnglish)
                    Text("English → Arabic").tag(ExerciseMode.englishToArabic)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 220)
                .onChange(of: exerciseMode) { _, _ in
                    // Restart session when mode changes
                    resetSession()
                    startNewSession()
                }
                
                // Centered score
                VStack(spacing: 2) {
                    Text("Score:")
                        .fontWeight(.medium)
                    
                    Text("\(correctAnswers)/\(correctAnswers + incorrectAnswers)")
                        .fontWeight(.semibold)
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if isLoading {
                ProgressView("Loading words...")
                    .padding()
            } else if wordStore.words.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("No Words Available")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Please initialize the Arabic words to continue.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Initialize Words") {
                        wordStore.initializeWords()
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                            startNewSession()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else if sessionCompleted {
                sessionCompletedView
            } else if let word = currentWord {
                // Word display
                if exerciseMode == .arabicToEnglish {
                    HStack(spacing: 16) {
                        Text(word.arabic)
                            .font(.system(size: 70))
                            .fontWeight(.bold)
                            .padding(.vertical, 30)
                        
                        // Add speaker button
                        Button(action: {
                            speakWord(word)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                    }
                    
                    Text("What does this word mean?")
                        .font(.title3)
                        .padding(.bottom, 20)
                } else {
                    Text(word.translation)
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .padding(.vertical, 30)
                    
                    Text("What is the Arabic word for this?")
                        .font(.title3)
                        .padding(.bottom, 20)
                }
                
                // Options
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        OptionButton(
                            option: option,
                            isSelected: selectedOption == option,
                            showResult: showingResult,
                            isCorrect: isCorrectOption(option),
                            action: {
                                if !showingResult {
                                    selectedOption = option
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    if showingResult {
                        // Move to next question
                        loadNextQuestion()
                    } else {
                        // Check answer
                        checkAnswer()
                    }
                }) {
                    Text(showingResult ? "Continue" : "Check Answer")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedOption == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedOption == nil)
                .padding()
            } else {
                ProgressView("Loading question...")
            }
        }
        .onAppear {
            // Give time for the UI to render
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
                startNewSession()
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private var sessionCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            
            Text("Session Completed!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've completed this practice session.")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Your results:")
                    .font(.headline)
                    .padding(.top)
                
                HStack {
                    Text("Correct answers:")
                    Spacer()
                    Text("\(correctAnswers)")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Incorrect answers:")
                    Spacer()
                    Text("\(incorrectAnswers)")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Accuracy:")
                    Spacer()
                    Text("\(calculateAccuracy())%")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Button("Start New Session") {
                resetSession()
                startNewSession()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top)
        }
        .padding()
    }
    
    private func calculateAccuracy() -> Int {
        let total = correctAnswers + incorrectAnswers
        guard total > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(total)) * 100)
    }
    
    private func resetSession() {
        correctAnswers = 0
        incorrectAnswers = 0
        sessionCompleted = false
    }
    
    private func startNewSession() {
        // Start with all words
        remainingWords = wordStore.words
        
        if remainingWords.isEmpty {
            print("No words available for the session")
            return
        }
        
        loadNextQuestion()
    }
    
    private func loadNextQuestion() {
        showingResult = false
        selectedOption = nil
        
        // If no more words, end session
        if remainingWords.isEmpty {
            sessionCompleted = true
            return
        }
        
        // Select a random word from remaining
        let randomIndex = Int.random(in: 0..<remainingWords.count)
        currentWord = remainingWords.remove(at: randomIndex)
        
        // Generate options (1 correct, 3 incorrect)
        generateOptions()
    }
    
    private func generateOptions() {
        guard let currentWord = currentWord else { return }
        
        // Start with the correct answer
        var newOptions: [String]
        
        if exerciseMode == .arabicToEnglish {
            newOptions = [currentWord.translation]
            
            // Add 3 incorrect options
            let otherWords = wordStore.words.filter { $0.id != currentWord.id }
            let shuffledWords = otherWords.shuffled()
            
            for i in 0..<min(3, shuffledWords.count) {
                newOptions.append(shuffledWords[i].translation)
            }
        } else {
            newOptions = [currentWord.arabic]
            
            // Add 3 incorrect options
            let otherWords = wordStore.words.filter { $0.id != currentWord.id }
            let shuffledWords = otherWords.shuffled()
            
            for i in 0..<min(3, shuffledWords.count) {
                newOptions.append(shuffledWords[i].arabic)
            }
        }
        
        // Shuffle options
        options = newOptions.shuffled()
    }
    
    private func isCorrectOption(_ option: String) -> Bool {
        guard let currentWord = currentWord else { return false }
        
        if exerciseMode == .arabicToEnglish {
            return option == currentWord.translation
        } else {
            return option == currentWord.arabic
        }
    }
    
    private func checkAnswer() {
        guard let currentWord = currentWord, let selectedOption = selectedOption else { return }
        
        isCorrect = isCorrectOption(selectedOption)
        
        // Update stats
        if isCorrect {
            correctAnswers += 1
        } else {
            incorrectAnswers += 1
        }
        
        // Update progress
        wordStore.updateWordProgress(wordId: currentWord.id, isCorrect: isCorrect)
        
        showingResult = true
    }
    
    private func speakWord(_ word: ArabicWordItem) {
        print("Speaking word: \(word.arabic)")
        speechSynthesizer.speak(word.arabic)
    }
}

// We're reusing the OptionButton from LetterExerciseView 