-- ==========================================
-- FINANZAS COMPARTIDAS - MIGRACIÓN COMPLETA
-- Ejecutar este script en el Editor SQL de Supabase (https://supabase.com/dashboard/project/_/sql)
-- ==========================================

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

-- 2. TABLA PROFILES Y TRIGGER DE REGISTRO
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. TABLAS GROUPS Y GROUP_MEMBERS Y HELPER FUNCTION
CREATE TABLE IF NOT EXISTS public.groups (
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

CREATE TABLE IF NOT EXISTS public.group_members (
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

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- 4. TABLA WALLETS
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    name TEXT NOT NULL DEFAULT '',
    type public.wallet_type NOT NULL,
    balance NUMERIC NOT NULL DEFAULT 0.00,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- 5. TABLA TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    is_extraordinary BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 6. TABLA BUDGET_WEEKS
CREATE TABLE IF NOT EXISTS public.budget_weeks (
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

ALTER TABLE public.budget_weeks ENABLE ROW LEVEL SECURITY;

-- 7. TABLA SETTLEMENTS
CREATE TABLE IF NOT EXISTS public.settlements (
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

ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

-- 8. POLÍTICAS RLS (PROFILES, GROUPS, GROUP_MEMBERS, WALLETS, TRANSACTIONS, BUDGET_WEEKS, SETTLEMENTS)
DROP POLICY IF EXISTS "Users can view their own profile or profiles of group members" ON public.profiles;
CREATE POLICY "Users can view their own profile or profiles of group members" ON public.profiles FOR SELECT USING (id = auth.uid() OR EXISTS (SELECT 1 FROM public.group_members gm1 JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id WHERE gm1.user_id = auth.uid() AND gm2.user_id = public.profiles.id));

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Group members can view their groups" ON public.groups;
CREATE POLICY "Group members can view their groups" ON public.groups FOR SELECT USING (public.is_group_member(id, auth.uid()));

DROP POLICY IF EXISTS "Authenticated users can lookup groups by invite_code" ON public.groups;
CREATE POLICY "Authenticated users can lookup groups by invite_code" ON public.groups FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can create a group" ON public.groups;
CREATE POLICY "Authenticated users can create a group" ON public.groups FOR INSERT WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Group members can update their groups" ON public.groups;
CREATE POLICY "Group members can update their groups" ON public.groups FOR UPDATE USING (public.is_group_member(id, auth.uid())) WITH CHECK (public.is_group_member(id, auth.uid()));

DROP POLICY IF EXISTS "Group creators or admins can delete their groups" ON public.groups;
CREATE POLICY "Group creators or admins can delete their groups" ON public.groups FOR DELETE USING (created_by = auth.uid() OR public.is_group_member(id, auth.uid()));

DROP POLICY IF EXISTS "Group members can view members of their groups" ON public.group_members;
CREATE POLICY "Group members can view members of their groups" ON public.group_members FOR SELECT USING (public.is_group_member(group_id, auth.uid()) OR user_id = auth.uid());

DROP POLICY IF EXISTS "Group members or group creator can invite/add members" ON public.group_members;
CREATE POLICY "Group members or group creator can invite/add members" ON public.group_members FOR INSERT WITH CHECK (public.is_group_member(group_id, auth.uid()) OR user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.created_by = auth.uid()));

DROP POLICY IF EXISTS "Group members can update group member records" ON public.group_members;
CREATE POLICY "Group members can update group member records" ON public.group_members FOR UPDATE USING (public.is_group_member(group_id, auth.uid())) WITH CHECK (public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Members can leave or admins can remove group members" ON public.group_members;
CREATE POLICY "Members can leave or admins can remove group members" ON public.group_members FOR DELETE USING (user_id = auth.uid() OR public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Users can view own wallets or shared group wallets" ON public.wallets;
CREATE POLICY "Users can view own wallets or shared group wallets" ON public.wallets FOR SELECT USING (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid())));

DROP POLICY IF EXISTS "Users can insert their own wallets" ON public.wallets;
CREATE POLICY "Users can insert their own wallets" ON public.wallets FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own wallets or group members if shared" ON public.wallets;
CREATE POLICY "Users can update their own wallets or group members if shared" ON public.wallets FOR UPDATE USING (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))) WITH CHECK (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid())));

DROP POLICY IF EXISTS "Users can delete their own wallets" ON public.wallets;
CREATE POLICY "Users can delete their own wallets" ON public.wallets FOR DELETE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view own transactions or group transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions or group transactions" ON public.transactions FOR SELECT USING (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid())));

DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions;
CREATE POLICY "Users can insert their own transactions" ON public.transactions FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own transactions or group transactions" ON public.transactions;
CREATE POLICY "Users can update own transactions or group transactions" ON public.transactions FOR UPDATE USING (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))) WITH CHECK (user_id = auth.uid() OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid())));

DROP POLICY IF EXISTS "Users can delete their own transactions" ON public.transactions;
CREATE POLICY "Users can delete their own transactions" ON public.transactions FOR DELETE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Group members can view budget weeks" ON public.budget_weeks;
CREATE POLICY "Group members can view budget weeks" ON public.budget_weeks FOR SELECT USING (public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Group members can insert budget weeks" ON public.budget_weeks;
CREATE POLICY "Group members can insert budget weeks" ON public.budget_weeks FOR INSERT WITH CHECK (public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Group members can update budget weeks" ON public.budget_weeks;
CREATE POLICY "Group members can update budget weeks" ON public.budget_weeks FOR UPDATE USING (public.is_group_member(group_id, auth.uid())) WITH CHECK (public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Group members can delete budget weeks" ON public.budget_weeks;
CREATE POLICY "Group members can delete budget weeks" ON public.budget_weeks FOR DELETE USING (public.is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "Group members or involved users can view settlements" ON public.settlements;
CREATE POLICY "Group members or involved users can view settlements" ON public.settlements FOR SELECT USING (public.is_group_member(group_id, auth.uid()) OR from_user_id = auth.uid() OR to_user_id = auth.uid());

DROP POLICY IF EXISTS "Group members or payer can create settlements" ON public.settlements;
CREATE POLICY "Group members or payer can create settlements" ON public.settlements FOR INSERT WITH CHECK (public.is_group_member(group_id, auth.uid()) OR from_user_id = auth.uid());

DROP POLICY IF EXISTS "Involved users or group members can update settlements" ON public.settlements;
CREATE POLICY "Involved users or group members can update settlements" ON public.settlements FOR UPDATE USING (public.is_group_member(group_id, auth.uid()) OR from_user_id = auth.uid() OR to_user_id = auth.uid()) WITH CHECK (public.is_group_member(group_id, auth.uid()) OR from_user_id = auth.uid() OR to_user_id = auth.uid());

DROP POLICY IF EXISTS "Payer or group members can delete pending settlements" ON public.settlements;
CREATE POLICY "Payer or group members can delete pending settlements" ON public.settlements FOR DELETE USING (from_user_id = auth.uid() OR public.is_group_member(group_id, auth.uid()));

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
    p_created_at TIMESTAMPTZ
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_tx JSONB;
    v_date_str DATE;
BEGIN
    INSERT INTO public.transactions (
        id, wallet_id, user_id, group_id, amount, category, is_shared, is_extraordinary, description, created_at
    ) VALUES (
        p_id, p_wallet_id, p_user_id, p_group_id, p_amount, p_category, p_is_shared, p_is_extraordinary, p_description, p_created_at
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
    END IF;

    RETURN v_new_tx;
END;
$$;
