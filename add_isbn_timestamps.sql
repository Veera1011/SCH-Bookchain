-- =====================================================
-- Add ISBN Verification Timestamps to borrow_records
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Add column to track WHEN the ISBN was verified at borrow time
ALTER TABLE borrow_records
  ADD COLUMN IF NOT EXISTS isbn_borrowed_verified_at timestamptz;

-- Add column to track WHEN the ISBN was verified at return time
ALTER TABLE borrow_records
  ADD COLUMN IF NOT EXISTS isbn_returned_verified_at timestamptz;
