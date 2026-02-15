-- =====================================================
-- Bug reporting + notifications system foundation
-- =====================================================

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS subscription_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS budget_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS monthly_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS public.bug_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (BTRIM(title) <> ''),
    description TEXT NOT NULL CHECK (BTRIM(description) <> ''),
    category TEXT NOT NULL CHECK (
        category IN (
            'bug',
            'ui_ux',
            'performance',
            'data_sync',
            'crash',
            'feedback',
            'other'
        )
    ),
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (
        severity IN ('low', 'medium', 'high', 'critical')
    ),
    app_version TEXT NOT NULL DEFAULT 'unknown',
    platform TEXT NOT NULL DEFAULT 'unknown',
    os_version TEXT NOT NULL DEFAULT 'unknown',
    device_model TEXT NOT NULL DEFAULT 'unknown',
    error_stack_trace TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (
        status IN ('open', 'in_progress', 'resolved', 'closed')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.bug_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own bug reports" ON public.bug_reports;
CREATE POLICY "Users can view own bug reports"
    ON public.bug_reports FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own bug reports" ON public.bug_reports;
CREATE POLICY "Users can insert own bug reports"
    ON public.bug_reports FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (BTRIM(title) <> ''),
    body TEXT NOT NULL CHECK (BTRIM(body) <> ''),
    type TEXT NOT NULL CHECK (
        type IN ('subscription_reminder', 'budget_alert', 'monthly_reminder')
    ),
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    month_id UUID REFERENCES public.months(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    payload JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own notifications" ON public.notifications;
CREATE POLICY "Users can insert own notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
    ON public.notifications FOR DELETE
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_bug_reports_user_created
    ON public.bug_reports(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bug_reports_user_status
    ON public.bug_reports(user_id, status);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
    ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_type_month
    ON public.notifications(user_id, type, month_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_budget_alert_once
    ON public.notifications(user_id, type, category_id, month_id)
    WHERE type = 'budget_alert' AND category_id IS NOT NULL AND month_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_monthly_once
    ON public.notifications(user_id, type, month_id)
    WHERE type = 'monthly_reminder' AND month_id IS NOT NULL;

DROP TRIGGER IF EXISTS update_bug_reports_updated_at ON public.bug_reports;
CREATE TRIGGER update_bug_reports_updated_at
    BEFORE UPDATE ON public.bug_reports
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_notifications_updated_at ON public.notifications;
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.delete_all_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_uncovered_tables TEXT[];
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT ARRAY_AGG(c.table_name ORDER BY c.table_name)
    INTO v_uncovered_tables
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema
     AND t.table_name = c.table_name
    WHERE c.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND c.column_name = 'user_id'
      AND c.table_name NOT IN (
          'profiles',
          'notifications',
          'bug_reports',
          'subscription_payment_events',
          'transaction_account_backfill_audit',
          'subscription_backfill_audit',
          'account_transfers',
          'transactions',
          'items',
          'categories',
          'income_sources',
          'subscriptions',
          'months',
          'accounts'
      );

    IF v_uncovered_tables IS NOT NULL
       AND array_length(v_uncovered_tables, 1) > 0 THEN
        RAISE EXCEPTION
            'delete_all_user_data is missing table coverage for: %',
            array_to_string(v_uncovered_tables, ', ');
    END IF;

    DELETE FROM public.subscription_payment_events
    WHERE user_id = v_user_id;

    DELETE FROM public.notifications
    WHERE user_id = v_user_id;

    DELETE FROM public.bug_reports
    WHERE user_id = v_user_id;

    DELETE FROM public.transaction_account_backfill_audit
    WHERE user_id = v_user_id;

    IF to_regclass('public.subscription_backfill_audit') IS NOT NULL THEN
        EXECUTE 'DELETE FROM public.subscription_backfill_audit WHERE user_id = $1'
        USING v_user_id;
    END IF;

    DELETE FROM public.account_transfers
    WHERE user_id = v_user_id;

    DELETE FROM public.transactions
    WHERE user_id = v_user_id;

    DELETE FROM public.items
    WHERE user_id = v_user_id;

    DELETE FROM public.categories
    WHERE user_id = v_user_id;

    DELETE FROM public.income_sources
    WHERE user_id = v_user_id;

    DELETE FROM public.subscriptions
    WHERE user_id = v_user_id;

    DELETE FROM public.months
    WHERE user_id = v_user_id;

    DELETE FROM public.accounts
    WHERE user_id = v_user_id;

    UPDATE public.profiles
    SET
      onboarding_completed = FALSE,
      display_name = COALESCE(
        NULLIF(
          split_part(
            (SELECT u.email FROM auth.users u WHERE u.id = v_user_id),
            '@',
            1
          ),
          ''
        ),
        'User'
      ),
      currency = 'GBP',
      locale = 'en_GB',
      notifications_enabled = TRUE,
      subscription_reminders_enabled = TRUE,
      budget_alerts_enabled = TRUE,
      monthly_reminders_enabled = TRUE,
      updated_at = NOW()
    WHERE user_id = v_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_all_user_data() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_all_user_data() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_all_user_data() TO authenticated;
