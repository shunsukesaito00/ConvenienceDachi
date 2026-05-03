import SwiftUI

struct VisitedInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount = 300
    @State private var usesPicker = false
    @State private var selectedCategories: Set<PurchaseCategory> = []

    let onSave: (Int?, [PurchaseCategory]) -> Void
    private let presets = [300, 500, 800, 1000]
    private let pickerAmounts = Array(stride(from: 0, through: 3000, by: 10))

    private var amount: Int? {
        selectedAmount == 0 ? nil : selectedAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日のコンビニ支出")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.ink)
                        Text("記録できただけで前進です。")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.mutedInk)
                    }

                    Text("いくら使いましたか？")
                        .font(.headline)
                        .foregroundStyle(Color.ink)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            ChoiceButton(title: "\(preset.formatted())円", isSelected: selectedAmount == preset) {
                                selectedAmount = preset
                                usesPicker = false
                            }
                        }
                        ChoiceButton(title: "10円単位", isSelected: usesPicker) {
                            usesPicker = true
                        }
                    }

                    if usesPicker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("金額")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.mutedInk)
                            Picker("金額", selection: $selectedAmount) {
                                ForEach(pickerAmounts, id: \.self) { amount in
                                    Text(amount == 0 ? "未入力" : "\(amount.formatted())円").tag(amount)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 130)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("買ったもの")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(PurchaseCategory.allCases) { category in
                                ChoiceButton(title: category.rawValue, isSelected: selectedCategories.contains(category)) {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }

                    Button("記録する") {
                        onSave(amount, Array(selectedCategories))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(18)
            }
            .background(Color.warmSurface.ignoresSafeArea())
            .navigationTitle("今日のコンビニ支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color.softGreen : Color.white)
                .foregroundStyle(isSelected ? Color.brandNavy : Color.ink)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.brandGreen : Color.black.opacity(0.10), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
