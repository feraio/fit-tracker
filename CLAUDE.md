# fit-tracker

Página estática de acompanhamento de treino, usada principalmente **no celular, dentro da
academia, entre séries**. Densidade e velocidade de leitura importam mais do que qualquer outra
coisa nesta página.

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

**O plano é o Ciclo A/B; a FASE é que muda a cada quatro semanas.** Hoje a fase é Adaptação, e
ela aparece só no `eyebrow` ("Central de comando · Fase de adaptação"). Quando virar Iniciante,
o que muda são os exercícios dos blocos e essa string — não o nome do plano, não a aba, não o
prefixo de persistência. Foi decisão explícita do Felipe, para não renomear tudo de quatro em
quatro semanas.

A chave é `fittracker.ab.v2.`. O `v1` era outro conjunto de exercícios, de antes desta
prescrição; as chaves `fittracker.ab.v1.*` continuam gravadas, órfãs, e ficam assim (ver
abaixo).

- Cada plano traz o próprio cabeçalho (`eyebrow`, `titulo`, `lede`, `legenda`), a própria faixa
  de semana e os próprios treinos. `renderCabecalho()` reescreve tudo isso, que vive **fora** de
  `#treinos`; `render()` cuida só dos cards.
- **Não existe mais faixa da semana (o calendário Seg a Dom).** Ela saiu de todos os planos, a
  pedido do Felipe, junto com `renderSemana()`, o CSS de `.week`/`.day`/`.legend` e o campo
  `semana[]` dos dados. O treino virou três sessões por semana em rotação A-B-A-B, sem dia fixo,
  então um calendário desenhado mentiria sobre qual treino é o de hoje. Não confundir com a
  faixa de **semana do ciclo** (`.semanas`), que é outra coisa e está viva.
- **A preferência `fittracker.prefs.v1.semana` morreu junto**, porque existia só para ligar e
  desligar esse calendário. Com ela saíram `mostrarSemana()`, o `[data-pref]` do handler de
  `change` e o bloco `.login-prefs` do diálogo de conta, que agora só tem e-mail e senha. O
  namespace `fittracker.prefs.v1.` continua reservado para preferência **de conta** (sincroniza,
  ao contrário de `fittracker.plano.v1`), mas hoje não tem nenhum membro.
- **Não existe mais caixa de nota por plano.** As duas que havia saíram na revisão da aba da
  bike: a de retorno lombar repetia o que o botão de fase dizia na época (a fase também já
  saiu, ver acima), e a de rotação do PPL descrevia um plano que não está em vigor. Com isso `#planoNota` e o CSS de `.note` também
  saíram — não sobrou caminho de render sem conteúdo. As notas **por exercício** (`ex[].nota`,
  classe `.ex-note`) são outra coisa e continuam.
- **Nenhum exercício tem `flag` hoje**, e por isso a legenda AJUSTE/LOMBAR saiu do `<footer>`:
  ela explicava tarjas que não existiam mais em lugar nenhum da página. O mecanismo (`ex[].flag`,
  `flagOk`, o CSS de `.flag`) continua no lugar, porque uma prescrição nova pode trazer um ponto
  a confirmar com a personal. Quem reintroduzir uma `flag` precisa devolver a legenda junto,
  senão a tarja fica sem explicação.
- **Cada plano tem o seu prefixo de persistência** (`key`): `fittracker.ab.v1.` e
  `fittracker.ppl.v1.`. Trocar de aba nunca mistura séries nem cargas. O prefixo do A/B não
  muda nunca — é onde já estão os dados salvos no navegador de quem usa a página.
- **O Ciclo A/B tem `semanas[]` no lugar de `treinos[]`.** É o primeiro plano assim. Cada bloco
  (`Semana 1`, `Semana 2`, `Semanas 3-4`) traz os próprios `treinos[]`, com os próprios
  exercícios e o próprio número de séries: a semana 1 e a 2 têm 3, as semanas 3 e 4 têm 4 e
  ganham exercícios novos. `blocoAtual()` resolve qual vale, e `render()` desenha o bloco.
  Plano sem `semanas[]` (PPL, Bike) segue lendo `plano.treinos` direto, e `renderSemanas()`
  esconde a faixa neles.
