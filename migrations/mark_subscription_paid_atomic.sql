-- ============================================================
-- Atomic subscription payment function
-- ============================================================
-- Creates transaction + resolves month/category/item + advances due date
-- in one database transaction.
-- ============================================================

CREATE OR REPLACE FUNCTION public.mark_subscription_paid(
    p_subscription_id UUID,
    p_paid_at DATE DEFAULT CURRENT_DATE,
    p_amount_override NUMERIC DEFAULT NULL
)
RETURNS TABLE (
    transaction_id UUID,
    month_id UUID,
    category_id UUID,
    item_id UUID,
    subscription_id UUID,
    amount NUMERIC,
    paid_at DATE,
    next_due_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_sub public.subscriptions%ROWTYPE;
    v_month_id UUID;
    v_category_id UUID;
    v_item_id UUID;
    v_amount NUMERIC;
    v_monthly_cost NUMERIC;
    v_next_due_date DATE;
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

    SELECT m.id
    INTO v_month_id
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
        -- Keep reserved category canonical.
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
        -- Legacy fallback by name for pre-link rows.
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
        'expense',
        v_amount,
        p_paid_at,
        'Subscription: ' || v_sub.name
    )
    RETURNING id INTO transaction_id;

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

    month_id := v_month_id;
    category_id := v_category_id;
    item_id := v_item_id;
    subscription_id := v_sub.id;
    amount := v_amount;
    paid_at := p_paid_at;
    next_due_date := v_next_due_date;

    RETURN NEXT;
END;
$$;
