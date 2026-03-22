//
//  AnalyticsView.swift
//  AutoQuiz
//

import SwiftUI

struct AnalyticsView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTimeRange: TimeRange = .thisWeek
    @State private var selectedRevisionSelection: ContentRevisionSelection = .current
    @State private var analyticsService: AnalyticsService?
    @State private var timeRangeMetrics: TimeRangeMetrics?
    @State private var learningProgress: LearningProgress?
    @State private var isLoading = true

    let document: Item?
    private let previewMetrics: TimeRangeMetrics?
    private let previewProgress: LearningProgress?

    init(
        document: Item? = nil,
        previewMetrics: TimeRangeMetrics? = nil,
        previewProgress: LearningProgress? = nil
    ) {
        self.document = document
        self.previewMetrics = previewMetrics
        self.previewProgress = previewProgress
        _timeRangeMetrics = State(initialValue: previewMetrics)
        _learningProgress = State(initialValue: previewProgress)
        _isLoading = State(initialValue: previewMetrics == nil)
    }

    var body: some View {
        AppDashboardModalContainer(title: document?.title ?? "Performance Analytics", maxWidth: 980, onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 20) {
                timeRangeSelector

                if document != nil {
                    versionSelector
                }

                if isLoading {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let metrics = timeRangeMetrics {
                    overviewSection(metrics.overview)

                    if !metrics.accuracyTrend.isEmpty {
                        accuracyTrendSection(metrics.accuracyTrend)
                    }

                    if !metrics.sessionTypeBreakdown.isEmpty {
                        questionTypeSection(metrics.sessionTypeBreakdown)
                    }

                    if let learningProgress {
                        learningProgressSection(learningProgress)
                    }

                    if !metrics.sessions.isEmpty {
                        recentSessionsSection(metrics.sessions.suffix(5))
                    }
                } else {
                    AppEmptyState(
                        title: "No Analytics Data",
                        systemImage: "chart.bar.xaxis",
                        description: "Complete a few quizzes to see performance analytics here."
                    )
                }
            }
            .accessibilityIdentifier("analytics-screen")
        }
        .macModalSize(.dashboard)
        .task(id: reloadID) {
            setupAnalyticsService()
            await loadAnalytics()
        }
    }

    private var reloadID: String {
        "\(appStore.isReady)-\(selectedTimeRange.rawValue)-\(selectedRevisionSelection.displayName(for: document))"
    }

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Period")
                .font(.headline)

            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .appCardStyle()
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

    private func overviewSection(_ overview: PerformanceOverview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title3.weight(.semibold))

            AdaptiveMetricGrid {
                MetricCard(
                    title: "Total Sessions",
                    value: "\(overview.totalSessions)",
                    subtitle: "\(overview.completedSessions) completed",
                    tone: .info
                )
                MetricCard(
                    title: "Overall Accuracy",
                    value: "\(Int(overview.overallAccuracy))%",
                    subtitle: "\(overview.totalCorrectAnswers)/\(overview.totalQuestionsAnswered) correct",
                    tone: .success
                )
                MetricCard(
                    title: "Total Points",
                    value: "\(overview.totalPointsEarned)",
                    subtitle: "Points earned",
                    tone: .warning
                )
                MetricCard(
                    title: "Average Session",
                    value: formatDuration(overview.averageSessionDuration),
                    subtitle: "Average duration",
                    tone: .neutral
                )
            }
        }
    }

    private func accuracyTrendSection(_ trend: [AccuracyTrend]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy Trend")
                .font(.title3.weight(.semibold))

            AccuracyTrendChart(data: trend)
                .frame(height: 220)
                .appCardStyle()
        }
    }

    private func questionTypeSection(_ metrics: [SessionTypeMetrics]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance by Question Type")
                .font(.title3.weight(.semibold))

            ForEach(metrics, id: \.questionType) { metric in
                QuestionTypeCard(metric: metric)
            }
        }
    }

    private func learningProgressSection(_ progress: LearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Progress")
                .font(.title3.weight(.semibold))

            AdaptiveMetricGrid {
                MetricCard(
                    title: "Current Streak",
                    value: "\(progress.currentStreak)",
                    subtitle: "Perfect sessions",
                    tone: .danger
                )
                MetricCard(
                    title: "Best Streak",
                    value: "\(progress.bestStreak)",
                    subtitle: "Personal best",
                    tone: .info
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(progress.recentPerformanceTrend.displayName)
                        .font(.headline)
                        .foregroundStyle(colorForTrend(progress.recentPerformanceTrend))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Improvement")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(progress.improvementRate, format: .number.precision(.fractionLength(1)))%")
                }
                .font(.headline)
                .foregroundStyle(progress.improvementRate >= 0 ? Color.green : .red)
            }
            .appCardStyle()
        }
    }

    private func recentSessionsSection<T: Collection>(_ sessions: T) -> some View where T.Element == QuizSession {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.title3.weight(.semibold))

            ForEach(Array(sessions), id: \.id) { session in
                SessionCard(session: session)
            }
        }
    }

    private func setupAnalyticsService() {
        guard previewMetrics == nil, let store = appStore.persistenceStore else { return }
        analyticsService = AnalyticsService(store: store)
    }

    private func loadAnalytics() async {
        if let previewMetrics {
            timeRangeMetrics = previewMetrics
            learningProgress = previewProgress
            isLoading = false
            return
        }

        guard let analyticsService else {
            isLoading = false
            timeRangeMetrics = nil
            return
        }

        isLoading = true

        async let metrics = analyticsService.getTimeRangeMetrics(
            for: selectedTimeRange,
            document: document,
            sourceContentRevision: selectedSourceContentRevision
        )
        async let progress = analyticsService.getLearningProgress(
            for: selectedTimeRange,
            document: document,
            sourceContentRevision: selectedSourceContentRevision
        )

        let (resolvedMetrics, resolvedProgress) = await (metrics, progress)
        timeRangeMetrics = resolvedMetrics
        learningProgress = resolvedProgress
        isLoading = false
    }

    private var selectedSourceContentRevision: Int? {
        selectedRevisionSelection.resolvedRevision(for: document)
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }

    private func colorForTrend(_ trend: PerformanceTrendDirection) -> Color {
        switch trend {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .blue
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let tone: AppStatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(tone.tint)
                    .frame(width: 10, height: 10)
            }

            Text(value)
                .font(.title2.weight(.bold))

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }
}

