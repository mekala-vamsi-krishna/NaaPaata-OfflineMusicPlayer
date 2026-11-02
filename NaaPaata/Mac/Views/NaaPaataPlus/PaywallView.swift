//
//  PaywallView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/5/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject private var store: StoreManager

    @State private var selectedProductID: String = "Naa_Paata_12M"
    @State private var purchasingProductID: String?

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("slider.vertical.3",
         "10-Band Parametric Equalizer",
         "Fine-tune your sound with precise control across ten frequency bands."),
        ("waveform.path.ecg",
         "Live Spectrum Analyzer",
         "See your music come alive with a real-time FFT display."),
        ("square.stack.3d.up",
         "Unlimited Custom Presets",
         "Save, rename, and browse your own EQ curves."),
        ("arrow.left.arrow.right",
         "A/B Comparison",
         "Compare two curves side by side with one click."),
        ("gauge.with.needle",
         "Headroom & Clip Detection",
         "Keep your sound clean with real-time peak metering."),
    ]

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if store.isPremimumUser {
                subscribedScrollView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    content
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }

            if store.isPurchasing {
                purchaseProcessingOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isPremimumUser)
        .animation(.easeInOut(duration: 0.2), value: store.isPurchasing)
        .task {
            if store.subscriptions.isEmpty {
                await store.loadProducts()
            }
            await store.refreshEntitlements()
        }
        .alert(item: $store.purchaseError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Restore Purchases", isPresented: $store.showRestoredAlert) {
            Button("OK") { store.showRestoredAlert = false }
        } message: {
            Text(store.restoredMessage)
        }
    }

    // MARK: - Subscribed scroll wrapper
    
    private var subscribedScrollView: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                subscribedState
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
            }
        }
    }

    // MARK: - Processing overlay

    private var purchaseProcessingOverlay: some View {
        ZStack {
            // Dim the paywall behind the overlay
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                VStack(spacing: 4) {
                    Text("Processing your purchase")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("This can take a moment. Please don't close the app.")
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
            .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {

            planSection
                .padding(.top, 32)

            restoreLink
                .padding(.top, 16)

            divider
                .padding(.top, 32)

            featureSection
                .padding(.top, 28)

            legalSection
                .padding(.top, 40)
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle accent glow behind the header for depth
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.10),
                    Color.accentColor.opacity(0.02),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 480
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Plans

    private var planSection: some View {
        HStack(alignment: .top, spacing: 12) {

            if store.subscriptions.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonCard
                }
            } else {
                ForEach(store.subscriptions, id: \.id) { product in
                    planCard(product)
                }
            }
        }
    }

    private var skeletonCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .frame(height: 230)
            .frame(maxWidth: .infinity)
            .overlay(
                ProgressView()
                    .controlSize(.small)
            )
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isThisPurchasing = purchasingProductID == product.id
        let badge = badgeLabel(for: product)
        let savings = savingsLabel(for: product)

        return VStack(alignment: .leading, spacing: 0) {

            // Badge row
            Group {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color.accentColor,
                                             Color.accentColor.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                } else {
                    Color.clear.frame(height: 18)
                }
            }

            Spacer().frame(height: 14)

            // Plan name
            Text(shortLabel(for: product))
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            Spacer().frame(height: 8)

            // Price
            Text(product.displayPrice)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Period
            Text(periodLabel(for: product))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 3)

            // Savings or per-month
            Group {
                if let savings {
                    Text(savings)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.green)
                } else if let perMonth = perMonthLabel(for: product) {
                    Text(perMonth)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                } else {
                    Color.clear
                }
            }
            .frame(height: 14)
            .padding(.top, 8)

            Spacer(minLength: 16)

            // Inline Subscribe button
            subscribeButton(for: product,
                            isSelected: isSelected,
                            isPurchasing: isThisPurchasing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 230, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.08)
                        : Color.primary.opacity(0.04)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? Color.accentColor
                        : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 0.75
                )
        )
        .shadow(
            color: isSelected
                ? Color.accentColor.opacity(0.15)
                : .clear,
            radius: 14,
            y: 6
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                selectedProductID = product.id
            }
        }
    }

    private func subscribeButton(
        for product: Product,
        isSelected: Bool,
        isPurchasing: Bool
    ) -> some View {
        Button {
            purchase(product)
        } label: {
            HStack(spacing: 6) {
                if isPurchasing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(isPurchasing ? "Processing…" : "Subscribe")
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor,
                                        Color.accentColor.opacity(0.85)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                Color.primary.opacity(0.15),
                                lineWidth: 1
                            )
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(purchasingProductID != nil)
    }

    // MARK: - Restore

    private var restoreLink: some View {
        Button("Restore Purchases") {
            Task { await store.restorePurchases() }
        }
        .buttonStyle(.plain)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 0.5)
    }

    // MARK: - Features

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("EVERYTHING INCLUDED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    featureRow(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        showDivider: index < features.count - 1
                    )
                }
            }
        }
    }

    private func featureRow(
        icon: String,
        title: String,
        subtitle: String,
        showDivider: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {

            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 50)
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 12) {

            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in System Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)

            HStack(spacing: 16) {
                Button("Terms of Use") {
                    openURL("https://doc-hosting.flycricket.io/naa-paata-terms-of-use/e91b4e23-3903-4bd3-a751-796f7fa41b75/terms")
                }
                .underline()
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Button("Privacy Policy") {
                    openURL("https://doc-hosting.flycricket.io/naa-paata-privacy-policy/18f4820c-07e6-431e-85ad-d228302f8335/privacy")
                }
                .underline()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium)) // Increased size for reviewers
            .foregroundStyle(.primary) // Changed to primary so it stands out
        }
    }

    // MARK: - Subscribed state

    private var subscribedState: some View {
        VStack(spacing: 0) {

            Spacer(minLength: 40)

            // MARK: Badge
            successBadge
                .padding(.bottom, 24)

            // MARK: Headline
            VStack(spacing: 8) {
                Text("You're all set.")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Naa Paata + is active on this Mac.\nThe full Equalizer is unlocked.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 36)

            // MARK: How to open the Equalizer
            VStack(alignment: .leading, spacing: 14) {

                Text("OPEN THE EQUALIZER")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.0)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)

                shortcutRow

                menuBarRow
            }
            .frame(maxWidth: 340)
            .padding(.horizontal, 40)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Success badge

    private var successBadge: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 72, weight: .regular))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.78, blue: 0.42),
                        Color(red: 0.12, green: 0.62, blue: 0.32)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.green.opacity(0.35), radius: 20, y: 8)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    // MARK: - Shortcut row

    private var shortcutRow: some View {
        HStack(spacing: 14) {

            shortcutBadge

            VStack(alignment: .leading, spacing: 2) {
                Text("Press the shortcut")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Opens the Equalizer from anywhere in the app.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var shortcutBadge: some View {
        HStack(spacing: 3) {
            Text("⌘")
                .font(.system(size: 15, weight: .medium))
            Text("E")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.primary)
        .frame(minWidth: 40, minHeight: 32)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
    }

    // MARK: - Menu bar row

    private var menuBarRow: some View {
        HStack(spacing: 14) {

            menuBarBadge

            VStack(alignment: .leading, spacing: 2) {
                Text("Or use the menu bar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text("Window")
                    Text("›")
                        .foregroundStyle(.tertiary)
                    Text("Equalizer")
                }
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var menuBarBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .frame(width: 40, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.75)
                )
                .shadow(color: .black.opacity(0.08), radius: 1, y: 1)

            Image(systemName: "menubar.rectangle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Helpers

    private var selectedProduct: Product? {
        store.subscriptions.first { $0.id == selectedProductID }
    }

    private func shortLabel(for product: Product) -> String {
        switch product.id {
        case "Naa_Paata_1M":  return "1 MONTH"
        case "Naa_Paata_6M":  return "6 MONTHS"
        case "Naa_Paata_12M": return "12 MONTHS"
        default:              return product.displayName.uppercased()
        }
    }

    private func periodLabel(for product: Product) -> String {
        guard let sub = product.subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month:
            let count = sub.subscriptionPeriod.value
            return count == 1 ? "per month" : "every \(count) months"
        case .year:  return "per year"
        case .week:  return "per week"
        case .day:   return "per day"
        @unknown default: return ""
        }
    }

    private func badgeLabel(for product: Product) -> String? {
        switch product.id {
        case "Naa_Paata_6M":  return "MOST POPULAR"
        case "Naa_Paata_12M": return "BEST VALUE"
        default:              return nil
        }
    }

    private func savingsLabel(for product: Product) -> String? {
        switch product.id {
        case "Naa_Paata_6M":  return "Save 17%"
        case "Naa_Paata_12M": return "Save 33%"
        default:              return nil
        }
    }

    /// Renders the "≈ $X.XX / month" line for plans without a savings label.
    /// Falls back to nil when the price math can't be derived.
    private func perMonthLabel(for product: Product) -> String? {
        // Only shown for the 1-month plan (others have savings labels).
        guard product.id == "Naa_Paata_1M" else { return nil }
        return "Billed monthly"
    }

    private func purchase(_ product: Product) {
        purchasingProductID = product.id
        Task {
            await store.purchase(product)
            purchasingProductID = nil
        }
    }

    private func openURL(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}
