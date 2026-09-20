import SwiftUI
import WidgetKit

// MARK: - Timeline

struct ArticleEntry: TimelineEntry {
    let date: Date
    let article: Article
    let image: UIImage?

    static let sample = ArticleEntry(
        date: .now,
        article: Article(
            pageId: 819,
            title: "Bicycle",
            description: "Pedal-driven two-wheel vehicle",
            extract: "A bicycle is a pedal-driven, human-powered, single-track vehicle with two wheels attached to a frame, one behind the other.",
            url: URL(string: "https://en.wikipedia.org/wiki/Bicycle")!,
            imageURL: nil
        ),
        image: nil
    )
}

/// The widget feeds itself: when WidgetKit asks for a timeline, the provider
/// fetches a fresh batch of articles and schedules them at the configured
/// interval. The app is only needed to change settings — the widget keeps
/// refreshing on its own, one timeline at a time, within iOS's reload budget.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ArticleEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (ArticleEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        Task {
            completion(await currentEntry() ?? .sample)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArticleEntry>) -> Void) {
        Task {
            let settings = SharedStore.loadSettings()
            let interval = TimeInterval(max(settings.refreshMinutes, 15) * 60)
            let now = Date()

            var articles = (try? await WikipediaClient.fetchArticles(settings: settings, limit: 4)) ?? []
            if articles.isEmpty, let latest = SharedStore.loadLatest() {
                articles = [latest]
            }

            var entries: [ArticleEntry] = []
            for (index, article) in articles.prefix(4).enumerated() {
                SharedStore.cacheArticle(article) // so a tap resolves later
                let image = await fetchImage(article)
                entries.append(ArticleEntry(
                    date: now.addingTimeInterval(interval * Double(index)),
                    article: article,
                    image: image
                ))
            }

            // Never hand back an empty timeline — the widget must always draw.
            if entries.isEmpty { entries.append(.sample) }

            // .atEnd: WidgetKit calls back once the last entry is shown.
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }

    private func currentEntry() async -> ArticleEntry? {
        if let latest = SharedStore.loadLatest() {
            return ArticleEntry(date: .now, article: latest, image: await fetchImage(latest))
        }
        return nil
    }

    private func fetchImage(_ article: Article) async -> UIImage? {
        guard let url = article.imageURL else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - View

struct WikipediaWidgetView: View {
    let entry: ArticleEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    private var palette: Palette { Palette.forScheme(scheme) }
    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        HStack(alignment: .top, spacing: isSmall ? 0 : 14) {
            VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
                HStack {
                    Text("WIKIPEDIA")
                        .font(.mono(10, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(palette.muted)
                    Spacer(minLength: 0)
                    Text("↗")
                        .font(.mono(10))
                        .foregroundStyle(palette.muted)
                }

                Text(entry.article.title)
                    .font(.serif(isSmall ? 20 : 22, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(isSmall ? 3 : 2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Text(isSmall && !entry.article.description.isEmpty
                     ? entry.article.description
                     : entry.article.extract)
                    .font(Font.serifItalic(isSmall ? 12 : 12.5))
                    .foregroundStyle(palette.muted)
                    .lineLimit(isSmall ? 2 : 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if !isSmall, let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 96, height: 120)
                    .clipped()
                    .overlay(Rectangle().stroke(palette.rule, lineWidth: 1))
            }
        }
        .padding(14)
        .widgetURL(URL(string: "wikipedia-newtab://article/\(entry.article.pageId)"))
        .containerBackground(palette.paper, for: .widget)
    }
}

// MARK: - Widget

struct WikipediaWidget: Widget {
    let kind = "WikipediaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WikipediaWidgetView(entry: entry)
        }
        .configurationDisplayName("Random Wikipedia")
        .description("A random Wikipedia article on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct WikipediaWidgets: WidgetBundle {
    var body: some Widget {
        WikipediaWidget()
    }
}
