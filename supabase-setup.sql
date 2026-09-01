-- Execute este script inteiro no SQL Editor do Supabase (New query -> colar -> Run)
-- Use este script apenas para um PROJETO NOVO. Se você já tem a tabela
-- "profiles" criada, use o arquivo supabase-migration-dados-corretor.sql
-- em vez deste (só adiciona as colunas novas, sem apagar nada).

-- Tabela de perfis: guarda a data de validade, o status e os dados de
-- contato de cada usuário (nome, WhatsApp, Creci)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  whatsapp text,
  creci text,
  expires_at date not null,
  active boolean not null default true,
  created_at timestamptz default now()
);

-- Ativa segurança em nível de linha (cada usuário só enxerga o próprio perfil)
alter table public.profiles enable row level security;

create policy "Usuário vê apenas o próprio perfil"
  on public.profiles for select
  using ( auth.uid() = id );
