# fit-tracker

Página estática de acompanhamento de treino (ciclo A/B), usada principalmente **no celular,
dentro da academia, entre séries**. Densidade e velocidade de leitura importam mais do que
qualquer outra coisa nesta página.

## Arquitetura e restrições

- **Arquivo único.** Todo o HTML, CSS e JS vivem em `index.html`. Sem build, sem
  dependências, sem framework, sem bundler. Servida pelo GitHub Pages a partir de `main`.
- JS em estilo ES5: templating por concatenação de string dentro de `render()`, e **um único
  listener de clique delegado no `document`**. Por causa da delegação, componentes novos não
  precisam ser re-ligados depois que `render()` reescreve `#treinos`.
- Qualquer markup que precise sobreviver ao re-render (overlays, diálogos) fica **fora** de
  `#treinos`.
- CSS escrito à mão, com design tokens em `:root`. A variável `--accent` é reassociada por
  card (`.treino.a` / `.treino.b`) — componentes novos devem herdá-la em vez de repetir cores.
- Interface toda em pt-BR, incluindo os `aria-label`.

## O contrato do `id`

Cada exercício em `treinos[].ex[]` tem um `id` estável que serve para **duas** coisas: chave
no `localStorage` e nome do arquivo da ilustração em `assets/ex/`.

- Renomear `n` (o nome exibido) é livre e não quebra nada.
- Renomear `id` zera a carga e as séries salvas daquele exercício, e quebra o caminho da
  ilustração.
- **Nunca voltar a chavear persistência por índice de array.** Era assim antes: reordenar ou
  inserir um exercício reatribuía séries e cargas ao exercício errado, em silêncio.

## Convenção de mídia

- `img:1` no objeto do exercício significa que existe `assets/ex/<id>.webp`, e faz aparecer um
  ícone discreto ao lado do nome. Sem `img`, nenhum ícone e nenhuma requisição.
- WebP, ~800–1000px de largura, menos de 120KB.
- O `src` da imagem só é atribuído **na abertura** do `<dialog>` — zero requisição de imagem
  no carregamento da página. Preservar esse comportamento: é o que mantém a página utilizável
  na rede da academia.
- Arquivo ausente mostra "Ilustração ainda não adicionada", nunca o ícone de imagem quebrada.
  O acervo é preenchido aos poucos, então esse estado é normal e não é bug.

## Decisões deliberadas — não são omissões

Estas ausências foram escolhidas. Reintroduzi-las é regressão, não melhoria.

- **Sem upload de imagem em runtime** (câmera → `localStorage`/base64). Cota de ~5MB, dado
  preso a um único browser de um único aparelho, e o wrapper `store.set` engole
  `QuotaExceededError` em silêncio — o usuário perderia mídia sem aviso. A fonte de verdade
  são arquivos commitados no repo.
- **Sem vídeo, GIF ou embed de YouTube.** Iframe de terceiros é pesado, depende de rede e
  destoa do tom da página.
- **Sem biblioteca de lightbox, carrossel, swipe ou zoom customizado.** O `<dialog>` nativo já
  entrega ESC, backdrop e trap de foco.
- **Offline / service worker está fora de escopo por decisão**, a tratar em outro momento.
  (O GitHub Pages serve com `max-age=600`, então o cache HTTP sozinho não garante a imagem
  sem sinal — é um problema real, só não é deste escopo.)

## Ilustrações: origem e licença

O repositório é **público**, então a procedência das imagens importa.

- **Fonte primária: [wger](https://wger.de)** — CC-BY-SA 4.0, com `license` e `licenseAuthor`
  em cada registro da API, o que torna a atribuição rastreável imagem a imagem.
- Lacunas: Wikimedia Commons, verificando a licença arquivo a arquivo.
- **Não usar `free-exercise-db`.** Declara Unlicense, mas a proveniência das imagens é
  questionada em issues abertas do próprio repositório e nunca foi esclarecida. Um repo
  declarar domínio público não transfere esse status a imagens de terceiros.
- CC-BY-SA exige atribuição — vai no `<footer>`, que já existe. Imagem recortada ou editada é
  obra derivada e continua CC-BY-SA.

`assets/ex/agachamento-hack.webp` é um **placeholder autoral**, feito só para o mecanismo ser
verificável ponta a ponta. Substituir pela ilustração real.
