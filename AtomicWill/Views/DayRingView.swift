//
//  DayRingView.swift
//  AtomicWill
//

import SwiftUI

/// A single progress ring. Values above 1 wrap into a second lap, like the Activity rings.
struct ProgressRing: View {
    /// `nil` means nothing is scheduled, so only a faint track is drawn.
    var progress: Double?
    var color: Color
    var lineWidth: CGFloat

    private var clamped: Double { min(max(progress ?? 0, 0), 2) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(progress == nil ? 0.08 : 0.22), lineWidth: lineWidth)

            if progress != nil {
                Circle()
                    .trim(from: 0, to: min(clamped, 1))
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                if clamped > 1 {
                    // Second lap: completed more than the goal.
                    Circle()
                        .trim(from: 0, to: clamped - 1)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .black.opacity(0.35), radius: lineWidth * 0.25)
                }
            }
        }
        .padding(lineWidth / 2)
        .animation(.smooth, value: clamped)
    }
}

/// The day's single ring, with optional content in the middle.
struct DayRingView<Center: View>: View {
    var summary: DaySummary
    /// Ring thickness as a fraction of the view's size.
    var thickness: CGFloat = 0.12
    @ViewBuilder var center: Center

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                ProgressRing(progress: summary.progress, color: .dayRing, lineWidth: max(size * thickness, 2))
                center
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(summary.accessibilityDescription))
    }
}

extension DayRingView where Center == EmptyView {
    init(summary: DaySummary, thickness: CGFloat = 0.12) {
        self.init(summary: summary, thickness: thickness) { EmptyView() }
    }
}

extension DaySummary {
    var accessibilityDescription: String {
        guard let progress else { return String(localized: "Nothing scheduled") }
        let percent = progress.formatted(.percent.precision(.fractionLength(0)))
        let parts = SummaryCategory.allCases.compactMap { category -> String? in
            guard let value = value(for: category) else { return nil }
            return "\(String(localized: category.title)) \(value.formatted(.percent.precision(.fractionLength(0))))"
        }
        return String(localized: "\(percent) complete") + ", " + parts.formatted(.list(type: .and))
    }
}

/// The ring with a breakdown by category, shown at the top of a day's list.
struct DaySummaryHeader: View {
    var summary: DaySummary

    var body: some View {
        HStack(spacing: 24) {
            DayRingView(summary: summary, thickness: 0.13) {
                VStack(spacing: 0) {
                    if let progress = summary.progress {
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                            .font(.title2.weight(.bold).monospacedDigit())
                            .contentTransition(.numericText(value: progress))
                        if summary.isComplete {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Color.dayRing)
                        }
                    } else {
                        Text("—")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(SummaryCategory.allCases, id: \.self) { category in
                    breakdownRow(for: category)
                }
                if summary.hasBrokenLimit {
                    Label("Limit exceeded", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func breakdownRow(for category: SummaryCategory) -> some View {
        HStack(spacing: 8) {
            Text(category.title)
                .foregroundStyle(.secondary)
                .frame(minWidth: 56, alignment: .leading)
            if let value = summary.value(for: category) {
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: value))
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("None scheduled")
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    DaySummaryHeader(summary: DaySummary(progress: 0.8, daily: 1, goals: 0.6, tasks: nil, hasBrokenLimit: true))
        .padding()
}
