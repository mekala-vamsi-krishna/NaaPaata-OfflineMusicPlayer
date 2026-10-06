//
//  SubscriptionsView.swift
//  NaaPaata
//

import SwiftUI
import StoreKit

struct SubscriptionsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager

    @State private var selectedProductID: String = "Naa_Paata_12M"

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    heroIcon
                        .padding(.bottom, 20)

                    titleBlock
                        .padding(.bottom, 24)

                    featureHighlight
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    planSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    subscribeButton
                        .padding(.horizontal, 24)

                    restoreButton
                        .padding(.top, 12)

                    termsRow
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }

            // MARK: Processing overlay
            if store.isPurchasing {
                purchaseProcessingOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: store.isPurchasing)
        // 👇 Dismiss only when the flag actually flips to true.
        //    This fires for purchases, restores, and any path that
        //    unlocks the entitlement — no more guessing after `purchase()`.
        .onChange(of: store.isPremimumUser) { _, isPremium in
            if isPremium { dismiss() }
        }
        .task {
            await store.refreshEntitlements()
            if store.isPremimumUser { dismiss() }
        }
        .alert(item: $store.purchaseError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        // ❌ Deleted: "Success!" alert. StoreKit's own confirmation is
        //    the success signal, and `onChange` dismisses the screen.
        .alert("Restore Purchases", isPresented: $store.showRestoredAlert) {
            Button("OK") {
                store.showRestoredAlert = false
                if store.isPremimumUser { dismiss() }
            }
        } message: {
            Text(store.restoredMessage)
        }
    }

    // MARK: - Processing overlay

    private var purchaseProcessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                VStack(spacing: 4) {
                    Text("Processing your purchase")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("This can take a moment.\nPlease don't close the app.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.35),
                    Color.black.opacity(0.0),
                    Color.accentColor.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.4),
                    .clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 320
            )
        }
    }

    // MARK: - Hero icon

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.5),
                            Color.accentColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.accentColor.opacity(0.7), radius: 20, y: 6)
        }
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Unlock the Equalizer")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Feature highlight

    private var featureHighlight: some View {
        HStack(spacing: 14) {

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Advanced Equalizer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text("10 bands • Bass, Treble, Pre-Amp • Custom presets")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .layoutPriority(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Plans

    @ViewBuilder
    private var planSection: some View {
        if store.subscriptions.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(height: 84)
        } else {
            VStack(spacing: 10) {
                ForEach(store.subscriptions, id: \.id) { product in
                    PlanRow(
                        product: product,
                        isSelected: selectedProductID == product.id
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedProductID = product.id
                        }
                    }
                }
            }
        }
    }

    // MARK: - CTA

    private var subscribeButton: some View {
        Button(action: purchase) {
            HStack(spacing: 8) {
                if store.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.45), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing || store.subscriptions.isEmpty)
        .opacity(store.subscriptions.isEmpty ? 0.5 : 1)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Terms

    private var termsRow: some View {
        HStack(spacing: 10) {
            Button("Terms") { }
            Text("•")
                .foregroundStyle(.white.opacity(0.3))
            Button("Privacy") { }
        }
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.4))
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = store.subscriptions.first(where: {
            $0.id == selectedProductID
        }) else { return }

        Task {
            await store.purchase(product)
            // No dismiss here — `.onChange(of: store.isPremimumUser)`
            // handles it the moment the flag flips. Calling dismiss()
            // here would race the flag update.
        }
    }
}

// MARK: - Plan row

private struct PlanRow: View {

    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    private var badge: String? {
        switch product.id {
        case "Naa_Paata_6M":  return "POPULAR"
        case "Naa_Paata_12M": return "BEST VALUE"
        default:              return nil
        }
    }

    private var savings: String? {
        switch product.id {
        case "Naa_Paata_6M":  return "Save 17%"
        case "Naa_Paata_12M": return "Save 33%"
        default:              return nil
        }
    }

    private var periodLabel: String {
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .month:
            let count = subscription.subscriptionPeriod.value
            return count == 1 ? "per month" : "every \(count) months"
        case .year:
            return "per year"
        case .week:
            return "per week"
        case .day:
            return "per day"
        @unknown default:
            return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.white.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }

                    if let savings {
                        Text(savings)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Text(periodLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? Color.accentColor : .white)

                    Text(periodLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.12)
                            : Color.white.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
