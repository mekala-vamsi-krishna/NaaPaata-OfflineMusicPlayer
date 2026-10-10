//
//  StatsSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/25/26.
//

import SwiftUI

struct StatsSettingsView: View {

    // MARK: - Aggregated data

    /// Total seconds listened in the current calendar month.
    private var totalSecondsThisMonth: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .month, for: now) else {
            return 0
        }
        return PlaySessionStore.shared
            .sessions(in: interval)
            .reduce(0) { $0 + $1.duration }
    }

    /// 7 rows × 6 columns of accumulated seconds, indexed by
    /// [weekdayIndex 0…6][timeSlot 0…5].
    private var heatmap: [[TimeInterval]] {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .month, for: now) else {
            return emptyGrid
        }

        var grid = emptyGrid

        for session in PlaySessionStore.shared.sessions(in: interval) {
            let weekday = weekdayIndex(for: session.startedAt, calendar: calendar)
            let hour = calendar.component(.hour, from: session.startedAt)
            let slot = TimeSlot.from(hour: hour).rawValue

            grid[weekday][slot] += session.duration
        }
        return grid
    }

    /// Largest cell value — used to normalise intensities.
    private var peakCellSeconds: TimeInterval {
        heatmap.flatMap { $0 }.max() ?? 0
    }

    private var emptyGrid: [[TimeInterval]] {
        Array(repeating: Array(repeating: 0, count: TimeSlot.allCases.count),
              count: 7)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                totalCard
                heatmapCard
            }
            .padding(24)
        }
        .navigationTitle("Stats")
    }

    // MARK: - Total card

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Month")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text(formattedTotal)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()

            Text(formattedTotalCaption)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColor.primary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.15), lineWidth: 1)
        )
    }

    private var formattedTotal: String {
        let total = Int(totalSecondsThisMonth.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var formattedTotalCaption: String {
        let total = Int(totalSecondsThisMonth.rounded())
        if total == 0 {
            return "Play a few songs to start tracking."
        }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") of listening"
        }
        return "\(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s") of listening"
    }

    // MARK: - Heatmap card

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("When You Listen")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                legend
            }

            grid

            Text("Darker cells mean more listening during that time of day.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Grid

    private var grid: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {

            // Header row — time slot labels
            GridRow {
                Color.clear.frame(width: 44, height: 14)

                ForEach(TimeSlot.allCases) { slot in
                    Text(slot.shortLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Seven day rows
            ForEach(0..<7, id: \.self) { dayIndex in
                GridRow {
                    Text(dayLabel(dayIndex))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)

                    ForEach(TimeSlot.allCases) { slot in
                        cell(
                            seconds: heatmap[dayIndex][slot.rawValue]
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func cell(seconds: TimeInterval) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color(for: seconds))
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .help(tooltip(for: seconds))
    }

    // MARK: - Colors

    private func color(for seconds: TimeInterval) -> Color {
        guard peakCellSeconds > 60 else {
            // Not enough data — show empty cells.
            return Color.primary.opacity(0.05)
        }

        let intensity = min(seconds / peakCellSeconds, 1.0)

        switch intensity {
        case ..<0.001: return Color.primary.opacity(0.05)
        case ..<0.25:  return AppColor.primary.opacity(0.22)
        case ..<0.50:  return AppColor.primary.opacity(0.42)
        case ..<0.75:  return AppColor.primary.opacity(0.62)
        default:       return AppColor.primary.opacity(0.90)
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            ForEach(Array(legendColors.enumerated()), id: \.offset) { _, color in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color)
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private var legendColors: [Color] {
        [
            Color.primary.opacity(0.05),
            AppColor.primary.opacity(0.22),
            AppColor.primary.opacity(0.42),
            AppColor.primary.opacity(0.62),
            AppColor.primary.opacity(0.90)
        ]
    }

    // MARK: - Helpers

    private func dayLabel(_ index: Int) -> String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index]
    }

    /// Converts a date into a 0-based weekday index where 0 = Monday.
    private func weekdayIndex(for date: Date, calendar: Calendar) -> Int {
        var cal = calendar
        cal.firstWeekday = 2                  // Monday
        let component = cal.component(.weekday, from: date)
        // component: 1 = Sunday … 7 = Saturday
        // Convert to: 0 = Monday … 6 = Sunday
        return (component + 5) % 7
    }

    private func tooltip(for seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "No listening" }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 1 { return "Less than a minute" }
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}
