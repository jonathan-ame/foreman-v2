create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers(customer_id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists chat_messages_customer_id_created_at_idx
  on chat_messages (customer_id, created_at asc);
