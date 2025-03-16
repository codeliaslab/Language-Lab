import SwiftUI
import AVFoundation

struct LetterExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var letterStore = LetterStore.shared
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    @State private var currentLetter: ArabicLetterItem?
    @State private var options: [String] = []
    @State private var selectedOption: String?
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var remainingLetters: [ArabicLetterItem] = []
    @State private var sessionCompleted = false
    @State private var isLoading = true
    
    // Stats
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    
    var body: some View {
        VStack {
            // Header with centered score
            VStack(spacing: 2) {
                Text("Score:")
                    .fontWeight(.medium)
                
                Text("\(correctAnswers)/\(correctAnswers + incorrectAnswers)")
                    .fontWeight(.semibold)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if isLoading {
                ProgressView("Loading letters...")
                    .padding()
            } else if letterStore.letters.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("No Letters Available")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Please initialize the Arabic letters to continue.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Initialize Letters") {
                        letterStore.initializeLetters()
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
            } else if let letter = currentLetter {
                // Letter display
                HStack(spacing: 16) {
                    Text(letter.arabic)
                        .font(.system(size: 70))
                        .fontWeight(.bold)
                        .padding(.vertical, 30)
                    
                    // Add speaker button
                    Button(action: {
                        speakLetter(letter)
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
                
                Text("What is this letter called?")
                    .font(.title3)
                    .padding(.bottom, 20)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        OptionButton(
                            option: option,
                            isSelected: selectedOption == option,
                            showResult: showingResult,
                            isCorrect: option == currentLetter?.transliteration,
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
        // Start with all letters
        remainingLetters = letterStore.letters
        
        if remainingLetters.isEmpty {
            print("No letters available for the session")
            return
        }
        
        loadNextQuestion()
    }
    
    private func loadNextQuestion() {
        showingResult = false
        selectedOption = nil
        
        // If no more letters, end session
        if remainingLetters.isEmpty {
            sessionCompleted = true
            return
        }
        
        // Select a random letter from remaining
        let randomIndex = Int.random(in: 0..<remainingLetters.count)
        currentLetter = remainingLetters.remove(at: randomIndex)
        
        // Generate options (1 correct, 3 incorrect)
        generateOptions()
    }
    
    private func generateOptions() {
        guard let currentLetter = currentLetter else { return }
        
        // Start with the correct answer
        var newOptions = [currentLetter.transliteration]
        
        // Add 3 incorrect options
        let otherLetters = letterStore.letters.filter { $0.id != currentLetter.id }
        let shuffledLetters = otherLetters.shuffled()
        
        for i in 0..<min(3, shuffledLetters.count) {
            newOptions.append(shuffledLetters[i].transliteration)
        }
        
        // Shuffle options
        options = newOptions.shuffled()
    }
    
    private func checkAnswer() {
        guard let currentLetter = currentLetter, let selectedOption = selectedOption else { return }
        
        isCorrect = selectedOption == currentLetter.transliteration
        
        // Update stats
        if isCorrect {
            correctAnswers += 1
        } else {
            incorrectAnswers += 1
        }
        
        // Update progress
        letterStore.updateLetterProgress(letterId: currentLetter.id, isCorrect: isCorrect)
        
        showingResult = true
    }
    
    private func speakLetter(_ letter: ArabicLetterItem) {
        print("Speaking letter: \(letter.arabic)")
        speechSynthesizer.speak(letter.arabic)
    }
}

struct OptionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var option: String
    var isSelected: Bool
    var showResult: Bool
    var isCorrect: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.title3)
                
                Spacer()
                
                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if showResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if showResult {
            if isCorrect {
                return Color.green.opacity(0.2)
            } else if isSelected {
                return Color.red.opacity(0.2)
            }
        }
        
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            // Use a color that works in both light and dark mode
            return colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
        }
    }
    
    private var foregroundColor: Color {
        if showResult && isCorrect {
            return .green
        } else if showResult && isSelected && !isCorrect {
            return .red
        }
        
        return isSelected ? .blue : (colorScheme == .dark ? .white : .primary)
    }
    
    private var borderColor: Color {
        if showResult {
            if isCorrect {
                return .green
            } else if isSelected {
                return .red
            }
        }
        
        return isSelected ? .blue : Color.gray.opacity(0.5)
    }
}

#Preview {
    LetterExerciseView()
} 