-- Quotes Table
create table public.quotes (
  id uuid default gen_random_uuid() primary key,
  content text not null,
  author text not null,
  category text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Search Index
create extension if not exists pg_trgm;
create index quotes_content_trgm_idx on quotes using gin (content gin_trgm_ops);
create index quotes_author_trgm_idx on quotes using gin (author gin_trgm_ops);

-- Favorites Table
create table public.favorites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  quote_id uuid references public.quotes not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, quote_id)
);

-- Collections Table
create table public.collections (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Collection Items Table
create table public.collection_items (
  id uuid default gen_random_uuid() primary key,
  collection_id uuid references public.collections on delete cascade not null,
  quote_id uuid references public.quotes on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(collection_id, quote_id)
);

-- RLS Policies (Security)
alter table public.quotes enable row level security;
create policy "Quotes are viewable by everyone" on public.quotes for select using (true);

alter table public.favorites enable row level security;
create policy "Users can view their own favorites" on public.favorites for select using (auth.uid() = user_id);
create policy "Users can insert their own favorites" on public.favorites for insert with check (auth.uid() = user_id);
create policy "Users can delete their own favorites" on public.favorites for delete using (auth.uid() = user_id);

alter table public.collections enable row level security;
create policy "Users can view their own collections" on public.collections for select using (auth.uid() = user_id);
create policy "Users can insert their own collections" on public.collections for insert with check (auth.uid() = user_id);
create policy "Users can update their own collections" on public.collections for update using (auth.uid() = user_id);
create policy "Users can delete their own collections" on public.collections for delete using (auth.uid() = user_id);

alter table public.collection_items enable row level security;
create policy "Users can view items in their collections" on public.collection_items for select using (
  exists (select 1 from public.collections where id = collection_items.collection_id and user_id = auth.uid())
);
create policy "Users can add items to their collections" on public.collection_items for insert with check (
  exists (select 1 from public.collections where id = collection_items.collection_id and user_id = auth.uid())
);
create policy "Users can remove items from their collections" on public.collection_items for delete using (
  exists (select 1 from public.collections where id = collection_items.collection_id and user_id = auth.uid())
);
