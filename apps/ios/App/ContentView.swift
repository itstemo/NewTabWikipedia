import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var showSettings = false
    @State private var zoomedArticle: Article?
    @State private var safariURL: URL?

    private var palette: Palette { Palette.forScheme(scheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                if let article = store.article {
                    articleView(article)
                } else if store.isLoading {
                    ProgressView().tint(palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(palette.paper)
        .refreshable { await store.discover(quiet: true) }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .sheet(item: $store.linkedArticle) { article in
            LinkedArticleView(article: article)
        }
        .fullScreenCover(item: $zoomedArticle) { article in
            PlateViewer(article: article)
        }
        .sheet(isPresented: Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )) {
            if let url = safariURL { SafariView(url: url).ignoresSafeArea() }
        }
        .task { await store.bootstrap() }
    }

    private var topBar: some View {
        HStack {
            Text("WIKIPEDIA")
                .font(.mono(11, weight: .medium))
                .tracking(2)
                .foregroundStyle(palette.muted)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15))
                    .foregroundStyle(palette.muted)
                    .padding(6)
            }
            .accessibilityLabel("Settings")
            Button { Task { await store.discover(quiet: true) } } label: {
                Text("↻")
                    .font(.serif(26))
                    .foregroundStyle(palette.accent)
                    .padding(6)
            }
            .accessibilityLabel("Find another article")
        }
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    private func articleView(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !article.description.isEmpty {
                Text(article.description)
                    .font(Font.serifItalic(15))
                    .foregroundStyle(palette.muted)
                    .padding(.bottom, 10)
            }

            Text(article.title)
                .font(.serif(38, weight: .semibold))
                .foregroundStyle(palette.ink)
                .padding(.bottom, 22)

            Rectangle()
                .fill(palette.ruleStrong)
                .frame(height: 1)
                .padding(.bottom, 20)

            if article.imageURL != nil {
                Button { zoomedArticle = article } label: {
                    plate(article)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View this plate at full size")
                .padding(.bottom, 24)
            } else {
                plate(article)
                    .padding(.bottom, 24)
            }

            Text(article.extract)
                .font(.serif(17.5))
                .lineSpacing(11)
                .foregroundStyle(palette.ink)
                .textSelection(.enabled)

            HStack(spacing: 28) {
                Button {
                    store.markOpened()
                    safariURL = article.url
                } label: {
                    Text("READ THE FULL ENTRY  →")
                        .font(.mono(11, weight: .medium))
                        .tracking(1.3)
                        .foregroundStyle(palette.accent)
                        .underline()
                }
                ShareLink(item: article.url) {
                    Text("SHARE")
                        .font(.mono(11, weight: .medium))
                        .tracking(1.3)
                        .foregroundStyle(palette.muted)
                }
            }
            .padding(.top, 30)
        }
    }

    private func plate(_ article: Article) -> some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                fallbackPlate(article)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipped()
        .overlay(Rectangle().stroke(palette.rule, lineWidth: 1))
    }

    private func fallbackPlate(_ article: Article) -> some View {
        palette.paperDeep.overlay(
            Text(article.title.prefix(1).uppercased())
                .font(.serif(72))
                .foregroundStyle(palette.muted)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No article yet")
                .font(.serif(30, weight: .semibold))
                .foregroundStyle(palette.ink)
            Text("Connect to the internet to discover your first article.")
                .font(.serif(16))
                .foregroundStyle(palette.muted)
            Button("TRY AGAIN") {
                Task { await store.discover(quiet: false) }
            }
            .font(.mono(13, weight: .medium))
            .foregroundStyle(palette.paper)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(palette.accent)
            .padding(.top, 12)
        }
        .padding(.top, 40)
    }
}

/// The article a widget tap carried in — resolved from the shared cache.
struct LinkedArticleView: View {
    let article: Article
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var safariURL: URL?

    private var palette: Palette { Palette.forScheme(scheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("WIKIPEDIA")
                        .font(.mono(11, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(palette.muted)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.mono(13))
                        .foregroundStyle(palette.accent)
                }
                .padding(.bottom, 40)

                if !article.description.isEmpty {
                    Text(article.description)
                        .font(Font.serifItalic(15))
                        .foregroundStyle(palette.muted)
                        .padding(.bottom, 10)
                }
                Text(article.title)
                    .font(.serif(34, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .padding(.bottom, 20)
                Rectangle().fill(palette.ruleStrong).frame(height: 1).padding(.bottom, 20)
                Text(article.extract)
                    .font(.serif(17))
                    .lineSpacing(10)
                    .foregroundStyle(palette.ink)
                Button {
                    safariURL = article.url
                } label: {
                    Text("READ THE FULL ENTRY  →")
                        .font(.mono(11, weight: .medium))
                        .tracking(1.3)
                        .foregroundStyle(palette.accent)
                        .underline()
                        .padding(.top, 26)
                }
            }
            .padding(24)
        }
        .background(palette.paper)
        .sheet(isPresented: Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )) {
            if let url = safariURL { SafariView(url: url).ignoresSafeArea() }
        }
    }
}
