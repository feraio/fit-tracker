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

## Dois planos, uma página

`planos[]` guarda um objeto por plano de treino: o **Ciclo A/B** (em vigor) e o **PPL**
(anterior, mantido só para consulta). A aba escolhida fica em `fittracker.plano.v1`.

- Cada plano traz o próprio cabeçalho (`eyebrow`, `titulo`, `lede`, `legenda`, `nota`), a
  própria faixa de semana e os próprios treinos. `renderCabecalho()` reescreve tudo isso, que
  vive **fora** de `#treinos`; `render()` cuida só dos cards.
- **Cada plano tem o seu prefixo de persistência** (`key`): `fittracker.ab.v1.` e
  `fittracker.ppl.v1.`. Trocar de aba nunca mistura séries nem cargas. O prefixo do A/B não
  muda nunca — é onde já estão os dados salvos no navegador de quem usa a página.
- A **fase** (retorno / prescrição completa) é global aos dois planos e continua em
  `fittracker.ab.v1.modo`, no namespace antigo de propósito: trocar essa chave descartaria a
  fase já salva.
- As abas seguem o padrão `tablist`, com `aria-selected`, tabindex móvel e navegação por
  setas. O `keydown` é delegado no `document` pelo mesmo motivo do clique: `renderAbas()`
  reescreve os botões a cada troca.
- Os macros do bloco Nutricional são iguais nos dois planos, então ficam fora da alternância.
- `semKg:1` no exercício esconde o campo de carga (aquecimento, trabalho por tempo).

## O contrato do `id`

Cada exercício em `treinos[].ex[]` tem um `id` estável que serve para **duas** coisas: chave
no `localStorage` e nome do arquivo da ilustração em `assets/ex/`.

- Renomear `n` (o nome exibido) é livre e não quebra nada.
- Renomear `id` zera a carga e as séries salvas daquele exercício, e quebra o caminho da
  ilustração.
- **Nunca voltar a chavear persistência por índice de array.** Era assim antes: reordenar ou
  inserir um exercício reatribuía séries e cargas ao exercício errado, em silêncio.

## Convenção de mídia

> **Desligada por ora.** `MIDIA_ATIVA = false` no topo do bloco de mídia. Enquanto for
> `false`, nenhum ícone é renderizado e nenhuma imagem é requisitada — mas o CSS, o
> `<dialog>`, o handler de clique, o `img:1` nos dados e o `assets/ex/` continuam todos no
> lugar. Voltar é virar a constante para `true`, nada mais. A decisão foi desligar em vez de
> remover justamente para não conflitar com o trabalho de ilustrações ainda em aberto.
> O resto desta seção descreve o comportamento com a chave ligada.

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
