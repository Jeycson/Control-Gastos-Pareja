-- Migration 05: Create Transactions Table, RLS and Indexes

CREATE TABLE public.transactions (
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

-- Row Level Security
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies: TRANSACTIONS
CREATE POLICY "Users can view own transactions or group transactions"
    ON public.transactions
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    );

CREATE POLICY "Users can insert their own transactions"
    ON public.transactions
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own transactions or group transactions"
    ON public.transactions
    FOR UPDATE
    USING (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    )
    WITH CHECK (
        user_id = auth.uid()
        OR (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
    );

CREATE POLICY "Users can delete their own transactions"
    ON public.transactions
    FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_transactions_wallet_id ON public.transactions(wallet_id);
CREATE INDEX idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX idx_transactions_group_id ON public.transactions(group_id);
CREATE INDEX idx_transactions_created_at ON public.transactions(created_at);