- **A semana escolhida (`fittracker.ab.v2.semana`) SINCRONIZA.** Não é preferência de
  aparelho: é em que ponto do ciclo a pessoa está, e isso é o mesmo no celular e no tablet. A
  única chave `fittracker.` que não sincroniza continua sendo `fittracker.plano.v1`, a aba.
- **A variação por semana é prescrição escrita, não regra aplicada por cima.** Cada bloco lista
  os exercícios por extenso, inclusive os repetidos. Derivar a semana 2 da semana 1 pouparia
  linhas e esconderia a troca do Tríceps Corda pelo Tríceps na Polia, que é justamente o tipo de
  detalhe que se confere em cima do aparelho. É por isso também que a fase antiga não volta: ela
  era um corte global de séries, e isto aqui é a prescrição real.
- **`r` e `rs` são exclusivos.** `r` é a repetição quando é igual em todas as séries; `rs` é a
  lista quando ela cai no fim (semana 2 e semanas 3-4 do Treino A). `prescDe()` resume em
  `4 × 12-15 → 10-12` em vez de listar as quatro, e a repetição exata de cada série vai no
  `aria-label` da bolinha, que é onde ela é perguntada.
- **O aquecimento é regra do treino, não propriedade de um exercício.** Ele vive numa `.t-nota`
  acima da lista, com texto fixo, e não num campo dos dados. Já esteve pendurado no primeiro
  exercício e o Felipe apontou o erro: a regra vale para qualquer treino, e lida dentro do
  "Crucifixo" ela parecia uma instrução daquele exercício. É nota e não bolinha porque, como
  série, inflaria a contagem do treino com trabalho que não é o prescrito.
- **`eq` é a lista de equipamentos aceitos, e fica fora do `n`.** "Crucifixo" é o que se varre na
  lista; "halter · cabo · máquina" é o que se lê uma vez e depois vira ruído. Separado, o nome
  fica com a primeira linha inteira e o ícone de vídeo para de cair numa linha sozinha.
- **O cardio é uma entrada do treino, com `semKg:1`.** 30 minutos, marcável como qualquer série.
  **30 é o número do Felipe, não o do PDF**, que para ganho de massa pede 25-30 e reserva 30-45
  para recomposição corporal. Está escrito no código para ninguém "corrigir" depois.
- **Não existe mais fase.** A prescrição desenhada é sempre a cheia, o número de séries vem
  direto de `ex[].s`, e não há mais `KEY_MODO`, `seriesDe()`, `RETORNO`, `semFase`, a faixa de
  botões `.phase` nem a tarja `.goal` ("alvo N"). A fase de retorno saiu primeiro do PPL (plano
  de consulta, cortá-lo mostrava prescrição que nunca foi prescrita) e depois do A/B, a pedido
  do Felipe: o retorno lombar acabou, e um seletor cuja única posição útil é "completa" é
  escolha falsa ocupando a primeira tela. Não reintroduzir sem prescrição nova da personal.
  Quem precisar de uma redução temporária mexe em `ex[].s`, que é um deploy e fica registrado —
  a fase era estado de aparelho fazendo o papel de prescrição.
- **As chaves `fittracker.ab.v1.*` continuam gravadas, órfãs, e ficam assim de propósito.**
  Nenhum código as lê desde que a prescrição mudou e o prefixo virou `ab.v2.`. Apagá-las seria
  escrever lápide e propagá-la a todos os aparelhos para limpar bytes inertes.
- As abas seguem o padrão `tablist`, com `aria-selected`, tabindex móvel e navegação por
  setas. O `keydown` é delegado no `document` pelo mesmo motivo do clique: `renderAbas()`
  reescreve os botões a cada troca.
