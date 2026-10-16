// Gymventory — service worker.
// The app page itself is fetched from the network first (so updates show up on the next open)
// and falls back to the saved copy offline. Icons, fonts and the rest come from the cache.
// Bump VERSION when you change files.
const VERSION = 'gymventory-2.0.1';
const SHELL = ['./', './index.html', './config.js', './manifest.webmanifest',
  './icons/icon-192.png', './icons/icon-512.png', './icons/maskable-512.png', './icons/apple-touch-icon.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
const timeout = (ms) => new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), ms));
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const sameOrigin = url.origin === self.location.origin;
  const font = /fonts\.(googleapis|gstatic)\.com$/.test(url.hostname);
  if (!sameOrigin && !font) return;                       // Supabase calls always go to the network
  const isPage = req.mode === 'navigate' || (sameOrigin && /\/(index\.html|config\.js)?$/.test(url.pathname));
  e.respondWith(caches.open(VERSION).then(async cache => {
    const key = req.mode === 'navigate' ? './index.html' : req;
    if (isPage) {
      try {
        const res = await Promise.race([fetch(req, { cache: 'no-cache' }), timeout(4000)]);
        if (res && res.ok) cache.put(key, res.clone());
        return res;
      } catch (err) {
        return (await cache.match(key, { ignoreSearch: true })) || Response.error();
      }
    }
    const hit = await cache.match(key);
    const net = fetch(req).then(res => {
      if (res && (res.ok || res.type === 'opaque')) cache.put(key, res.clone());
      return res;
    }).catch(() => hit || Response.error());
    return hit || net;
  }));
});
