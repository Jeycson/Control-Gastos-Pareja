-- Migration 03: Create Groups and Group Members Tables, Helper Function, RLS and Indexes

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

-- Security Definer Helper Function to prevent RLS recursion
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

-- Row Level Security
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies: GROUPS
CREATE POLICY "Group members can view their groups"
    ON public.groups
    FOR SELECT
    USING (public.is_group_member(id, auth.uid()));

CREATE POLICY "Authenticated users can lookup groups by invite_code"
    ON public.groups
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can create a group"
    ON public.groups
    FOR INSERT
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "Group members can update their groups"
    ON public.groups
    FOR UPDATE
    USING (public.is_group_member(id, auth.uid()))
    WITH CHECK (public.is_group_member(id, auth.uid()));

CREATE POLICY "Group creators or admins can delete their groups"
    ON public.groups
    FOR DELETE
    USING (created_by = auth.uid() OR public.is_group_member(id, auth.uid()));

-- RLS Policies: GROUP MEMBERS
CREATE POLICY "Group members can view members of their groups"
    ON public.group_members
    FOR SELECT
    USING (public.is_group_member(group_id, auth.uid()) OR user_id = auth.uid());

CREATE POLICY "Group members or group creator can invite/add members"
    ON public.group_members
    FOR INSERT
    WITH CHECK (
        public.is_group_member(group_id, auth.uid())
        OR user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.groups g
            WHERE g.id = group_id AND g.created_by = auth.uid()
        )
    );

CREATE POLICY "Group members can update group member records"
    ON public.group_members
    FOR UPDATE
    USING (public.is_group_member(group_id, auth.uid()))
    WITH CHECK (public.is_group_member(group_id, auth.uid()));

CREATE POLICY "Members can leave or admins can remove group members"
    ON public.group_members
    FOR DELETE
    USING (user_id = auth.uid() OR public.is_group_member(group_id, auth.uid()));

-- Indexes
CREATE INDEX idx_groups_created_by ON public.groups(created_by);
CREATE INDEX idx_groups_invite_code ON public.groups(invite_code);
CREATE INDEX idx_groups_created_at ON public.groups(created_at);
CREATE INDEX idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX idx_group_members_group_id ON public.group_members(group_id);
