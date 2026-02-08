-- ============================================================
-- Add is_archived flag to items
-- ============================================================
-- Used to hide archived subscription items without deleting history.
-- ============================================================

ALTER TABLE public.items
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_items_category_archived
    ON public.items(category_id, is_archived);
