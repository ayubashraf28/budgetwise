-- =====================================================
-- Inactive account retention and activity heartbeat
-- =====================================================

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE public.profiles
SET last_active_at = NOW();

CREATE INDEX IF NOT EXISTS profiles_last_active_at_idx
    ON public.profiles (last_active_at);

CREATE OR REPLACE FUNCTION public.touch_profile_last_active()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_now TIMESTAMPTZ := NOW();
    v_display_name TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT COALESCE(
        NULLIF(
            split_part(u.email, '@', 1),
            ''
        ),
        CASE WHEN COALESCE(u.is_anonymous, FALSE) THEN 'Guest' ELSE 'User' END
    )
    INTO v_display_name
    FROM auth.users u
    WHERE u.id = v_user_id;

    INSERT INTO public.profiles (
        user_id,
        display_name,
        currency,
        locale,
        onboarding_completed,
        notifications_enabled,
        subscription_reminders_enabled,
        budget_alerts_enabled,
        monthly_reminders_enabled,
        last_active_at,
        created_at,
        updated_at
    )
    VALUES (
        v_user_id,
        COALESCE(v_display_name, 'Guest'),
        'GBP',
        'en_GB',
        FALSE,
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        v_now,
        v_now,
        v_now
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        last_active_at = EXCLUDED.last_active_at,
        updated_at = EXCLUDED.updated_at;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.touch_profile_last_active() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.touch_profile_last_active() FROM anon;
GRANT EXECUTE ON FUNCTION public.touch_profile_last_active() TO authenticated;

CREATE OR REPLACE FUNCTION public.preview_inactive_users(
    guest_retention_days integer DEFAULT 90,
    account_retention_days integer DEFAULT 180
)
RETURNS TABLE (
    user_id uuid,
    email text,
    is_anonymous boolean,
    provider text,
    last_active_at timestamptz,
    retention_days integer,
    deletion_due_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id AS user_id,
        u.email::text,
        COALESCE(u.is_anonymous, FALSE) AS is_anonymous,
        COALESCE(
            NULLIF(u.raw_app_meta_data ->> 'provider', ''),
            CASE
                WHEN COALESCE(u.is_anonymous, FALSE) THEN 'anonymous'
                WHEN u.email IS NOT NULL THEN 'email'
                ELSE 'account'
            END
        )::text AS provider,
        p.last_active_at,
        CASE
            WHEN COALESCE(u.is_anonymous, FALSE) THEN guest_retention_days
            ELSE account_retention_days
        END AS retention_days,
        p.last_active_at + make_interval(
            days => CASE
                WHEN COALESCE(u.is_anonymous, FALSE) THEN guest_retention_days
                ELSE account_retention_days
            END
        ) AS deletion_due_at
    FROM auth.users u
    JOIN public.profiles p
      ON p.user_id = u.id
    WHERE p.last_active_at <= NOW() - make_interval(
        days => CASE
            WHEN COALESCE(u.is_anonymous, FALSE) THEN guest_retention_days
            ELSE account_retention_days
        END
    )
    ORDER BY p.last_active_at ASC, u.id ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.preview_inactive_users(integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.preview_inactive_users(integer, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.preview_inactive_users(integer, integer) FROM authenticated;

CREATE OR REPLACE FUNCTION public.delete_inactive_users(
    guest_retention_days integer DEFAULT 90,
    account_retention_days integer DEFAULT 180
)
RETURNS TABLE (
    deleted_guest_count integer,
    deleted_account_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    WITH candidates AS (
        SELECT
            u.id,
            COALESCE(u.is_anonymous, FALSE) AS is_anonymous
        FROM auth.users u
        JOIN public.profiles p
          ON p.user_id = u.id
        WHERE p.last_active_at <= NOW() - make_interval(
            days => CASE
                WHEN COALESCE(u.is_anonymous, FALSE) THEN guest_retention_days
                ELSE account_retention_days
            END
        )
    ),
    deleted AS (
        DELETE FROM auth.users u
        USING candidates c
        WHERE u.id = c.id
        RETURNING c.is_anonymous
    )
    SELECT
        COUNT(*) FILTER (WHERE is_anonymous)::integer AS deleted_guest_count,
        COUNT(*) FILTER (WHERE NOT is_anonymous)::integer AS deleted_account_count
    FROM deleted;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_inactive_users(integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_inactive_users(integer, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_inactive_users(integer, integer) FROM authenticated;

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
      last_active_at = NOW(),
      updated_at = NOW()
    WHERE user_id = v_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_all_user_data() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_all_user_data() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_all_user_data() TO authenticated;
