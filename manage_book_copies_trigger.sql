-- =====================================================
-- Auto-Update available_copies on Borrow / Return
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Function: Adjust available_copies based on borrow status changes
CREATE OR REPLACE FUNCTION manage_book_copies()
RETURNS TRIGGER AS $$
BEGIN
  -- ── NEW ROW INSERTED (a new borrow) ───────────────────────────────────
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'borrowed' THEN
      -- Decrement available copies (but never below 0)
      UPDATE books
      SET available_copies = GREATEST(available_copies - 1, 0)
      WHERE id = NEW.book_id;
    END IF;
    RETURN NEW;
  END IF;

  -- ── ROW UPDATED ────────────────────────────────────────────────────────
  IF TG_OP = 'UPDATE' THEN
    -- Was NOT borrowed before, now IS → decrement
    IF OLD.status <> 'borrowed' AND NEW.status = 'borrowed' THEN
      UPDATE books
      SET available_copies = GREATEST(available_copies - 1, 0)
      WHERE id = NEW.book_id;

    -- Was borrowed (or overdue), now returned / lost → increment
    ELSIF OLD.status IN ('borrowed', 'overdue') AND NEW.status IN ('returned', 'lost') THEN
      UPDATE books
      SET available_copies = LEAST(available_copies + 1, total_copies)
      WHERE id = NEW.book_id;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger if it exists
DROP TRIGGER IF EXISTS trg_manage_book_copies ON borrow_records;

-- Create trigger: fires after INSERT or UPDATE on borrow_records
CREATE TRIGGER trg_manage_book_copies
  AFTER INSERT OR UPDATE OF status
  ON borrow_records
  FOR EACH ROW
  EXECUTE FUNCTION manage_book_copies();

-- =====================================================
-- Optional: Re-sync copies right now from live data
-- Run once to fix any existing mismatches
-- =====================================================
UPDATE books b
SET available_copies = (
  b.total_copies - (
    SELECT COUNT(*)
    FROM borrow_records br
    WHERE br.book_id = b.id
      AND br.status IN ('borrowed', 'overdue')
  )
)
WHERE b.is_active = true;
