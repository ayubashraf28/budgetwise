-- ============================================================
-- Phase 6: account backfill + enforcement for transactions
-- ============================================================
-- 1) Ensure every user with missing transaction.account_id has an active account.
-- 2) Backfill legacy transactions.account_id.
-- 3) Enforce account_id NOT NULL for income/expense transactions.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.transaction_account_backfill_audit (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    transaction_id UUID NOT NULL,
    assigned_account_id UUID,
    strategy TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.transaction_account_backfill_audit ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'transaction_account_backfill_audit'
          AND policyname = 'Users can view own transaction account backfill audit'
    ) THEN
        CREATE POLICY "Users can view own transaction account backfill audit"
            ON public.transaction_account_backfill_audit FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_transaction_account_backfill_audit_user_id
    ON public.transaction_account_backfill_audit(user_id);

-- Create an active fallback account for users that have missing account_id rows
-- and no active accounts yet.
WITH users_needing_fallback_account AS (
    SELECT DISTINCT t.user_id
    FROM public.transactions t
    WHERE t.type IN ('income', 'expense')
      AND t.account_id IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM public.accounts a
          WHERE a.user_id = t.user_id
            AND a.is_archived = FALSE
      )
)
INSERT INTO public.accounts (
    user_id,
    name,
    type,
    currency,
    opening_balance,
    include_in_net_worth,
    is_archived,
    sort_order
)
SELECT
    u.user_id,
    'Cash',
    'cash',
    COALESCE(p.currency, 'GBP'),
    0,
    TRUE,
    FALSE,
    0
FROM users_needing_fallback_account u
LEFT JOIN public.profiles p ON p.user_id = u.user_id
WHERE NOT EXISTS (
    SELECT 1
    FROM public.accounts a
    WHERE a.user_id = u.user_id
      AND a.is_archived = FALSE
);

-- Backfill missing account_id from each user's first active account.
WITH fallback_accounts AS (
    SELECT DISTINCT ON (a.user_id)
        a.user_id,
        a.id AS account_id
    FROM public.accounts a
    WHERE a.is_archived = FALSE
    ORDER BY a.user_id, a.sort_order, a.created_at, a.id
),
backfilled_transactions AS (
    UPDATE public.transactions t
    SET account_id = fa.account_id
    FROM fallback_accounts fa
    WHERE t.user_id = fa.user_id
      AND t.type IN ('income', 'expense')
      AND t.account_id IS NULL
    RETURNING t.user_id, t.id AS transaction_id, t.account_id
)
INSERT INTO public.transaction_account_backfill_audit (
    user_id,
    transaction_id,
    assigned_account_id,
    strategy,
    details
)
SELECT
    bt.user_id,
    bt.transaction_id,
    bt.account_id,
    'fallback_first_active_account',
    '{}'::jsonb
FROM backfilled_transactions bt;

-- Optional convenience: assign default funding account for active subscriptions.
WITH fallback_accounts AS (
    SELECT DISTINCT ON (a.user_id)
        a.user_id,
        a.id AS account_id
    FROM public.accounts a
    WHERE a.is_archived = FALSE
    ORDER BY a.user_id, a.sort_order, a.created_at, a.id
)
UPDATE public.subscriptions s
SET default_account_id = fa.account_id
FROM fallback_accounts fa
WHERE s.user_id = fa.user_id
  AND s.is_active = TRUE
  AND s.default_account_id IS NULL;

-- Enforce transaction account ownership.
-- Archived accounts are allowed only when preserving an unchanged historical link
-- on UPDATE; they are blocked for new transactions or account reassignments.
CREATE OR REPLACE FUNCTION public.enforce_transaction_account_ownership()
RETURNS TRIGGER AS $$
DECLARE
    account_user_id UUID;
    account_archived BOOLEAN;
BEGIN
    IF NEW.account_id IS NULL THEN
        RAISE EXCEPTION 'account_id is required';
    END IF;

    SELECT a.user_id, a.is_archived
    INTO account_user_id, account_archived
    FROM public.accounts a
    WHERE a.id = NEW.account_id;

    IF account_user_id IS NULL OR account_user_id <> NEW.user_id THEN
        RAISE EXCEPTION 'account_id is invalid or not owned by user';
    END IF;

    IF account_archived
       AND (TG_OP = 'INSERT' OR NEW.account_id IS DISTINCT FROM OLD.account_id) THEN
        RAISE EXCEPTION 'Archived accounts cannot be used for new transactions';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_transaction_account_ownership_trg ON public.transactions;
CREATE TRIGGER enforce_transaction_account_ownership_trg
    BEFORE INSERT OR UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.enforce_transaction_account_ownership();

DO $$
DECLARE
    v_missing_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_missing_count
    FROM public.transactions t
    WHERE t.type IN ('income', 'expense')
      AND t.account_id IS NULL;

    IF v_missing_count > 0 THEN
        RAISE EXCEPTION
            'Cannot enforce transactions.account_id NOT NULL: % rows still missing account_id',
            v_missing_count;
    END IF;
END $$;

ALTER TABLE public.transactions
ALTER COLUMN account_id SET NOT NULL;
