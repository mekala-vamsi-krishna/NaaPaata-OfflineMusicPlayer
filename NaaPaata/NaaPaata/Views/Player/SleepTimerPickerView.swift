//
//  SleepTimerPickerView.swift
//  NaaPaata
//
//  Created by Antigravity on 2/16/26.
//

import SwiftUI

struct SleepTimerPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Sleep Timer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(sleepTimerManager.isTimerActive ? "Timer is active" : "Set a time to stop playback")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                if sleepTimerManager.isTimerActive {
                    // MARK: - Active Timer View
                    VStack(spacing: 20) {
                        Text(sleepTimerManager.formattedTimeRemaining)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.bottom, 32)
                } else {
                    // MARK: - Picker View
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            Picker("Hours", selection: $selectedHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour) h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .tint(AppColors.primary)

                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute) m").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .tint(AppColors.primary)
                        }
                        .frame(height: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }

                // MARK: - Spacer to push button to bottom
                Spacer(minLength: 20)

                // MARK: - Action Button (always at the same position)
                if sleepTimerManager.isTimerActive {
                    Button(action: {
                        sleepTimerManager.stopTimer()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16))
                            Text("Stop Timer")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.red)
                        .cornerRadius(14)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    Button(action: {
                        sleepTimerManager.setTimer(hours: selectedHours, minutes: selectedMinutes)
                        dismiss()
                    }) {
                        Text("Start Timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppColors.primary)
                            .cornerRadius(14)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Preview
#Preview {
    SleepTimerPickerView()
        .environmentObject(SleepTimerManager.shared)
}
