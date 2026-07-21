-- ============================================================
-- Row Level Security
-- Anggota hanya akses data miliknya; staff akses sesuai peran.
-- Mutasi keuangan lewat RPC security-definer (bypass RLS).
-- ============================================================

alter table staff_roles          enable row level security;
alter table members              enable row level security;
alter table savings_accounts     enable row level security;
alter table savings_transactions enable row level security;
alter table loans                enable row level security;
alter table loan_installments    enable row level security;
alter table payments             enable row level security;
alter table notifications        enable row level security;
alter table audit_log            enable row level security;

-- ---------- staff_roles ----------
create policy staff_roles_select on staff_roles
  for select using (user_id = auth.uid() or is_pengurus());
create policy staff_roles_manage on staff_roles
  for all using (is_pengurus()) with check (is_pengurus());

-- ---------- members ----------
create policy members_select on members
  for select using (user_id = auth.uid() or is_staff());
-- Self-registration: user membuat baris anggota miliknya sendiri (status default pending)
create policy members_insert_self on members
  for insert with check (user_id = auth.uid());
create policy members_insert_staff on members
  for insert with check (is_staff());
create policy members_update_self on members
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy members_update_staff on members
  for update using (is_staff()) with check (is_staff());

-- ---------- savings_accounts (mutasi via trigger) ----------
create policy savings_accounts_select on savings_accounts
  for select using (
    member_id = current_member_id() or is_staff()
  );

-- ---------- savings_transactions (insert via RPC) ----------
create policy savings_txn_select on savings_transactions
  for select using (
    member_id = current_member_id() or is_staff()
  );

-- ---------- loans ----------
create policy loans_select on loans
  for select using (
    member_id = current_member_id() or is_staff()
  );

-- ---------- loan_installments ----------
create policy installments_select on loan_installments
  for select using (
    is_staff() or loan_id in (
      select id from loans where member_id = current_member_id()
    )
  );

-- ---------- payments ----------
create policy payments_select on payments
  for select using (
    member_id = current_member_id() or is_staff()
  );

-- ---------- notifications ----------
create policy notifications_select on notifications
  for select using (
    member_id = current_member_id() or is_staff()
  );
create policy notifications_update_own on notifications
  for update using (member_id = current_member_id())
  with check (member_id = current_member_id());

-- ---------- audit_log ----------
create policy audit_log_select on audit_log
  for select using (is_staff());
