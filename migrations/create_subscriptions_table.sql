-- ============================================================
-- Create subscriptions table with RLS + indexes
-- ============================================================
-- Phase 1 migration: core subscriptions persistence.
-- Safe to run multiple times.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'GBP',
    icon TEXT NOT NULL DEFAULT 'credit-card',
    color TEXT NOT NULL DEFAULT '#6366f1',
    billing_cycle TEXT NOT NULL DEFAULT 'monthly'
        CHECK (billing_cycle IN ('weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
    next_due_date DATE NOT NULL,
    is_auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    custom_cycle_days INTEGER,
    category_name TEXT,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    reminder_days_before INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT subscriptions_custom_cycle_days_check
        CHECK (custom_cycle_days IS NULL OR custom_cycle_days > 0)
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'subscriptions'
          AND policyname = 'Users can view own subscriptions'
    ) THEN
        CREATE POLICY "Users can view own subscriptions"
            ON public.subscriptions FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'subscriptions'
          AND policyname = 'Users can insert own subscriptions'
    ) THEN
        CREATE POLICY "Users can insert own subscriptions"
            ON public.subscriptions FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'subscriptions'
          AND policyname = 'Users can update own subscriptions'
    ) THEN
        CREATE POLICY "Users can update own subscriptions"
            ON public.subscriptions FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'subscriptions'
          AND policyname = 'Users can delete own subscriptions'
    ) THEN
        CREATE POLICY "Users can delete own subscriptions"
            ON public.subscriptions FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id
    ON public.subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_due_date
    ON public.subscriptions(user_id, next_due_date);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_active
    ON public.subscriptions(user_id, is_active);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'update_updated_at'
          AND n.nspname = 'public'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_subscriptions_updated_at'
    ) THEN
        CREATE TRIGGER update_subscriptions_updated_at
            BEFORE UPDATE ON public.subscriptions
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
    END IF;
END $$;
