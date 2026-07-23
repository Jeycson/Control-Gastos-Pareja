-- Migration 04: Create Wallets Table, RLS and Indexes

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

-- Row Level Security
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- RLS Policies: WALLETS
CREATE POLICY "Users can view own wallets or shared group wallets"
    ON public.wallets
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    );

CREATE POLICY "Users can insert their own wallets"
    ON public.wallets
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own wallets or group members if shared"
    ON public.wallets
    FOR UPDATE
    USING (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    )
    WITH CHECK (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    );

CREATE POLICY "Users can delete their own wallets"
    ON public.wallets
    FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX idx_wallets_group_id ON public.wallets(group_id);
CREATE INDEX idx_wallets_created_at ON public.wallets(created_at);
