-- fit-tracker · schema do Supabase
-- Rodar inteiro no SQL Editor do projeto. É idempotente: dá para rodar de novo.
--
-- Modelo: uma linha por chave do localStorage, por pessoa. As chaves são as
-- mesmas que a página já usa (fittracker.ab.v1.B.puxada-frontal.1), então não
-- existe tradução entre o navegador e o banco.

create table if not exists estado (
  user_id       uuid not null references auth.users on delete cascade default auth.uid(),
  chave         text not null,
  valor         text,                       -- null = apagado (lápide, ver abaixo)
  atualizado_em timestamptz not null default now(),
  primary key (user_id, chave)
);

-- `valor = null` é lápide, não DELETE. Sem isso, desmarcar uma série no celular
-- seria ressuscitado pela linha velha do tablet na sincronização seguinte.

-- O `default now()` só vale no INSERT. Como o cliente usa upsert
-- (Prefer: resolution=merge-duplicates), o UPDATE precisa deste gatilho para
-- carimbar a hora do servidor — é ele que decide quem vence, e não o relógio do
-- aparelho, que erra.
create or replace function toca_atualizado_em() returns trigger as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists estado_toca on estado;
create trigger estado_toca
  before insert or update on estado
  for each row execute function toca_atualizado_em();

-- Índice do delta: o cliente só pede o que mudou desde a última sincronização.
create index if not exists estado_delta on estado (user_id, atualizado_em);

-- ---------------------------------------------------------------------------
-- Row Level Security
--
-- ISTO é o que protege os dados. A chave anônima vai no fonte da página, que é
-- público — ela é inofensiva só porque toda tabela tem RLS ligado e política
-- explícita. Uma tabela sem RLS é lida por qualquer pessoa que tenha a chave.
-- ---------------------------------------------------------------------------
alter table estado enable row level security;

drop policy if exists "dono lê"       on estado;
drop policy if exists "dono insere"   on estado;
drop policy if exists "dono atualiza" on estado;
drop policy if exists "dono apaga"    on estado;

create policy "dono lê"       on estado for select using (auth.uid() = user_id);
create policy "dono insere"   on estado for insert with check (auth.uid() = user_id);
create policy "dono atualiza" on estado for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dono apaga"    on estado for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Keepalive por ESCRITA
--
-- Em outubro de 2026 o projeto foi pausado por "7 dias de inatividade" com os
-- dois pingers verdes. O ping era um SELECT do PostgREST que devolvia
-- HTTP 200, CF-Cache-Status: DYNAMIC e corpo []: tecnicamente perfeito, e
-- mesmo assim o timer não reiniciou. A hipótese que sobrou é que leitura não
-- conte, ou não conte sozinha — um SELECT não gera WAL nem toca disco.
--
-- HIPÓTESE NÃO VERIFICADA. Isto aqui é o experimento, não a solução provada.
-- Ver a seção "Keepalive" no CLAUDE.md antes de mexer.
--
-- A forma importa tanto quanto a função. A alternativa óbvia seria uma tabela
-- com política de UPDATE para `anon`, e ela foi recusada: o repositório é
-- público e a chave publicável está no fonte da página, então isso seria uma
-- escrita aberta a qualquer pessoa da internet. Aqui a tabela fica com RLS
-- ligado e ZERO políticas, o que a torna inalcançável pela API, e quem escreve
-- é uma função `security definer` que roda como dona e ignora o RLS.
--
-- O que o `anon` ganha com isso é exatamente um verbo: carimbar um timestamp.
-- Não lê nada, não insere, não apaga, e não chega perto de `estado`.
-- ---------------------------------------------------------------------------
create table if not exists keepalive (
  unico boolean primary key default true check (unico),
  em    timestamptz not null default now()
);

-- Uma linha, e só uma: a chave primária é um booleano que só aceita `true`.
insert into keepalive (unico) values (true) on conflict (unico) do nothing;

-- RLS ligado e nenhuma política. Toda tabela precisa de RLS (sem ele, a chave
-- publicável lê tudo); sem política nenhuma, nem o anon nem o autenticado
-- alcançam esta tabela pela API. É intencional.
alter table keepalive enable row level security;

-- `security definer` é a parte afiada: a função roda com os privilégios da
-- dona e passa por cima do RLS. Por isso ela não recebe argumento nenhum, toca
-- uma linha de uma tabela só, e o corpo é fixo. Nunca dar parâmetro a ela, e
-- nunca deixar ela encostar em `estado`.
--
-- O `search_path` fixo fecha o truque de plantar um objeto homônimo num schema
-- que venha antes no caminho de busca.
--
-- Ela devolve o carimbo ANTERIOR, não o novo. Assim a resposta diz quando foi
-- o ping passado, e dá para ver se o outro pinger continua vivo sem precisar
-- de permissão de leitura na tabela.
create or replace function keepalive_toca() returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare anterior timestamptz;
begin
  select em into anterior from keepalive where unico;
  update keepalive set em = now() where unico;
  return anterior;
end;
$$;

revoke all on function keepalive_toca() from public;
grant execute on function keepalive_toca() to anon, authenticated;

-- Chamada: POST /rest/v1/rpc/keepalive_toca com o header apikey e mais nada.
-- POST e não GET porque a função escreve, e o PostgREST só aceita GET em
-- função declarada stable ou immutable.
