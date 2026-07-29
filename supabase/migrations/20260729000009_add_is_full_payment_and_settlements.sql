-- Migration 09: Add is_full_payment column to transactions and update atomic RPC function

ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS is_full_payment BOOLEAN NOT NULL DEFAULT FALSE;

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
    p_created_at TIMESTAMPTZ,
    p_is_full_payment BOOLEAN DEFAULT FALSE
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_tx JSONB;
    v_date_str DATE;
    v_member_count INT;
    v_share NUMERIC;
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
        is_full_payment,
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
        p_is_full_payment,
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
        'is_full_payment', is_full_payment,
        'is_extraordinary', is_extraordinary,
        'description', description,
        'created_at', created_at
    ) INTO v_new_tx;

    -- 2. Atomic Balance Deduction from Payer Wallet
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

        -- 4. Automatic pending settlements generation when 100% is paid upfront
        IF p_is_full_payment THEN
            SELECT COUNT(*) INTO v_member_count
            FROM public.group_members
            WHERE group_id = p_group_id;

            IF v_member_count > 1 THEN
                v_share := p_amount / v_member_count;

                INSERT INTO public.settlements (group_id, from_user_id, to_user_id, amount, status)
                SELECT p_group_id, user_id, p_user_id, v_share, 'pending'::public.settlement_status
                FROM public.group_members
                WHERE group_id = p_group_id AND user_id <> p_user_id;
            END IF;
        END IF;
    END IF;

    RETURN v_new_tx;
END;
$$;
