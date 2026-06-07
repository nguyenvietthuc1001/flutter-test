-- Create matches table
create table if not exists public.matches (
  id uuid default gen_random_uuid() primary key,
  room_code text not null unique,
  player_x text,
  player_o text,
  board jsonb not null,
  current_player text not null default 'X',
  status text not null default 'waiting',
  winner text,
  winning_line jsonb,
  last_move_row integer,
  last_move_col integer,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Realtime for the matches table
-- First check if publication exists, then add table. We wrap in a do block to handle cases where it might already be added.
do $$
begin
  if not exists (
    select 1 
    from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'matches'
  ) then
    alter publication supabase_realtime add table public.matches;
  end if;
end $$;

-- Enable Row Level Security
alter table public.matches enable row level security;

-- Drop existing policies if they exist to avoid duplication errors
drop policy if exists "Allow public read access" on public.matches;
drop policy if exists "Allow public insert access" on public.matches;
drop policy if exists "Allow public update access" on public.matches;

-- Create policies
create policy "Allow public read access" on public.matches for select using (true);
create policy "Allow public insert access" on public.matches for insert with check (true);
create policy "Allow public update access" on public.matches for update using (true) with check (true);
