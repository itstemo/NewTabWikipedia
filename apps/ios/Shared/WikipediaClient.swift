import Foundation

/// Port of the filter and request logic shared with the Chrome extension
/// (apps/chrome-extension/newtab.js). Keep the reject patterns and extract
/// limits in step — they exist to keep sports seasons, election tables and
/// one-line stubs out of the feed.
enum WikipediaClient {
    static let minExtract = 300

    static let entryLengths: [String: Int] = [
        "brief": 340, "standard": 640, "long": 1100,
    ]

    /// Curated sections — real English Wikipedia category titles.
    static let topics: [(id: String, label: String, category: String)] = [
        ("physics", "Physics", "Category:Physics"),
        ("history", "History", "Category:History"),
        ("mathematics", "Mathematics", "Category:Mathematics"),
        ("technology", "Technology", "Category:Technology"),
        ("geography", "Geography", "Category:Geography"),
        ("art", "Art", "Category:Art"),
        ("music", "Music", "Category:Music"),
        ("literature", "Literature", "Category:Literature"),
    ]

    static let languages: [(code: String, label: String)] = [
        ("en", "English"), ("es", "Español"), ("de", "Deutsch"),
        ("fr", "Français"), ("it", "Italiano"), ("pt", "Português"),
        ("nl", "Nederlands"), ("pl", "Polski"), ("sv", "Svenska"),
        ("ja", "日本語"),
    ]

    static let rejectDescription = try! NSRegularExpression(
        pattern: #"\b(sports? season|football season|association football|footballer|cricketer|baseball player|basketball player|ice hockey player|rugby|olympic|election|census-designated|unincorporated community|village in|commune in|genus of|species of (moth|fly|beetle|snail))\b"#,
        options: .caseInsensitive)

    static let rejectTitle = try! NSRegularExpression(
        pattern: #"^(List of|\d{4}[–-]\d{2,4} |\d{4} (FIFA|UEFA|NCAA|Summer|Winter))"#,
        options: .caseInsensitive)

    static func apiBase(language: String) -> String {
        "https://\(language).wikipedia.org/w/api.php"
    }

    static func randomURL(language: String, limit: Int = 12) -> URL {
        components(language: language, query: [
            "action": "query", "format": "json", "formatversion": "2", "origin": "*",
            "generator": "random", "grnnamespace": "0", "grnlimit": "\(limit)",
            "prop": "extracts|pageimages|description|info",
            "exintro": "1", "explaintext": "1", "exsentences": "5",
            "piprop": "thumbnail|original", "pithumbsize": "900", "inprop": "url",
        ])
    }

    static func categoryMembersURL(category: String, language: String, limit: Int = 500) -> URL {
        components(language: language, query: [
            "action": "query", "format": "json", "formatversion": "2", "origin": "*",
            "list": "categorymembers", "cmtitle": category,
            "cmnamespace": "0", "cmtype": "page", "cmlimit": "\(limit)",
        ])
    }

    static func pageLookupURL(pageIds: [Int], language: String) -> URL {
        components(language: language, query: [
            "action": "query", "format": "json", "formatversion": "2", "origin": "*",
            "pageids": pageIds.map(String.init).joined(separator: "|"),
            "prop": "extracts|pageimages|description|info",
            "exintro": "1", "explaintext": "1", "exsentences": "5",
            "piprop": "thumbnail|original", "pithumbsize": "900", "inprop": "url",
        ])
    }

    private static func components(language: String, query: [String: String]) -> URL {
        var c = URLComponents(string: apiBase(language: language))!
        c.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c.url!
    }

    private static func fetch(_ url: URL) async throws -> WikiQueryResponse {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(WikiQueryResponse.self, from: data)
    }

    static func keep(_ page: WikiQueryResponse.Page) -> Bool {
        guard let title = page.title, let extract = page.extract,
              extract.trimmingCharacters(in: .whitespaces).count >= minExtract,
              page.fullurl != nil else { return false }
        if matches(rejectTitle, in: title) { return false }
        if let description = page.description, matches(rejectDescription, in: description) {
            return false
        }
        return true
    }

    private static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    static func trim(_ text: String, to maxLength: Int) -> String {
        let clean = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        guard clean.count > maxLength else { return clean }
        let cut = String(clean.prefix(maxLength))
        for mark in [". ", "? ", "! "] {
            if let stop = cut.range(of: mark, options: .backwards),
               cut.distance(from: cut.startIndex, to: stop.lowerBound) > Int(Double(maxLength) * 0.5) {
                return String(cut[...stop.lowerBound])
            }
        }
        return cut.trimmingCharacters(in: .whitespaces) + "…"
    }

    static func toArticle(_ page: WikiQueryResponse.Page, entryLength: String = "standard") -> Article? {
        guard keep(page),
              let pageId = page.pageid,
              let title = page.title?.trimmingCharacters(in: .whitespaces),
              let urlString = page.fullurl, let url = URL(string: urlString)
        else { return nil }
        return Article(
            pageId: pageId,
            title: title,
            description: page.description?.trimmingCharacters(in: .whitespaces) ?? "",
            extract: trim(page.extract ?? "", to: entryLengths[entryLength] ?? 640),
            url: url,
            imageURL: (page.thumbnail?.source ?? page.original?.source).flatMap(URL.init(string:))
        )
    }

    /// One batch of usable articles honoring the user's settings. Curated
    /// sections are English categories, so other languages draw pure random.
    static func fetchArticles(settings: SharedStore.Settings, limit: Int = 12) async throws -> [Article] {
        let language = settings.language
        let categories = language == "en"
            ? settings.topics.compactMap { id in topics.first { $0.id == id }?.category }
            : []

        let pages: [WikiQueryResponse.Page]
        if categories.isEmpty {
            pages = try await fetch(randomURL(language: language, limit: limit)).query?.pages ?? []
        } else {
            let members = try await withThrowingTaskGroup(of: WikiQueryResponse.self) { group in
                for category in categories {
                    group.addTask { try await fetch(categoryMembersURL(category: category, language: language)) }
                }
                var all: [WikiQueryResponse.Member] = []
                for try await response in group {
                    all += response.query?.categorymembers ?? []
                }
                return all
            }
            let ids = Array(Set(members.compactMap(\.pageid)).shuffled().prefix(48))
            guard !ids.isEmpty else { return [] }
            pages = try await fetch(pageLookupURL(pageIds: ids, language: language)).query?.pages ?? []
        }
        return pages.compactMap { toArticle($0, entryLength: settings.entryLength) }
    }
}
