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
    @Query private var words: [ArabicWord]
    @State private var isFirstLaunch = true
    
    var body: some View {
        NavigationView {
            List {
                ForEach(words) { word in
                    VStack(alignment: .leading) {
                        Text(word.arabic)
                            .font(.title)
                        Text(word.transliteration)
                            .font(.subheadline)
                        Text(word.translation)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Arabic Words")
        }
        .onAppear {
            if isFirstLaunch && WordsManager.shared.hasWords(modelContext: modelContext) == false {
                WordsManager.shared.importWordsFromJSON(modelContext: modelContext)
                isFirstLaunch = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ArabicWord.self, inMemory: true)
}
