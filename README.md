# fit-tracker

Central de comando do meu ciclo de treino A/B: prescrição das séries, marcação de progresso e
carga por exercício, mais o resumo da semana e das macros.

Página estática de arquivo único, sem build nem dependências, feita para ser aberta no celular
durante o treino. O progresso fica salvo no `localStorage` do próprio navegador.

Em abas, na mesma página: o **Ciclo A/B** em vigor, o **PPL** anterior guardado para consulta e
a **Bike** intervalada — esta somente leitura, sem nada para marcar. As versões da prescrição da
bike que ainda não estão em vigor ficam em
[`docs/bike-intervalado.md`](docs/bike-intervalado.md).

As convenções do projeto, o contrato do `id` dos exercícios, como adicionar ilustrações e
quais decisões técnicas foram tomadas de propósito — estão em [`CLAUDE.md`](CLAUDE.md).
