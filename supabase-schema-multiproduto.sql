-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Cria a estrutura para múltiplos produtos (loteamentos), cada um com sua
-- própria lista de lotes, e o vínculo de quais usuários têm acesso a quais
-- produtos.
--
-- Este script é seguro para rodar de novo do zero (remove qualquer versão
-- parcial criada numa tentativa anterior antes de recriar tudo).

-- ---------------------------------------------------------------------------
-- Limpeza (caso uma tentativa anterior tenha criado parte da estrutura)
-- ---------------------------------------------------------------------------
drop table if exists public.lotes cascade;
drop table if exists public.user_products cascade;
drop table if exists public.products cascade;

-- ---------------------------------------------------------------------------
-- Tabela de produtos (cada loteamento/empreendimento é um produto)
-- ---------------------------------------------------------------------------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  active boolean not null default true,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------------
-- Vínculo usuário <-> produto liberado (um usuário pode ter vários produtos)
-- Criada antes das políticas de "products", porque elas fazem referência
-- a esta tabela.
-- ---------------------------------------------------------------------------
create table public.user_products (
  user_id uuid references auth.users(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  granted_at timestamptz default now(),
  primary key (user_id, product_id)
);

-- ---------------------------------------------------------------------------
-- Segurança da tabela de produtos (agora que user_products já existe)
-- ---------------------------------------------------------------------------
alter table public.products enable row level security;

create policy "Usuário vê apenas produtos liberados para ele"
  on public.products for select
  using (
    exists (
      select 1 from public.user_products up
      where up.product_id = products.id
        and up.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Segurança da tabela de vínculos
-- ---------------------------------------------------------------------------
alter table public.user_products enable row level security;

create policy "Usuário vê apenas seus próprios vínculos de produto"
  on public.user_products for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Tabela de lotes (substitui o antigo data.js estático — agora os dados
-- ficam protegidos por produto, no banco)
-- ---------------------------------------------------------------------------
create table public.lotes (
  id bigint generated always as identity primary key,
  product_id uuid references public.products(id) on delete cascade not null,
  quadra int not null,
  lote int not null,
  area numeric not null,
  valor numeric not null,
  entrada numeric not null,
  avista numeric,
  p12 numeric,
  p24 numeric,
  p36 numeric,
  sem_balao numeric,
  balao_anual numeric,
  com_balao numeric,
  sem_entrada numeric,
  unique (product_id, quadra, lote)
);

alter table public.lotes enable row level security;

-- Usuário só vê lotes de produtos que tiver sido liberado
create policy "Usuário vê apenas lotes de produtos liberados"
  on public.lotes for select
  using (
    exists (
      select 1 from public.user_products up
      where up.product_id = lotes.product_id
        and up.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Índice para acelerar a busca por quadra/lote dentro de um produto
-- ---------------------------------------------------------------------------
create index idx_lotes_product_quadra_lote on public.lotes (product_id, quadra, lote);
