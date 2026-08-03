/* Wikipedia New Tab
 *
 * The page's one job: paint a legible encyclopedia entry the instant the tab
 * opens. Everything here is arranged around that.
 *
 * Storage is localStorage, not chrome.storage.local, because localStorage is
 * synchronous: the queue is read and the entry painted in the first script
 * turn, before the first frame. chrome.storage is promise-based and would
 * cost a frame of empty page on every single tab.
 *
 * All filtering happens at write time, when entries enter the queue, so the
 * render path never blocks, retries, or discards.
 */

const QUEUE_KEY = "wnt.queue";
const LAST_KEY = "wnt.last";

const QUEUE_TARGET = 8;   // a few days of casual use, offline
const QUEUE_MIN = 4;      // top up when we drop below this
const FETCH_COUNT = 12;   // over-fetch: filters reject a good share
const MIN_EXTRACT = 300;  // shorter than this is a stub, not an entry
const MAX_EXTRACT = 640;  // trimmed at a sentence boundary

const API = "https://en.wikipedia.org/w/api.php";

/* Random Wikipedia skews hard toward sports seasons, squad lists, election
 * tables and one-line athlete stubs — the length filter alone doesn't catch
 * them (a group-stage results table clears 500 characters easily). This is
 * the single knob for entry quality; widen it as you notice repeat offenders. */
const REJECT_DESCRIPTION = /\b(sports? season|football season|association football|footballer|cricketer|baseball player|basketball player|ice hockey player|rugby|olympic|election|census-designated|unincorporated community|village in|commune in|genus of|species of (moth|fly|beetle|snail))\b/i;

const REJECT_TITLE = /^(List of|\d{4}[–-]\d{2,4} |\d{4} (FIFA|UEFA|NCAA|Summer|Winter))/i;

const el = (id) => document.getElementById(id);

let current = null; // the entry on screen, for the full-size viewer

/* ----------------------------------------------------------- storage -- */

