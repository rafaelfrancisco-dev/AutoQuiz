//
//  AnalyticsView.swift
//  AutoQuiz
//

import SwiftUI

struct AnalyticsView: View {
    @Environment(AppStore.self) private var appStore

    @State private var selectedTimeRange: TimeRange = .thisWeek
    @State private var selectedRevisionSelection: ContentRevisionSelection = .current
    @State private var analyticsService: AnalyticsService?
    @State private var timeRangeMetrics: TimeRangeMetrics?
    @State private var learningProgress: LearningProgress?
    @State private var isLoading = true

    let document: Item?

    init(document: Item? = nil) {
        self.document = document
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let metrics = timeRangeMetrics {
                        timeRangeSelector

                        if document != nil {
                            versionSelector
                        }

                        overviewSection(metrics.overview)

                        if !metrics.accuracyTrend.isEmpty {
                            accuracyTrendSection(metrics.accuracyTrend)
                        }

                        if !metrics.sessionTypeBreakdown.isEmpty {
                            questionTypeSection(metrics.sessionTypeBreakdown)
                        }

                        learningProgressSection

                        if !metrics.sessions.isEmpty {
                            recentSessionsSection(metrics.sessions.suffix(5))
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle(document?.title ?? "Performance Analytics")
            .onAppear {
                setupAnalyticsService()
                loadAnalytics()
            }
            .task(id: appStore.isReady) {
                setupAnalyticsService()
                loadAnalytics()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                loadAnalytics()
            }
            .onChange(of: selectedRevisionSelection) { _, _ in
                loadAnalytics()
            }
        }
    }

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Period")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var versionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content Version")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Content Version", selection: $selectedRevisionSelection) {
                ForEach(revisionOptions, id: \.self) { selection in
                    Text(selection.displayName(for: document))
                        .tag(selection)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func overviewSection(_ overview: PerformanceOverview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Total Sessions",
                    value: "\(overview.totalSessions)",
                    subtitle: "\(overview.completedSessions) completed",
                    color: .blue
                )

                MetricCard(
                    title: "Overall Accuracy",
                    value: "\(Int(overview.overallAccuracy))%",
                    subtitle: "\(overview.totalCorrectAnswers)/\(overview.totalQuestionsAnswered) correct",
                    color: .green
                )

                MetricCard(
                    title: "Total Points",
                    value: "\(overview.totalPointsEarned)",
                    subtitle: "Points earned",
                    color: .orange
                )

                MetricCard(
                    title: "Avg. Session",
                    value: formatDuration(overview.averageSessionDuration),
                    subtitle: "Average duration",
                    color: .purple
                )
            }
        }
    }

    private func accuracyTrendSection(_ trend: [AccuracyTrend]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy Trend")
                .font(.title2)
                .fontWeight(.semibold)

            AccuracyTrendChart(data: trend)
                .frame(height: 200)
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func questionTypeSection(_ metrics: [SessionTypeMetrics]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance by Question Type")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(metrics, id: \.questionType) { metric in
                QuestionTypeCard(metric: metric)
            }
        }
    }

    private var learningProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Progress")
                .font(.title2)
                .fontWeight(.semibold)

            if let progress = learningProgress {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MetricCard(
                        title: "Current Streak",
                        value: "\(progress.currentStreak)",
                        subtitle: "Perfect sessions",
                        color: .red
                    )

                    MetricCard(
                        title: "Best Streak",
                        value: "\(progress.bestStreak)",
                        subtitle: "Personal best",
                        color: .indigo
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trend")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(progress.recentPerformanceTrend.displayName)
                            .font(.headline)
                            .foregroundColor(colorForTrend(progress.recentPerformanceTrend))
                    }

                    Spacer()

                    if progress.improvementRate != 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Improvement")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(progress.improvementRate > 0 ? "+" : "")\(String(format: "%.1f", progress.improvementRate))%")
                                .font(.headline)
                                .foregroundColor(progress.improvementRate > 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(Color.platformControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func recentSessionsSection<T: Collection>(_ sessions: T) -> some View where T.Element == QuizSession {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(Array(sessions), id: \.id) { session in
                SessionCard(session: session)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Analytics Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete some quizzes to see your performance analytics here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func setupAnalyticsService() {
        guard let store = appStore.persistenceStore else { return }
        analyticsService = AnalyticsService(store: store)
    }

    private func loadAnalytics() {
        guard let analyticsService else { return }

        isLoading = true

        Task {
            async let metrics = analyticsService.getTimeRangeMetrics(
                for: selectedTimeRange,
                document: document,
                sourceContentRevision: selectedSourceContentRevision
            )

            async let learningProgress = analyticsService.getLearningProgress(
                for: selectedTimeRange,
                document: document,
                sourceContentRevision: selectedSourceContentRevision
            )

            let (resolvedMetrics, resolvedProgress) = await (metrics, learningProgress)

            await MainActor.run {
                self.timeRangeMetrics = resolvedMetrics
                self.learningProgress = resolvedProgress
                self.isLoading = false
            }
        }
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
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuestionTypeCard: View {
    let metric: SessionTypeMetrics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.questionType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(metric.sessionCount) sessions • \(metric.totalQuestions) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(metric.averageAccuracy))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("accuracy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionCard: View {
    let session: QuizSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.questionType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.accuracyPercentage))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(session.accuracyPercentage >= 80 ? .green : session.accuracyPercentage >= 60 ? .orange : .red)

                Text("\(session.questionsCorrect)/\(session.questionsAttempted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(session.isCompleted ? .green : .red)
        }
        .padding()
        .background(Color.platformControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AnalyticsView()
        .environment(AppStore())
}
