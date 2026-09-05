import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  Linking,
  Pressable,
  RefreshControl,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import {
  fetchRandomArticles,
  type WikipediaArticle,
} from '@newtabwikipedia/wikipedia';

import { loadSavedArticle, saveArticle } from './src/articleStorage';
import WikipediaWidget, { type WikipediaWidgetProps } from './src/widgets/WikipediaWidget';

const WIDGET_INTERVAL_MS = 6 * 60 * 60 * 1000;

function toWidgetProps(article: WikipediaArticle): WikipediaWidgetProps {
  return {
    title: article.title,
    description: article.description,
    extract: article.extract,
    url: article.url,
  };
}

function scheduleWidgetArticles(articles: WikipediaArticle[]): void {
  const usable = articles.slice(0, 6);
  if (!usable.length) return;

  WikipediaWidget.updateSnapshot(toWidgetProps(usable[0]));
  WikipediaWidget.updateTimeline(
    usable.map((article, index) => ({
      date: new Date(Date.now() + index * WIDGET_INTERVAL_MS),
      props: toWidgetProps(article),
    })),
  );
}

export default function App() {
  const [article, setArticle] = useState<WikipediaArticle | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    void bootstrap();
  }, []);

  async function bootstrap(): Promise<void> {
    const saved = await loadSavedArticle();
    if (saved) {
      setArticle(saved);
      scheduleWidgetArticles([saved]);
      setIsLoading(false);
      void discover(true);
      return;
    }

    await discover(false);
  }

  async function discover(quiet: boolean): Promise<void> {
    if (quiet || article) setIsRefreshing(true);
    else setIsLoading(true);
    setErrorMessage(null);

    try {
      const articles = await fetchRandomArticles();
      const next = articles[Math.floor(Math.random() * articles.length)];
      if (!next) throw new Error('No usable articles returned');

      setArticle(next);
      await saveArticle(next);
      scheduleWidgetArticles(articles);
    } catch {
      if (!article) {
        setErrorMessage('Connect to the internet to discover your first article.');
      }
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }

  async function openArticle(): Promise<void> {
    if (article) await Linking.openURL(article.url);
  }

  if (isLoading && !article) {
    return (
      <SafeAreaView style={styles.centered}>
        <ActivityIndicator color={COLORS.accent} />
        <Text style={styles.loadingText}>Finding an article…</Text>
        <StatusBar style="auto" />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="auto" />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => void discover(false)}
            tintColor={COLORS.accent}
          />
        }>
        <View style={styles.content}>
          <View style={styles.topBar}>
            <Text style={styles.brand}>WIKIPEDIA</Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Find another article"
              hitSlop={12}
              onPress={() => void discover(false)}
              style={({ pressed }) => [styles.shuffleButton, pressed && styles.pressed]}>
              <Text style={styles.shuffleIcon}>↻</Text>
            </Pressable>
          </View>

          {article ? (
            <ArticleContent article={article} onOpen={openArticle} />
          ) : (
            <View style={styles.emptyState}>
              <Text style={styles.emptyTitle}>No article yet</Text>
              <Text style={styles.emptyBody}>{errorMessage ?? 'Try again to discover something new.'}</Text>
              <Pressable onPress={() => void discover(false)} style={styles.primaryButton}>
                <Text style={styles.primaryButtonText}>Try again</Text>
              </Pressable>
            </View>
          )}

          {errorMessage && article ? <Text style={styles.offlineNotice}>{errorMessage}</Text> : null}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function ArticleContent({ article, onOpen }: { article: WikipediaArticle; onOpen: () => Promise<void> }) {
  return (
    <View>
      {article.description ? <Text style={styles.description}>{article.description.toUpperCase()}</Text> : null}
      <Text style={styles.title}>{article.title}</Text>
      <View style={styles.rule} />

      {article.imageUrl ? (
        <Image
          accessibilityLabel={article.description || article.title}
          source={{ uri: article.imageUrl }}
          resizeMode="cover"
          style={styles.image}
        />
      ) : null}

      <Text selectable style={styles.extract}>
        {article.extract}
      </Text>

      <Pressable
        accessibilityRole="link"
        onPress={() => void onOpen()}
        style={({ pressed }) => [styles.readButton, pressed && styles.pressed]}>
        <Text style={styles.readButtonText}>READ THE FULL ENTRY  →</Text>
      </Pressable>
    </View>
  );
}

const COLORS = {
  paper: '#F5F4F0',
  ink: '#17181C',
  muted: '#6B6C72',
  rule: '#D6D4CC',
  accent: '#2F4B96',
};

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: COLORS.paper },
  scrollContent: { flexGrow: 1 },
  content: { width: '100%', maxWidth: 680, alignSelf: 'center', padding: 24 },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    backgroundColor: COLORS.paper,
  },
  loadingText: { color: COLORS.muted, fontSize: 15 },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 48,
  },
  brand: { color: COLORS.muted, fontSize: 11, fontWeight: '700', letterSpacing: 2 },
  shuffleButton: { padding: 4 },
  shuffleIcon: { color: COLORS.accent, fontSize: 28, lineHeight: 28 },
  description: { color: COLORS.muted, fontSize: 11, fontWeight: '600', letterSpacing: 1.4, marginBottom: 10 },
  title: { color: COLORS.ink, fontFamily: 'Georgia', fontSize: 38, lineHeight: 44, marginBottom: 24 },
  rule: { height: 1, backgroundColor: COLORS.rule, marginBottom: 22 },
  image: { width: '100%', height: 220, marginBottom: 24, backgroundColor: COLORS.rule },
  extract: { color: COLORS.ink, fontFamily: 'Georgia', fontSize: 18, lineHeight: 30 },
  readButton: { alignSelf: 'flex-start', marginTop: 30, paddingVertical: 8 },
  readButtonText: { color: COLORS.accent, fontSize: 11, fontWeight: '700', letterSpacing: 1.3 },
  offlineNotice: { color: COLORS.muted, fontSize: 12, lineHeight: 18, marginTop: 24 },
  emptyState: { alignItems: 'flex-start', marginTop: 40 },
  emptyTitle: { color: COLORS.ink, fontFamily: 'Georgia', fontSize: 30, marginBottom: 12 },
  emptyBody: { color: COLORS.muted, fontSize: 16, lineHeight: 24, maxWidth: 320 },
  primaryButton: { backgroundColor: COLORS.accent, marginTop: 24, paddingHorizontal: 18, paddingVertical: 12 },
  primaryButtonText: { color: '#FFFFFF', fontSize: 13, fontWeight: '700' },
  pressed: { opacity: 0.55 },
});
