import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    private var palette: Palette { Palette.forScheme(scheme) }
    private var isEnglish: Bool { store.settings.language == "en" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    appearance
                    language
                    entryLength
                    sections
                    widget
                    progress
                }
                .padding(24)
            }
            .background(palette.paper)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.mono(13))
                        .foregroundStyle(palette.accent)
                }
            }
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.mono(10, weight: .medium))
            .tracking(1.4)
            .foregroundStyle(palette.muted)
            .padding(.bottom, 4)
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("APPEARANCE")
            Picker("Appearance", selection: Binding(
                get: { store.settings.theme },
                set: { v in store.update { $0.theme = v } }
            )) {
                Text("Device").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    private var language: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("LANGUAGE")
            Picker("Language", selection: Binding(
                get: { store.settings.language },
                set: { v in store.update { $0.language = v } }
            )) {
                ForEach(WikipediaClient.languages, id: \.code) { lang in
                    Text(lang.label).tag(lang.code)
                }
            }
            .tint(palette.ink)
            if !isEnglish {
                Text("Sections are drawn from English Wikipedia categories.")
                    .font(.mono(11))
                    .foregroundStyle(palette.faint)
            }
        }
    }

    private var entryLength: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("ENTRY LENGTH")
            Picker("Entry length", selection: Binding(
                get: { store.settings.entryLength },
                set: { v in store.update { $0.entryLength = v } }
            )) {
                Text("Brief").tag("brief")
                Text("Standard").tag("standard")
                Text("Long").tag("long")
            }
            .pickerStyle(.segmented)
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 4) {
            heading("SECTIONS")
            ForEach(WikipediaClient.topics, id: \.id) { topic in
                Toggle(isOn: Binding(
                    get: { store.settings.topics.contains(topic.id) },
                    set: { on in
                        store.update { s in
                            if on && !s.topics.contains(topic.id) { s.topics.append(topic.id) }
                            if !on { s.topics.removeAll { $0 == topic.id } }
                        }
                    }
                )) {
                    Text(topic.label)
                        .font(.mono(14))
                        .foregroundStyle(palette.ink)
                }
                .tint(palette.accent)
                .disabled(!isEnglish)
                .opacity(isEnglish ? 1 : 0.45)
            }
        }
    }

    private var widget: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("WIDGET REFRESH")
            Picker("Refresh every", selection: Binding(
                get: { store.settings.refreshMinutes },
                set: { v in store.update { $0.refreshMinutes = v } }
            )) {
                Text("1 hour").tag(60)
                Text("3 hours").tag(180)
                Text("6 hours").tag(360)
                Text("12 hours").tag(720)
                Text("Daily").tag(1440)
            }
            .tint(palette.ink)
            Text("iOS schedules the exact refresh time; this sets the gap between articles.")
                .font(.mono(11))
                .foregroundStyle(palette.faint)
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("YOUR PROGRESS")
            HStack(spacing: 32) {
                stat(store.stats.articles, "articles encountered")
                stat(store.stats.opened, "full entries opened")
            }
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(value)")
                .font(.serif(28))
                .foregroundStyle(palette.ink)
            Text(label.uppercased())
                .font(.mono(9))
                .tracking(1)
                .foregroundStyle(palette.muted)
        }
    }
}
