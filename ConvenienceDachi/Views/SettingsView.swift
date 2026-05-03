import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    @State private var showingSpendEditor = false
    @State private var showingTimeEditor = false

    private let goalOptions = [5, 10, 15, 20, 25]

    private var spendBinding: Binding<Int> {
        Binding(
            get: { store.settings.averageSpendAmount },
            set: { store.setAverageSpendAmount($0) }
        )
    }

    private var reminderBinding: Binding<String> {
        Binding(
            get: { store.settings.reminderTime },
            set: { store.setReminderTime($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本設定") {
                    Button {
                        showingSpendEditor = true
                    } label: {
                        HStack {
                            Text("平均支出額：\(store.settings.averageSpendAmount.formatted())円")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Picker("月間目標", selection: $store.settings.monthlyGoalDays) {
                        ForEach(goalOptions, id: \.self) { day in
                            Text("\(day)日").tag(day)
                        }
                    }
                }

                Section("通知") {
                    Toggle("通知", isOn: $store.settings.reminderEnabled)
                    Button {
                        showingTimeEditor = true
                    } label: {
                        HStack {
                            Text("通知時刻：\(store.settings.reminderTime)")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("広告") {
                    Toggle("広告を削除", isOn: $store.settings.adsRemoved)
                    Stepper("記録後の広告：\(store.settings.interstitialFrequency)回に1回", value: $store.settings.interstitialFrequency, in: 1...10)
                }

                Section("情報") {
                    Link("サポート", destination: URL(string: "https://shunsukesaito00.github.io/ConvenienceDachi/support.html")!)
                    Link("利用規約", destination: URL(string: "https://shunsukesaito00.github.io/ConvenienceDachi/terms.html")!)
                    Link("プライバシーポリシー", destination: URL(string: "https://shunsukesaito00.github.io/ConvenienceDachi/privacy.html")!)
                }

                Section {
                    Button("データをリセット", role: .destructive) {
                        showingResetAlert = true
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("記録データをすべて削除しますか？", isPresented: $showingResetAlert) {
                Button("削除する", role: .destructive) {
                    store.resetAllData()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません。")
            }
            .sheet(isPresented: $showingSpendEditor) {
                NavigationStack {
                    VStack(spacing: 8) {
                        Text("10円単位で調整できます。")
                            .font(.subheadline)
                            .foregroundStyle(Color.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AverageSpendPickerControls(amount: spendBinding)
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .navigationTitle("平均支出額")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showingSpendEditor = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingTimeEditor) {
                NavigationStack {
                    VStack(spacing: 8) {
                        Text("15分単位で調整できます。")
                            .font(.subheadline)
                            .foregroundStyle(Color.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ReminderTimePickerControls(time: reminderBinding)
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .navigationTitle("通知時刻")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showingTimeEditor = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}
