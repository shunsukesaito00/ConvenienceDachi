import SwiftUI

struct AverageSpendPickerControls: View {
    @Binding var amount: Int

    private let presets = [300, 500, 800, 1000]

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    ChoiceButton(title: "\(preset.formatted())円", isSelected: amount == preset) {
                        amount = preset
                    }
                }
            }

            Picker("", selection: $amount) {
                ForEach(UserSettings.allValidSpendAmounts, id: \.self) { value in
                    Text("\(value.formatted())円").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 176)
        }
        .onAppear {
            amount = UserSettings.normalizedSpend(amount)
        }
        .onChange(of: amount) { _, newValue in
            let normalized = UserSettings.normalizedSpend(newValue)
            if normalized != newValue {
                amount = normalized
            }
        }
    }
}

struct ReminderTimePickerControls: View {
    @Binding var time: String

    private let presets = ["20:00", "21:00", "22:00"]

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    ChoiceButton(title: preset, isSelected: time == preset) {
                        time = preset
                    }
                }
            }

            Picker("", selection: $time) {
                ForEach(UserSettings.allQuarterHourTimeStrings, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 176)
        }
        .onAppear {
            time = UserSettings.normalizedReminderTime(time)
        }
        .onChange(of: time) { _, newValue in
            let normalized = UserSettings.normalizedReminderTime(newValue)
            if normalized != newValue {
                time = normalized
            }
        }
    }
}
