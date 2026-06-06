-- ============================================================
--  Quran Tracker — teacher sync database setup
--  Run once: Supabase dashboard → SQL Editor → New query → paste → Run
--  Change the passcode on the TWO lines marked  <<< CHANGE THIS  (keep them identical)
--
--  Security model: the public (anon) key can ONLY call the functions
--  below — it cannot read or write the table directly.
--   • students upload via save_student()                 (own log/weekly/hw_done)
--   • students read their own note+homework: get_student()
--   • teacher reads everyone: get_all_students(pass)      (passcode-gated)
--   • teacher writes note+homework: set_teacher_data(pass) (passcode-gated)
-- ============================================================

create table if not exists public.students (
  student_id   text primary key,
  name         text not null,
  lang         text,
  log          jsonb default '[]'::jsonb,   -- student-owned: daily log
  weekly       jsonb default '{}'::jsonb,   -- student-owned: weekly task completion
  hw_done      jsonb default '{}'::jsonb,   -- student-owned: { homeworkId: true }
  teacher_note text  default '',            -- teacher-owned
  homework     jsonb default '[]'::jsonb,   -- teacher-owned: [{id,text,due}]
  updated_at   timestamptz default now()
);
alter table public.students add column if not exists hw_done jsonb default '{}'::jsonb;
alter table public.students add column if not exists teacher_note text default '';
alter table public.students add column if not exists homework jsonb default '[]'::jsonb;

alter table public.students enable row level security;   -- no anon policies → no direct table access

-- Student uploads their own row (student-owned fields only).
create or replace function public.save_student(p_id text, p_name text, p_lang text, p_log jsonb, p_weekly jsonb, p_hw_done jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.students(student_id, name, lang, log, weekly, hw_done, updated_at)
  values (p_id, p_name, p_lang, coalesce(p_log,'[]'::jsonb), coalesce(p_weekly,'{}'::jsonb), coalesce(p_hw_done,'{}'::jsonb), now())
  on conflict (student_id) do update
    set name=excluded.name, lang=excluded.lang, log=excluded.log, weekly=excluded.weekly,
        hw_done=excluded.hw_done, updated_at=now();
end; $$;
revoke all on function public.save_student(text,text,text,jsonb,jsonb,jsonb) from public;
grant execute on function public.save_student(text,text,text,jsonb,jsonb,jsonb) to anon;

-- Student reads their OWN teacher note + homework (by their unguessable id).
create or replace function public.get_student(p_id text)
returns table(teacher_note text, homework jsonb) language plpgsql security definer set search_path = public as $$
begin
  return query select s.teacher_note, s.homework from public.students s where s.student_id = p_id;
end; $$;
revoke all on function public.get_student(text) from public;
grant execute on function public.get_student(text) to anon;

-- Teacher reads everyone — only when the passcode matches.
create or replace function public.get_all_students(pass text)
returns setof public.students language plpgsql security definer set search_path = public as $$
begin
  if pass = 'changeme123' then          -- <<< CHANGE THIS to your own teacher passcode
    return query select * from public.students order by updated_at desc;
  else
    return;
  end if;
end; $$;
revoke all on function public.get_all_students(text) from public;
grant execute on function public.get_all_students(text) to anon;

-- Teacher writes a note + homework for one student (passcode-gated, teacher-owned fields only).
create or replace function public.set_teacher_data(pass text, p_id text, p_note text, p_homework jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if pass <> 'changeme123' then return; end if;   -- <<< CHANGE THIS (same passcode as above)
  update public.students set teacher_note = p_note, homework = coalesce(p_homework,'[]'::jsonb) where student_id = p_id;
end; $$;
revoke all on function public.set_teacher_data(text,text,text,jsonb) from public;
grant execute on function public.set_teacher_data(text,text,text,jsonb) to anon;

-- Teacher deletes one student (passcode-gated).
-- Wrong passcode RAISES (PostgREST returns 401) so the client never shows a
-- false "deleted"; returns the number of rows actually removed.
create or replace function public.delete_student(pass text, p_id text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if pass <> 'changeme123' then                   -- <<< CHANGE THIS (same passcode as above)
    raise exception 'unauthorized' using errcode = '42501';
  end if;
  delete from public.students where student_id = p_id;
  get diagnostics n = row_count;
  return n;
end; $$;
revoke all on function public.delete_student(text,text) from public;
grant execute on function public.delete_student(text,text) to anon;

-- Teacher deletes ALL students (passcode-gated). Use with care.
-- Wrong passcode RAISES (PostgREST returns 401); returns rows removed.
create or replace function public.delete_all_students(pass text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if pass <> 'changeme123' then                   -- <<< CHANGE THIS (same passcode as above)
    raise exception 'unauthorized' using errcode = '42501';
  end if;
  delete from public.students;
  get diagnostics n = row_count;
  return n;
end; $$;
revoke all on function public.delete_all_students(text) from public;
grant execute on function public.delete_all_students(text) to anon;

notify pgrst, 'reload schema';
