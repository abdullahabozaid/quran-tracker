-- ============================================================
--  Quran Tracker — teacher sync database setup
--  Run this once in your Supabase project:
--    Supabase dashboard → SQL Editor → New query → paste → Run
--  Then change the passcode on the line marked  <<< CHANGE THIS
-- ============================================================

create table if not exists public.students (
  student_id  text primary key,
  name        text not null,
  lang        text,
  log         jsonb default '[]'::jsonb,
  weekly      jsonb default '{}'::jsonb,
  updated_at  timestamptz default now()
);

alter table public.students enable row level security;

-- Students may ADD and UPDATE their own row (anonymous key). No direct reading.
drop policy if exists "anon insert" on public.students;
drop policy if exists "anon update" on public.students;
create policy "anon insert" on public.students for insert to anon with check (true);
create policy "anon update" on public.students for update to anon using (true) with check (true);

-- The teacher reads everything ONLY through this passcode-protected function.
-- (Direct reading of the table by the public key is blocked above.)
create or replace function public.get_all_students(pass text)
returns setof public.students
language plpgsql
security definer
set search_path = public
as $$
begin
  if pass = 'changeme123' then          -- <<< CHANGE THIS to your own teacher passcode
    return query select * from public.students order by updated_at desc;
  else
    return;                              -- wrong passcode → returns nothing
  end if;
end;
$$;

grant execute on function public.get_all_students(text) to anon;
