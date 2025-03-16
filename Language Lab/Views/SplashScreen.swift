import SwiftUI

struct SplashScreen: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var loadingProgress = 0.0
    
    // Reference to stores to monitor initialization
    @ObservedObject private var letterStore = LetterStore.shared
    @ObservedObject private var wordStore = WordStore.shared
    
    // Callback for when initialization is complete
    var onInitializationComplete: () -> Void
    
    // Timer for smooth animation
    @State private var timer: Timer?
    @State private var actualProgress = 0.0
    @State private var targetProgress = 0.0
    @State private var isDataReady = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 20) {
                    // App logo/icon
                    Image(systemName: "character.book.closed")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(size)
                        .opacity(opacity)
                    
                    // App name
                    Text("Language Lab")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(opacity)
                    
                    // Loading indicator
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: 250, height: 6)
                                .foregroundColor(Color.gray.opacity(0.3))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: 250 * loadingProgress, height: 6)
                                .foregroundColor(.blue)
                                .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                        }
                        
                        Text("Loading resources...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding(20)
            }
        }
        .onAppear {
            // Start the animation
            withAnimation(.easeIn(duration: 1.2)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            
            // Start rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                self.rotation = 360
            }
            
            // Start initialization in background
            DispatchQueue.global(qos: .userInitiated).async {
                // Initialize stores if needed
                if letterStore.letters.isEmpty {
                    letterStore.initializeLetters()
                }
                
                if wordStore.words.isEmpty {
                    wordStore.initializeWords()
                }
                
                // Mark data as ready when both stores are initialized
                DispatchQueue.main.async {
                    self.isDataReady = true
                    self.targetProgress = 1.0
                }
            }
            
            // Set up smooth progress animation
            setupSmoothProgressAnimation()
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func setupSmoothProgressAnimation() {
        // Start with a slow progress that speeds up over time
        // This creates the illusion of loading even if initialization is fast
        
        // Initial target is 80% - we'll reach 100% when data is actually ready
        targetProgress = 0.8
        
        // Create a timer that updates 30 times per second for smooth animation
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            // Calculate how much to move toward target per frame
            // Slower at start, faster at end
            let step = (targetProgress - actualProgress) * 0.05
            
            // Update actual progress
            actualProgress += step
            
            // Update the visible progress
            withAnimation(.linear(duration: 0.03)) {
                loadingProgress = actualProgress
            }
            
            // Check if we should complete
            if isDataReady && actualProgress >= 0.99 {
                // Ensure we reach exactly 1.0
                loadingProgress = 1.0
                
                // Clean up timer
                timer?.invalidate()
                timer = nil
                
                // Wait a moment at 100% before completing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onInitializationComplete()
                }
            }
        }
        
        // Ensure the splash screen lasts at least 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // If data is ready but we're still showing splash screen, complete it
            if isDataReady && timer != nil {
                targetProgress = 1.0
            }
        }
    }
} 