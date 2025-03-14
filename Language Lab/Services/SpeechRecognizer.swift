import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    @Published var errorMessage: String?
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    // Create a dedicated audio session for better control
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        // Use the Arabic locale
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar"))
        super.init()
        self.speechRecognizer?.delegate = self
        
        // Request authorization on init
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self?.errorMessage = "Speech recognition not authorized"
                }
            }
        }
    }
    
    func startRecording() {
        // Reset state
        recognizedText = ""
        isRecognizing = true
        errorMessage = nil
        
        // Properly configure audio session
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest,
                  let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
                errorMessage = "Speech recognition not available"
                isRecognizing = false
                return
            }
            
            // Enable on-device recognition
            if #available(iOS 13, *) {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
            
            // Configure input node with larger buffer for better results
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            // Start recognition with robust error handling
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let transcript = result.bestTranscription.formattedString
                    print("Recognized: \(transcript)")
                    self.recognizedText = transcript
                }
                
                if error != nil {
                    print("Recognition error: \(error?.localizedDescription ?? "unknown error")")
                    if self.isRecognizing {
                        // Only report errors if we're still expecting to recognize
                        self.errorMessage = "Recognition error"
                        self.stopRecording()
                    }
                }
                
                if result?.isFinal == true {
                    print("Final result received")
                    // Save the final result before stopping
                    if let finalText = result?.bestTranscription.formattedString {
                        self.recognizedText = finalText
                    }
                }
            }
            
            // Start audio engine with proper error handling
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Audio session error: \(error.localizedDescription)")
            errorMessage = "Audio session error"
            isRecognizing = false
        }
    }
    
    func stopRecording() {
        // Capture the final recognized text
        let finalText = recognizedText
        
        // Clean up resources
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Properly handle audio session
        do {
            // Use setActive(false) with notifyOthersOnDeactivation to avoid session conflicts
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        // Ensure we have the final recognition result
        if recognizedText.isEmpty && !finalText.isEmpty {
            recognizedText = finalText
        }
        
        isRecognizing = false
        
        // Clean up references
        recognitionRequest = nil
        recognitionTask = nil
    }
}