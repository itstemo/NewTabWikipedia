import Foundation

/// Everything the app and the widget extension share, persisted in the App
/// Group container. The widget reads settings and the article cache; the app
/// writes both.
enum SharedStore {
    static let appGroup = "group.com.temo.wikipedia.newtab"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    // MARK: Settings

    struct Settings: Codable {
        var theme: String = "system"        // system | light | dark
        var language: String = "en"
        var topics: [String] = []           // curated topic ids; en only
        var entryLength: String = "standard" // brief | standard | long
        var refreshMinutes: Int = 360       // widget cadence
    }

    static func loadSettings() -> Settings {
        guard let data = defaults.data(forKey: "settings"),
              let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else { return Settings() }
        return settings
    }

    static func saveSettings(_ settings: Settings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: "settings")
        }
    }

    // MARK: Article cache

    /// Articles keyed by pageId so a widget tap can resolve its entry even
    /// hours later. Capped — the cache is a lookup table, not a history.
    static func cacheArticle(_ article: Article) {
        var cache = articleCache()
        cache[String(article.pageId)] = article
        if cache.count > 60 {
            for key in cache.keys.prefix(cache.count - 60) { cache.removeValue(forKey: key) }
        }
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: "articleCache")
        }
    }

    static func cachedArticle(pageId: Int) -> Article? {
        articleCache()[String(pageId)]
    }

    private static func articleCache() -> [String: Article] {
        guard let data = defaults.data(forKey: "articleCache"),
              let cache = try? JSONDecoder().decode([String: Article].self, from: data)
        else { return [:] }
        return cache
    }

    /// The most recent article, for cold starts and offline fallback.
    static func loadLatest() -> Article? {
        guard let data = defaults.data(forKey: "latestArticle") else { return nil }
        return try? JSONDecoder().decode(Article.self, from: data)
    }

    static func saveLatest(_ article: Article) {
        if let data = try? JSONEncoder().encode(article) {
            defaults.set(data, forKey: "latestArticle")
        }
    }

    // MARK: Stats

    struct Stats: Codable {
        var articles: Int = 0
        var opened: Int = 0
    }

    static func loadStats() -> Stats {
        guard let data = defaults.data(forKey: "stats"),
              let stats = try? JSONDecoder().decode(Stats.self, from: data)
        else { return Stats() }
        return stats
    }

    static func bumpStat(_ keyPath: WritableKeyPath<Stats, Int>) {
        var stats = loadStats()
        stats[keyPath: keyPath] += 1
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: "stats")
        }
    }
}
