-- Execute este script no SQL Editor do Supabase (New query -> colar -> Run)
-- Adiciona o controle de "1 dispositivo ativo por vez": sempre que um login
-- novo acontece, o dispositivo anterior é desconectado automaticamente.

alter table public.profiles
  add column if not exists active_device_id text;

create or replace function public.register_device(device_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set active_device_id = device_id
  where id = auth.uid();
end;
$$;

grant execute on function public.register_device(text) to authenticated;
