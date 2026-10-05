/* Gestor Financeiro — service worker
   A página vem da rede quando há conexão (para uma versão nova aparecer no
   próximo recarregar) e do cache quando está offline. Ícones e manifesto são
   cache-first. Os dados ficam no IndexedDB, nunca aqui. */
const CACHE = "gestor-v35";
const SHELL = ["./", "./index.html", "./manifest.webmanifest", "./icon.svg"];

self.addEventListener("install", e => {
  /* cache:"reload" fura o cache HTTP do navegador — sem isso o casco novo
     podia ser montado com o index.html velho */
  e.waitUntil(caches.open(CACHE)
    .then(c => c.addAll(SHELL.map(u => new Request(u, {cache: "reload"}))))
    .then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

const guardar = (req, res) => {
  if (res && res.ok && new URL(req.url).origin === location.origin) {
    const copy = res.clone();
    caches.open(CACHE).then(c => c.put(req, copy));
  }
  return res;
};

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req, {cache: "no-store"}).then(res => guardar(req, res))
        .catch(() => caches.match(req).then(hit => hit || caches.match("./index.html")))
    );
    return;
  }
  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => guardar(req, res))
      .catch(() => caches.match("./index.html")))
  );
});
