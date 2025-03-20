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
    @State private var showingExitConfirmation = false
    @State private var selectedMotivationalMessage: String = ""
    
    // Stats
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    @State private var currentQuestionIndex = 0
    @State private var totalQuestions = 10
    @State private var sessionStartTime = Date()
    @State private var sessionDuration: TimeInterval = 0
    @State private var xpGained: Int = 0
    
    // Animation states for results screen
    @State private var showAnimation = false
    @State private var showTiles = false
    @State private var showButton = false
    
    // Haptic feedback generator
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            // Background color matching other exercise views
            (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                .ignoresSafeArea()
            
            if sessionCompleted {
                // Full-page results view
                sessionCompletedView
            } else {
                VStack(spacing: 0) {
                    // Top bar with exit button and progress bar
                    HStack(spacing: 12) {
                        // Exit button
                        Button(action: {
                            if currentQuestionIndex > 0 && !sessionCompleted {
                                // Only show confirmation if we're in the middle of a session
                                showingExitConfirmation = true
                            } else {
                                // Dismiss directly if we're at the beginning
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(8)
                        }
                        
                        // Larger progress bar
                        ProgressView(value: Double(currentQuestionIndex), total: Double(totalQuestions))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 16)
                            .scaleEffect(x: 1, y: 2.0, anchor: .center)
                            .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    if isLoading {
                        // Center the loading indicator in the screen
                        Spacer()
                        ProgressView("Loading...")
                            .padding()
                        Spacer()
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
                            // Trigger haptic feedback
                            hapticFeedback.impactOccurred()
                            
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
                        // This should rarely be seen as we're loading the whole view at once
                        Spacer()
                        ProgressView("Loading question...")
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            // Prepare haptic feedback
            hapticFeedback.prepare()
            
            // Load everything at once, similar to SpeakExerciseView
            isLoading = true
            
            // Give time for the UI to render
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startNewSession()
                isLoading = false
            }
        }
        .confirmationDialog(
            "Are you sure you want to end this exercise?",
            isPresented: $showingExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Exercise", role: .destructive) {
                dismiss()
            }
            Button("Continue Exercise", role: .cancel) {
                // Just dismiss the dialog
            }
        } message: {
            Text("Your progress in this session will be lost.")
        }
        .interactiveDismissDisabled(true)
    }
    
    private var sessionCompletedView: some View {
        VStack(spacing: 0) {
            // Celebration animation and content
            VStack(spacing: 20) {
                // Animation section
                ZStack {
                    // Animated background circles
                    ForEach(0..<15, id: \.self) { _ in
                        Circle()
                            .fill(
                                Color(
                                    red: Double.random(in: 0.5...1.0),
                                    green: Double.random(in: 0.5...1.0),
                                    blue: Double.random(in: 0.5...1.0)
                                )
                            )
                            .frame(width: CGFloat.random(in: 10...30))
                            .position(
                                x: CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                                y: CGFloat.random(in: 20...120) // Reduced height range
                            )
                            .opacity(showAnimation ? 0.7 : 0)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 1.0...2.0))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...0.5)),
                                value: showAnimation
                            )
                    }
                    
                    // Trophy icon with animation
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70)) // Reduced from 80
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                        .scaleEffect(showAnimation ? 1.1 : 0.8)
                        .opacity(showAnimation ? 1 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: showAnimation
                        )
                }
                .frame(height: 180) 
                .padding(.top, 40) 
                .onAppear {
                    // Select a single motivational message when the view appears
                    if selectedMotivationalMessage.isEmpty {
                        selectedMotivationalMessage = getRandomMotivationalMessage()
                    }
                    
                    // Start animations with slight delays
                    showAnimation = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showTiles = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showButton = true
                    }
                }
                
                // Motivational message (now using the pre-selected message)
                Text(selectedMotivationalMessage)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                
                Text("You've completed the letter recognition exercise.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                // Results tiles
                HStack(spacing: 12) {
                    // XP gained
                    ResultTile(
                        icon: "bolt.fill",
                        value: "\(xpGained)",
                        label: "XP Gained",
                        color: .orange,
                        show: showTiles
                    )
                    
                    // Score percentage
                    ResultTile(
                        icon: "chart.bar.fill",
                        value: "\(calculateAccuracy())%",
                        label: "Score",
                        color: accuracyColor,
                        show: showTiles
                    )
                    
                    // Time taken
                    ResultTile(
                        icon: "clock.fill",
                        value: formatDuration(sessionDuration),
                        label: "Time",
                        color: .blue,
                        show: showTiles
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 15) // Flexible space with minimum
                
                // Claim XP button
                Button(action: {
                    // Trigger haptic feedback for a satisfying finish
                    hapticFeedback.impactOccurred()
                    
                    // Dismiss the view
                    dismiss()
                }) {
                    Text("Claim XP")
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20) // Reduced from 30
                .opacity(showButton ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showButton)
            }
            .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height)
        }
    }
    
    // Helper struct for result tiles
    struct ResultTile: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        let show: Bool
        
        var body: some View {
            VStack(spacing: 8) { 
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15) 
            .background(color.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(show ? 1 : 0.7)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: show)
        }
    }
    
    // Get a single random motivational message
    private func getRandomMotivationalMessage() -> String {
        let messages = [
            "Great job!",
            "Excellent work!",
            "You're making progress!",
            "Keep it up!",
            "Well done!",
            "You're on a roll!",
            "Fantastic effort!",
            "You're getting better!",
            "Amazing progress!",
            "You're crushing it!"
        ]
        return messages.randomElement() ?? "Great job!"
    }
    
    // Format duration as MM:SS
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Color for accuracy based on performance
    private var accuracyColor: Color {
        let accuracy = calculateAccuracy()
        if accuracy >= 80 {
            return .green
        } else if accuracy >= 60 {
            return .orange
        } else {
            return .red
        }
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
        currentQuestionIndex = 0
        sessionStartTime = Date()
    }
    
    private func startNewSession() {
        // Start with all letters
        remainingLetters = letterStore.letters.shuffled()
        
        if remainingLetters.isEmpty {
            print("No letters available for the session")
            return
        }
        
        loadNextQuestion()
    }
    
    private func loadNextQuestion() {
        showingResult = false
        selectedOption = nil
        
        // If we've reached 10 questions or no more letters, end session
        if currentQuestionIndex >= totalQuestions || remainingLetters.isEmpty {
            // Calculate session duration
            sessionDuration = Date().timeIntervalSince(sessionStartTime)
            
            // Calculate XP gained (10 per correct answer)
            xpGained = correctAnswers * 10
            
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
        
        // Increment question index
        currentQuestionIndex += 1
        
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