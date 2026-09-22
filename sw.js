/* Service worker do fit-tracker.
   Existe por um motivo só: a página precisa abrir na rede da academia, ou sem
   rede nenhuma. O GitHub Pages serve com max-age=600, então sem isto um retorno
   depois de 10 minutos tenta revalidar e trava no sinal ruim.

   IMPORTANTE: subir VERSAO a cada deploy. É o que faz o aparelho largar a cópia
   velha — sem isso a correção que você acabou de publicar não chega no celular. */
var VERSAO = 'fit-v16';

/* Só o casco da página. As ilustrações ficam de fora de propósito: elas são
   pedidas sob demanda e não podem inflar o cache. */
var CASCO = ['./', './index.html'];

self.addEventListener('install', function(ev){
  ev.waitUntil(
    caches.open(VERSAO).then(function(c){ return c.addAll(CASCO); })
          .then(function(){ return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(ev){
  ev.waitUntil(
    caches.keys().then(function(nomes){
      return Promise.all(nomes.map(function(n){
        return n === VERSAO ? null : caches.delete(n);
      }));
    }).then(function(){ return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(ev){
  var req = ev.request;

  /* Nada de mexer no que não é nosso: Supabase e Google Fonts vão direto para a
     rede. Interceptar API daria resposta velha de treino, que é pior que erro. */
  if (req.method !== 'GET') return;
  if (new URL(req.url).origin !== self.location.origin) return;

  /* Cache primeiro, atualização por baixo. A cópia nova entra na próxima
     abertura — é o preço de abrir instantâneo e sem sinal. */
  ev.respondWith(
    caches.match(req).then(function(cacheada){
      var daRede = fetch(req).then(function(r){
        if (r && r.status === 200){
          var copia = r.clone();
          caches.open(VERSAO).then(function(c){ c.put(req, copia); });
        }
        return r;
      }).catch(function(){
        /* Offline e sem cópia: deixa o navegador mostrar o erro dele. */
        return cacheada || Response.error();
      });
      return cacheada || daRede;
    })
  );
});