- Os macros do bloco Nutricional são iguais nos dois planos, então ficam fora da alternância.
- `semKg:1` no exercício esconde o campo de carga (aquecimento, trabalho por tempo).
- **O cabeçalho "Treinamento" não tem mais contador de séries à direita** (`#totalMeta`, que lia
  "57 séries no ciclo A-B" e, na bike, "V1 · sessão de 35 a 40 min"). Saiu a pedido do Felipe:
  o número que importa entre séries é o do card que está na mão, e esse continua no `t-prog` e
  no rodapé de cada treino. Um total de ciclo no topo é contabilidade, não prescrição. O `.meta`
  do bloco Nutricional é outro e continua.

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
- **A carga é `type="text"` de propósito, com `data-dec="1"`.** `type="number"` só reconhece o
  ponto como separador decimal, em qualquer idioma, e **rejeita a tecla da vírgula**: o
  caractere não chega a ser inserido, então a tela não muda e nada indica que algo foi recusado.
  O teclado decimal do iPhone mostra o separador da região — em pt-BR, a vírgula — então quem
  digitava "10,5" acabava com **"105" salvo em silêncio**. O defeito não era perder a carga: era
  gravar a carga errada, dez vezes maior, sem aviso. (Um valor com vírgula que chegasse pelo
  `value=` do render viraria `""` de fato, e aí sim o handler apagaria a chave — mas pelo
  `type="number"` esse valor nunca conseguia ser salvo, então o caminho não era alcançado.
  Registrado aqui porque ele volta a existir se alguém trouxer `type="number"` de volta.)
  Com `text` o que foi digitado chega inteiro ao handler e `normDec()` troca vírgula por ponto,
  junta ponto repetido, descarta o que não é dígito (sem `type="number"` não há mais
  `min`/`step` para segurar sinal e letra) e devolve o valor normalizado ao campo — ver o
  número mudar de "10,5" para "10.5" é o retorno de que entrou. **Gravar sempre com ponto** é o
  que mantém o número legível igual nos dois aparelhos e no Supabase. Os campos da nutrição
  continuam `type="number"`: são inteiros, e sem casa decimal a vírgula não aparece no caminho.

## Bike intervalado

A **prescrição** da bike é somente leitura: as etapas são conferidas em cima do aparelho e não
recebem input. O que recebe input é o **pé do card**, e só ele.

- **`leitura:1` separa a prescrição.** `render()` desvia para `renderLeitura()`, que desenha
  etapas em vez de cards — a bike não tem `treinos[]`, porque não tem exercício, carga nem
  repetição.
- **A bike REGISTRA sessão desde setembro de 2026, e por isso ganhou `key`
  (`fittracker.bike.v1.`).** Foi pedido do Felipe: ele já registrava as sessões de bike no
  Garmin e no GymRats, e queria os três tipos de treino num banco só. Tempo detalhado e métrica
  fina seguem no Garmin; aqui fica o que serve para lembrar que a sessão aconteceu.
  A entrada anterior dizia que "nada nesta aba encosta no `localStorage`". **Isso não vale
  mais.**
- **A sessão registra três coisas e mais nada**: tiros por etapa, tempo total em minutos e
  nível de esforço (o mesmo componente `.sens` dos cards de força). Escopo definido pelo Felipe,
  e vale respeitar: sem carga, sem repetição, sem observações. Se um dia entrar observação, é
  decisão nova.
- **O contador de tiros passou a persistir, e isto reverte uma decisão registrada.** Ele vivia
  só em memória porque, sem um jeito de fechar a sessão, gravar faria a de segunda abrir com os
  oito tiros já marcados. **Com o Finalizar existindo, essa razão caiu** — e ficar em memória
  virou o problema, porque o número que a sessão precisa registrar é justamente este. Um campo
  guarda as duas coisas, o "em qual eu estou" e o "quantos fiz", em vez de um contador volátil
  mais um campo de registro que poderiam divergir. É o mesmo princípio das repetições feitas nos
  cards de força.
- **Os tiros são chaveados pelo `id` da etapa, nunca pelo índice.** O contrato do `id` vale aqui
  como vale para exercício: reordenar as etapas com chave por índice reatribuiria a contagem à
  etapa errada, em silêncio. Só etapa com `reps` ≥ `MIN_TIROS` **e** com `id` conta tiro
  (`temTiros()`), e é a mesma função que decide se a etapa aparece no detalhe do histórico — uma
  etapa que nunca conta (a ativação, com 3) não pode aparecer lá com um traço eterno fingindo
  que faltou algo. Prescrição nova que dê 4 ou mais tiros a uma etapa precisa dar `id` a ela.
