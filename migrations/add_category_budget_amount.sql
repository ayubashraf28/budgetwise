-- =====================================================
-- Add budget_amount column to categories table
-- =====================================================
-- Stores category-level budget limit.
-- Existing categories remain valid; null means "not explicitly set".
-- =====================================================

ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS budget_amount DECIMAL(12,2);
