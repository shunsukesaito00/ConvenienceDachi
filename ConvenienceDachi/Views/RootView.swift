import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color.brandNavy)
    }
}

struct MainTabView: View {
    @State private var showingSettings = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "checkmark.circle") }

            CalendarScreen()
                .tabItem { Label("カレンダー", systemImage: "calendar") }

            ReportView()
                .tabItem { Label("レポート", systemImage: "chart.bar") }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.top, 6)
            .padding(.trailing, 12)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
