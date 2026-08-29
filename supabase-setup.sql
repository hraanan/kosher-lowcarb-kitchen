-- Kosher Low-Carb Kitchen: community tables (paste into Supabase SQL Editor and Run)
create table if not exists ratings (
  id uuid primary key default gen_random_uuid(),
  recipe_id text not null,
  stars int not null check (stars between 1 and 5),
  voter text not null,
  created_at timestamptz not null default now()
);

create table if not exists submissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  by_name text,
  category text,
  kosher text default 'pareve',
  ingredients jsonb not null,
  instructions jsonb not null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists requests (
  id uuid primary key default gen_random_uuid(),
  dish text not null,
  by_name text,
  notes text,
  status text not null default 'pending',
  recipe_id text,
  created_at timestamptz not null default now()
);

alter table ratings enable row level security;
alter table submissions enable row level security;
alter table requests enable row level security;

create policy "public read ratings" on ratings for select using (true);
create policy "public insert ratings" on ratings for insert with check (true);
create policy "public read submissions" on submissions for select using (true);
create policy "public insert submissions" on submissions for insert with check (true);
create policy "public read requests" on requests for select using (true);
create policy "public insert requests" on requests for insert with check (true);
create policy "public update requests" on requests for update using (true) with check (true);

-- migrate the existing fulfilled request
insert into requests (dish, by_name, status, recipe_id, created_at)
values ('lemmon pie', 'hagai', 'added', 'keto-lemon-meringue-pie', '2026-08-29');
