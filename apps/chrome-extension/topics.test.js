const test = require('node:test');
const assert = require('node:assert/strict');

const { TOPICS, categoryMembersURL, pageLookupURL } = require('./topics.js');

test('defines sections backed by real Wikipedia category titles', () => {
  assert.equal(TOPICS.physics.category, 'Category:Physics');
  assert.equal(TOPICS.history.category, 'Category:History');
  assert.equal(TOPICS.technology.category, 'Category:Technology');
  assert.equal(TOPICS.mathematics.category, 'Category:Mathematics');
  assert.equal(TOPICS.all.category, null);
});

test('builds a category-members API request for article pages', () => {
  const url = new URL(categoryMembersURL('Category:Physics'));

  assert.equal(url.searchParams.get('list'), 'categorymembers');
  assert.equal(url.searchParams.get('cmtitle'), 'Category:Physics');
  assert.equal(url.searchParams.get('cmnamespace'), '0');
  assert.equal(url.searchParams.get('cmtype'), 'page');
});

test('builds a page lookup API request with image data', () => {
  const url = new URL(pageLookupURL([1, 2, 3]));

  assert.equal(url.searchParams.get('pageids'), '1|2|3');
  assert.equal(url.searchParams.get('prop'), 'extracts|pageimages|info');
  assert.equal(url.searchParams.get('piprop'), 'thumbnail|original');
});
