-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Adiciona o campo de CRECI da imobiliária (diferente do CRECI individual
-- de cada corretor, que já existe na tabela profiles).

alter table public.agencies
  add column if not exists creci text;
