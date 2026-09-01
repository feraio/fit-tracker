# fit-tracker

Página estática de acompanhamento de treino (ciclo A/B), usada principalmente **no celular,
dentro da academia, entre séries**. Densidade e velocidade de leitura importam mais do que
qualquer outra coisa nesta página.

## Arquitetura e restrições

- **Arquivo único, com quatro exceções nomeadas.** Todo o HTML, CSS e JS da página vivem em
  `index.html`. Sem build, sem dependências, sem framework, sem bundler. Servida pelo GitHub
  Pages a partir de `main`. As exceções, todas obrigatórias e nenhuma delas código de página:
  `sw.js` (um service worker **precisa** ser arquivo próprio, no escopo certo — não dá para
  embutir), `ana/index.html` (três linhas de redirecionamento), `supabase/schema.sql`
  (documentação do banco) e `docs/bike-intervalado.md` (as versões da prescrição da bike que
  **não** estão em vigor — ver "Bike intervalado" abaixo). O Supabase é acessado por `fetch` na API REST, sem SDK, justamente
  para não reintroduzir dependência.
- JS em estilo ES5: templating por concatenação de string dentro de `render()`, e **um único
  listener de clique delegado no `document`**. Por causa da delegação, componentes novos não
  precisam ser re-ligados depois que `render()` reescreve `#treinos`.
- Qualquer markup que precise sobreviver ao re-render (overlays, diálogos) fica **fora** de
  `#treinos`.
- CSS escrito à mão, com design tokens em `:root`. A variável `--accent` é reassociada por
  card (`.treino.a` / `.treino.b`) — componentes novos devem herdá-la em vez de repetir cores.
- Interface toda em pt-BR, incluindo os `aria-label`.

## Três planos, uma página

`planos[]` guarda um objeto por plano: o **Ciclo A/B** (em vigor), o **PPL** (anterior, mantido
só para consulta) e a **Bike** (intervalado, somente leitura). A aba escolhida fica em
`fittracker.plano.v1`.

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

## Sincronização e contas

A fonte de verdade continua sendo o `localStorage`: **a página renderiza dele na hora e nunca
espera rede**. O Supabase é uma cópia durável por cima disso.

- **`store` é a única costura de persistência.** `bruto` fala direto com o `localStorage`;
  `store` grava igual e ainda marca a chave como suja. O pull grava por `bruto` de propósito —
  usar `store` ali sujaria de novo o que acabou de chegar, e a fila nunca esvaziaria.
- **Push antes de pull, sempre.** Chave ainda na fila nunca é sobrescrita pelo remoto. Quem
  decide o vencedor é o `now()` do Postgres (gatilho `estado_toca`), nunca o relógio do
  aparelho — relógio de cliente erra.
- **`valor = null` é lápide, não `DELETE`.** Sem isso, desmarcar uma série no celular seria
  ressuscitado pela linha velha do tablet.
- **A aba escolhida (`fittracker.plano.v1`) não sincroniza.** É preferência de aparelho;
  sincronizar faria o celular pular de aba porque o tablet foi aberto. Quem decide é
  `sincronizavel()`.
- **Entrar é opcional e nunca bloqueia.** Sem login a página funciona inteira, só local. Isso é
  deliberado: um erro de autenticação não pode deixar ninguém sem treino no meio da série.
- **A chave anônima no fonte é segura, e só por causa do RLS.** O repositório é público. Toda
  tabela precisa de RLS ligado e política explícita; uma tabela sem RLS é lida por qualquer
  pessoa com a chave. Nunca colocar a `service_role` na página — ela ignora o RLS.
- A Ana usa os mesmos `planos[]`, com dados separados por conta. `ana/index.html` só redireciona
  com `?u=`, que pré-preenche o e-mail. A separação real vem do RLS, não da URL.
- **O `localStorage` tem dono, e `fittracker.sync.dono` é quem diz qual.** Ele sobrevive ao
  logout de propósito. Sem isso, sair e entrar com outra conta no mesmo aparelho fazia
  `migrar()` re-enfileirar o `localStorage` de quem saiu, e o push (que vem antes do pull)
  gravava aquilo na conta de quem entrou, com hora nova — sobrescrevendo os dados dela no
  servidor, não só vazando. O RLS não protege contra isso: a escrita é autenticada como quem
  entrou. Por isso `sair()` **não** zera o `migrado`, e `migrar()` só roda em aparelho sem dono
  gravado. Fica uma janela conhecida: aparelho deslogado *antes* desta versão não tem dono, e é
  indistinguível de um que nunca teve conta — fechar por heurística quebraria o primeiro login
  de verdade, que é o caso comum. Fecha sozinha no primeiro login já com esta versão.
- **Resposta em voo é da conta que a pediu.** `geracao` sobe a cada saída e a cada troca; push e
  pull carregam a geração de quando saíram e descartam o resultado se ela mudou. Sem isso um
  pull lento que aterrissa depois da troca reescreve o localStorage com o dado de quem saiu e
  ainda adianta o cursor `desde` — e a conta nova nunca mais recebe as próprias linhas naquele
  aparelho, porque todas são anteriores ao cursor.
