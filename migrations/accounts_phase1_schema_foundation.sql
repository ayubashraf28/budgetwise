-- ============================================================
-- Phase 1: accounts schema foundation
-- ============================================================
-- Adds first-class account tracking primitives:
-- - public.accounts
-- - public.transactions.account_id (nullable during migration window)
-- - public.account_transfers
-- ============================================================

CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'cash'
        CHECK (type IN ('cash', 'debit', 'credit', 'savings', 'other')),
    currency TEXT NOT NULL DEFAULT 'GBP',
    opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
    credit_limit NUMERIC(12,2),
    include_in_net_worth BOOLEAN NOT NULL DEFAULT TRUE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT accounts_name_not_blank CHECK (BTRIM(name) <> ''),
    CONSTRAINT accounts_credit_limit_non_negative
        CHECK (credit_limit IS NULL OR credit_limit >= 0)
);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own accounts" ON public.accounts;
CREATE POLICY "Users can view own accounts"
    ON public.accounts FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own accounts" ON public.accounts;
CREATE POLICY "Users can insert own accounts"
    ON public.accounts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own accounts" ON public.accounts;
CREATE POLICY "Users can update own accounts"
    ON public.accounts FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own accounts" ON public.accounts;
CREATE POLICY "Users can delete own accounts"
    ON public.accounts FOR DELETE
    USING (auth.uid() = user_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_user_name_active_unique
    ON public.accounts (user_id, LOWER(BTRIM(name)))
    WHERE is_archived = FALSE;
CREATE INDEX IF NOT EXISTS idx_accounts_user_archived
    ON public.accounts(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_accounts_user_sort
    ON public.accounts(user_id, sort_order);

ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES public.accounts(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON public.transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_account_date
    ON public.transactions(user_id, account_id, date);
CREATE INDEX IF NOT EXISTS idx_transactions_month_account
    ON public.transactions(month_id, account_id);

CREATE TABLE IF NOT EXISTS public.account_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    to_account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    date DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT account_transfers_distinct_accounts CHECK (from_account_id <> to_account_id)
);

ALTER TABLE public.account_transfers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own account transfers" ON public.account_transfers;
CREATE POLICY "Users can view own account transfers"
    ON public.account_transfers FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own account transfers" ON public.account_transfers;
CREATE POLICY "Users can insert own account transfers"
    ON public.account_transfers FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own account transfers" ON public.account_transfers;
CREATE POLICY "Users can update own account transfers"
    ON public.account_transfers FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own account transfers" ON public.account_transfers;
CREATE POLICY "Users can delete own account transfers"
    ON public.account_transfers FOR DELETE
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_account_transfers_user_date
    ON public.account_transfers(user_id, date);
CREATE INDEX IF NOT EXISTS idx_account_transfers_from_account
    ON public.account_transfers(from_account_id, date);
CREATE INDEX IF NOT EXISTS idx_account_transfers_to_account
    ON public.account_transfers(to_account_id, date);

CREATE OR REPLACE FUNCTION public.enforce_account_transfer_ownership()
RETURNS TRIGGER AS $$
DECLARE
    from_ok BOOLEAN;
    to_ok BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.accounts a
        WHERE a.id = NEW.from_account_id
          AND a.user_id = NEW.user_id
          AND a.is_archived = FALSE
    ) INTO from_ok;

    IF NOT from_ok THEN
        RAISE EXCEPTION 'from_account_id is invalid, archived, or not owned by user';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.accounts a
        WHERE a.id = NEW.to_account_id
          AND a.user_id = NEW.user_id
          AND a.is_archived = FALSE
    ) INTO to_ok;

    IF NOT to_ok THEN
        RAISE EXCEPTION 'to_account_id is invalid, archived, or not owned by user';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_account_transfer_ownership_trg ON public.account_transfers;
CREATE TRIGGER enforce_account_transfer_ownership_trg
    BEFORE INSERT OR UPDATE ON public.account_transfers
    FOR EACH ROW EXECUTE FUNCTION public.enforce_account_transfer_ownership();

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_accounts_updated_at ON public.accounts;
CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON public.accounts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_account_transfers_updated_at ON public.account_transfers;
CREATE TRIGGER update_account_transfers_updated_at
    BEFORE UPDATE ON public.account_transfers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
