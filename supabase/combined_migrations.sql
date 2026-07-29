-- ==========================================
-- FINANZAS COMPARTIDAS - MIGRACIÓN COMPLETA (MODO PERSONAL / SIN SUPABASE AUTH)
-- Ejecutar este script en el Editor SQL de Supabase (https://supabase.com/dashboard/project/_/sql)
-- ==========================================

-- 0. LIMPIEZA DE TABLAS PREVIAS (RESETEO DE DATOS)
DROP TABLE IF EXISTS public.settlements CASCADE;
DROP TABLE IF EXISTS public.budget_weeks CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.wallets CASCADE;
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.groups CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. ENUMS Y TIPOS PERSONALIZADOS
DO $$ BEGIN
    CREATE TYPE public.wallet_type AS ENUM ('cash', 'card');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.group_role AS ENUM ('admin', 'member');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.settlement_status AS ENUM ('pending', 'settled', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. TABLA PROFILES
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TABLAS GROUPS Y GROUP_MEMBERS Y HELPER FUNCTION
CREATE TABLE public.groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL DEFAULT UPPER(substring(md5(random()::text) from 1 for 6)),
    budget_total NUMERIC NOT NULL CHECK (budget_total >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    weeks_count INT NOT NULL CHECK (weeks_count > 0),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.group_members (
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role public.group_role NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

CREATE OR REPLACE FUNCTION public.is_group_member(_group_id UUID, _user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.group_members
        WHERE group_id = _group_id AND user_id = _user_id
    );
$$;

-- 4. TABLA WALLETS
CREATE TABLE public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    name TEXT NOT NULL DEFAULT '',
    type public.wallet_type NOT NULL,
    balance NUMERIC NOT NULL DEFAULT 0.00,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. TABLA TRANSACTIONS
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    is_extraordinary BOOLEAN NOT NULL DEFAULT FALSE,
    is_full_payment BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. TABLA BUDGET_WEEKS
CREATE TABLE public.budget_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    week_number INT NOT NULL CHECK (week_number > 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    planned_amount NUMERIC NOT NULL DEFAULT 0.00 CHECK (planned_amount >= 0),
    spent_amount NUMERIC NOT NULL DEFAULT 0.00 CHECK (spent_amount >= 0),
    adjusted_amount NUMERIC NOT NULL DEFAULT 0.00 CHECK (adjusted_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (group_id, week_number)
);

-- 7. TABLA SETTLEMENTS
CREATE TABLE public.settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    from_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    status public.settlement_status NOT NULL DEFAULT 'pending',
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_different_users CHECK (from_user_id <> to_user_id)
);

-- 8. DESACTIVAR RLS PARA MODO PERSONAL DE USO DIRECTO
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_weeks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements DISABLE ROW LEVEL SECURITY;

ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS is_full_payment BOOLEAN NOT NULL DEFAULT FALSE;

-- 9. FUNCIÓN RPC ATÓMICA DE REGISTRO DE TRANSACCIONES
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
    INSERT INTO public.transactions (
        id, wallet_id, user_id, group_id, amount, category, is_shared, is_full_payment, is_extraordinary, description, created_at
    ) VALUES (
        p_id, p_wallet_id, p_user_id, p_group_id, p_amount, p_category, p_is_shared, p_is_full_payment, p_is_extraordinary, p_description, p_created_at
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

    UPDATE public.wallets
    SET balance = balance - p_amount
    WHERE id = p_wallet_id;

    IF p_is_shared AND p_group_id IS NOT NULL THEN
        v_date_str := p_created_at::DATE;

        UPDATE public.budget_weeks
        SET spent_amount = spent_amount + p_amount
        WHERE group_id = p_group_id
          AND start_date <= v_date_str
          AND end_date >= v_date_str;

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
