# Bike intervalado — versões da prescrição

A aba **Bike** do `index.html` mostra **só a versão vigente**, hoje a **V1**. As versões
seguintes moram aqui e em nenhum outro lugar: prescrição que ainda não vale não pode chegar
perto da tela de quem está pedalando.

Este arquivo é a fonte da verdade de *o que existe*. O `index.html` é a fonte da verdade de
*o que está em vigor*. Trocar de versão é um deploy, não uma edição de dados — ver
[Como trocar de versão](#como-trocar-de-versão) no fim.

> **Por que um arquivo separado, e não comentário no código.** O `index.html` é arquivo único
> e dá para ler de ponta a ponta; enfiar três prescrições futuras dentro do `planos[]` faria a
> V2 conviver com a V1 a um descuido de distância de ser renderizada. Fora do código, o risco
> é zero e o histórico de cada versão fica em commit próprio.

---

## Estrutura da sessão

Sessão única, cerca de 35 a 40 min. Só o **bloco principal** muda entre as versões: aquecimento,
ativação e volta à calma são os mesmos em todas.

| Etapa | Prescrição |
|---|---|
| Aquecimento | 12 a 15 min, resistência baixa, cadência confortável, subindo aos poucos |
| Ativação | 3 tiros de 10 s, 1 min fácil entre eles |
| Bloco principal | **muda por versão** — ver abaixo |
| Volta à calma | 5 a 8 min |

### Por que não há coluna de intensidade

A intensidade é descrita **em palavras** — "resistência baixa", "forte", "fácil" — e é assim
que ela aparece na aba, no `det` de cada etapa. Não há número, e a ausência é escolha.

**Velocidade não serve.** No marcador de uma bike, km/h é função da rotação do volante e da
calibração daquele aparelho: 25 km/h na resistência 3 e na resistência 12 são esforços
completamente diferentes, e o número não transfere de uma bike para outra. Uma faixa de km/h
escrita aqui seria precisão falsa, e precisão falsa é pior que campo nenhum para quem está
seguindo a prescrição em cima do aparelho.

**PSE (percepção de esforço, de 0 a 10) chegou a ser implementado e foi retirado**, porque
resolvia o problema errado: quem tem marcador na bike quer um número para comparar com o
marcador, não outra escala subjetiva.

O que faria funcionar é calibração, não estimativa: medir na **sua** bike, uma vez, a que
velocidade e resistência cada etapa acontece, e fixar esses números aqui. Aí eles são medidos,
valem para aquele aparelho, e entram como um campo novo na etapa — trocar isso é deploy, como
qualquer outra mudança de prescrição.

---

## V1 — semanas 1 a 3 · **em vigor**

**8 tiros de 30 s forte, 90 s fácil entre eles.**

É esta que está no `planos[]`, no objeto `id:'bike'`.

## V2 — semanas 4 a 6

**10 tiros de 30 s, 75 s fácil entre eles.**

## V3 — semanas 7 a 9

**12 tiros de 30 s, 60 s fácil entre eles.**

## V4 — depois da V3

Duas variações **alternáveis** do bloco principal:

- 5 a 6 tiros de 60 s forte, 2 min fácil entre eles
- 4 blocos de 3 min em intensidade alta, 3 min fácil entre eles

A V4 **não substitui a V3**: as duas alternam. Quando ela entrar, a aba deixa de ter uma única
"versão vigente" e passa a ter duas prescrições válidas ao mesmo tempo — é o primeiro ponto em
que o componente de etapas, que hoje desenha uma sessão só, vai precisar mudar de verdade.

---

## Quando trocar de versão

Avaliação **por percepção**. O app não registra nada disto: não há campo, não há histórico, não
há nada salvo na aba da bike. Avançar quando as duas condições valerem:

1. Todos os tiros completos e o último no mesmo ritmo do primeiro, em **duas sessões seguidas**
2. Qualidade dos treinos de força na sequência da semana mantida

Se a segunda condição cair, **reduzir o número de tiros antes de trocar de versão**.

---

## Como trocar de versão

Tudo num commit só, em `index.html`, no objeto `id:'bike'` de `planos[]`:

1. `abaTag` — o rótulo da aba (`'V1'` → `'V2'`).
2. `sessao.badge` e `sessao.meta` — o círculo do card e o texto ao lado de "Treinamento".
3. A etapa com `forte:1` — `num`, `det` e **`reps`** do bloco principal. O `reps` é o que
   desenha a fileira de bolinhas do contador, e ela precisa ter o número de tiros da versão
   nova. Errar aqui não dá erro: dá contador com o número errado de bolinhas.
4. `sessao.avanco` — o critério no pé do card cita a versão seguinte pelo nome.
5. **`VERSAO` em `sw.js`.** Sem isso a correção não chega no celular, que é o único lugar onde
   esta página é lida.

Depois, aqui: mover o `**em vigor**` para a versão nova.

Nada de migração, nada de chave nova, nada para limpar no `localStorage` — a aba não grava
nada. O contador de tiros vive em memória e zera ao recarregar, de propósito: ele é do treino
de hoje, não um registro.

## O contador de tiros

Bloco com **4 repetições ou mais** ganha uma fileira de bolinhas, para não se perder a conta no
meio. Quem decide é o `reps` da etapa contra a constante `MIN_TIROS` no script. A ativação, com
3 tiros, fica sem — nesse tamanho dá para guardar de cabeça, e a fileira só ocuparia tela.

Todas as versões seguintes passam do limite (V2 tem 10, V3 tem 12, V4 tem 5 a 6 e 4), então
todas ganham contador sem precisar de nada além do `reps` certo.

A marcação é **cumulativa**, e não oito interruptores soltos como nos cards de força: tocar no
tiro 5 marca do 1 ao 5, e tocar de novo no último marcado volta um. Tiro é sequência, e a
pergunta em cima da bike é "em qual eu estou" — não "quais eu fiz".