- **`finalizarLeitura()` é o `finalizar()` dos planos sem exercício.** Mesma forma (varre
  `atual.`, move para `log.<id>.`, apaga a origem, com a mesma volta para o navegador que recusa
  enumerar o `localStorage`), sem o retrato de carga, que não existe aqui. A meta guarda
  `versao` e não `semana`: o que muda a prescrição da bike é a versão, e é ela que dá sentido ao
  número de tiros de uma sessão antiga.
- **A sessão inteira não cabe mais numa tela.** A prescrição cabe: do topo até o critério de
  avanço são ~930px numa tela de 844, e o pé de registro leva a página a ~2040px. É o preço de
  registrar, e é aceitável porque o pé é lido no fim, não entre os tiros. Ao mexer no cabeçalho
  desta aba, o que se confere agora é que a **prescrição** continua perto de uma tela.
- **A intensidade é descrita em palavras, não em número.** "Resistência baixa", "forte",
  "fácil" — no `det` da etapa, como na especificação. Não há campo de velocidade nem de PSE, e
  isso é decisão: km/h no marcador de bike é função da calibração daquele aparelho e não
  transfere entre bikes, e uma escala subjetiva não ajuda quem já tem marcador. Número
  estimado aqui seria precisão falsa. `docs/bike-intervalado.md` guarda o argumento inteiro e
  o que faria funcionar (calibrar na bike de verdade e fixar o medido).
- **Bloco com `reps` ≥ `MIN_TIROS` (4) ganha a fileira de bolinhas.** Abaixo disso dá para
  guardar de cabeça e a fileira só ocuparia tela — a ativação, com 3 tiros, fica sem. A bolinha
  `.tiro` divide o CSS com a `.set` dos cards de força, porque são a mesma bolinha; o que não se
  divide é o comportamento, e por isso são classes distintas com ramos distintos no handler de
  clique. A marcação é **cumulativa** (tocar no 5 marca do 1 ao 5, tocar de novo volta um): tiro
  é sequência, e a pergunta em cima da bike é "em qual eu estou".
- **Só a versão vigente é renderizada.** A V2, a V3, a V4 e o critério de avanço estão em
  `docs/bike-intervalado.md`, que também traz o passo a passo de trocar de versão. Prescrição
  que ainda não vale não pode ficar a um descuido de distância de ser desenhada.
  Trocar de versão é um deploy, não uma edição de dados.
- **O componente é desenhado para ser lido de longe**, com o corpo em movimento: número grande
  sempre na mesma coluna à direita, uma etapa por linha, e o bloco principal destacado com o
  `--accent` do card. O critério de avanço fica no **pé** da prescrição, que é quando ele é
  lido: no fim da sessão, logo antes do registro.
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

## Sessão e registro

O personal pediu para registrar peso, repetições feitas, como a sessão foi e observações. Isso
virou um **log por sessão**, e **nenhuma migração de banco foi preciso**: a tabela `estado` do
Supabase é chave/valor genérica, então o histórico é só um conjunto de chaves novas que já entra
na fila, na lápide e no RLS que existiam. Quem for mexer nisso não precisa tocar em SQL.

- **`atual.` é a sessão em andamento; `log.<id>.` é a sessão fechada.** Tudo sob
  `fittracker.ab.v2.atual.<treino>.` é o que está sendo preenchido agora. `finalizar()` move
  para `fittracker.ab.v2.log.<id>.` e apaga a origem, e a lápide faz a sessão sumir do card
  nos outros aparelhos também.
- **A CARGA NÃO MORA NA SESSÃO.** Ela fica em `fittracker.ab.v2.kg.<treino>.<exercício>`, fora
  de `atual.`, porque é o valor corrente daquele exercício e não um dado de uma sessão só. O
  Finalizar **copia** para o log e **deixa o campo preenchido**: voltar na quinta e reencontrar
  a barra vazia seria perder exatamente o número que o personal mandou anotar. Zerar é apagar o
  campo à mão. O retrato copiado para o log é dos exercícios do bloco desenhado.
