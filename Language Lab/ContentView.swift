//
//  ContentView.swift
//  Language Lab
//
//  Created by Elias Amal on 2025-03-14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var words: [ArabicWord]
    @StateObject private var letterStore = LetterStore.shared
    @StateObject private var wordStore = WordStore.shared
    
    // State variables for navigation
    @State private var showingLetterExercise = false
    @State private var showingWordExercise = false
    @State private var showingSpeakExercise = false
    @State private var showingLetterLearn = false
    @State private var showingWordLearn = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Loading state
    @State private var isInitializing = true
    
    // Debug flag - can be toggled in UI
    @State private var debugMode = false
    
    // Skip initialization when coming from splash screen
    var skipInitialization: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 30) {
                        // Debug toggle (only visible in development)
                        #if DEBUG
                        Toggle("Debug Mode", isOn: $debugMode)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        #endif
                        
                        // Debug info
                        if debugMode {
                            debugInfoView
                        }
                        
                        // Learn Section
                        VStack(spacing: 15) {
                            sectionHeader(title: "Learn", systemImage: "book.fill")
                            
                            ExerciseButton(
                                title: "Letters",
                                systemImage: "character.textbox"
                            ) {
                                showingLetterLearn = true
                            }
                            
                            ExerciseButton(
                                title: "Words",
                                systemImage: "text.book.closed"
                            ) {
                                showingWordLearn = true
                            }
                        }
                        .padding(.horizontal)
                        
                        // Practice Section
                        VStack(spacing: 15) {
                            sectionHeader(title: "Practice", systemImage: "brain.head.profile")
                            
                            ExerciseButton(
                                title: "Letters",
                                systemImage: "character.textbox"
                            ) {
                                if letterStore.letters.isEmpty {
                                    alertMessage = "Please wait while letters are being initialized."
                                    showingAlert = true
                                } else {
                                    showingLetterExercise = true
                                }
                            }
                            
                            ExerciseButton(
                                title: "Words",
                                systemImage: "text.book.closed"
                            ) {
                                if wordStore.words.isEmpty {
                                    alertMessage = "Please wait while words are being initialized."
                                    showingAlert = true
                                } else {
                                    showingWordExercise = true
                                }
                            }
                            
                            ExerciseButton(
                                title: "Speak",
                                systemImage: "waveform"
                            ) {
                                if wordStore.words.isEmpty {
                                    alertMessage = "Please wait while words are being initialized."
                                    showingAlert = true
                                } else {
                                    showingSpeakExercise = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .navigationTitle("Language Lab")
                .sheet(isPresented: $showingLetterExercise) {
                    LetterExerciseView()
                }
                .sheet(isPresented: $showingWordExercise) {
                    WordExerciseView()
                }
                .sheet(isPresented: $showingSpeakExercise) {
                    SpeakExerciseView()
                }
                .sheet(isPresented: $showingLetterLearn) {
                    // You'll need to create this view
                    Text("Letter Learn View - Coming Soon")
                        .font(.title)
                        .padding()
                    // Replace with LetterLearnView() when created
                }
                .sheet(isPresented: $showingWordLearn) {
                    // You'll need to create this view
                    Text("Word Learn View - Coming Soon")
                        .font(.title)
                        .padding()
                    // Replace with WordLearnView() when created
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .opacity(isInitializing ? 0 : 1)
            }
            
            // Loading overlay - only show if not skipping initialization
            if isInitializing && !skipInitialization {
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
        .onAppear {
            // If we're coming from splash screen, data is already initialized
            if skipInitialization {
                isInitializing = false
                return
            }
            
            // Otherwise, initialize data in background
            DispatchQueue.global(qos: .userInitiated).async {
                // Initialize stores if needed
                if letterStore.letters.isEmpty {
                    letterStore.initializeLetters()
                }
                
                if wordStore.words.isEmpty {
                    wordStore.initializeWords()
                }
                
                // Return to main thread to update UI
                DispatchQueue.main.async {
                    // Show UI with animation
                    withAnimation(.easeIn(duration: 0.3)) {
                        isInitializing = false
                    }
                }
            }
        }
    }
    
    // Helper view for section headers
    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.top, 5)
    }
    
    // Debug information view
    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Information")
                .font(.headline)
                .padding(.bottom, 4)
            
            Group {
                Text("Letters loaded: \(letterStore.letters.count)")
                Text("Words loaded: \(wordStore.words.count)")
                Text("SwiftData words: \(words.count)")
                Text("Color scheme: \(colorScheme == .dark ? "Dark" : "Light")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ExerciseButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ArabicWord.self, inMemory: true)
        .modelContainer(for: ArabicLetter.self, inMemory: true)
        .modelContainer(for: LetterProgress.self, inMemory: true)
}
