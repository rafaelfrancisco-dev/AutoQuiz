//
//  AccuracyTrendChart.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI

struct AccuracyTrendChart: View {
    let data: [AccuracyTrend]

    private let chartHeight: CGFloat = 140
    private let pointRadius: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accuracy Over Time")
                        .font(.headline)

                    Text("Daily average performance for the selected range.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let latest = data.last {
                    AppBadge(text: "\(Int(latest.accuracy))%", tone: tone(for: latest.accuracy))
                }
            }

            if data.count >= 2 {
                chartBody
                    .frame(height: chartHeight)

                xAxisLabels
            } else {
                AppEmptyState(
                    title: "Not Enough Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "Complete more quiz sessions to see an accuracy trend."
                )
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var chartBody: some View {
        GeometryReader { geometry in
            let plotWidth = max(geometry.size.width - 28, 1)
            let plotHeight = geometry.size.height
            let points = calculatePoints(width: plotWidth, height: plotHeight)

            ZStack(alignment: .leading) {
                gridLines(width: plotWidth, height: plotHeight)

                Path { path in
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(tone(for: data[index].accuracy).tint)
                        .frame(width: pointRadius * 2, height: pointRadius * 2)
                        .position(point)
                        .accessibilityLabel("\(Int(data[index].accuracy)) percent on \(data[index].date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .padding(.leading, 28)
        }
    }

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Path { path in
                for index in 0...4 {
                    let y = height - (CGFloat(index) * height / 4)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.platformBorder.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            VStack(alignment: .leading, spacing: 0) {
                ForEach([100, 75, 50, 25, 0], id: \.self) { label in
                    Text("\(label)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private var xAxisLabels: some View {
        HStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, trend in
                if shouldShowLabel(for: index) {
                    Text(trend.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.leading, 28)
    }

    private func shouldShowLabel(for index: Int) -> Bool {
        data.count <= 6 || index == 0 || index == data.count - 1 || index.isMultiple(of: max(data.count / 4, 1))
    }

    private func calculatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        let xStep = width / CGFloat(max(data.count - 1, 1))

        return data.enumerated().map { index, trend in
            CGPoint(
                x: CGFloat(index) * xStep,
                y: height - (CGFloat(trend.accuracy) / 100 * height)
            )
        }
    }

    private func tone(for accuracy: Double) -> AppStatusTone {
        switch accuracy {
        case 90...:
            return .success
        case 70..<90:
            return .warning
        default:
            return .danger
        }
    }
}

#Preview {
    let sampleData = [
        AccuracyTrend(date: Date().addingTimeInterval(-6 * 24 * 3600), accuracy: 65, questionsCount: 10),
        AccuracyTrend(date: Date().addingTimeInterval(-5 * 24 * 3600), accuracy: 72, questionsCount: 8),
        AccuracyTrend(date: Date().addingTimeInterval(-4 * 24 * 3600), accuracy: 80, questionsCount: 12),
        AccuracyTrend(date: Date().addingTimeInterval(-3 * 24 * 3600), accuracy: 85, questionsCount: 15),
        AccuracyTrend(date: Date().addingTimeInterval(-2 * 24 * 3600), accuracy: 78, questionsCount: 9),
        AccuracyTrend(date: Date().addingTimeInterval(-1 * 24 * 3600), accuracy: 90, questionsCount: 11),
        AccuracyTrend(date: Date(), accuracy: 95, questionsCount: 14)
    ]

    AccuracyTrendChart(data: sampleData)
        .padding()
}