- **O `<id>` da sessão é `Date.now()`.** Não colide entre aparelhos sem contador combinado e
  ordena o histórico sozinho. Relógio de cliente erra, e é exatamente por isso que ele **não**
  decide conflito em lugar nenhum desta página; aqui é só ordenação de leitura, o único uso em
  que errar não corrompe nada. Data não é pedida nem mostrada: o Felipe não quer preencher data.
- **A presença da chave da série é o que marca a bolinha, e o valor dela são as repetições
  feitas.** Um campo guarda as duas coisas em vez de um `'1'` e um número que poderiam divergir.
  Exercício sem repetição contável (prancha, cardio) grava `'1'`: continua marcável, só não tem
  número a pedir. Quem decide é `metaDe()`, que extrai o primeiro número da prescrição e devolve
  vazio em `30s-1min`.
- **O campo de repetições só aparece depois que a série é marcada, já com a meta dentro.** Card
  de treino que ainda não começou tem exatamente a densidade de antes: nenhuma linha extra,
  nenhum campo pedindo atenção. Bateu a meta, não se digita nada.
- **Esvaziar o campo de repetições NÃO desmarca a série** (`data-meta` no input, tratado no
  handler de `change`). A regra geral da página é "campo vazio apaga a chave", e aqui a chave é
  o que marca a bolinha: seguir a regra desmarcaria a série só porque a pessoa limpou o número
  para redigitar. Pior, em silêncio — a bolinha continuava pintada até o próximo render, e aí a
  série sumia sem ninguém encostar nela. Selecionar tudo e apagar antes de digitar é o gesto
  normal num teclado de celular. Vazio volta para a meta. O campo de **carga** segue a regra
  geral e apaga, porque ali vazio significa mesmo "não tem carga".
- **O campo de repetições é inteiro, e trunca no primeiro caractere que não é dígito**
  (`data-int="1"`). Descartar os não-dígitos em vez de truncar faria "12,5" virar 125: uma
  contagem dez vezes maior, gravada em silêncio, exatamente o formato do defeito que o campo de
  carga tinha com `type="number"`. Truncando vira 12.
- **`finalizar()` varre por prefixo, não reconstrói as chaves a partir do bloco.** Assim uma
  sessão começada numa semana e finalizada depois de trocar de bloco leva tudo junto. Há uma
  volta para o navegador que recusa enumerar o `localStorage` (aba privada do Safari), em que as
  chaves são reconstruídas a partir do bloco desenhado: sem ela o Finalizar virava botão morto e
  a sessão se perdia em silêncio, que é pior que a lacuna que a varredura cobre.
- **Não existe mais "Zerar treino".** A sessão é fechada pelo Finalizar, que guarda em vez de
  descartar, e desmarcar uma série é tocar nela de novo. O Finalizar é um botão de largura cheia
  porque é o último toque da sessão, dado em pé; ele herda o `--accent` do card, então o A é
  vermelho e o B é azul.
- **Existe UMA caixa de confirmação para toda a página** (`#confirmaBox`, um `<dialog>` fora de
  `#treinos` como manda a arquitetura). `pedirConfirmacao(titulo, texto, rotulo, acao)` preenche
  o texto e guarda o que fazer no "sim". Usam ela o Finalizar e o apagar do histórico; duas
  caixas quase iguais seriam uma para manter em sincronia com a outra.
- **`confirmaAcao` guarda a ação em memória, não no DOM.** `render()` reescreve `#treinos` e o
  diálogo vive fora dele, então um `data-` no card não sobreviveria. O handler de `cancel` (o
  ESC do `<dialog>`) zera a variável: sem isso a ação ficaria pendurada e o próximo "sim"
  executaria a anterior.
- **ESC e toque no backdrop caem no lado do "não".** Quem esbarrou no botão não pode perder a
  sessão por não achar o cancelar.
- **Tocar numa bolinha chama `render()` inteiro**, e não só `updateProg()`, porque a linha de
  repetições aparece e some com a marcação. É barato: a delegação no `document` não religa nada,
  e não há campo em foco quando se toca numa bolinha (o `change` do campo dispara antes, no
  blur).

### Preferências de conta

