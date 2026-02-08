-- ============================================================
-- Add subscription links to items and transactions
-- ============================================================
-- Phase 1 migration: relational linkage for robust mapping.
-- Safe to run multiple times.
-- ============================================================

ALTER TABLE public.items
ADD COLUMN IF NOT EXISTS subscription_id UUID;

ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS subscription_id UUID;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'items_subscription_id_fkey'
    ) THEN
        ALTER TABLE public.items
        ADD CONSTRAINT items_subscription_id_fkey
        FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id)
        ON DELETE SET NULL;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'transactions_subscription_id_fkey'
    ) THEN
        ALTER TABLE public.transactions
        ADD CONSTRAINT transactions_subscription_id_fkey
        FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id)
        ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_items_subscription_id
    ON public.items(subscription_id);

CREATE INDEX IF NOT EXISTS idx_transactions_subscription_id
    ON public.transactions(subscription_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_items_category_subscription_unique
    ON public.items(category_id, subscription_id)
    WHERE subscription_id IS NOT NULL;
