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
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

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
CREATE POLICY "Users can view own months"
    ON public.months FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own months"
    ON public.months FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own months"
    ON public.months FOR UPDATE
    USING (auth.uid() = user_id);

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
CREATE POLICY "Users can view own income sources"
    ON public.income_sources FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own income sources"
    ON public.income_sources FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own income sources"
    ON public.income_sources FOR UPDATE
    USING (auth.uid() = user_id);

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
CREATE POLICY "Users can view own categories"
    ON public.categories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories"
    ON public.categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
    ON public.categories FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
    ON public.categories FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 5. ITEMS TABLE
-- Budget line items within categories
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    projected DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_budgeted BOOLEAN DEFAULT TRUE,
    is_recurring BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own items"
    ON public.items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own items"
    ON public.items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own items"
    ON public.items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own items"
    ON public.items FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 6. TRANSACTIONS TABLE
-- Actual income and expense records
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    month_id UUID REFERENCES public.months(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
    income_source_id UUID REFERENCES public.income_sources(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
    amount DECIMAL(12,2) NOT NULL,
    date DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own transactions"
    ON public.transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
    ON public.transactions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
    ON public.transactions FOR DELETE
    USING (auth.uid() = user_id);


-- -----------------------------------------------------
-- 7. INDEXES FOR PERFORMANCE
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_months_user_id ON public.months(user_id);
CREATE INDEX IF NOT EXISTS idx_months_active ON public.months(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_months_dates ON public.months(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_income_sources_month ON public.income_sources(month_id);
CREATE INDEX IF NOT EXISTS idx_income_sources_user ON public.income_sources(user_id);

CREATE INDEX IF NOT EXISTS idx_categories_month ON public.categories(month_id);
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort ON public.categories(month_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_items_category ON public.items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_user ON public.items(user_id);
CREATE INDEX IF NOT EXISTS idx_items_sort ON public.items(category_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_transactions_month ON public.transactions(month_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_item ON public.transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, date);


-- -----------------------------------------------------
-- 8. HELPER FUNCTIONS
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

DROP TRIGGER IF EXISTS update_items_updated_at ON public.items;
CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON public.transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
