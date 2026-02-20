//
//  SpacedRepetitionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 22/06/2025.
//

import SwiftUI
import SwiftData

struct SpacedRepetitionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var spacedRepetitionService: SpacedRepetitionService?
    @State private var currentSession: SpacedRepetitionSession?
    @State private var showingAnswer = false
    @State private var startTime = Date()
    @State private var isSessionComplete = false
    @State private var sessionStats: SessionStats?
    @State private var selectedRevisionSelection: ContentRevisionSelection = .current
    
    let document: Item?
    
    init(document: Item? = nil) {
        self.document = document
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if document != nil {
                    versionSelector
                }
                
                if let session = currentSession {
                    if !isSessionComplete {
                        activeSessionView(session: session)
                    } else {
                        sessionCompleteView
                    }
                } else {
                    loadingView
                }
            }
            .padding()
            .navigationTitle("Spaced Repetition")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if isSessionComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if isSessionComplete {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                #endif
            }
        }
        .onAppear {
            setupService()
            startSession()
        }
        .onChange(of: selectedRevisionSelection) { _, _ in
            startSession()
        }
    }
    
    // MARK: - Active Session View
    
    @ViewBuilder
    private func activeSessionView(session: SpacedRepetitionSession) -> some View {
        VStack(spacing: 24) {
            // Progress indicator
            progressView(session: session)
            
            if let currentCard = session.currentCard {
                // Card content
                cardView(card: currentCard)
                
                // Answer section
                if showingAnswer {
                    answerSection(card: currentCard)
                } else {
                    showAnswerButton
                }
            }
        }
    }
    
    private func progressView(session: SpacedRepetitionSession) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Card \(session.currentCardIndex + 1) of \(session.cards.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let card = session.currentCard {
                    DifficultyBadge(difficulty: card.difficultyLevel)
                }
            }
            
            ProgressView(value: session.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 6)
                .scaleEffect(x: 1, y: 1.5)
        }
    }
    
    private func cardView(card: SpacedRepetitionCard) -> some View {
        VStack(spacing: 16) {
            // Question type indicator
            HStack {
                Image(systemName: card.questionType == .multipleChoice ? "list.bullet.circle" : "checkmark.circle")
                    .foregroundColor(.secondary)
                
                Text(card.questionType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if card.totalReviews > 0 {
                    Text("\(Int(card.accuracyPercentage))% accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Question text
            Text(card.questionText)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var showAnswerButton: some View {
        Button("Show Answer") {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAnswer = true
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
    
    private func answerSection(card: SpacedRepetitionCard) -> some View {
        VStack(spacing: 20) {
            // Answer text
            VStack(spacing: 8) {
                Text("Answer")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(card.answerText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Quality buttons
            VStack(spacing: 12) {
                Text("How well did you know this?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    qualityButton(title: "Perfect", subtitle: "Easy recall", quality: 5, color: .green)
                    qualityButton(title: "Good", subtitle: "Correct with effort", quality: 4, color: .blue)
                    qualityButton(title: "Hard", subtitle: "Difficult but correct", quality: 3, color: .orange)
                    qualityButton(title: "Wrong", subtitle: "Incorrect answer", quality: 1, color: .red)
                }
            }
        }
    }
    
    private func qualityButton(title: String, subtitle: String, quality: Int, color: Color) -> some View {
        Button {
            recordAnswer(quality: quality)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(color)
    }
    
    // MARK: - Session Complete View
    
    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            if let stats = sessionStats {
                VStack(spacing: 16) {
                    Text("Great work! Here's how you did:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(title: "Cards Reviewed", value: "\(stats.totalCards)", color: .blue)
                        StatCard(title: "Accuracy", value: "\(Int(stats.accuracy))%", color: .green)
                        StatCard(title: "Average Time", value: stats.formattedAverageTime, color: .orange)
                        StatCard(title: "Perfect Recalls", value: "\(stats.perfectRecalls)", color: .purple)
                    }
                }
            }
            
            Button("Start New Session") {
                startSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Preparing your review session...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var versionSelector: some View {
        HStack {
            Picker("Content Version", selection: $selectedRevisionSelection) {
                ForEach(revisionOptions, id: \.self) { selection in
                    Text(selection.displayName(for: document))
                        .tag(selection)
                }
            }
            .pickerStyle(.menu)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupService() {
        spacedRepetitionService = SpacedRepetitionService(modelContext: modelContext)
    }
    
    private func startSession() {
        guard let service = spacedRepetitionService else { return }
        let selectedSourceContentRevision = selectedRevisionSelection.resolvedRevision(for: document)
        
        // Check if we need to create cards for this document
        if let document = document {
            let existingCards = service.getAllCards(
                for: document,
                sourceContentRevision: selectedSourceContentRevision
            )
            let shouldCreateCardsForCurrentRevision =
                selectedSourceContentRevision == nil || selectedSourceContentRevision == document.contentRevision
            
            if existingCards.isEmpty && shouldCreateCardsForCurrentRevision {
                Task {
                    await service.createCardsFromQuestions(
                        for: document,
                        sourceContentRevision: selectedSourceContentRevision
                    )
                    await MainActor.run {
                        self.currentSession = service.startReviewSession(
                            for: document,
                            sourceContentRevision: selectedSourceContentRevision
                        )
                    }
                }
                return
            }
        }
        
        // Start session with existing cards
        currentSession = service.startReviewSession(
            for: document,
            sourceContentRevision: selectedSourceContentRevision
        )
        showingAnswer = false
        isSessionComplete = false
        sessionStats = nil
        startTime = Date()
    }
    
    private func recordAnswer(quality: Int) {
        guard let service = spacedRepetitionService,
              var session = currentSession,
              let currentCard = session.currentCard else { return }
        
        let responseTime = Date().timeIntervalSince(startTime)
        service.recordReview(card: currentCard, quality: quality, responseTime: responseTime)
        
        // Move to next card
        session.moveToNextCard()
        currentSession = session
        
        if session.isComplete {
            // Calculate session statistics
            calculateSessionStats(session: session)
            isSessionComplete = true
        } else {
            // Reset for next card
            showingAnswer = false
            startTime = Date()
        }
    }
    
    private func calculateSessionStats(session: SpacedRepetitionSession) {
        let completedCards = session.completedCards
        guard !completedCards.isEmpty else { return }
        
        let totalCards = completedCards.count
        let correctAnswers = completedCards.filter { $0.correctReviews > 0 }.count // Simplified
        let accuracy = totalCards > 0 ? Double(correctAnswers) / Double(totalCards) * 100 : 0
        let averageTime = completedCards.reduce(0.0) { $0 + $1.averageResponseTime } / Double(totalCards)
        let perfectRecalls = completedCards.filter { $0.easinessFactor > 2.4 }.count
        
        sessionStats = SessionStats(
            totalCards: totalCards,
            accuracy: accuracy,
            averageTime: averageTime,
            perfectRecalls: perfectRecalls
        )
    }
    
    private var revisionOptions: [ContentRevisionSelection] {
        guard let document else {
            return [.current]
        }
        
        var options: [ContentRevisionSelection] = [.current]
        options.append(contentsOf: document.availableContentRevisions
            .filter { $0 != document.contentRevision }
            .map(ContentRevisionSelection.revision))
        return options
    }
}

// MARK: - Supporting Views

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(colorForDifficulty.opacity(0.2))
            .foregroundColor(colorForDifficulty)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var colorForDifficulty: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .veryHard: return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Types

struct SessionStats {
    let totalCards: Int
    let accuracy: Double
    let averageTime: TimeInterval
    let perfectRecalls: Int
    
    var formattedAverageTime: String {
        if averageTime < 60 {
            return String(format: "%.1fs", averageTime)
        } else {
            let minutes = Int(averageTime) / 60
            let seconds = Int(averageTime) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

#Preview {
    SpacedRepetitionView()
        .modelContainer(for: [Item.self, SpacedRepetitionCard.self], inMemory: true)
}