`fittracker.prefs.v1.*` é o namespace reservado para preferência **de conta**, não de aparelho:
sincroniza, ao contrário de `fittracker.plano.v1` (a aba escolhida), que é a única chave
`fittracker.` que `sincronizavel()` exclui. **Hoje não tem nenhum membro**: a única preferência
que existiu ligava a faixa da semana, e saiu com ela. Se voltar a haver uma, ela vai no diálogo
de conta, que já existe — não abrir uma tela de configurações para isso.

## Histórico

É uma **vista**, não um arquivo: mora no hash (`#historico` para a lista, `#historico/<id>` para
a sessão), e `vistaAtual()` é o roteador. O `hashchange` chama `renderCabecalho()` e `render()`,
porque o título, o eyebrow e o link mudam com a vista e os três vivem fora de `#treinos`.

- **Por que hash e não arquivo separado, já que o Felipe pediu uma página.** O hash entrega o
  que ele queria: endereço de verdade (o botão voltar do celular funciona, dá para favoritar),
  a vista já sai filtrada pelo plano de onde se entrou, e não é aba. Um `.html` separado
  custaria as 862 linhas de CSS e, pior, as ~278 linhas da camada de sincronização, cujas
  sutilezas esta documentação inteira descreve: duas cópias significam uma correção que chega só
  numa metade, e o sintoma disso é dado errado, não erro. Se um dia valer o arquivo separado,
  ele pode ler o `localStorage` direto (mesma origem) e enfileirar a lápide sem duplicar o push
  e o pull — mas aí uma página passa a gravar numa fila que outra esvazia, e esse acoplamento é
  o que se está comprando.
- **NÃO HÁ GATE DE LOGIN, e não é esquecimento.** O histórico é o `localStorage` do próprio
  aparelho: quem abre o endereço público vê o `localStorage` dele, vazio, e quem chega nos dados
  é quem está com o celular destravado — e essa pessoa já podia marcar série e apagar carga sem
  login nenhum. Quem protege o dado no servidor é o RLS, no Postgres. Esconder tela não
  protegeria nada e criaria um jeito novo de ficar sem o próprio treino (sessão expirada =
  histórico vazio com os dados intactos no aparelho), que é a mesma armadilha que a decisão da
  aba da bike já recusou. Sem login, uma linha diz que está mostrando só as sessões daquele
  aparelho: entrar muda o que **vem** dos outros, não o que já está ali.
- **A data sai de graça do `id` da sessão.** Ela nunca foi pedida ao Felipe, mas o `Date.now()`
  do Finalizar estava guardado desde sempre para ordenar. "hoje" e "ontem" por extenso, porque é
  assim que se pensa numa lista curta.
- **`lerLog()` devolve `null` quando não dá para enumerar o `localStorage`**, e a tela avisa.
  Uma lista vazia ali mentiria dizendo que não há sessão nenhuma.
- **O detalhe lê o histórico, não a prescrição de hoje.** Os exercícios saem na ordem do bloco
  daquela sessão, e o que já saiu do plano entra no fim pelo id cru em vez de sumir: o registro
  precisa continuar legível depois que a fase mudar.
- **Apagar escreve lápide em cada chave da sessão**, nunca `DELETE`, que é o que faz a sessão
  sumir também nos outros aparelhos. Vai atrás da confirmação, como o Finalizar.
- **`pintarLinkHistorico()` é chamado por `render()` e por `renderCabecalho()`.** A contagem
  muda a cada sessão finalizada e apagada, e esses caminhos redesenham os cards sem passar pelo
  cabeçalho; só no cabeçalho, o número ficava um passo atrás do que a pessoa acabou de fazer.
- **Trocar de aba sai do histórico.** O histórico é de um plano, e continuar nele depois de
  trocar mostraria a lista de um com o cabeçalho do outro. Plano sem `key` (a bike) não registra
  sessão, então o link não aparece e um `#historico` forçado na URL cai de volta no treino.
