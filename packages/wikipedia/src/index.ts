export const WIKIPEDIA_API = 'https://en.wikipedia.org/w/api.php';
export const MIN_EXTRACT_LENGTH = 240;
export const MAX_EXTRACT_LENGTH = 640;

export type WikipediaPage = {
  pageid?: number;
  title?: string;
  description?: string;
  extract?: string;
  fullurl?: string;
  thumbnail?: {
    source?: string;
  };
};

export type WikipediaArticle = {
  id: string;
  pageId: number;
  title: string;
  description: string;
  extract: string;
  url: string;
  imageUrl: string | null;
};

export type WikipediaQueryResponse = {
  query?: {
    pages?: WikipediaPage[];
  };
};

const REJECT_DESCRIPTION = /\b(sports? season|football season|footballer|cricketer|baseball player|basketball player|ice hockey player|rugby|olympic|election|census-designated|unincorporated community|village in|commune in|genus of|species of (moth|fly|beetle|snail))\b/i;
const REJECT_TITLE = /^(List of|\d{4}[–-]\d{2,4} |\d{4} (FIFA|UEFA|NCAA|Summer|Winter))/i;

export function buildRandomArticleURL(limit = 12): string {
  const url = new URL(WIKIPEDIA_API);
  const params: Record<string, string> = {
    action: 'query',
    format: 'json',
    formatversion: '2',
    origin: '*',
    generator: 'random',
    grnnamespace: '0',
    grnlimit: String(limit),
    prop: 'extracts|pageimages|info',
    exintro: '1',
    explaintext: '1',
    exsentences: '5',
    piprop: 'thumbnail',
    pithumbsize: '900',
    inprop: 'url',
  };

  Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value));
  return url.toString();
}

export function cleanExtract(value: string, maxLength = MAX_EXTRACT_LENGTH): string {
  const clean = value.replace(/\s+/g, ' ').trim();
  if (clean.length <= maxLength) return clean;

  const cut = clean.slice(0, maxLength);
  const stops = [cut.lastIndexOf('. '), cut.lastIndexOf('? '), cut.lastIndexOf('! ')];
  const sentenceStop = Math.max(...stops);
  if (sentenceStop > maxLength * 0.5) return cut.slice(0, sentenceStop + 1);
  return `${cut.trimEnd()}…`;
}

export function shouldKeepPage(page: WikipediaPage): boolean {
  const extract = page.extract?.trim() ?? '';
  const title = page.title?.trim() ?? '';
  if (!page.pageid || !title || extract.length < MIN_EXTRACT_LENGTH) return false;
  if (!page.fullurl) return false;
  if (REJECT_TITLE.test(title)) return false;
  if (page.description && REJECT_DESCRIPTION.test(page.description)) return false;
  return true;
}

export function toArticle(page: WikipediaPage): WikipediaArticle | null {
  if (!shouldKeepPage(page)) return null;

  return {
    id: String(page.pageid),
    pageId: page.pageid!,
    title: page.title!.trim(),
    description: page.description?.trim() ?? '',
    extract: cleanExtract(page.extract!),
    url: page.fullurl!,
    imageUrl: page.thumbnail?.source ?? null,
  };
}

export function parseArticles(response: WikipediaQueryResponse): WikipediaArticle[] {
  return (response.query?.pages ?? []).map(toArticle).filter((article): article is WikipediaArticle => article !== null);
}

export async function fetchRandomArticles(limit = 12): Promise<WikipediaArticle[]> {
  const response = await fetch(buildRandomArticleURL(limit), { cache: 'no-store' });
  if (!response.ok) throw new Error(`Wikipedia request failed with HTTP ${response.status}`);
  return parseArticles((await response.json()) as WikipediaQueryResponse);
}

export async function fetchRandomArticle(): Promise<WikipediaArticle> {
  const articles = await fetchRandomArticles();
  const article = articles[Math.floor(Math.random() * articles.length)];
  if (!article) throw new Error('Wikipedia returned no usable articles');
  return article;
}
