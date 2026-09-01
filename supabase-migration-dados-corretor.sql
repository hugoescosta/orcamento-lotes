-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Use este arquivo se você JÁ TEM a tabela "profiles" criada e só precisa
-- adicionar os campos novos (nome, WhatsApp, Creci). Não apaga nada existente.

alter table public.profiles
  add column if not exists display_name text,
  add column if not exists whatsapp text,
  add column if not exists creci text;
