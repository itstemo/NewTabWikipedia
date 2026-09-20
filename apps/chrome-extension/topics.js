(function (global) {
  // Category titles are English — curated sections only apply when the
  // language setting is English. Everything else parameterizes cleanly.
  function apiBase(language) {
    const lang = /^[a-z][a-z0-9-]*$/i.test(language || '') ? language.toLowerCase() : 'en';
    return `https://${lang}.wikipedia.org/w/api.php`;
  }

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

  function categoryMembersURL(category, limit = 500, language) {
    const url = new URL(apiBase(language));
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

  function pageLookupURL(pageIds, language) {
    const url = new URL(apiBase(language));
    const params = {
      action: 'query',
      format: 'json',
      formatversion: '2',
      origin: '*',
      pageids: pageIds.join('|'),
      prop: 'extracts|pageimages|description|info',
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

  function categorySearchURL(query, limit = 10, language) {
    const url = new URL(apiBase(language));
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

  const api = { TOPICS, apiBase, categoryMembersURL, categorySearchURL, pageLookupURL };
  global.WikipediaTopics = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof globalThis !== 'undefined' ? globalThis : window);
