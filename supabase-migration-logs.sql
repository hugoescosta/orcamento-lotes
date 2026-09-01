-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Cria a tabela de logs de uso do app: login/logout, trocas de senha,
-- trocas de dispositivo, buscas de lote, geração de PDF, negações de
-- acesso, e qualquer evento relevante registrado pelo app.

create table public.logs (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  user_email text,
  event_type text not null,
  product_id uuid references public.products(id) on delete set null,
  device_id text,
  details jsonb
);

alter table public.logs enable row level security;

-- Qualquer inserção é permitida (inclusive antes do login, ex: tentativa de
-- login que falhou) — não existe política de leitura para usuários comuns,
-- então ninguém além do painel de administração (que usa a chave secreta,
-- sem passar pelas regras de segurança) consegue LER os logs.
create policy "Qualquer inserção de log é permitida"
  on public.logs for insert
  with check (true);

create index idx_logs_created_at on public.logs (created_at desc);
create index idx_logs_user_id on public.logs (user_id);
create index idx_logs_event_type on public.logs (event_type);
