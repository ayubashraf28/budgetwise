-- Ensure foreign key indexes exist on transactions table.
-- Supabase performance advisor flagged these as missing.
-- Safe to re-run: CREATE INDEX IF NOT EXISTS is idempotent.

CREATE INDEX IF NOT EXISTS idx_transactions_account_id
ON public.transactions(account_id);

CREATE INDEX IF NOT EXISTS idx_transactions_month
ON public.transactions(month_id);

CREATE INDEX IF NOT EXISTS idx_transactions_subscription_id
ON public.transactions(subscription_id);
