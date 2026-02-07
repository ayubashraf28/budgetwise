-- ============================================================
-- Add is_budgeted column to items table
-- ============================================================
-- This allows per-item budget toggling within a category.
-- When is_budgeted = false, the item's projected amount is
-- excluded from the category's totalProjected calculation,
-- but its actual spending still counts toward totalActual.
--
-- The category-level is_budgeted acts as a parent override:
-- if the category is non-budgeted, all its items are treated
-- as non-budgeted regardless of this flag.
-- ============================================================

ALTER TABLE items
ADD COLUMN IF NOT EXISTS is_budgeted BOOLEAN DEFAULT TRUE;

-- Backfill: all existing items default to budgeted
UPDATE items SET is_budgeted = TRUE WHERE is_budgeted IS NULL;

