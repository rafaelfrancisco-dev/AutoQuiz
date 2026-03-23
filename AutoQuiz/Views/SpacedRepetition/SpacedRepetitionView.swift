//
//  SpacedRepetitionView.swift
//  AutoQuiz
//

import SwiftUI

struct SpacedRepetitionView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var spacedRepetitionService: SpacedRepetitionService?
    @State private var currentSession: SpacedRepetitionSession?
    @State private var showingAnswer = false
    @State private var startTime = Date()
    @State private var isSessionComplete = false
    @State private var sessionStats: SessionStats?
    @State private var selectedRevisionSelection: ContentRevisionSelection = .current
    @State private var isLoadingSession = true

    let document: Item?
    private let previewSession: SpacedRepetitionSession?
    private let previewIsComplete: Bool
    private let previewStats: SessionStats?

    init(
        document: Item? = nil,
        previewSession: SpacedRepetitionSession? = nil,
        previewIsComplete: Bool = false,
        previewStats: SessionStats? = nil
    ) {
        self.document = document
        self.previewSession = previewSession
        self.previewIsComplete = previewIsComplete
        self.previewStats = previewStats
        _currentSession = State(initialValue: previewSession)
        _isSessionComplete = State(initialValue: previewIsComplete)
        _sessionStats = State(initialValue: previewStats)
    }

    var body: some View {
        AppDashboardModalContainer(title: "Spaced Repetition", maxWidth: 900, onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 20) {
                if document != nil {
                    versionSelector
                }

                if let session = currentSession {
                    if isSessionComplete {
                        sessionCompleteView
                    } else {
                        activeSessionView(session: session)
                    }
                } else if isLoadingSession {
                    loadingView
                } else {
                    AppEmptyState(
                        title: "No Cards Due",
                        systemImage: "calendar.badge.clock",
                        description: "No cards are due for review. Generate questions first or check back later."
                    )
                }
            }
            .accessibilityIdentifier("spaced-repetition-screen")
        }
        .macModalSize(.dashboard)
        .task(id: reloadID) {
            await setupServiceIfNeeded()
            await startSession()
        }
    }

    private var reloadID: String {
        "\(appStore.isReady)-\(selectedRevisionSelection.displayName(for: document))"
    }

    @ViewBuilder
    private func activeSessionView(session: SpacedRepetitionSession) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            progressView(session: session)

            if let currentCard = session.currentCard {
                cardView(card: currentCard)

                if showingAnswer {
                    answerSection(card: currentCard)
                } else {
                    Button("Show Answer") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingAnswer = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                AppEmptyState(
                    title: "No Cards Ready",
                    systemImage: "brain",
                    description: "There are no due cards for the selected document version."
                )
            }
        }
    }

    private func progressView(session: SpacedRepetitionSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card \(session.currentCardIndex + 1) of \(session.cards.count)")
                        .font(.title3.weight(.semibold))
                    Text("Review due items and reinforce recent learning.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let card = session.currentCard {
                    DifficultyBadge(difficulty: card.difficultyLevel)
                }
            }

            ProgressView(value: session.progress)
                .tint(.blue)
        }
        .appCardStyle()
    }

    private func cardView(card: SpacedRepetitionCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AppBadge(text: card.questionType.displayName, tone: .neutral)
                Spacer()
                if card.totalReviews > 0 {
                    AppBadge(text: "\(Int(card.accuracyPercentage))% accuracy", tone: .info)
                }
            }

            Text(card.questionText)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appCardStyle()
    }

    private func answerSection(card: SpacedRepetitionCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Answer")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(card.answerText)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppStatusTone.success.subtleBackground, in: .rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppStatusTone.success.subtleBorder, lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("How well did you know this?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                qualityButton(title: "Perfect", subtitle: "Easy recall", quality: 5, tone: .success)
                qualityButton(title: "Good", subtitle: "Correct with effort", quality: 4, tone: .info)
                qualityButton(title: "Hard", subtitle: "Difficult but correct", quality: 3, tone: .warning)
                qualityButton(title: "Wrong", subtitle: "Incorrect answer", quality: 1, tone: .danger)
            }
        }
        .appCardStyle()
    }

    private func qualityButton(title: String, subtitle: String, quality: Int, tone: AppStatusTone) -> some View {
        Button {
            recordAnswer(quality: quality)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
        }
        .buttonStyle(QuizActionButtonStyle(tone: tone))
    }

    private var sessionCompleteView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                AppBadge(text: "Session Complete", tone: .success, systemImage: "checkmark.circle.fill")
                Text("Great work. Your review session is finished.")
                    .font(.title3.weight(.semibold))
            }
            .appCardStyle()

            if let stats = sessionStats {
                AdaptiveMetricGrid {
                    StatCard(title: "Cards Reviewed", value: "\(stats.totalCards)", tone: .info)
                    StatCard(title: "Accuracy", value: "\(Int(stats.accuracy))%", tone: .success)
                    StatCard(title: "Average Time", value: stats.formattedAverageTime, tone: .warning)
                    StatCard(title: "Perfect Recalls", value: "\(stats.perfectRecalls)", tone: .neutral)
                }
            }

            Button("Start New Session") {
                Task {
                    await startSession()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparing your review session...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    private var versionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content Version")
                .font(.headline)
            Picker("Content Version", selection: $selectedRevisionSelection) {
                ForEach(revisionOptions, id: \.self) { selection in
                    Text(selection.displayName(for: document))
                        .tag(selection)
                }
            }
            .pickerStyle(.menu)
        }
        .appCardStyle()
    }

    private func setupServiceIfNeeded() async {
        guard previewSession == nil, let store = appStore.persistenceStore else { return }
        spacedRepetitionService = SpacedRepetitionService(store: store)
    }

    private func startSession() async {
        isLoadingSession = true

        if let previewSession {
            currentSession = previewSession
            isSessionComplete = previewIsComplete
            sessionStats = previewStats
            showingAnswer = previewIsComplete
            isLoadingSession = false
            return
        }

        guard let service = spacedRepetitionService else {
            currentSession = nil
            isLoadingSession = false
            return
        }

        let selectedSourceContentRevision = selectedRevisionSelection.resolvedRevision(for: document)

        if let document {
            let existingCards = await service.getAllCards(
                for: document,
                sourceContentRevision: selectedSourceContentRevision
            )
            let shouldCreateCardsForCurrentRevision =
                selectedSourceContentRevision == nil || selectedSourceContentRevision == document.contentRevision

            if existingCards.isEmpty && shouldCreateCardsForCurrentRevision {
                await service.createCardsFromQuestions(
                    for: document,
                    sourceContentRevision: selectedSourceContentRevision
                )
            }
        }

        currentSession = await service.startReviewSession(
            for: document,
            sourceContentRevision: selectedSourceContentRevision
        )
        showingAnswer = false
        isSessionComplete = false
        sessionStats = nil
        startTime = Date()
        isLoadingSession = false
    }

    private func recordAnswer(quality: Int) {
        guard let service = spacedRepetitionService ?? previewServiceProxy,
              var session = currentSession,
              let currentCard = session.currentCard else { return }

        let responseTime = Date().timeIntervalSince(startTime)

        Task {
            await service.recordReview(card: currentCard, quality: quality, responseTime: responseTime)
        }

        session.moveToNextCard()
        currentSession = session

        if session.isComplete {
            calculateSessionStats(session: session)
            isSessionComplete = true
        } else {
            showingAnswer = false
            startTime = Date()
        }
    }

    private var previewServiceProxy: SpacedRepetitionService? {
        nil
    }

    private func calculateSessionStats(session: SpacedRepetitionSession) {
        let completedCards = session.completedCards
        guard !completedCards.isEmpty else { return }

        let totalCards = completedCards.count
        let correctAnswers = completedCards.filter { $0.correctReviews > 0 }.count
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

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel

    private var tone: AppStatusTone {
        switch difficulty {
        case .easy:
            return .success
        case .medium:
            return .info
        case .hard:
            return .warning
        case .veryHard:
            return .danger
        }
    }

    var body: some View {
        AppBadge(text: difficulty.rawValue, tone: tone)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let tone: AppStatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(tone.tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }
}

struct SessionStats {
    let totalCards: Int
    let accuracy: Double
    let averageTime: TimeInterval
    let perfectRecalls: Int

    var formattedAverageTime: String {
        if averageTime < 60 {
            return averageTime.formatted(.number.precision(.fractionLength(1))) + "s"
        } else {
            let minutes = Int(averageTime) / 60
            let seconds = Int(averageTime) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

#Preview("Spaced Repetition Active") {
    let item = PreviewData.sampleItem()
    let cards = PreviewData.sampleSpacedRepetitionCards(for: item)
    let session = SpacedRepetitionSession(cards: cards, document: item, startTime: .now)

    return SpacedRepetitionView(document: item, previewSession: session)
        .environment(AppStore())
}

#Preview("Spaced Repetition Complete") {
    let item = PreviewData.sampleItem()
    let cards = PreviewData.sampleSpacedRepetitionCards(for: item)
    var session = SpacedRepetitionSession(cards: cards, document: item, startTime: .now)
    session.moveToNextCard()
    session.moveToNextCard()

    return SpacedRepetitionView(
        document: item,
        previewSession: session,
        previewIsComplete: true,
        previewStats: SessionStats(totalCards: 2, accuracy: 100, averageTime: 3.2, perfectRecalls: 1)
    )
    .environment(AppStore())
}
