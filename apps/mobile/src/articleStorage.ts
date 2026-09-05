import AsyncStorage from '@react-native-async-storage/async-storage';

import type { WikipediaArticle } from '@newtabwikipedia/wikipedia';

const ARTICLE_KEY = '@newtab-wikipedia/latest-article';

export async function loadSavedArticle(): Promise<WikipediaArticle | null> {
  try {
    const value = await AsyncStorage.getItem(ARTICLE_KEY);
    return value ? (JSON.parse(value) as WikipediaArticle) : null;
  } catch {
    return null;
  }
}

export async function saveArticle(article: WikipediaArticle): Promise<void> {
  await AsyncStorage.setItem(ARTICLE_KEY, JSON.stringify(article));
}
