-- ============================================================
-- Phase 5: subscription + account integration
-- ============================================================
-- Adds default account on subscriptions and updates payment RPC:
-- - subscriptions.default_account_id
-- - ownership validation trigger for default account
-- - mark_subscription_paid accepts p_account_id and writes transactions.account_id
-- ============================================================

ALTER TABLE public.subscriptions
ADD COLUMN IF NOT EXISTS default_account_id UUID
    REFERENCES public.accounts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_subscriptions_default_account_id
    ON public.subscriptions(default_account_id);

CREATE OR REPLACE FUNCTION public.enforce_subscription_default_account_ownership()
RETURNS TRIGGER AS $$
DECLARE
    account_ok BOOLEAN;
BEGIN
    IF NEW.default_account_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.accounts a
        WHERE a.id = NEW.default_account_id
          AND a.user_id = NEW.user_id
          AND a.is_archived = FALSE
    ) INTO account_ok;

    IF NOT account_ok THEN
        RAISE EXCEPTION 'default_account_id is invalid, archived, or not owned by user';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_subscription_default_account_ownership_trg ON public.subscriptions;
CREATE TRIGGER enforce_subscription_default_account_ownership_trg
    BEFORE INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.enforce_subscription_default_account_ownership();

DROP FUNCTION IF EXISTS public.mark_subscription_paid(UUID, DATE, NUMERIC);
DROP FUNCTION IF EXISTS public.mark_subscription_paid(UUID, DATE, NUMERIC, UUID);
DROP FUNCTION IF EXISTS public.mark_subscription_paid(UUID, DATE, NUMERIC, UUID, UUID);

