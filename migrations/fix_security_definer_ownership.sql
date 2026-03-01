-- =====================================================
-- Fix SECURITY DEFINER functions to enforce ownership
-- =====================================================
-- These functions previously ran as DB owner without checking
-- auth.uid(), allowing any authenticated user to query another
-- user's data by passing arbitrary UUIDs.
-- Now they return 0 if the caller does not own the record.
-- =====================================================

-- Fix get_item_actual: verify the item belongs to the calling user
CREATE OR REPLACE FUNCTION public.get_item_actual(p_item_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    -- Verify ownership: item must belong to the calling user
    IF NOT EXISTS (
        SELECT 1 FROM public.items WHERE id = p_item_id AND user_id = auth.uid()
    ) THEN
        RETURN 0;
    END IF;

    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE item_id = p_item_id AND type = 'expense'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.get_item_actual(UUID) SET search_path = public;


-- Fix get_category_actual: verify the category belongs to the calling user
CREATE OR REPLACE FUNCTION public.get_category_actual(p_category_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    -- Verify ownership: category must belong to the calling user
    IF NOT EXISTS (
        SELECT 1 FROM public.categories WHERE id = p_category_id AND user_id = auth.uid()
    ) THEN
        RETURN 0;
    END IF;

    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE category_id = p_category_id AND type = 'expense'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.get_category_actual(UUID) SET search_path = public;


-- Fix get_income_source_actual: verify the income source belongs to the calling user
CREATE OR REPLACE FUNCTION public.get_income_source_actual(p_income_source_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    -- Verify ownership: income source must belong to the calling user
    IF NOT EXISTS (
        SELECT 1 FROM public.income_sources WHERE id = p_income_source_id AND user_id = auth.uid()
    ) THEN
        RETURN 0;
    END IF;

    RETURN COALESCE(
        (SELECT SUM(amount) FROM public.transactions WHERE income_source_id = p_income_source_id AND type = 'income'),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.get_income_source_actual(UUID) SET search_path = public;
