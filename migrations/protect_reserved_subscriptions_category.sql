-- ============================================================
-- Protect reserved subscriptions category name
-- ============================================================
-- Prevents regular categories from clashing with the system
-- "Subscriptions" category used by the subscriptions feature.
-- ============================================================

CREATE OR REPLACE FUNCTION public.enforce_reserved_subscriptions_category()
RETURNS TRIGGER AS $$
DECLARE
    new_name_normalized TEXT := LOWER(BTRIM(NEW.name));
BEGIN
    -- Any reserved name is canonicalized to the system category shape.
    IF new_name_normalized IN ('subscription', 'subscriptions') THEN
        NEW.name := 'Subscriptions';
        NEW.icon := 'repeat';
        NEW.color := '#8b5cf6';
        NEW.is_budgeted := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_reserved_subscriptions_category_trg ON public.categories;
CREATE TRIGGER enforce_reserved_subscriptions_category_trg
    BEFORE INSERT OR UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.enforce_reserved_subscriptions_category();

-- Normalize any existing reserved-name categories to the canonical
-- system "Subscriptions" shape.
UPDATE public.categories
SET
    name = 'Subscriptions',
    icon = 'repeat',
    color = '#8b5cf6',
    is_budgeted = TRUE
WHERE LOWER(BTRIM(name)) IN ('subscription', 'subscriptions');