CREATE OR REPLACE FUNCTION public.mark_subscription_paid(
    p_subscription_id UUID,
    p_paid_at DATE DEFAULT CURRENT_DATE,
    p_amount_override NUMERIC DEFAULT NULL,
    p_request_id UUID DEFAULT NULL,
    p_account_id UUID DEFAULT NULL
)
RETURNS TABLE (
    transaction_id UUID,
    month_id UUID,
    month_name TEXT,
    category_id UUID,
    item_id UUID,
    subscription_id UUID,
    amount NUMERIC,
    paid_at DATE,
    next_due_date DATE,
    duplicate_prevented BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_sub public.subscriptions%ROWTYPE;
    v_month_id UUID;
    v_month_name TEXT;
    v_category_id UUID;
    v_item_id UUID;
    v_amount NUMERIC;
    v_monthly_cost NUMERIC;
    v_next_due_date DATE;
    v_transaction_id UUID;
    v_existing_event public.subscription_payment_events%ROWTYPE;
    v_existing_tx public.transactions%ROWTYPE;
    v_effective_account_id UUID;
    v_account_is_valid BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT *
    INTO v_sub
    FROM public.subscriptions
    WHERE id = p_subscription_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Subscription not found';
    END IF;

    v_effective_account_id := COALESCE(p_account_id, v_sub.default_account_id);

    IF v_effective_account_id IS NULL THEN
        RAISE EXCEPTION 'No funding account selected for subscription payment';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.accounts a
        WHERE a.id = v_effective_account_id
          AND a.user_id = v_user_id
          AND a.is_archived = FALSE
    ) INTO v_account_is_valid;

    IF NOT v_account_is_valid THEN
        RAISE EXCEPTION 'Funding account is invalid, archived, or not owned by user';
    END IF;

    IF p_request_id IS NOT NULL THEN
        SELECT *
        INTO v_existing_event
        FROM public.subscription_payment_events e
        WHERE e.user_id = v_user_id
          AND e.request_id = p_request_id
        ORDER BY e.id DESC
        LIMIT 1;

        IF FOUND THEN
            IF v_existing_event.transaction_id IS NOT NULL THEN
                SELECT *
                INTO v_existing_tx
                FROM public.transactions t
                WHERE t.id = v_existing_event.transaction_id
                  AND t.user_id = v_user_id
                LIMIT 1;

                IF FOUND THEN
                    SELECT m.name
                    INTO v_month_name
                    FROM public.months m
                    WHERE m.id = v_existing_tx.month_id;

                    UPDATE public.subscription_payment_events
                    SET status = 'duplicate_request',
                        duplicate_prevented = TRUE,
                        details = COALESCE(details, '{}'::JSONB) || jsonb_build_object(
                            'last_duplicate_return_at', NOW()
                        )
                    WHERE user_id = v_user_id
                      AND request_id = p_request_id;

                    transaction_id := v_existing_tx.id;
                    month_id := v_existing_tx.month_id;
                    month_name := COALESCE(v_month_name, 'Unknown month');
                    category_id := v_existing_tx.category_id;
                    item_id := v_existing_tx.item_id;
                    subscription_id := v_sub.id;
                    amount := v_existing_tx.amount;
                    paid_at := v_existing_tx.date;
                    next_due_date := v_sub.next_due_date;
                    duplicate_prevented := TRUE;
                    RETURN NEXT;
                    RETURN;
                END IF;
            END IF;

            RAISE EXCEPTION 'Duplicate payment request already processed';
        END IF;

        INSERT INTO public.subscription_payment_events (
            user_id,
            request_id,
            subscription_id,
            status,
            paid_at,
            details
        )
        VALUES (
            v_user_id,
            p_request_id,
            v_sub.id,
            'started',
            p_paid_at,
            jsonb_build_object(
                'source', 'mark_subscription_paid',
                'account_id', v_effective_account_id
            )
        );
    END IF;

    SELECT m.id, m.name
    INTO v_month_id, v_month_name
    FROM public.months m
    WHERE m.user_id = v_user_id
      AND p_paid_at >= m.start_date
      AND p_paid_at <= m.end_date
    ORDER BY m.start_date
    LIMIT 1;

    IF v_month_id IS NULL THEN
        RAISE EXCEPTION 'No month found for payment date %', p_paid_at;
    END IF;

    SELECT c.id
    INTO v_category_id
    FROM public.categories c
    WHERE c.user_id = v_user_id
      AND c.month_id = v_month_id
      AND LOWER(BTRIM(c.name)) IN ('subscription', 'subscriptions')
    ORDER BY c.created_at
    LIMIT 1
    FOR UPDATE;

    IF v_category_id IS NULL THEN
        INSERT INTO public.categories (user_id, month_id, name, icon, color, is_budgeted)
        VALUES (v_user_id, v_month_id, 'Subscriptions', 'repeat', '#8b5cf6', TRUE)
        RETURNING id INTO v_category_id;
    ELSE
        UPDATE public.categories
        SET name = 'Subscriptions',
            icon = 'repeat',
            color = '#8b5cf6',
            is_budgeted = TRUE
        WHERE id = v_category_id;
    END IF;

    CASE v_sub.billing_cycle
        WHEN 'weekly' THEN v_monthly_cost := v_sub.amount * 4.33;
        WHEN 'monthly' THEN v_monthly_cost := v_sub.amount;
        WHEN 'quarterly' THEN v_monthly_cost := v_sub.amount / 3;
        WHEN 'yearly' THEN v_monthly_cost := v_sub.amount / 12;
        WHEN 'custom' THEN
            v_monthly_cost := v_sub.amount * 30 / GREATEST(COALESCE(v_sub.custom_cycle_days, 30), 1);
        ELSE v_monthly_cost := v_sub.amount;
    END CASE;

    SELECT i.id
    INTO v_item_id
    FROM public.items i
    WHERE i.user_id = v_user_id
      AND i.category_id = v_category_id
      AND i.subscription_id = v_sub.id
    ORDER BY i.created_at
    LIMIT 1
    FOR UPDATE;

    IF v_item_id IS NULL THEN
        SELECT i.id
        INTO v_item_id
        FROM public.items i
        WHERE i.user_id = v_user_id
          AND i.category_id = v_category_id
          AND i.subscription_id IS NULL
          AND LOWER(BTRIM(i.name)) = LOWER(BTRIM(v_sub.name))
        ORDER BY i.created_at
        LIMIT 1
        FOR UPDATE;
    END IF;

    IF v_item_id IS NULL THEN
        INSERT INTO public.items (
            user_id,
            category_id,
            subscription_id,
            name,
            projected,
            is_archived,
            is_budgeted,
            is_recurring
        )
        VALUES (
            v_user_id,
            v_category_id,
            v_sub.id,
            v_sub.name,
            v_monthly_cost,
            FALSE,
            TRUE,
            TRUE
        )
        RETURNING id INTO v_item_id;
    ELSE
        UPDATE public.items
        SET subscription_id = v_sub.id,
            name = v_sub.name,
            projected = v_monthly_cost,
            is_archived = FALSE,
            is_budgeted = TRUE,
            is_recurring = TRUE
        WHERE id = v_item_id;
    END IF;

    v_amount := COALESCE(p_amount_override, v_sub.amount);

    INSERT INTO public.transactions (
        user_id,
        month_id,
        category_id,
        item_id,
        subscription_id,
        account_id,
        type,
        amount,
        date,
        note
    )
    VALUES (
        v_user_id,
        v_month_id,
        v_category_id,
        v_item_id,
        v_sub.id,
        v_effective_account_id,
        'expense',
        v_amount,
        p_paid_at,
        'Subscription: ' || v_sub.name
    )
    RETURNING id INTO v_transaction_id;

    IF v_sub.is_auto_renew THEN
        CASE v_sub.billing_cycle
            WHEN 'weekly' THEN v_next_due_date := v_sub.next_due_date + 7;
            WHEN 'monthly' THEN v_next_due_date := (v_sub.next_due_date + INTERVAL '1 month')::DATE;
            WHEN 'quarterly' THEN v_next_due_date := (v_sub.next_due_date + INTERVAL '3 months')::DATE;
            WHEN 'yearly' THEN v_next_due_date := (v_sub.next_due_date + INTERVAL '1 year')::DATE;
            WHEN 'custom' THEN
                v_next_due_date := v_sub.next_due_date + GREATEST(COALESCE(v_sub.custom_cycle_days, 30), 1);
            ELSE v_next_due_date := v_sub.next_due_date;
        END CASE;
    ELSE
        v_next_due_date := v_sub.next_due_date;
    END IF;

    UPDATE public.subscriptions
    SET next_due_date = v_next_due_date
    WHERE id = v_sub.id
      AND user_id = v_user_id;

    transaction_id := v_transaction_id;
    month_id := v_month_id;
    month_name := COALESCE(v_month_name, 'Unknown month');
    category_id := v_category_id;
    item_id := v_item_id;
    subscription_id := v_sub.id;
    amount := v_amount;
    paid_at := p_paid_at;
    next_due_date := v_next_due_date;
    duplicate_prevented := FALSE;

    IF p_request_id IS NOT NULL THEN
        UPDATE public.subscription_payment_events
        SET transaction_id = v_transaction_id,
            status = 'success',
            duplicate_prevented = FALSE,
            details = COALESCE(details, '{}'::JSONB) || jsonb_build_object(
                'month_id', month_id,
                'category_id', category_id,
                'item_id', item_id,
                'amount', amount,
                'next_due_date', next_due_date,
                'account_id', v_effective_account_id
            )
        WHERE user_id = v_user_id
          AND request_id = p_request_id;
    END IF;

    RETURN NEXT;
END;
$$;
