import SwiftUI
import Speech
import AVFoundation

// Add Color extension for custom colors
extension Color {
    static let correctGreen = Color(hex: "#58cc02")
}

// Add hex initializer for Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Helper class to handle speech synthesis
class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isPlaying = false
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    func speak(_ text: String, language: String = "ar-SA") {
        // Don't start if already playing
        if isPlaying {
            return
        }
        
        print("Speaking text: \(text) in language: \(language)")
        isPlaying = true
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        // Configure the utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4 // Slower rate for clearer pronunciation
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 0.5
        
        // Speak
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Started speaking")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Finished speaking")
        isPlaying = false
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Cancelled speaking")
        isPlaying = false
    }
}

struct SpeakExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var wordStore = WordStore.shared
    @State private var speechRecognizer: SpeechRecognizer?
    @State private var speechSynthesizer: SpeechSynthesizer?
    
    @State private var currentWord: ArabicWordItem?
    @State private var recognizedText = ""
    @State private var feedbackState: FeedbackState = .waiting
    @State private var remainingWords: [ArabicWordItem] = []
    @State private var sessionCompleted = false
    @State private var isLoading = true
    @State private var attemptsRemaining = 3
    @State private var showHoldInstruction = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var isProcessingResult = false
    @State private var debugMode = false // Set to true to see debug info
    @State private var hasBeenGraded = false // Track if the current attempt has been graded
    
    // Stats
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    
    // Add this property to store the final recognized text
    @State private var finalRecognizedText: String = ""
    
    // Add these properties to better track recognition state
    @State private var recognitionBuffer: [String] = []
    @State private var recognitionTimer: Timer?
    @State private var lastNonEmptyText: String = ""
    
    // Add a proper app initialization state
    @State private var isAppInitializing = true
    
    // Add or update these feedback generator properties
    @State private var feedbackGenerator = UINotificationFeedbackGenerator()
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Add new state variables for progress bar
    @State private var currentQuestionIndex = 0
    @State private var totalQuestions = 10
    
    enum FeedbackState {
        case waiting
        case recording
        case correct
        case tryAgain
        case incorrect
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack {
                // Progress bar at the very top
                ProgressView(value: Double(currentQuestionIndex), total: Double(totalQuestions))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
                
                // Question counter
                Text("\(currentQuestionIndex)/\(totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                // Header with centered score
                VStack(spacing: 2) {
                    Text("Score:")
                        .fontWeight(.medium)
                    
                    Text("\(correctAnswers)/\(correctAnswers + incorrectAnswers)")
                        .fontWeight(.semibold)
                        .font(.title3)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                if isLoading {
                    ProgressView("Loading words...")
                        .padding()
                        .onAppear {
                            // Start loading words immediately
                            loadWords()
                        }
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
                                loadWords()
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
                    Spacer()
                    
                    // Word card
                    VStack(spacing: 16) {
                        HStack {
                            Text(word.arabic)
                                .font(.system(size: 36, weight: .bold))
                                .padding(.vertical, 8)
                            
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
                            .disabled(speechSynthesizer?.isPlaying ?? false)
                            .opacity(speechSynthesizer?.isPlaying ?? false ? 0.5 : 1.0)
                        }
                        
                        Text(word.transliteration)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(word.translation)
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(.bottom, 8)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Feedback area
                    VStack(spacing: 16) {
                        // Feedback message area
                        VStack(spacing: 16) {
                            switch feedbackState {
                            case .waiting:
                                // Empty state - just show recording instructions
                                if showHoldInstruction {
                                    Text("HOLD TO SPEAK")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .scaleEffect(1.0)
                                        .padding(.vertical, 4)
                                        .opacity(0.8)
                                }
                                
                            case .recording:
                                Text("Recording...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if !recognizedText.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("Heard:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(recognizedText)
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                                } else {
                                    Text(" ")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                }
                                
                            case .correct:
                                Text("Correct! 🎉")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.correctGreen)
                                    .onAppear {
                                        // Trigger success haptic feedback
                                        feedbackGenerator.notificationOccurred(.success)
                                    }
                                
                            case .tryAgain:
                                Text("Try Again")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .onAppear {
                                        // Trigger warning haptic feedback
                                        feedbackGenerator.notificationOccurred(.warning)
                                    }
                                
                                Text("Attempts remaining: \(attemptsRemaining)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                            case .incorrect:
                                Text("Incorrect")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .onAppear {
                                        // Trigger error haptic feedback
                                        feedbackGenerator.notificationOccurred(.error)
                                    }
                            }
                        }
                        .frame(height: 100)
                        .padding()
                        
                        Spacer() // Push content to top and button to bottom


                        // Microphone button
                        VStack { 
                            Text("HOLD TO SPEAK")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.vertical, 4)
                                .opacity(0.8)

                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.blue)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: (isRecording ? Color.red : Color.blue).opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .scaleEffect(isRecording ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3), value: isRecording)
                            }
                            .frame(width: 70, height: 70)
                            .padding(.bottom, 30)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isRecording && !isProcessingResult && feedbackState != .correct && feedbackState != .incorrect {
                                            startRecording()
                                        }
                                    }
                                    .onEnded { _ in
                                        if isRecording {
                                            stopRecording()
                                        }
                                    }
                            )
                            .disabled(isProcessingResult || feedbackState == .correct || feedbackState == .incorrect)
                            .opacity((isProcessingResult || feedbackState == .correct || feedbackState == .incorrect) ? 0.5 : 1.0)
                        }
                        
                        // Continue button - always at bottom, enabled only for correct/incorrect states
                        Button(action: {
                            // Trigger haptic on press down
                            impactGenerator.impactOccurred()
                            moveToNextWord()
                        }) {
                            Text("Continue")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    feedbackState == .correct || feedbackState == .incorrect 
                                    ? (feedbackState == .correct ? Color.correctGreen : Color.blue)
                                    : Color.gray
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(feedbackState != .correct && feedbackState != .incorrect)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Debug panel
                    if debugMode && !recognizedText.isEmpty && feedbackState != .correct && feedbackState != .incorrect {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Debug Info:")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("Recognized: \(recognizedText)")
                                .font(.caption)
                            
                            Button("Play Recording") {
                                playRecording()
                            }
                            .font(.caption)
                            .padding(.vertical, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                }
                
                // Example usage of getRecordingURL
                // Button("Show Recording Path") {
                //     let url = getRecordingURL()
                //     print("Recording URL: \(url.path)")
                // }
            }
            .opacity(isAppInitializing ? 0 : 1)
            
            // Initialization overlay
            if isAppInitializing {
                VStack {
                    Text("Language Lab")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Speak")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Session") {
                    sessionCompleted = true
                }
            }
        }
        .onAppear {
            // Initialize in background
            DispatchQueue.global(qos: .userInitiated).async {
                // Initialize speech services
                let recognizer = SpeechRecognizer()
                let synthesizer = SpeechSynthesizer()
                
                // Switch back to main thread to update UI
                DispatchQueue.main.async {
                    self.speechRecognizer = recognizer
                    self.speechSynthesizer = synthesizer
                    
                    // Show the UI
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.isAppInitializing = false
                    }
                    
                    // Request permissions after UI is visible
                    self.requestSpeechAuthorization()
                    
                    // Prepare haptic feedback generators
                    self.feedbackGenerator.prepare()
                    self.impactGenerator.prepare()
                }
            }
        }
    }
    
    private var sessionCompletedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.correctGreen)
            
            Text("Session Completed!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Correct:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(correctAnswers)")
                        .fontWeight(.bold)
                        .foregroundColor(.correctGreen)
                }
                
                HStack {
                    Text("Incorrect:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(incorrectAnswers)")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Total:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(correctAnswers + incorrectAnswers)")
                        .fontWeight(.bold)
                }
                
                if correctAnswers + incorrectAnswers > 0 {
                    HStack {
                        Text("Accuracy:")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int((Double(correctAnswers) / Double(correctAnswers + incorrectAnswers)) * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal)
            
            Button("Start New Session") {
                resetSession()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            .padding(.top, 16)
        }
        .padding()
    }
    
    // MARK: - Session Management
    
    private func loadWords() {
        print("Loading words...")
        
        // Check if words are available
        if wordStore.words.isEmpty {
            print("No words available in the word store")
            isLoading = false
            return
        }
        
        // Get a subset of words for practice (10 or fewer)
        let practiceWords = Array(wordStore.words.shuffled().prefix(10))
        
        print("Loaded \(practiceWords.count) words for practice")
        
        // Set up the session
        remainingWords = practiceWords
        moveToNextWord()
        isLoading = false
    }
    
    private func moveToNextWord() {
        print("Moving to next word...")
        
        // Reset state for the new word
        recognizedText = ""
        feedbackState = .waiting
        attemptsRemaining = 3
        hasBeenGraded = false
        
        if remainingWords.isEmpty {
            print("No more words, session completed")
            sessionCompleted = true
            return
        }
        
        // Get the next word
        currentWord = remainingWords.removeFirst()
        print("Next word: \(currentWord?.arabic ?? "nil") (\(currentWord?.transliteration ?? "nil"))")
        
        // Update the question index
        currentQuestionIndex += 1
    }
    
    private func resetSession() {
        print("Resetting session...")
        
        // Reset all session state
        recognizedText = ""
        feedbackState = .waiting
        sessionCompleted = false
        correctAnswers = 0
        incorrectAnswers = 0
        attemptsRemaining = 3
        hasBeenGraded = false
        
        // Load new words
        isLoading = true
        loadWords()
    }
    
    // MARK: - Speech Recognition
    
    private func startRecording() {
        // Ensure speech recognizer is initialized
        guard let speechRecognizer = speechRecognizer else {
            print("Speech recognizer not initialized")
            return
        }
        
        isRecording = true
        feedbackState = .recording
        recognizedText = ""
        finalRecognizedText = ""
        lastNonEmptyText = ""
        recognitionBuffer.removeAll()
        
        // Configure audio session for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session for recording: \(error)")
        }
        
        // Start recording using SpeechRecognizer
        speechRecognizer.startRecording()
        
        // Start a timer to continuously capture recognized text
        recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] timer in
            guard self.isRecording else { return }
            
            // Get current recognized text from the speech recognizer
            let currentText = speechRecognizer.recognizedText
            self.recognizedText = currentText
            
            // Store non-empty text
            if !currentText.isEmpty {
                print("Capturing during recognition: \"\(currentText)\"")
                self.recognitionBuffer.append(currentText)
                self.lastNonEmptyText = currentText
            }
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        // Stop our timer
        recognitionTimer?.invalidate()
        recognitionTimer = nil
        
        // Get the best text from our buffer
        let bestText = getBestRecognizedText()
        finalRecognizedText = bestText
        
        print("Final text from buffer: \"\(finalRecognizedText)\"")
        print("Last non-empty text: \"\(lastNonEmptyText)\"")
        print("Recognition buffer size: \(recognitionBuffer.count)")
        
        isRecording = false
        
        // Stop recording using SpeechRecognizer
        speechRecognizer?.stopRecording()
        
        // Reset audio session for playback
        resetAudioSessionForPlayback()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let currentWord = self.currentWord else { return }
            
            // Use our best available text for evaluation
            let textToEvaluate = self.getBestTextForEvaluation()
            print("Text being used for evaluation: \"\(textToEvaluate)\"")
            
            self.evaluateRecognitionResult(for: currentWord, withRecognizedText: textToEvaluate)
        }
    }
    
    private func getBestRecognizedText() -> String {
        // If buffer is empty, return empty string
        if recognitionBuffer.isEmpty {
            return ""
        }
        
        // Return the longest text in our buffer (usually the most complete)
        return recognitionBuffer
            .sorted { $0.count > $1.count }
            .first ?? ""
    }
    
    private func getBestTextForEvaluation() -> String {
        // Try multiple sources for the text, in order of preference
        if !finalRecognizedText.isEmpty {
            return finalRecognizedText
        } else if !lastNonEmptyText.isEmpty {
            return lastNonEmptyText
        } else if !recognitionBuffer.isEmpty {
            return getBestRecognizedText()
        } else {
            return speechRecognizer?.recognizedText ?? ""
        }
    }
    
    private func resetAudioSessionForPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session reset for playback")
        } catch {
            print("Failed to reset audio session: \(error)")
        }
    }
    
    private func evaluateRecognitionResult(for word: ArabicWordItem, withRecognizedText capturedText: String) {
        // Use the captured text
        let finalRecognizedText = capturedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Debug information
        print("Target word: \"\(word.arabic)\"")
        print("Evaluating with captured text: \"\(finalRecognizedText)\"")
        
        // Normalize both strings for comparison
        let normalizedTarget = word.arabic
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let normalizedRecognized = finalRecognizedText
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        print("Normalized target: \"\(normalizedTarget)\"")
        print("Normalized recognized: \"\(normalizedRecognized)\"")
        
        // More flexible matching for Arabic
        let matchFound = !normalizedRecognized.isEmpty && (
            normalizedTarget.contains(normalizedRecognized) || 
            normalizedRecognized.contains(normalizedTarget) ||
            // Check if at least half the characters match in sequence
            normalizedTarget.contains(String(normalizedRecognized.prefix(normalizedRecognized.count/2))) ||
            normalizedRecognized.contains(String(normalizedTarget.prefix(normalizedTarget.count/2)))
        )
        
        if matchFound {
            print("✅ CORRECT ANSWER")
            feedbackState = .correct
            correctAnswers += 1
            wordStore.updateWordProgress(wordId: word.id, isCorrect: true)
        } else {
            print("❌ INCORRECT ANSWER")
            attemptsRemaining -= 1
            
            if attemptsRemaining > 0 {
                // Still have attempts left
                feedbackState = .tryAgain
            } else {
                // No more attempts
                feedbackState = .incorrect
                incorrectAnswers += 1
                wordStore.updateWordProgress(wordId: word.id, isCorrect: false)
            }
        }
    }
    
    // MARK: - Audio Playback
    
    // Play the recorded audio for debugging
    private func playRecording() {
        let url = getRecordingURL()
        
        print("Playing recording from \(url.path)")
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        } catch {
            print("Error playing recording: \(error.localizedDescription)")
        }
    }
    
    // Speak the word using text-to-speech
    private func speakWord(_ word: ArabicWordItem) {
        // Ensure speech synthesizer is initialized
        guard let speechSynthesizer = speechSynthesizer else {
            print("Speech synthesizer not initialized")
            return
        }
        
        print("Speaking word: \(word.arabic)")
        // Trigger haptic feedback
//        impactGenerator.impactOccurred()
        speechSynthesizer.speak(word.arabic)
    }
    
    // ONLY add this to your existing onCreate or similar lifecycle method
    private func checkSpeechPermissions() {
        requestSpeechAuthorization()
    }
    
    private func getRecordingURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("speech_recording.m4a")
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    print("Speech recognition not authorized")
                }
            }
        }
    }
}