function readQueue() {
  try {
    const raw = localStorage.getItem(QUEUE_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeQueue(queue) {
  try {
    localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
  } catch {
    /* quota or private mode: the page still works, it just refetches */
  }
}

function readLast() {
  try {
    const raw = localStorage.getItem(LAST_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

/* ------------------------------------------------------------ images -- */

/* Commons thumbnail URLs carry their width in the path
 * (.../thumb/4/42/Name.jpg/500px-Name.jpg), so a different size is one string
 * edit away — no second API call to get a bigger copy of the same file.
 *
 * But only these widths exist. Wikimedia rejects hotlinked thumbnails at any
 * other size with a 400, so an invented width like 336px is not a smaller
 * image, it is a broken one (T414805). Requests are rounded *up* to a step,
 * then downsized by the browser.
 *
 * https://www.mediawiki.org/wiki/Common_thumbnail_sizes
 */
const STEPS = [20, 40, 60, 120, 250, 330, 500, 960, 1280, 1920, 3840];

/* Smallest step that covers `need`, never exceeding `cap` (the original's
 * own width — asking for an upscale is what makes a plate look pixelated).
 * A vector original has no meaningful width, so it is never capped. */
function step(need, cap) {
  const pool = cap ? STEPS.filter((s) => s <= cap) : STEPS;
  if (!pool.length) return STEPS[0];
  return pool.find((s) => s >= need) ?? pool[pool.length - 1];
}

function atWidth(url, width) {
  return url.replace(/\/\d+px-/, `/${width}px-`);
}

function urlWidth(url) {
  const m = url.match(/\/(\d+)px-/);
  return m ? Number(m[1]) : 0;
}

function plateWidth() {
  const token = getComputedStyle(document.documentElement).getPropertyValue("--plate-w");
  return parseInt(token, 10) || 168;
}

function cap(entry) {
  return entry.vector ? 0 : entry.width || 0;
}

function plateSrc(entry) {
  if (!urlWidth(entry.thumbnail)) return entry.thumbnail; // not a thumb URL
  const need = plateWidth() * (window.devicePixelRatio || 1);
  return atWidth(entry.thumbnail, step(need, cap(entry)));
}

/* Deliberately not `original`: that can be a 40-megapixel scan. A viewport-
 * sized copy is indistinguishable on screen and arrives in a fraction of the
 * time. Only fetched when the plate is actually clicked. */
function fullSrc(entry) {
  if (!urlWidth(entry.thumbnail)) return entry.thumbnail; // already an original
  const viewport = Math.min(window.innerWidth, window.innerHeight * 1.2);
  const need = Math.min(viewport * (window.devicePixelRatio || 1), 1920);
  return atWidth(entry.thumbnail, step(need, cap(entry)));
}

/* ------------------------------------------------------------ render -- */

function trimExtract(text) {
  const clean = text.replace(/\s+/g, " ").trim();
  if (clean.length <= MAX_EXTRACT) return clean;
  const cut = clean.slice(0, MAX_EXTRACT);
  const stop = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf("? "), cut.lastIndexOf("! "));
  return stop > MAX_EXTRACT * 0.5 ? cut.slice(0, stop + 1) : cut.trimEnd() + "…";
}

function render(entry, { stale = false } = {}) {
  document.title = entry.title;

  el("gloss").textContent = entry.description || "";
  el("headword").textContent = entry.title;
  el("headword").href = entry.url;
  el("read").href = entry.url;
  el("extract").textContent = trimExtract(entry.extract);

  const notice = el("notice");
  notice.hidden = !stale;
  if (stale) {
    notice.textContent =
      "Showing a saved entry. New ones will load when you're back online.";
  }

  const img = el("plate-img");
  const button = el("plate-btn");
  current = entry;
  if (entry.thumbnail) {
    img.classList.remove("fade-in");
    img.src = plateSrc(entry);
    img.alt = entry.description || entry.title;
    button.hidden = false;

    // Fade only on a cache miss. A preloaded plate completes synchronously
    // and should simply be there; anything that arrives later gets the 160ms.
    if (!img.complete) {
      img.addEventListener("load", () => img.classList.add("fade-in"), { once: true });
    }
    img.addEventListener("error", () => { button.hidden = true; }, { once: true });
  } else {
    // The column holds its width and stays empty. Never reflow the text.
    button.hidden = true;
    img.removeAttribute("src");
  }

  const letter = (entry.title.match(/[a-z0-9]/i) || ["·"])[0].toUpperCase();
  el("index-letter").textContent = letter;
  el("index-number").textContent = "№ " + entry.pageid;

  el("entry").hidden = false;

  try {
    localStorage.setItem(LAST_KEY, JSON.stringify(entry));
  } catch { /* non-fatal */ }
}

/* ------------------------------------------------------------- fetch -- */

/* One request for a dozen entries. The per-article random/summary endpoint
 * would cost one round trip each to refill the queue. */
function apiUrl() {
  const params = new URLSearchParams({
    action: "query",
    format: "json",
    formatversion: "2",
    origin: "*",
    generator: "random",
    grnnamespace: "0",
    grnlimit: String(FETCH_COUNT),
    prop: "extracts|pageimages|description|info",
    exintro: "1",
    explaintext: "1",
    exlimit: "max",
    // `original` comes back in the same request, so the full-size view costs
    // no extra round trip — only its dimensions, which cap what we ask for.
    piprop: "thumbnail|original",
    pithumbsize: "330", // a standard step; see STEPS above
    inprop: "url",
  });
  return `${API}?${params}`;
}

function keep(page) {
  if (!page.extract || page.extract.length < MIN_EXTRACT) return false;
  if (REJECT_TITLE.test(page.title)) return false;
  if (page.description && REJECT_DESCRIPTION.test(page.description)) return false;
  return true;
}

function toEntry(page) {
  // Stored unresized. The size is chosen at render time, when the device
  // pixel ratio is actually known.
  return {
    pageid: page.pageid,
    title: page.title,
    width: page.original?.width || 0,
    // An SVG's nominal width is not a resolution limit; it rasterises at any
    // size, so it must not be capped by it.
    vector: /\.svg$/i.test(page.original?.source || ""),
    description: page.description || "",
    extract: page.extract,
    thumbnail: page.thumbnail?.source || null,
    url: page.fullurl,
  };
}

async function fetchEntries() {
  const res = await fetch(apiUrl(), { cache: "no-store" });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  return (data?.query?.pages || []).filter(keep).map(toEntry);
}

/* Fills the browser's HTTP cache so the plate is already decoded by the time
 * this entry reaches the front of the queue. */
function preload(entry) {
  if (entry.thumbnail) new Image().src = plateSrc(entry);
}

async function topUp() {
  let queue = readQueue();
  if (queue.length >= QUEUE_MIN) return;

  // Two passes at most: filters are aggressive, one batch may not be enough.
  for (let attempt = 0; attempt < 2 && queue.length < QUEUE_TARGET; attempt++) {
    let fresh;
    try {
      fresh = await fetchEntries();
    } catch {
      return; // Silent. A new tab never shows a network error.
    }
    const seen = new Set(queue.map((e) => e.pageid));
    for (const entry of fresh) {
      if (queue.length >= QUEUE_TARGET) break;
      if (seen.has(entry.pageid)) continue;
      seen.add(entry.pageid);
      preload(entry);
      queue.push(entry);
    }
    writeQueue(queue);
  }
}

/* -------------------------------------------------------------- boot -- */

/* Takes the next entry and paints it. Returns false if the queue is dry. */
function advance() {
  const queue = readQueue();
  const entry = queue.shift();
  if (!entry) return false;
  writeQueue(queue);
  render(entry);
  return true;
}

async function coldStart() {
  // First install, or an empty queue. Happens rarely; fetch inline.
  try {
    const fresh = await fetchEntries();
    if (fresh.length) {
      fresh.forEach(preload);
      writeQueue(fresh.slice(1, QUEUE_TARGET + 1));
      render(fresh[0]);
      return;
    }
  } catch { /* fall through to the saved entry */ }

  const last = readLast();
  if (last) render(last, { stale: true });
}

/* The full-size view is loaded on click and never before: no point spending
 * bandwidth on a large copy of an image most tabs are never asked about. */
function wireViewer() {
  const viewer = el("viewer");
  const viewerImg = el("viewer-img");

  el("plate-btn").addEventListener("click", () => {
    if (!current?.thumbnail) return;
    viewerImg.src = fullSrc(current);
    viewerImg.alt = current.description || current.title;
    viewer.showModal(); // <dialog> gives Escape and focus containment free
  });

  // Clicking the image or the backdrop closes it; the dialog fills its own
  // box, so any click landing on the element itself is a backdrop click.
  viewer.addEventListener("click", () => viewer.close());
  viewer.addEventListener("close", () => viewerImg.removeAttribute("src"));
}

function boot() {
  wireViewer();

  if (advance()) {
    // Painted from cache. Refill in the background, off the critical path.
    topUp();
  } else {
    coldStart();
  }

  el("another").addEventListener("click", () => {
    if (!advance()) coldStart();
    topUp();
  });

  document.addEventListener("keydown", (e) => {
    if (e.key !== "r" && e.key !== "R") return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (el("viewer").open) return; // Escape closes the viewer; R does nothing
    if (/^(INPUT|TEXTAREA)$/.test(e.target.tagName) || e.target.isContentEditable) return;
    e.preventDefault();
    if (!advance()) coldStart();
    topUp();
  });
}

boot();
