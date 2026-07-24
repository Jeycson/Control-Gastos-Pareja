-- Migration 08: Atomic Transaction Registration RPC Function
-- Fixes race conditions on wallet balances and budget_weeks spent_amount

CREATE OR REPLACE FUNCTION public.register_transaction_atomic(
    p_id UUID,
    p_wallet_id UUID,
    p_user_id UUID,
    p_group_id UUID,
    p_amount NUMERIC,
    p_category TEXT,
    p_is_shared BOOLEAN,
    p_is_extraordinary BOOLEAN,
    p_description TEXT,
    p_created_at TIMESTAMPTZ
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_tx JSONB;
    v_date_str DATE;
BEGIN
    -- 1. Insert Transaction
    INSERT INTO public.transactions (
        id,
        wallet_id,
        user_id,
        group_id,
        amount,
        category,
        is_shared,
        is_extraordinary,
        description,
        created_at
    ) VALUES (
        p_id,
        p_wallet_id,
        p_user_id,
        p_group_id,
        p_amount,
        p_category,
        p_is_shared,
        p_is_extraordinary,
        p_description,
        p_created_at
    )
    RETURNING jsonb_build_object(
        'id', id,
        'wallet_id', wallet_id,
        'user_id', user_id,
        'group_id', group_id,
        'amount', amount,
        'category', category,
        'is_shared', is_shared,
        'is_extraordinary', is_extraordinary,
        'description', description,
        'created_at', created_at
    ) INTO v_new_tx;

    -- 2. Atomic Balance Deduction (prevents lost updates under concurrent spending)
    UPDATE public.wallets
    SET balance = balance - p_amount
    WHERE id = p_wallet_id;

    -- 3. Atomic Budget Week Spent Increment
    IF p_is_shared AND p_group_id IS NOT NULL THEN
        v_date_str := p_created_at::DATE;

        UPDATE public.budget_weeks
        SET spent_amount = spent_amount + p_amount
        WHERE group_id = p_group_id
          AND start_date <= v_date_str
          AND end_date >= v_date_str;
    END IF;

    RETURN v_new_tx;
END;
$$;
