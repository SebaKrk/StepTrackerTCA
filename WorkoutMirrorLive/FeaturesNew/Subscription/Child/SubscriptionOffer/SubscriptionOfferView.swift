//
//  SubscriptionOfferView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SubscriptionOfferFeature.self)
struct SubscriptionOfferView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SubscriptionOfferFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    if showsRecordedSummary {
                        recordedSummary
                    }
                    benefits
                    productsSection
                    if store.strategy == .appManaged {
                        basicNote
                    }
                }
                .padding()
                .animation(.default, value: store.isLoading)
                .animation(.default, value: store.selectedProductID)
            }
            .safeAreaBar(edge: .bottom) {
                actions
            }
            .toolbar {
                closeToolbarItem
            }
            .background(backgroundGradient)
            .onAppear {
                send(.onAppear)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            crownBadge
            title
            subtitle
        }
        .frame(maxWidth: .infinity)
    }

    private var recordedSummary: some View {
        HStack(spacing: 8) {
            recordedTile(store.recordedWorkouts, label: "Workouts")
            recordedTile(store.savedPlans, label: "Plans")
            recordedTile(store.personalRecords, label: "Records")
        }
        .transition(.opacity)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 10) {
            benefitRow("Full history of workouts and plans")
            benefitRow("Statistics, analytics and exercises")
            benefitRow("Training readiness with explanation")
            benefitRow("More board scans every day")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var productsSection: some View {
        if store.isLoading {
            loadingView
        } else if store.hasLoadFailed {
            loadFailedView
        } else {
            productList
        }
    }

    private var productList: some View {
        VStack(spacing: 10) {
            ForEach(store.products) { product in
                productRow(product)
            }
        }
        .transition(.opacity)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            if store.hasPurchaseFailed {
                purchaseFailedText
            }
            if let days = store.freeTrialDays, let product = store.selectedProduct {
                freeTrialTerms(days: days, product: product)
            }
            purchaseButton
            stayOnBasicButton
            restoreButton
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.default, value: store.hasPurchaseFailed)
        .animation(.default, value: store.isPurchasing)
    }

    @ToolbarContentBuilder
    private var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            closeButton
        }
    }

    // MARK: - Buttons

    private var closeButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Image(systemName: "xmark")
        }
    }

    private var purchaseButton: some View {
        Button {
            send(.purchaseButtonTapped)
        } label: {
            purchaseButtonLabel
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(ProGold.accent)
        .disabled(store.isPurchasing || store.selectedProduct == nil)
    }

    private var stayOnBasicButton: some View {
        Button {
            send(.stayOnBasicButtonTapped)
        } label: {
            Text("Stay on Basic")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .disabled(store.isPurchasing)
    }

    private var restoreButton: some View {
        Button {
            send(.restoreButtonTapped)
        } label: {
            Text("Restore Purchases")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .disabled(store.isPurchasing)
    }

    private var retryButton: some View {
        Button {
            send(.retryButtonTapped)
        } label: {
            Text("Try Again")
        }
    }

    private func productRow(_ product: SubscriptionProduct) -> some View {
        Button {
            send(.productTapped(product.id))
        } label: {
            productRowLabel(product)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Details

    private var showsRecordedSummary: Bool {
        store.strategy == .appManaged && store.hasRecordedAnything
    }

    private var crownBadge: some View {
        Image(systemName: "crown.fill")
            .font(.title)
            .foregroundStyle(ProGold.gradient)
            .frame(width: 64, height: 64)
            .glassEffect(in: Circle())
    }

    @ViewBuilder
    private var title: some View {
        Group {
            switch store.strategy {
            case .appManaged:
                Text("Your 14 days of Pro are over")
            case .storeIntroOffer:
                Text("Try Pro free for 14 days")
            }
        }
        .font(.title2.bold())
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var subtitle: some View {
        Group {
            switch store.strategy {
            case .appManaged:
                Text("Here is what you recorded in that time.")
            case .storeIntroOffer:
                Text("Everything is unlocked. Cancel anytime before the trial ends.")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    private func recordedTile(_ value: Int, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    private func benefitRow(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.subheadline.bold())
                .foregroundStyle(ProGold.accent)
            Text(text)
                .font(.subheadline)
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .transition(.opacity)
    }

    private var loadFailedView: some View {
        ContentUnavailableView {
            Label("Couldn't load the offer", systemImage: "wifi.exclamationmark")
        } actions: {
            retryButton
        }
        .transition(.opacity)
    }

    private func productRowLabel(_ product: SubscriptionProduct) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    productTitle(product)
                    if let percent = product.savingsPercent {
                        savingsBadge(percent)
                    }
                }
                productSubtitle(product)
            }
            Spacer()
            Text(product.displayPrice)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(ProGold.gradient, lineWidth: 2)
                .opacity(product.id == store.selectedProductID ? 1 : 0)
        }
    }

    @ViewBuilder
    private func productTitle(_ product: SubscriptionProduct) -> some View {
        Group {
            switch product.period {
            case .yearly:
                Text("Yearly")
            case .monthly:
                Text("Monthly")
            }
        }
        .font(.headline)
    }

    @ViewBuilder
    private func productSubtitle(_ product: SubscriptionProduct) -> some View {
        Group {
            if let monthlyPrice = product.displayMonthlyPrice {
                Text("\(monthlyPrice) per month")
            } else {
                Text("Cancel anytime")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func savingsBadge(_ percent: Int) -> some View {
        Text("Save \(percent)%")
            .font(.caption.bold())
            .foregroundStyle(ProGold.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(ProGold.accent.opacity(0.15), in: Capsule())
    }

    @ViewBuilder
    private var purchaseButtonLabel: some View {
        if store.isPurchasing {
            ProgressView()
        } else {
            switch store.strategy {
            case .appManaged:
                Text("Unlock Pro")
                    .font(.headline)
            case .storeIntroOffer:
                Text("Start free trial")
                    .font(.headline)
            }
        }
    }

    private func freeTrialTerms(days: Int, product: SubscriptionProduct) -> some View {
        Group {
            switch product.period {
            case .yearly:
                Text("\(days) days free, then \(product.displayPrice) per year")
            case .monthly:
                Text("\(days) days free, then \(product.displayPrice) per month")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .transition(.opacity)
    }

    private var purchaseFailedText: some View {
        Text("The purchase didn't go through. Try again.")
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .transition(.opacity)
    }

    private var basicNote: some View {
        Text("Your workouts keep being saved and nothing is lost. Without Pro you open the 3 most recent.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [ProGold.lock.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("After 14 days — no card") {
    SubscriptionOfferView(
        store: Store(
            initialState: SubscriptionOfferFeature.State(
                strategyOverride: .appManaged,
                recordedWorkouts: 12,
                savedPlans: 9,
                personalRecords: 4
            )
        ) {
            SubscriptionOfferFeature()
        }
    )
}

#Preview("Free trial — with card") {
    SubscriptionOfferView(
        store: Store(
            initialState: SubscriptionOfferFeature.State(strategyOverride: .storeIntroOffer)
        ) {
            SubscriptionOfferFeature()
        }
    )
}