- **Troca de conta com a fila suja não passa.** Se sobrou chave sem enviar, o login da outra
  conta é recusado com aviso, em vez de escolher sozinho entre gravar na conta errada e
  descartar treino. Fila vazia: as chaves da conta anterior são apagadas e a tela é repintada
  ali mesmo — o pull não redesenha quando volta vazio, e a tela ficaria mostrando o treino de
  quem saiu.
- **Um handler para todo campo que guarda valor.** Carga dos exercícios e macros da nutrição
  usam o mesmo `data-campo`, que carrega a própria chave — não existe tabela de correspondência
  para manter em sincronia. Campo esvaziado apaga a chave, e é isso que vira lápide.

## Bike intervalado

A aba **Bike** é o primeiro plano **somente leitura** da página: mostra a prescrição da versão
vigente para conferir em cima do aparelho, e não recebe input nenhum.

- **`leitura:1` no plano é o que separa os dois mundos.** `render()` desvia para
  `renderLeitura()` antes de tocar em `plano.key` ou `plano.treinos` — a bike não tem nenhum
  dos dois. Sem série para marcar e sem carga para guardar, **nada nesta aba encosta no
  `localStorage`**, e por consequência nada dela entra na fila, na lápide ou no RLS. Não há
  sincronização nova a fazer aqui, e não há nenhuma a manter.
- A **fase** (retorno / prescrição completa) é prescrição de força e some na aba da bike.
  `.phase` tem `display:flex`, que ganha do `[hidden]` do navegador: por isso existe
  `.phase[hidden]{display:none}`. Tirar essa regra faz a fase reaparecer, funcionando à toa.
- **Só a versão vigente é renderizada.** A V2, a V3, a V4 e o critério de avanço estão em
  `docs/bike-intervalado.md`, que também traz o passo a passo de trocar de versão. Prescrição
  que ainda não vale não pode ficar a um descuido de distância de ser desenhada.
  Trocar de versão é um deploy, não uma edição de dados.
- **O componente é desenhado para ser lido de longe**, com o corpo em movimento: número grande
  sempre na mesma coluna à direita, uma etapa por linha, e o bloco principal destacado com o
  `--accent` do card. Por isso o critério de avanço fica no **pé** do card, e o plano não tem
  `nota`: a caixa amarela acima empurrava o bloco principal para fora da primeira tela do
  celular, que é exatamente o que a aba existe para evitar. Ao mexer no cabeçalho desta aba,
  conferir de novo que o bloco principal cabe sem rolagem em uma tela de 390×844.
- O amarelo (`--yellow15`) já era a cor do que não é musculação — "15 kg · futebol / recarga".
  A bike herda ela, no card e no `h1 .slash.bk`.
- Os macros do bloco Nutricional continuam fora da alternância, como nos outros dois planos.

## Nutrição

A **estrutura** (quais cards, quais linhas, os rótulos, quais macros são fixas) é template e
continua no código, em `NUTRI`. O que pertence a cada pessoa são só os **valores**, e esses
vivem no `localStorage` e sobem para o Supabase como qualquer outra chave:
`fittracker.nutri.v1.<card>.<campo>`.

- Nenhuma sincronização nova foi preciso: as chaves começam com `fittracker.`, então já entram
  na fila, na lápide e no RLS que já existiam.
- **Não existe semente automática.** Quem entra sem valor nenhum vê o mesmo componente com os
  campos vazios, para preencher. Semear com os números de outra pessoa mostraria dieta alheia
  como se fosse a própria — em macro, isso é pior que campo vazio.
- Os valores que ficaram hardcoded até agosto de 2026 (2460/154/301/71/25 a 35 e
  3100/154/460/71) foram migrados para a conta do Felipe, não para o código. Estão registrados
  aqui só para poderem ser reconstruídos se a conta se perder.
- O número grande de kcal é o próprio campo. Não há valor derivado para redesenhar, então
  digitar nunca dispara re-render — que é o que faria o foco pular no meio da edição.

## Preferências de conta

`fittracker.prefs.v1.*` são preferências **de conta**, não de aparelho: sincronizam, e quem
desliga a faixa da semana a vê desligada em qualquer celular. Ficam no diálogo de conta, que já
existia — não abrir uma tela de configurações para isso.

Não confundir com `fittracker.plano.v1` (aba escolhida), que é de aparelho e por isso é a única
chave `fittracker.` que `sincronizavel()` exclui.

## Service worker

`sw.js` existe para a página abrir na rede da academia, ou sem rede nenhuma — o GitHub Pages
serve com `max-age=600`, então sem ele um retorno depois de 10 minutos trava no sinal ruim.

- **Subir `VERSAO` em `sw.js` a cada deploy que mexa na página.** É isso que faz o aparelho
  largar a cópia velha. Esquecer significa publicar uma correção que não chega no celular.
- Cache primeiro, atualização por baixo: a cópia nova entra na abertura seguinte. É o preço de
  abrir instantâneo.
