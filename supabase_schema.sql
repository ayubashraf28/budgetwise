-- =====================================================
-- BUDGETWISE DATABASE SCHEMA
-- =====================================================
-- Version: 1.0.0
-- Run this in Supabase SQL Editor to create all tables
-- =====================================================

-- -----------------------------------------------------
-- 1. PROFILES TABLE
-- Extends Supabase auth.users with app-specific data
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    display_name TEXT,
    currency TEXT DEFAULT 'GBP',
    locale TEXT DEFAULT 'en_GB',
    onboarding_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, display_name)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- -----------------------------------------------------
-- 2. MONTHS TABLE
-- Each budget period (usually calendar month)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.months (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_month UNIQUE (user_id, start_date)
);

-- Enable RLS
ALTER TABLE public.months ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own months" ON public.months;
CREATE POLICY "Users can view own months"
    ON public.months FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own months" ON public.months;
CREATE POLICY "Users can insert own months"
    ON public.months FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own months" ON public.months;
CREATE POLICY "Users can update own months"
    ON public.months FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own months" ON public.months;
CREATE POLICY "Users can delete own months"
    ON public.months FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 3. INCOME SOURCES TABLE
-- Projected and actual income for each month
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.income_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    month_id UUID REFERENCES public.months(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    projected DECIMAL(12,2) NOT NULL DEFAULT 0,
    actual DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_recurring BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.income_sources ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own income sources" ON public.income_sources;
CREATE POLICY "Users can view own income sources"
    ON public.income_sources FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own income sources" ON public.income_sources;
CREATE POLICY "Users can insert own income sources"
    ON public.income_sources FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own income sources" ON public.income_sources;
CREATE POLICY "Users can update own income sources"
    ON public.income_sources FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own income sources" ON public.income_sources;
CREATE POLICY "Users can delete own income sources"
    ON public.income_sources FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 4. CATEGORIES TABLE
-- Expense categories for each month
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    month_id UUID REFERENCES public.months(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'wallet',
    color TEXT NOT NULL DEFAULT '#6366f1',
    is_budgeted BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
CREATE POLICY "Users can view own categories"
    ON public.categories FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
CREATE POLICY "Users can insert own categories"
    ON public.categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
CREATE POLICY "Users can update own categories"
    ON public.categories FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
CREATE POLICY "Users can delete own categories"
    ON public.categories FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 5. SUBSCRIPTIONS TABLE
-- Recurring payments tracked independently from budget items
-- -----------------------------------------------------
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

-- Enable RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view own subscriptions"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can insert own subscriptions"
    ON public.subscriptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can update own subscriptions"
    ON public.subscriptions FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can delete own subscriptions"
    ON public.subscriptions FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 6. ITEMS TABLE
-- Budget line items within categories
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    projected DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    is_budgeted BOOLEAN DEFAULT TRUE,
    is_recurring BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backward-compat: existing DBs created before subscriptions support
-- need this column added explicitly.
ALTER TABLE public.items
ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL;
ALTER TABLE public.items
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Enable RLS
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own items" ON public.items;
CREATE POLICY "Users can view own items"
    ON public.items FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own items" ON public.items;
CREATE POLICY "Users can insert own items"
    ON public.items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own items" ON public.items;
CREATE POLICY "Users can update own items"
    ON public.items FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own items" ON public.items;
CREATE POLICY "Users can delete own items"
    ON public.items FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 7. TRANSACTIONS TABLE
-- Actual income and expense records
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    month_id UUID REFERENCES public.months(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    income_source_id UUID REFERENCES public.income_sources(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
    amount DECIMAL(12,2) NOT NULL,
    date DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backward-compat: existing DBs created before subscriptions support
-- need this column added explicitly.
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions"
    ON public.transactions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
CREATE POLICY "Users can insert own transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
CREATE POLICY "Users can update own transactions"
    ON public.transactions FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
CREATE POLICY "Users can delete own transactions"
    ON public.transactions FOR DELETE
    USING (auth.uid() = user_id);

-- -----------------------------------------------------
-- 8. SUBSCRIPTION PAYMENT EVENTS TABLE
-- Structured payment logs for observability and idempotency
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_payment_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    request_id UUID,
    subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (
        status IN (
            'started',
            'success',
            'failed',
            'duplicate_request',
            'duplicate_blocked_client'
        )
    ),
    paid_at DATE,
    duplicate_prevented BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    details JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_payment_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own subscription payment events" ON public.subscription_payment_events;
CREATE POLICY "Users can view own subscription payment events"
    ON public.subscription_payment_events FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscription payment events" ON public.subscription_payment_events;
CREATE POLICY "Users can insert own subscription payment events"
    ON public.subscription_payment_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);


-- -----------------------------------------------------
-- 9. INDEXES FOR PERFORMANCE
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_months_user_id ON public.months(user_id);
CREATE INDEX IF NOT EXISTS idx_months_active ON public.months(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_months_dates ON public.months(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_income_sources_month ON public.income_sources(month_id);
CREATE INDEX IF NOT EXISTS idx_income_sources_user ON public.income_sources(user_id);

CREATE INDEX IF NOT EXISTS idx_categories_month ON public.categories(month_id);
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort ON public.categories(month_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_due_date ON public.subscriptions(user_id, next_due_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_active ON public.subscriptions(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_items_category ON public.items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_user ON public.items(user_id);
CREATE INDEX IF NOT EXISTS idx_items_sort ON public.items(category_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_items_category_archived ON public.items(category_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_items_subscription_id ON public.items(subscription_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_items_category_subscription_unique
    ON public.items(category_id, subscription_id)
    WHERE subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_month ON public.transactions(month_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_item ON public.transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_transactions_subscription_id ON public.transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, date);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subscription_payment_events_user_request_unique
    ON public.subscription_payment_events(user_id, request_id)
    WHERE request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_subscription_payment_events_user_created
    ON public.subscription_payment_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscription_payment_events_subscription_created
    ON public.subscription_payment_events(subscription_id, created_at DESC);


-- -----------------------------------------------------
-- 10. HELPER FUNCTIONS
-- -----------------------------------------------------

-- Function: Get item actual total from transactions
CREATE OR REPLACE FUNCTION public.get_item_actual(p_item_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE item_id = p_item_id AND type = 'expense'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get category actual total from transactions
CREATE OR REPLACE FUNCTION public.get_category_actual(p_category_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE category_id = p_category_id AND type = 'expense'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get income source actual from transactions
CREATE OR REPLACE FUNCTION public.get_income_source_actual(p_income_source_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE income_source_id = p_income_source_id AND type = 'income'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Protect reserved system "Subscriptions" category
CREATE OR REPLACE FUNCTION public.enforce_reserved_subscriptions_category()
RETURNS TRIGGER AS $$
DECLARE
    new_name_normalized TEXT := LOWER(BTRIM(NEW.name));
BEGIN
    IF new_name_normalized IN ('subscription', 'subscriptions') THEN
        NEW.name := 'Subscriptions';
        NEW.icon := 'repeat';
        NEW.color := '#8b5cf6';
        NEW.is_budgeted := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS public.mark_subscription_paid(UUID, DATE, NUMERIC);

CREATE OR REPLACE FUNCTION public.mark_subscription_paid(
    p_subscription_id UUID,
    p_paid_at DATE DEFAULT CURRENT_DATE,
    p_amount_override NUMERIC DEFAULT NULL,
    p_request_id UUID DEFAULT NULL
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
            jsonb_build_object('source', 'mark_subscription_paid')
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
                'next_due_date', next_due_date
            )
        WHERE user_id = v_user_id
          AND request_id = p_request_id;
    END IF;

    RETURN NEXT;
END;
$$;

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_months_updated_at ON public.months;
CREATE TRIGGER update_months_updated_at
    BEFORE UPDATE ON public.months
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_income_sources_updated_at ON public.income_sources;
CREATE TRIGGER update_income_sources_updated_at
    BEFORE UPDATE ON public.income_sources
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS enforce_reserved_subscriptions_category_trg ON public.categories;
CREATE TRIGGER enforce_reserved_subscriptions_category_trg
    BEFORE INSERT OR UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.enforce_reserved_subscriptions_category();

UPDATE public.categories
SET
    name = 'Subscriptions',
    icon = 'repeat',
    color = '#8b5cf6',
    is_budgeted = TRUE
WHERE LOWER(BTRIM(name)) IN ('subscription', 'subscriptions');

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_items_updated_at ON public.items;
CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON public.transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
