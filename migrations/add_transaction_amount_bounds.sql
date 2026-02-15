DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.transactions
        WHERE amount <= 0 OR amount > 999999999.99
    ) THEN
        RAISE EXCEPTION
            'Cannot enforce transaction amount bounds: existing rows contain amount <= 0 or > 999999999.99';
    END IF;
END $$;

ALTER TABLE public.transactions
DROP CONSTRAINT IF EXISTS transactions_amount_bounds_check;

ALTER TABLE public.transactions
ADD CONSTRAINT transactions_amount_bounds_check
CHECK (amount > 0 AND amount <= 999999999.99);
