import SwiftUI
import WidgetKit

@MainActor
final class AppStore: ObservableObject {
    @Published var article: Article?
    @Published var isLoading = true
    /// Guards re-entrant fetches — a second ↻ tap or pull-to-refresh while a
    /// fetch is in flight is ignored rather than racing it.
    @Published var isFetching = false
    @Published var settings: SharedStore.Settings
    @Published var stats: SharedStore.Stats
    /// Set when a widget tap routes an article URL into the app.
    @Published var linkedArticle: Article?

    init() {
        settings = SharedStore.loadSettings()
        stats = SharedStore.loadStats()
    }

    var theme: String {
        get { settings.theme }
        set { update { $0.theme = newValue } }
    }

    func update(_ mutate: (inout SharedStore.Settings) -> Void) {
        let previous = settings
        mutate(&settings)
        SharedStore.saveSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
        // Content settings change what fetchArticles returns — refresh the
        // on-screen article too. Theme/refresh cadence apply in place.
        let contentChanged = previous.language != settings.language
            || Set(previous.topics) != Set(settings.topics)
            || previous.entryLength != settings.entryLength
        if contentChanged { Task { await discover(quiet: true) } }
    }

    func bootstrap() async {
        if let saved = SharedStore.loadLatest() {
            article = saved
            isLoading = false
            await discover(quiet: true)
        } else {
            await discover(quiet: false)
        }
    }

    func discover(quiet: Bool) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        if !quiet && article == nil { isLoading = true }
        defer { isLoading = false }
        guard let articles = try? await WikipediaClient.fetchArticles(settings: settings),
              let next = articles.randomElement() else { return }
        show(next)
        for other in articles { SharedStore.cacheArticle(other) }
    }

    /// Paint an article without a fetch — used by widget deep links.
    func show(_ next: Article) {
        article = next
        SharedStore.saveLatest(next)
        SharedStore.cacheArticle(next)
        SharedStore.bumpStat(\.articles)
        stats = SharedStore.loadStats()
    }

    func handleOpenURL(_ url: URL) {
        // wikipedia-newtab://article/<pageId>
        guard url.scheme == "wikipedia-newtab",
              url.host == "article",
              let pageId = Int(url.pathComponents.dropFirst().first ?? ""),
              let found = SharedStore.cachedArticle(pageId: pageId)
        else { return }
        linkedArticle = found
    }

    func markOpened() {
        SharedStore.bumpStat(\.opened)
        stats = SharedStore.loadStats()
    }
}