struct QuestionTypeCard: View {
    let metric: SessionTypeMetrics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(metric.questionType.displayName)
                    .font(.headline)

                Text("\(metric.sessionCount) sessions • \(metric.totalQuestions) questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(metric.averageAccuracy))%")
                    .font(.title3.weight(.semibold))
                Text("accuracy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCardStyle()
    }
}

struct SessionCard: View {
    let session: QuizSession

    private var accuracyTone: AppStatusTone {
        if session.accuracyPercentage >= 80 {
            return .success
        } else if session.accuracyPercentage >= 60 {
            return .warning
        } else {
            return .danger
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.questionType.displayName)
                    .font(.headline)

                Text(session.startTime, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(session.accuracyPercentage))%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accuracyTone.tint)
                Text("\(session.questionsCorrect)/\(session.questionsAttempted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(session.isCompleted ? .green : .red)
        }
        .appCardStyle()
    }
}

#Preview("Analytics Populated") {
    let item = PreviewData.sampleItem()
    let sessions = PreviewData.sampleQuizSessions(for: item)
    let metrics = TimeRangeMetrics(
        timeRange: .thisWeek,
        sessions: sessions,
        overview: PerformanceOverview(
            totalSessions: sessions.count,
            completedSessions: sessions.filter(\.isCompleted).count,
            totalQuestionsAnswered: sessions.reduce(0) { $0 + $1.questionsAttempted },
            totalCorrectAnswers: sessions.reduce(0) { $0 + $1.questionsCorrect },
            totalPointsEarned: sessions.reduce(0) { $0 + $1.totalPointsEarned },
            averageSessionDuration: 420,
            overallAccuracy: 78,
            completionRate: 0.92
        ),
        accuracyTrend: sessions.enumerated().map { offset, session in
            AccuracyTrend(
                date: Calendar.current.date(byAdding: .day, value: -offset, to: .now) ?? .now,
                accuracy: session.accuracyPercentage,
                questionsCount: session.questionsAttempted
            )
        }.sorted { $0.date < $1.date },
        sessionTypeBreakdown: [
            SessionTypeMetrics(
                questionType: .multipleChoice,
                sessionCount: 3,
                averageAccuracy: 82,
                averageResponseTime: 9,
                totalQuestions: 30,
                bestStreak: 2
            ),
            SessionTypeMetrics(
                questionType: .trueFalse,
                sessionCount: 3,
                averageAccuracy: 74,
                averageResponseTime: 7,
                totalQuestions: 30,
                bestStreak: 1
            )
        ]
    )
    let progress = LearningProgress(
        currentStreak: 2,
        bestStreak: 4,
        improvementRate: 12.4,
        weakestAreas: [],
        strongestAreas: [],
        recentPerformanceTrend: .improving
    )

    return AnalyticsView(document: item, previewMetrics: metrics, previewProgress: progress)
        .environment(AppStore())
}

#Preview("Analytics Empty") {
    AnalyticsView(document: PreviewData.emptyItem(), previewMetrics: nil, previewProgress: nil)
        .environment(AppStore())
}
