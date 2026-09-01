-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Adiciona o controle de "precisa trocar senha no próximo login" e uma
-- função segura que só permite ao próprio usuário desmarcar essa flag
-- (sem abrir uma brecha para ele alterar outros campos do próprio perfil,
-- como validade ou status).

alter table public.profiles
  add column if not exists must_change_password boolean not null default false;

create or replace function public.clear_must_change_password()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set must_change_password = false
  where id = auth.uid();
end;
$$;

grant execute on function public.clear_must_change_password() to authenticated;
