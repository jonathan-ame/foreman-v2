create table if not exists page_views (
  id uuid primary key default gen_random_uuid(),
  path text not null,
  referrer text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  user_agent text,
  ip_hash text,
  created_at timestamptz not null default now()
);

create index if not exists page_views_created_at_idx
  on page_views (created_at desc);

create index if not exists page_views_path_idx
  on page_views (path);
