import test from 'node:test';
import assert from 'node:assert/strict';

import {
  buildRandomArticleURL,
  cleanExtract,
  shouldKeepPage,
  toArticle,
  type WikipediaPage,
} from './index.ts';

const page = (overrides: Partial<WikipediaPage> = {}): WikipediaPage => ({
  pageid: 42,
  title: 'A Good Article',
  description: 'A useful subject',
  extract: 'A '.repeat(160),
  fullurl: 'https://en.wikipedia.org/wiki/A_Good_Article',
  thumbnail: { source: 'https://upload.wikimedia.org/image.jpg' },
  ...overrides,
});

test('builds a random Wikipedia API URL with the expected query', () => {
  const url = new URL(buildRandomArticleURL());

  assert.equal(url.origin + url.pathname, 'https://en.wikipedia.org/w/api.php');
  assert.equal(url.searchParams.get('generator'), 'random');
  assert.equal(url.searchParams.get('grnnamespace'), '0');
  assert.equal(url.searchParams.get('formatversion'), '2');
  assert.equal(url.searchParams.get('origin'), '*');
});

test('cleans whitespace and trims extracts at a sentence boundary', () => {
  const cleaned = cleanExtract('  First   sentence.\n\nSecond sentence.  ');
  assert.equal(cleaned, 'First sentence. Second sentence.');

  const long = `${'A'.repeat(300)}. ${'B'.repeat(300)}.`;
  assert.equal(cleanExtract(long, 320).endsWith('.'), true);
});

test('rejects short and low-quality random pages', () => {
  assert.equal(shouldKeepPage(page({ extract: 'Too short' })), false);
  assert.equal(shouldKeepPage(page({ title: 'List of Famous Things' })), false);
  assert.equal(shouldKeepPage(page({ description: 'A football season' })), false);
  assert.equal(shouldKeepPage(page()), true);
});

test('converts an API page into an app article', () => {
  assert.deepEqual(toArticle(page()), {
    id: '42',
    pageId: 42,
    title: 'A Good Article',
    description: 'A useful subject',
    extract: 'A '.repeat(160).trim(),
    url: 'https://en.wikipedia.org/wiki/A_Good_Article',
    imageUrl: 'https://upload.wikimedia.org/image.jpg',
  });
});

test('falls back to the original image source when no thumbnail exists', () => {
  const article = toArticle(page({
    thumbnail: undefined,
    original: { source: 'https://upload.wikimedia.org/original.jpg' },
  }));

  assert.equal(article?.imageUrl, 'https://upload.wikimedia.org/original.jpg');
});

test('does not convert pages without a canonical URL', () => {
  assert.equal(toArticle(page({ fullurl: undefined })), null);
});
