import SwiftUI
import AVFoundation

struct WordLearnView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wordStore = WordStore.shared
    
    @State private var selectedSection: WordSection = .common
    
    enum WordSection {
        case common
        case search
        case camera
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Section selector
                HStack(spacing: 0) {
                    SectionButton(title: "Common", systemImage: "text.book.closed", isSelected: selectedSection == .common) {
                        selectedSection = .common
                    }
                    
                    SectionButton(title: "Search", systemImage: "magnifyingglass", isSelected: selectedSection == .search) {
                        selectedSection = .search
                    }
                    
                    SectionButton(title: "Camera", systemImage: "camera", isSelected: selectedSection == .camera) {
                        selectedSection = .camera
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content area
                ZStack {
                    if selectedSection == .common {
                        CommonWordsView(words: wordStore.words)
                    } else if selectedSection == .search {
                        SearchWordsView(words: wordStore.words)
                    } else {
                        CameraView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Arabic Words")
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
        }
    }
}

struct SectionButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(10)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct CommonWordsView: View {
    let words: [ArabicWordItem]
    @State private var categoryFilter: String? = nil
    
    var categories: [String] {
        Array(Set(words.map { $0.category })).sorted()
    }
    
    var filteredWords: [ArabicWordItem] {
        if let category = categoryFilter {
            return words.filter { $0.category == category }
        } else {
            return words
        }
    }
    
    var body: some View {
        VStack {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    CategoryButton(title: "All", isSelected: categoryFilter == nil) {
                        categoryFilter = nil
                    }
                    
                    ForEach(categories, id: \.self) { category in
                        CategoryButton(title: category.capitalized, isSelected: categoryFilter == category) {
                            categoryFilter = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Word list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredWords) { word in
                        WordCard(word: word)
                    }
                }
                .padding()
            }
        }
    }
}

struct WordCard: View {
    let word: ArabicWordItem
    @State private var isSpeaking = false
    
    // Use a shared speech synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(word.arabic)
                    .font(.system(size: 28, weight: .bold))
                    .environment(\.layoutDirection, .rightToLeft)
                
                Spacer()
                
                Button(action: {
                    pronounceWord()
                }) {
                    Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title3)
                        .foregroundColor(isSpeaking ? .gray : .blue)
                }
                .disabled(isSpeaking)
            }
            
            Text(word.transliteration)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(word.translation)
                .font(.body)
            
            Text(word.category.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Simplified pronunciation function
    private func pronounceWord() {
        guard !isSpeaking else { return }
        isSpeaking = true
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: word.arabic)
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
}

struct SearchWordsView: View {
    let words: [ArabicWordItem]
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .english
    
    enum SearchMode {
        case english
        case arabic
        case transliteration
    }
    
    var filteredWords: [ArabicWordItem] {
        guard !searchText.isEmpty else { return [] }
        
        let lowercasedSearch = searchText.lowercased()
        
        switch searchMode {
        case .english:
            return words.filter { $0.translation.lowercased().contains(lowercasedSearch) }
        case .arabic:
            return words.filter { $0.arabic.contains(searchText) }
        case .transliteration:
            return words.filter { $0.transliteration.lowercased().contains(lowercasedSearch) }
        }
    }
    
    var body: some View {
        VStack {
            // Search controls
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for words...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Search mode selector
                Picker("Search Mode", selection: $searchMode) {
                    Text("English").tag(SearchMode.english)
                    Text("Arabic").tag(SearchMode.arabic)
                    Text("Transliteration").tag(SearchMode.transliteration)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            
            // Results
            if searchText.isEmpty {
                VStack {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Enter a search term to find Arabic words")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredWords.isEmpty {
                VStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No matching words found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredWords) { word in
                            WordCard(word: word)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct CameraView: View {
    @State private var showingCameraNotAvailable = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Camera Object Recognition")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Point your camera at objects to see their names in Arabic")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showingCameraNotAvailable = true
            }) {
                Text("Open Camera")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .alert(isPresented: $showingCameraNotAvailable) {
            Alert(
                title: Text("Feature Coming Soon"),
                message: Text("Camera object recognition will be available in a future update."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    WordLearnView()
} 