//
//  AccuracyTrendChart.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI

struct AccuracyTrendChart: View {
    let data: [AccuracyTrend]
    
    private let chartHeight: CGFloat = 120
    private let pointRadius: CGFloat = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accuracy Over Time")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let latest = data.last {
                    Text("\(Int(latest.accuracy))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            if data.count >= 2 {
                GeometryReader { geometry in
                    let width = geometry.size.width - 32 // Account for padding
                    let height = chartHeight
                    
                    ZStack {
                        // Grid lines
                        gridLines(width: width, height: height)
                        
                        // Chart line and points
                        chartContent(width: width, height: height)
                        
                        // Y-axis labels
                        yAxisLabels(height: height)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: chartHeight + 20)
            } else {
                Text("Not enough data points to show trend")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            }
            
            // X-axis labels (dates)
            if data.count >= 2 {
                xAxisLabels
            }
        }
        .padding(.vertical, 12)
    }
    
    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Horizontal grid lines (accuracy percentages)
            for i in 0...4 {
                let y = height - (CGFloat(i) * height / 4)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
        }
        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
    }
    
    private func chartContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Chart line
            chartLine(width: width, height: height)
            
            // Data points
            chartPoints(width: width, height: height)
        }
    }
    
    private func chartLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            guard data.count >= 2 else { return }
            
            let points = calculatePoints(width: width, height: height)
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: [.blue, .green],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func chartPoints(width: CGFloat, height: CGFloat) -> some View {
        let points = calculatePoints(width: width, height: height)
        
        return ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            Circle()
                .fill(colorForAccuracy(data[index].accuracy))
                .frame(width: pointRadius * 2, height: pointRadius * 2)
                .position(point)
        }
    }
    
    private func yAxisLabels(height: CGFloat) -> some View {
        VStack {
            ForEach(0..<5) { i in
                HStack {
                    Text("\(100 - i * 25)%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: height / 4)
            }
        }
        .frame(height: height)
    }
    
    private var xAxisLabels: some View {
        HStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, trend in
                if data.count <= 7 || index % max(1, data.count / 5) == 0 {
                    Text(trend.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func calculatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        
        let xStep = width / CGFloat(data.count - 1)
        
        return data.enumerated().map { index, trend in
            let x = CGFloat(index) * xStep
            let y = height - (CGFloat(trend.accuracy) / 100.0 * height)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func colorForAccuracy(_ accuracy: Double) -> Color {
        switch accuracy {
        case 90...100:
            return .green
        case 70..<90:
            return .orange
        default:
            return .red
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
        .frame(height: 200)
        .padding()
        .background(Color.gray.opacity(0.1))
}