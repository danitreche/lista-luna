-- Execute este arquivo uma vez no SQL Editor do projeto Supabase.
create table if not exists public.gift_reservations (
  gift_id smallint primary key check (gift_id between 1 and 48),
  reservation_token uuid not null,
  reserved_at timestamptz not null default now()
);

alter table public.gift_reservations enable row level security;

drop policy if exists "Anyone can see chosen gifts" on public.gift_reservations;
create policy "Anyone can see chosen gifts"
on public.gift_reservations for select
to anon
using (true);

drop policy if exists "Anyone can choose an available gift" on public.gift_reservations;
create policy "Anyone can choose an available gift"
on public.gift_reservations for insert
to anon
with check (gift_id between 1 and 48);

-- A chave secreta da reserva nunca pode ser lida pelo público.
revoke all on table public.gift_reservations from anon, authenticated;
grant select (gift_id, reserved_at) on table public.gift_reservations to anon;
grant insert (gift_id, reservation_token) on table public.gift_reservations to anon;

-- Permite desmarcar somente com o token salvo no aparelho que fez a escolha.
create or replace function public.unreserve_gift(
  p_gift_id smallint,
  p_reservation_token uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.gift_reservations
  where gift_id = p_gift_id
    and reservation_token = p_reservation_token;
  return found;
end;
$$;

revoke all on function public.unreserve_gift(smallint, uuid) from public;
grant execute on function public.unreserve_gift(smallint, uuid) to anon;
