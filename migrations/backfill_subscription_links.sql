-- ============================================================
-- Backfill subscription links for legacy records + audit
-- ============================================================
-- Phase 1 migration: conservative backfill only when mapping is unambiguous.
-- Safe to re-run; only null subscription_id rows are considered.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.subscription_backfill_audit (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('item', 'transaction')),
    entity_id UUID NOT NULL,
    subscription_id UUID,
    strategy TEXT NOT NULL,
    ambiguity_count INTEGER,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_backfill_audit ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'subscription_backfill_audit'
          AND policyname = 'Users can view own subscription backfill audit'
    ) THEN
        CREATE POLICY "Users can view own subscription backfill audit"
            ON public.subscription_backfill_audit FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_subscription_backfill_audit_user_id
    ON public.subscription_backfill_audit(user_id);

-- Link items in the Subscriptions category to a single matching subscription name.
WITH item_candidates AS (
    SELECT
        i.id AS item_id,
        i.user_id,
        i.name AS item_name,
        s.id AS subscription_id,
        COUNT(*) OVER (PARTITION BY i.id) AS candidate_count
    FROM public.items i
    JOIN public.categories c
      ON c.id = i.category_id
     AND c.user_id = i.user_id
    JOIN public.subscriptions s
      ON s.user_id = i.user_id
     AND LOWER(BTRIM(s.name)) = LOWER(BTRIM(i.name))
    WHERE i.subscription_id IS NULL
      AND LOWER(c.name) = 'subscriptions'
),
linked_items AS (
    UPDATE public.items i
    SET subscription_id = ic.subscription_id
    FROM item_candidates ic
    WHERE i.id = ic.item_id
      AND ic.candidate_count = 1
    RETURNING i.id, i.user_id, i.subscription_id
)
INSERT INTO public.subscription_backfill_audit (
    user_id, entity_type, entity_id, subscription_id, strategy, ambiguity_count, details
)
SELECT
    li.user_id,
    'item',
    li.id,
    li.subscription_id,
    'name_match_subscriptions_category',
    1,
    '{}'::jsonb
FROM linked_items li;

-- Audit ambiguous item matches for manual review.
WITH item_candidates AS (
    SELECT
        i.id AS item_id,
        i.user_id,
        i.name AS item_name,
        s.id AS subscription_id,
        COUNT(*) OVER (PARTITION BY i.id) AS candidate_count
    FROM public.items i
    JOIN public.categories c
      ON c.id = i.category_id
     AND c.user_id = i.user_id
    JOIN public.subscriptions s
      ON s.user_id = i.user_id
     AND LOWER(BTRIM(s.name)) = LOWER(BTRIM(i.name))
    WHERE i.subscription_id IS NULL
      AND LOWER(c.name) = 'subscriptions'
)
INSERT INTO public.subscription_backfill_audit (
    user_id, entity_type, entity_id, subscription_id, strategy, ambiguity_count, details
)
SELECT DISTINCT
    ic.user_id,
    'item',
    ic.item_id,
    NULL::UUID,
    'name_match_subscriptions_category_ambiguous',
    ic.candidate_count::INTEGER,
    jsonb_build_object('item_name', ic.item_name)
FROM item_candidates ic
WHERE ic.candidate_count > 1;

-- Backfill transactions from linked items.
WITH linked_tx AS (
    UPDATE public.transactions t
    SET subscription_id = i.subscription_id
    FROM public.items i
    WHERE t.subscription_id IS NULL
      AND t.item_id = i.id
      AND i.subscription_id IS NOT NULL
    RETURNING t.id, t.user_id, t.subscription_id
)
INSERT INTO public.subscription_backfill_audit (
    user_id, entity_type, entity_id, subscription_id, strategy, ambiguity_count, details
)
SELECT
    lt.user_id,
    'transaction',
    lt.id,
    lt.subscription_id,
    'from_item_subscription_link',
    1,
    '{}'::jsonb
FROM linked_tx lt;

-- Fallback: link remaining transactions by "Subscription: <name>" note if unique.
WITH tx_note_candidates AS (
    SELECT
        t.id AS transaction_id,
        t.user_id,
        REGEXP_REPLACE(t.note, '(?i)^subscription:\s*', '') AS parsed_name,
        s.id AS subscription_id,
        COUNT(*) OVER (PARTITION BY t.id) AS candidate_count
    FROM public.transactions t
    JOIN public.subscriptions s
      ON s.user_id = t.user_id
     AND LOWER(BTRIM(s.name)) = LOWER(BTRIM(REGEXP_REPLACE(t.note, '(?i)^subscription:\s*', '')))
    WHERE t.subscription_id IS NULL
      AND t.note IS NOT NULL
      AND t.note ~* '^subscription:\s*'
),
linked_note_tx AS (
    UPDATE public.transactions t
    SET subscription_id = nc.subscription_id
    FROM tx_note_candidates nc
    WHERE t.id = nc.transaction_id
      AND nc.candidate_count = 1
    RETURNING t.id, t.user_id, t.subscription_id
)
INSERT INTO public.subscription_backfill_audit (
    user_id, entity_type, entity_id, subscription_id, strategy, ambiguity_count, details
)
SELECT
    lnt.user_id,
    'transaction',
    lnt.id,
    lnt.subscription_id,
    'from_note_subscription_prefix',
    1,
    '{}'::jsonb
FROM linked_note_tx lnt;

-- Audit ambiguous note-based transaction matches.
WITH tx_note_candidates AS (
    SELECT
        t.id AS transaction_id,
        t.user_id,
        REGEXP_REPLACE(t.note, '(?i)^subscription:\s*', '') AS parsed_name,
        s.id AS subscription_id,
        COUNT(*) OVER (PARTITION BY t.id) AS candidate_count
    FROM public.transactions t
    JOIN public.subscriptions s
      ON s.user_id = t.user_id
     AND LOWER(BTRIM(s.name)) = LOWER(BTRIM(REGEXP_REPLACE(t.note, '(?i)^subscription:\s*', '')))
    WHERE t.subscription_id IS NULL
      AND t.note IS NOT NULL
      AND t.note ~* '^subscription:\s*'
)
INSERT INTO public.subscription_backfill_audit (
    user_id, entity_type, entity_id, subscription_id, strategy, ambiguity_count, details
)
SELECT DISTINCT
    nc.user_id,
    'transaction',
    nc.transaction_id,
    NULL::UUID,
    'from_note_subscription_prefix_ambiguous',
    nc.candidate_count::INTEGER,
    jsonb_build_object('parsed_name', nc.parsed_name)
FROM tx_note_candidates nc
WHERE nc.candidate_count > 1;

-- Optional verification queries:
-- SELECT entity_type, strategy, COUNT(*) FROM public.subscription_backfill_audit GROUP BY 1,2 ORDER BY 1,2;
-- SELECT COUNT(*) AS remaining_items_without_link FROM public.items WHERE subscription_id IS NULL;
-- SELECT COUNT(*) AS remaining_transactions_without_link
-- FROM public.transactions t
-- WHERE t.note ~* '^subscription:\s*' AND t.subscription_id IS NULL;
