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
