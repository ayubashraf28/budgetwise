-- ============================================================
-- Fix transaction month_ids to match their actual date
-- ============================================================
-- This migration fixes transactions that were created before
-- the Impv9 changes, where month_id was set from the "active month"
-- instead of being derived from the transaction's date.
--
-- Run this AFTER ensuring all 12 months exist (the app does this
-- automatically on startup via ensureMonthSetupProvider).
-- ============================================================

-- Step 1: Update month_id for transactions whose date does not
--         fall within their currently assigned month's date range.
UPDATE transactions t
SET month_id = m.id
FROM months m
WHERE t.user_id = m.user_id
  AND t.date >= m.start_date
  AND t.date <= m.end_date
  AND t.month_id != m.id;

-- Step 2: Fix category_id — find a matching category (by name)
--         in the correct month for transactions whose category
--         belongs to a different month than the transaction's month_id.
UPDATE transactions t
SET category_id = new_cat.id
FROM categories old_cat,
     categories new_cat
WHERE t.category_id = old_cat.id
  AND old_cat.month_id != t.month_id
  AND new_cat.name = old_cat.name
  AND new_cat.month_id = t.month_id
  AND new_cat.user_id = t.user_id;

-- Step 3: Fix item_id — find a matching item (by name) in the
--         correct month's category for transactions whose item
--         belongs to a different category than the transaction's category_id.
UPDATE transactions t
SET item_id = new_item.id
FROM items old_item,
     items new_item
WHERE t.item_id IS NOT NULL
  AND t.item_id = old_item.id
  AND old_item.category_id != t.category_id
  AND new_item.name = old_item.name
  AND new_item.category_id = t.category_id;

-- Step 4 (optional): Verify — check for any remaining mismatches.
-- Run this SELECT to confirm no transactions still have wrong month_ids.
-- If it returns rows, those transactions may need manual review.
--
-- SELECT t.id, t.date, t.month_id AS current_month_id, m.id AS expected_month_id
-- FROM transactions t
-- JOIN months m ON t.user_id = m.user_id
--   AND t.date >= m.start_date
--   AND t.date <= m.end_date
-- WHERE t.month_id != m.id;