- **O PPL ganhou histórico de graça, e foi ele que revelou dois defeitos.** Nada no registro é
  específico do A/B: `plano.key` é o que decide, então qualquer plano com `key` e `treinos[]` já
  marca série, grava carga, finaliza e lista. Mas o PPL não tem `semanas[]`, e dois pontos do
  código tratavam o bloco como se sempre houvesse um:
  - `bloco.descanso` é campo do bloco de semana. Sem bloco, o rodapé do PPL lia
    "18 séries · 6 itens · **undefined**". Agora o trecho só entra quando existe.
  - `finalizar()` gravava `semana: bloco.id`, e sem `semanas[]` o bloco é o próprio plano: o
    registro do PPL saía com `semana: "ppl"` e a lista mostrava "semana ppl". Agora `semana` só
    é gravada quando o plano tem blocos, e **`rotuloSemana()` resolve o rótulo pelos blocos do
    plano em vez de imprimir o valor cru** — sessão antiga com um valor que não corresponde a
    bloco nenhum simplesmente não mostra semana, em vez de inventar uma.

  A lição para quem adicionar plano novo: `semanas[]` é opcional, e todo código que lê `bloco`
  precisa aguentar o bloco ser o próprio plano.
- **A bike também tem histórico**, desde que passou a registrar sessão (ver "Bike intervalado").
  Como ela não tem exercício nem carga, `renderSessao()` desvia para `renderSessaoLeitura()` no
  detalhe, e `resumoDaSessao()` é o único lugar que decide o que resume uma sessão: força conta
  série, bike conta tiro e minuto. Um lugar só, para a lista e o detalhe não divergirem.

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
  destoa do tom da página. **Link comum para o YouTube é outra coisa e existe** (ver
  "Demonstração em vídeo" abaixo): um `<a target="_blank">` não baixa nada, não roda nada e não
  atrasa a primeira pintura. A proibição é de embed, não de link.
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

## Demonstração em vídeo

`VIDEOS` mapeia `id` do exercício para um endereço do YouTube, e faz aparecer um ícone discreto
de play ao lado do nome. Chaveado pelo `id`, como `assets/ex/<id>.webp`: **uma entrada por
exercício**, e não uma cópia em cada bloco de semana. Exercício sem entrada não ganha ícone.

- É um `<a href target="_blank" rel="noopener noreferrer">`, não um botão: abre fora e nem passa
  pelo handler de clique delegado. Nada é embutido na página.
- **Procedência, e por que ela importa aqui.** Os endereços vieram das anotações de link do PDF
  da personal, extraídos por posição na página. **A coluna de links do PDF está deslocada**: na
  primeira tabela de cada treino ela bate, e nas demais o link da linha N está na linha N-1. O
  mapa foi montado cruzando as cinco tabelas e ficando com o que a maioria diz; o Felipe
  conferiu três títulos (crucifixo, puxada e supino reto) e os três caem onde o modelo prevê.
- **`triceps-corda` fica de fora de propósito.** O PDF repete nele o link da rosca direta, que
  duas tabelas confirmam ser da rosca. Link errado numa fase que é sobre técnica é pior que link
  nenhum.
- Cinco entradas vêm de uma tabela só (`remada-unilateral`, `elevacao-lateral`,
  `triceps-frances`, `agachamento`, `abdominal-crunch`). Estão marcadas no código. Se alguma
  abrir o vídeo errado, é uma delas.
- Ao receber uma prescrição nova, **não confiar na ordem dos links do PDF**. Extrair, cruzar as
  tabelas e conferir pelo menos um título antes de publicar.

## Ilustrações: origem e licença

O repositório é **público**, então a procedência das imagens importa.

- **Fonte primária: [wger](https://wger.de)** — CC-BY-SA 4.0, com `license` e `licenseAuthor`
  em cada registro da API, o que torna a atribuição rastreável imagem a imagem.
- Lacunas: Wikimedia Commons, verificando a licença arquivo a arquivo.
- **Não usar `free-exercise-db`.** Declara Unlicense, mas a proveniência das imagens é
  questionada em issues abertas do próprio repositório e nunca foi esclarecida. Um repo
  declarar domínio público não transfere esse status a imagens de terceiros.
- CC-BY-SA exige atribuição — vai no `<footer>`, que existe e hoje só tem a data justamente
  para caber isso. Imagem recortada ou editada é
  obra derivada e continua CC-BY-SA.

`assets/ex/agachamento-hack.webp` é um **placeholder autoral**, feito só para o mecanismo ser
verificável ponta a ponta. Substituir pela ilustração real.
