-- =====================================================
-- MIGRATION: Add is_budgeted column to categories
-- =====================================================
-- Run this in Supabase SQL Editor
-- This adds support for optional category budgeting.
-- Existing categories default to TRUE (budgeted).
-- =====================================================

ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_budgeted BOOLEAN DEFAULT TRUE;

