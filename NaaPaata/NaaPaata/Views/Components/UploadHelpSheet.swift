//
//  InstructionView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/4/26.
//

import SwiftUI

struct UploadHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    
                    // MARK: Page 1 - Mac Finder
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Upload from Mac")
                                .font(.title2.bold())
                                .padding(.top, 20)
                            
                            // Replace "upload_mac" with your actual image asset name
                            Image("upload_mac")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 350)
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("1. Connect your iPhone to your Mac using a cable.")
                                Text("2. Open **Finder** on your Mac and select your iPhone from the sidebar.")
                                Text("3. Navigate to the **Files** tab.")
                                Text("4. Drag and drop your audio files into the **Naa Paata** folder.")
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 40)
                            
                            Spacer()
                        }
                    }
                    .tag(0)
                    
                    // MARK: Page 2 - iOS Files App
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Upload from Files App")
                                .font(.title2.bold())
                                .padding(.top, 20)
                            
                            // Replace "upload_files" with your actual image asset name
                            Image("upload_files")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 350)
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("1. Open the **Files** app on your iPhone.")
                                Text("2. Navigate to **On My iPhone** → **Naa Paata**.")
                                Text("3. Copy or move your audio files directly into this folder.")
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 32)
                            
                            // Warning Note
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 16))
                                
                                Text("**Note:** If you uninstall the app, you might lose your music files. Make sure to keep a backup of your files!")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                            
                            Spacer()
                        }
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always)) // Shows dots at the bottom
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    UploadHelpSheet()
}
