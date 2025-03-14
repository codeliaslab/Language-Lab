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
    
    @State private var isFirstLaunch = true
    @State private var showingLetterExercise = false
    @State private var showingWordExercise = false
    @State private var showingSpeakExercise = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Language Lab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                // Debug info
                Text("Letters: \(letterStore.letters.count) | Words: \(wordStore.words.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Exercise buttons
                VStack(spacing: 15) {
                    ExerciseButton(title: "Letters", systemImage: "character.textbox") {
                        showingLetterExercise = true
                    }
                    
                    ExerciseButton(title: "Words", systemImage: "text.book.closed") {
                        showingWordExercise = true
                    }
                    
                    ExerciseButton(title: "Speak", systemImage: "mic.circle") {
                        showingSpeakExercise = true
                    }
                    
                    ExerciseButton(title: "Phrases", systemImage: "text.bubble") {
                        // Phrases exercise will be implemented later
                        alertMessage = "Phrases exercise coming soon!"
                        showingAlert = true
                    }
                }
                
                Spacer()
                
                // Debug button
                Button("Reinitialize Data") {
                    letterStore.initializeLetters()
                    wordStore.initializeWords()
                    alertMessage = "Data reinitialized: \(letterStore.letters.count) letters and \(wordStore.words.count) words available"
                    showingAlert = true
                }
                .padding()
                .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.gray.opacity(0.2))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Arabic Learning")
            .sheet(isPresented: $showingLetterExercise) {
                LetterExerciseView()
            }
            .sheet(isPresented: $showingWordExercise) {
                WordExerciseView()
            }
            .sheet(isPresented: $showingSpeakExercise) {
                SpeakExerciseView()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            if isFirstLaunch {
                // Make sure data is initialized
                if letterStore.letters.isEmpty {
                    letterStore.initializeLetters()
                }
                
                if wordStore.words.isEmpty {
                    wordStore.initializeWords()
                }
                
                isFirstLaunch = false
            }
        }
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
