-- Accelerates high-frequency monthly transaction queries.
CREATE INDEX IF NOT EXISTS idx_transactions_user_month_date
ON public.transactions(user_id, month_id, date DESC);
