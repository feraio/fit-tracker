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
3. A etapa com `forte:1` — `num` e `det` do bloco principal.
4. `sessao.avanco` — o critério no pé do card cita a versão seguinte pelo nome.
5. **`VERSAO` em `sw.js`.** Sem isso a correção não chega no celular, que é o único lugar onde
   esta página é lida.

Depois, aqui: mover o `**em vigor**` para a versão nova.

Nada de migração, nada de chave nova, nada para limpar no `localStorage` — a aba é somente
leitura e não guarda estado nenhum.
