-- Migration 01: Create Custom Enum Types

CREATE TYPE public.wallet_type AS ENUM ('cash', 'card');
CREATE TYPE public.group_role AS ENUM ('admin', 'member');
CREATE TYPE public.settlement_status AS ENUM ('pending', 'settled', 'cancelled');
