import SwiftUI
import Speech
import AVFoundation

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
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
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
    @State private var debugMode = true // Set to true to see debug info
    @State private var hasBeenGraded = false // Track if the current attempt has been graded
    
    // Stats
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    
    // Add these properties to better manage recognition state
    @State private var finalRecognizedText: String = ""
    @State private var recognitionInProgress = false
    @State private var lastRecognizedText: String = ""
    
    enum FeedbackState {
        case waiting
        case recording
        case correct
        case tryAgain
        case incorrect
    }
    
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
                        .disabled(speechSynthesizer.isPlaying)
                        .opacity(speechSynthesizer.isPlaying ? 0.5 : 1.0)
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
                    switch feedbackState {
                    case .waiting:
                        Text("Hold the microphone button and speak the word")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // "HOLD TO SPEAK" instruction that pulses
                        if showHoldInstruction {
                            Text("HOLD TO SPEAK")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.vertical, 4)
                                .opacity(0.8)
                        }
                        
                    case .recording:
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if !recognizedText.isEmpty {
                            Text("Heard: \(recognizedText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                    case .correct:
                        Text("Correct! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Button("Continue") {
                            moveToNextWord()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                        
                    case .tryAgain:
                        Text("Try Again")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Attempts remaining: \(attemptsRemaining)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !recognizedText.isEmpty && debugMode {
                            Text("Heard: \(recognizedText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                    case .incorrect:
                        Text("Incorrect")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("The correct pronunciation is:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            speakWord(word)
                        }) {
                            Label("Listen", systemImage: "speaker.wave.2.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .disabled(speechSynthesizer.isPlaying)
                        
                        Button("Continue") {
                            moveToNextWord()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .frame(height: 150)
                .padding()
                
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
                
                // Microphone button
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
            
            // Example usage of getRecordingURL
            Button("Show Recording Path") {
                let url = getRecordingURL()
                print("Recording URL: \(url.path)")
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
            requestSpeechAuthorization()
            // Start the "HOLD TO SPEAK" pulsing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                showHoldInstruction = true
            }
        }
    }
    
    private var sessionCompletedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
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
                        .foregroundColor(.green)
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
        isRecording = true
        feedbackState = .recording
        recognizedText = ""
        finalRecognizedText = ""
        lastRecognizedText = ""
        recognitionInProgress = true
        
        // Set up a timer to continuously capture recognized text during recording
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !self.isRecording {
                timer.invalidate()
                return
            }
            
            // Capture any text that appears during recognition
            if !self.recognizedText.isEmpty {
                self.lastRecognizedText = self.recognizedText
                print("Capturing during recognition: \"\(self.lastRecognizedText)\"")
            }
        }
        
        do {
            try speechRecognizer.startRecording()
        } catch {
            print("Recording error: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        // First, capture any text we have before stopping
        if !recognizedText.isEmpty {
            finalRecognizedText = recognizedText
        } else if !lastRecognizedText.isEmpty {
            // Fall back to the last text we captured during recognition
            finalRecognizedText = lastRecognizedText
        }
        
        print("Final captured text before stopping: \"\(finalRecognizedText)\"")
        
        isRecording = false
        recognitionInProgress = false
        
        // Stop recording with your existing code
        speechRecognizer.stopRecording()
        
        // Reset audio session for playback after recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to reset audio session: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let currentWord = self.currentWord else { return }
            
            // Use our captured text for evaluation
            let textToEvaluate = self.finalRecognizedText.isEmpty ? self.lastRecognizedText : self.finalRecognizedText
            print("Text being used for evaluation: \"\(textToEvaluate)\"")
            
            self.evaluateRecognitionResult(for: currentWord, withRecognizedText: textToEvaluate)
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
        print("Speaking word: \(word.arabic)")
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
