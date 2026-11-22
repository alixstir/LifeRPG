-- Life RPG : à coller dans Supabase > SQL Editor > Run (une seule fois)

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

create table activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  stat text,
  xp int not null default 0,
  gold int not null default 0,
  skill text,
  stat_xp int not null default 0,
  daily boolean not null default false,
  active boolean not null default true,
  created_at timestamptz default now()
);

create table journal (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  day date not null,
  activity text not null,
  qty int not null default 1,
  xp int not null default 0,
  gold int not null default 0,
  bonus_xp int not null default 0,
  skill text,
  stat text,
  stat_xp int not null default 0,
  created_at timestamptz default now()
);
create index journal_user_day on journal (user_id, day);

alter table profiles enable row level security;
alter table activities enable row level security;
alter table journal enable row level security;

-- chaque joueur ne voit et ne modifie que ses propres activités et son propre journal
create policy "profils visibles par les joueurs connectés" on profiles for select to authenticated using (true);
create policy "créer son profil" on profiles for insert to authenticated with check (id = auth.uid());
create policy "modifier son profil" on profiles for update to authenticated using (id = auth.uid());
create policy "mes activités" on activities for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "mon journal : lire" on journal for select to authenticated using (user_id = auth.uid());
create policy "mon journal : ajouter" on journal for insert to authenticated with check (user_id = auth.uid());
create policy "mon journal : retirer" on journal for delete to authenticated using (user_id = auth.uid());

-- classement : les autres joueurs ne voient que le nom et les totaux, jamais le détail du journal
create view leaderboard as
  select p.id, p.name,
         coalesce(sum(j.xp + j.bonus_xp), 0)::int as xp,
         coalesce(sum(j.gold), 0)::int as gold,
         coalesce(sum(j.xp + j.bonus_xp) filter (where j.day >= current_date - 6), 0)::int as week_xp
  from profiles p left join journal j on j.user_id = p.id
  group by p.id, p.name;
revoke all on leaderboard from anon;
grant select on leaderboard to authenticated;