- O SW ignora tudo que não é da mesma origem. Supabase e Google Fonts vão direto para a rede:
  resposta velha de API seria pior que erro.

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
- **A aba da bike não é escondida de quem não entrou.** A especificação pedia "visível apenas
  para sessão autenticada, coerente com o comportamento das demais" — mas as demais não são
  gated, e entrar nunca bloqueia nada nesta página. Esconder também não protegeria coisa
  alguma: a prescrição é hardcoded e o repositório é público, então ela vai no fonte do
  `index.html` para qualquer visitante de qualquer jeito. O que sobraria era o risco de um erro
  de autenticação deixar alguém sem o treino em cima da bike. Decidido com o Felipe.
- **Sem cadastro, magic link ou recuperação de senha na página.** O único endpoint de auth em
  uso é `token?grant_type=…`; conta é criada na mão no painel do Supabase. São duas contas, e
  cada tela dessas é rede a mais no caminho de quem só quer marcar uma série. Isto é uma
  ausência conhecida, não um esquecimento — se um dia houver mais gente, reavaliar.

(A antiga entrada sobre offline / service worker saiu: `sw.js` existe desde então, e a seção
"Service worker" acima descreve o que ficou.)

## Plataforma: por que continua Supabase + GitHub Pages

Migrar para **Vercel + Turso** (com Better-Auth ou Clerk) foi avaliado em agosto de 2026 e
recusado. As três razões, para não reabrir do zero:

- **Não há segredo a esconder.** A `sb_publishable_…` no fonte é pública por design; quem
  protege os dados é o RLS. "Esconder a chave num `.env` no servidor" resolve um problema que
  esta página não tem.
- **Turso não tem RLS, e o token dele é acesso total de leitura e escrita.** Ele não pode ir ao
  browser, então a function no servidor deixaria de ser escolha e viraria obrigação — e a
  separação Felipe/Ana sairia do Postgres para virar um `WHERE user_id = ?` escrito à mão em
  cada rota. Errar isso não dá erro, dá dado errado. É downgrade de segurança, não upgrade.
- **O Supabase pausar é problema de pinger, não de plataforma.** Ver a seção abaixo.

Storage nunca foi o gargalo: os dados são alguns KB, e o free do Supabase dá 500MB.

### Se a migração voltar à mesa

Cinco armadilhas, todas silenciosas — nenhuma delas dá erro, todas dão dado errado:

1. **`sw.js` ignora cross-origin, e é só por isso que ele não cacheia o Supabase.** Uma API em
   `/api/*` na Vercel seria **same-origin** e passaria a ser cacheada: resposta velha de sync,
   que é exatamente o que o comentário no `fetch` handler existe para evitar. Exigiria excluir
   `/api/` explicitamente.
2. **`estado_toca` precisa de equivalente.** Sem carimbo de servidor no UPDATE, o cursor delta
   nunca avança e todo aparelho fica permanentemente desatualizado naquela chave.
3. **O cursor `desde` é comparação lexicográfica de string** sobre o formato de timestamp que o
   servidor devolve. SQLite não tem `timestamptz`; mudar o formato (`Z` vs `+00:00`, com ou sem
   fração) para a sincronização sem avisar.
4. **`valor: null` é lápide, não `DELETE`.** Middleware que limpe nulls do JSON faz desmarcar
   série parar de propagar.
5. **`user_id` nunca é enviado pelo cliente** — vem do `default auth.uid()`. Qualquer backend
   novo tem que derivar o dono do token no servidor, ou o upsert perde a coluna de dono.

## Keepalive: o banco não pode pausar

O plano gratuito do Supabase pausa o projeto após 7 dias sem atividade, e religar é manual no
painel. Treinar já mantém vivo; o risco é férias ou lesão.

- **São dois pingers, de propósito.** `.github/workflows/supabase-keepalive.yml` roda a cada 3
  dias, e há um segundo no cron-job.org, externo, **diário** e em horário deslocado. Diário e não
  a cada 3 dias porque o agendador de lá é grade de dia-do-mês, não expressão cron: "a cada 3
  dias" só sairia marcando 1, 4, 7… que desalinha na virada do mês. Diário custa o mesmo e
  sobra margem.
- **O que confirma que o ping vale é `CF-Cache-Status: DYNAMIC` na resposta.** `HIT` seria um
  200 idêntico servido pelo Cloudflare sem tocar no Postgres — um pinger que parece saudável e
  não marca atividade nenhuma. Ao mexer no endereço ou nos headers, conferir isso, e não só o
  código de status. `Content-Length: 2` (o `[]`) mostra que o RLS fez o seu papel.
- **Um só não basta**, e não é redundância paranoica: o GitHub desativa workflow agendado após
  60 dias sem commits no repositório. Ou seja, "parei de treinar e parei de commitar" derruba o
  workflow e o banco junto — que é precisamente o cenário que ele deveria cobrir. Os dois
  pingers falham por motivos não correlacionados.
- Não trocar por `pg_cron` dentro do próprio Supabase: a atividade que conta para o timer é
  requisição externa.
- A página não depende disso para funcionar. Banco pausado significa sync parado, não treino
  perdido — o `localStorage` continua sendo a fonte de verdade.

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
