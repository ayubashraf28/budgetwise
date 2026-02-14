-- Enforce non-empty names for user-facing entities.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'months_name_not_blank'
      AND conrelid = 'public.months'::regclass
  ) THEN
    ALTER TABLE public.months
    ADD CONSTRAINT months_name_not_blank
    CHECK (BTRIM(name) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'income_sources_name_not_blank'
      AND conrelid = 'public.income_sources'::regclass
  ) THEN
    ALTER TABLE public.income_sources
    ADD CONSTRAINT income_sources_name_not_blank
    CHECK (BTRIM(name) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'categories_name_not_blank'
      AND conrelid = 'public.categories'::regclass
  ) THEN
    ALTER TABLE public.categories
    ADD CONSTRAINT categories_name_not_blank
    CHECK (BTRIM(name) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'items_name_not_blank'
      AND conrelid = 'public.items'::regclass
  ) THEN
    ALTER TABLE public.items
    ADD CONSTRAINT items_name_not_blank
    CHECK (BTRIM(name) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'subscriptions_name_not_blank'
      AND conrelid = 'public.subscriptions'::regclass
  ) THEN
    ALTER TABLE public.subscriptions
    ADD CONSTRAINT subscriptions_name_not_blank
    CHECK (BTRIM(name) <> '');
  END IF;
END $$;
