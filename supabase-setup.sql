-- 우리 둘의 스케줄 (고운 × JK) — Supabase 테이블 준비 SQL
-- Supabase 대시보드 > SQL Editor 에 전체 붙여넣고 RUN 한 번만 누르면 됩니다.
-- 비밀번호는 평문이 아니라 SHA-256 해시로만 검사합니다. (아래 해시 = 페이지와 동일)

create table if not exists public.schedule_events (
  id text primary key,
  date date not null,
  time text,
  owner text not null check (owner in ('goun', 'friend', 'together')),
  title text not null,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.schedule_memos (
  id text primary key,
  text text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.schedule_events enable row level security;
alter table public.schedule_memos enable row level security;

grant select, insert, update, delete on public.schedule_events to anon, authenticated;
grant select, insert, update, delete on public.schedule_memos to anon, authenticated;

create or replace function public.pin_ok() returns boolean
language sql stable as $fn$
  select encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json ->> 'x-pin', ''), 'UTF8')), 'hex')
       = '1426279dcbdf749f1edd7e89fd9db820fc3e5ce2930fa63ce9c5dce9af3da447'
$fn$;

drop policy if exists "events_pin" on public.schedule_events;
create policy "events_pin" on public.schedule_events
  for all to anon, authenticated
  using (public.pin_ok())
  with check (public.pin_ok());

drop policy if exists "memos_pin" on public.schedule_memos;
create policy "memos_pin" on public.schedule_memos
  for all to anon, authenticated
  using (public.pin_ok())
  with check (public.pin_ok());
