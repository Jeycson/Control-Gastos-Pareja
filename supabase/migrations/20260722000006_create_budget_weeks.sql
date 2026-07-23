-- Migration 06: Create Budget Weeks Table, RLS and Indexes

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

-- Row Level Security
ALTER TABLE public.budget_weeks ENABLE ROW LEVEL SECURITY;

-- RLS Policies: BUDGET WEEKS
CREATE POLICY "Group members can view budget weeks"
    ON public.budget_weeks
    FOR SELECT
    USING (public.is_group_member(group_id, auth.uid()));

CREATE POLICY "Group members can insert budget weeks"
    ON public.budget_weeks
    FOR INSERT
    WITH CHECK (public.is_group_member(group_id, auth.uid()));

CREATE POLICY "Group members can update budget weeks"
    ON public.budget_weeks
    FOR UPDATE
    USING (public.is_group_member(group_id, auth.uid()))
    WITH CHECK (public.is_group_member(group_id, auth.uid()));

CREATE POLICY "Group members can delete budget weeks"
    ON public.budget_weeks
    FOR DELETE
    USING (public.is_group_member(group_id, auth.uid()));

-- Indexes
CREATE INDEX idx_budget_weeks_group_id ON public.budget_weeks(group_id);
CREATE INDEX idx_budget_weeks_start_end_date ON public.budget_weeks(start_date, end_date);
