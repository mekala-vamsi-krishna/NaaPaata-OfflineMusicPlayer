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
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Sleep Timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(sleepTimerManager.isTimerActive ? "Timer is active: \(sleepTimerManager.formattedTimeRemaining)" : "Set a time to stop playback")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 24)
            
            if sleepTimerManager.isTimerActive {
                // Active timer view
                VStack(spacing: 16) {
                    Text(sleepTimerManager.formattedTimeRemaining)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        sleepTimerManager.stopTimer()
                        dismiss()
                    }) {
                        Text("Stop Timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.red.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 24)
            } else {
                // Picker view
                HStack(spacing: 0) {
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0..<24) { hour in
                            Text("\(hour) h").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) m").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 150)
                .padding(.horizontal, 16)
                
                // Actions
                VStack(spacing: 12) {
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            Color(red: 0.1, green: 0.05, blue: 0.2)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }
}

// Add a helper to SleepTimerManager to get current values if we wanted to pre-fill picker
// For now, defaults are 0h 30m

#Preview {
    SleepTimerPickerView()
        .environmentObject(SleepTimerManager.shared)
}

