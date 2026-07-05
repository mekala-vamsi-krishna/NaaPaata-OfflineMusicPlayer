//
//  InstructionView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/4/26.
//

import SwiftUI

struct InstructionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Image("InstructionImage")
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * 0.6
                            )
                            .clipped()

                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                                .padding(.top, 2)

                            Text("Once your songs or music folder are added to **Naa Paata** folder in the files app, **close the app and reopen app** again")
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            AppColors.primary.opacity(0.12)
                                .cornerRadius(16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                }
                .background(
                    LinearGradient(
                        colors: [
                            AppColors.background,
                            AppColors.background.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .navigationTitle("How to Use?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    InstructionView()
}
