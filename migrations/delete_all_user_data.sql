-- =====================================================
-- Delete all user-owned app data while preserving auth account
-- =====================================================

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

    -- Fail closed if new user-owned tables are introduced but not handled.
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
