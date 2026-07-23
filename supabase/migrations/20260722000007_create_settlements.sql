-- Migration 07: Create Settlements Table, RLS and Indexes

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

-- Row Level Security
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

-- RLS Policies: SETTLEMENTS
CREATE POLICY "Group members or involved users can view settlements"
    ON public.settlements
    FOR SELECT
    USING (
        public.is_group_member(group_id, auth.uid())
        OR from_user_id = auth.uid()
        OR to_user_id = auth.uid()
    );

CREATE POLICY "Group members or payer can create settlements"
    ON public.settlements
    FOR INSERT
    WITH CHECK (
        public.is_group_member(group_id, auth.uid())
        OR from_user_id = auth.uid()
    );

CREATE POLICY "Involved users or group members can update settlements"
    ON public.settlements
    FOR UPDATE
    USING (
        public.is_group_member(group_id, auth.uid())
        OR from_user_id = auth.uid()
        OR to_user_id = auth.uid()
    )
    WITH CHECK (
        public.is_group_member(group_id, auth.uid())
        OR from_user_id = auth.uid()
        OR to_user_id = auth.uid()
    );

CREATE POLICY "Payer or group members can delete pending settlements"
    ON public.settlements
    FOR DELETE
    USING (
        from_user_id = auth.uid()
        OR public.is_group_member(group_id, auth.uid())
    );

-- Indexes
CREATE INDEX idx_settlements_group_id ON public.settlements(group_id);
CREATE INDEX idx_settlements_from_user ON public.settlements(from_user_id);
CREATE INDEX idx_settlements_to_user ON public.settlements(to_user_id);
CREATE INDEX idx_settlements_created_at ON public.settlements(created_at);
