-- ============================================================
--  Quran Tracker — teacher sync database setup
--  Run once: Supabase dashboard → SQL Editor → New query → paste → Run
--  Then change the passcode on the line marked  <<< CHANGE THIS
--
--  Security model: the public (anon) key can ONLY call the two
--  functions below. It cannot read or write the table directly.
--   • students save via save_student()           (write-only)
--   • teacher reads via get_all_students(pass)    (passcode-gated)
-- ============================================================

create table if not exists public.students (
  student_id  text primary key,
  name        text not null,
  lang        text,
  log         jsonb default '[]'::jsonb,
  weekly      jsonb default '{}'::jsonb,
  updated_at  timestamptz default now()
);

alter table public.students enable row level security;   -- no anon policies → no direct table access

-- Students upload their own row (insert-or-update). Runs as owner, so no table grants needed.
create or replace function public.save_student(p_id text, p_name text, p_lang text, p_log jsonb, p_weekly jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.students(student_id, name, lang, log, weekly, updated_at)
  values (p_id, p_name, p_lang, coalesce(p_log,'[]'::jsonb), coalesce(p_weekly,'{}'::jsonb), now())
  on conflict (student_id) do update
    set name = excluded.name, lang = excluded.lang, log = excluded.log,
        weekly = excluded.weekly, updated_at = now();
end; $$;
revoke all on function public.save_student(text,text,text,jsonb,jsonb) from public;
grant execute on function public.save_student(text,text,text,jsonb,jsonb) to anon;

-- Teacher reads everyone — only when the passcode matches.
create or replace function public.get_all_students(pass text)
returns setof public.students language plpgsql security definer set search_path = public as $$
begin
  if pass = 'changeme123' then          -- <<< CHANGE THIS to your own teacher passcode
    return query select * from public.students order by updated_at desc;
  else
    return;                              -- wrong passcode → returns nothing
  end if;
end; $$;
revoke all on function public.get_all_students(text) from public;
grant execute on function public.get_all_students(text) to anon;

-- Tell the API to pick up the new functions immediately.
notify pgrst, 'reload schema';
