(function (global) {
  const API = 'https://en.wikipedia.org/w/api.php';

  // These are real Wikipedia category titles, not UI-only labels.
  const TOPICS = Object.freeze({
    all: { label: 'All sections', category: null },
    physics: { label: 'Physics', category: 'Category:Physics' },
    history: { label: 'History', category: 'Category:History' },
    mathematics: { label: 'Mathematics', category: 'Category:Mathematics' },
    technology: { label: 'Technology', category: 'Category:Technology' },
    geography: { label: 'Geography', category: 'Category:Geography' },
    art: { label: 'Art', category: 'Category:Art' },
    music: { label: 'Music', category: 'Category:Music' },
    literature: { label: 'Literature', category: 'Category:Literature' },
  });

  function categoryMembersURL(category, limit = 500) {
    const url = new URL(API);
    const params = {
      action: 'query',
      format: 'json',
      formatversion: '2',
      origin: '*',
      list: 'categorymembers',
      cmtitle: category,
      cmnamespace: '0',
      cmtype: 'page',
      cmlimit: String(limit),
    };
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value));
    return url.toString();
  }

  function pageLookupURL(pageIds) {
    const url = new URL(API);
    const params = {
      action: 'query',
      format: 'json',
      formatversion: '2',
      origin: '*',
      pageids: pageIds.join('|'),
      prop: 'extracts|pageimages|info',
      exintro: '1',
      explaintext: '1',
      exsentences: '5',
      piprop: 'thumbnail|original',
      pithumbsize: '900',
      inprop: 'url',
    };
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value));
    return url.toString();
  }

  function categorySearchURL(query, limit = 10) {
    const url = new URL(API);
    const params = {
      action: 'query',
      format: 'json',
      formatversion: '2',
      origin: '*',
      list: 'search',
      srnamespace: '14',
      srsearch: query,
      srlimit: String(limit),
    };
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value));
    return url.toString();
  }

  const api = { TOPICS, categoryMembersURL, categorySearchURL, pageLookupURL };
  global.WikipediaTopics = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof globalThis !== 'undefined' ? globalThis : window);
