-- =====================================================
-- Rating Auto-Update Trigger for SCH BookChain
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Function: Recalculate a book's avg_rating and rating_count
-- whenever a borrow record with a rating is inserted or updated.

CREATE OR REPLACE FUNCTION update_book_rating()
RETURNS TRIGGER AS $$
BEGIN
  -- Only act when a rating is being set (non-null) and status is returned
  IF NEW.rating IS NOT NULL AND NEW.status = 'returned' THEN
    UPDATE books
    SET
      avg_rating   = (
        SELECT ROUND(AVG(rating)::numeric, 2)
        FROM borrow_records
        WHERE book_id = NEW.book_id
          AND status  = 'returned'
          AND rating  IS NOT NULL
      ),
      rating_count = (
        SELECT COUNT(*)
        FROM borrow_records
        WHERE book_id = NEW.book_id
          AND status  = 'returned'
          AND rating  IS NOT NULL
      )
    WHERE id = NEW.book_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger if it exists
DROP TRIGGER IF EXISTS trg_update_book_rating ON borrow_records;

-- Create trigger: fires after INSERT or UPDATE on borrow_records
CREATE TRIGGER trg_update_book_rating
  AFTER INSERT OR UPDATE OF rating, status
  ON borrow_records
  FOR EACH ROW
  EXECUTE FUNCTION update_book_rating();

-- =====================================================
-- Optional: Back-fill existing ratings right now
-- Run this once to populate ratings from existing data
-- =====================================================
UPDATE books b
SET
  avg_rating   = sub.avg_r,
  rating_count = sub.cnt
FROM (
  SELECT
    book_id,
    ROUND(AVG(rating)::numeric, 2) AS avg_r,
    COUNT(*)                        AS cnt
  FROM borrow_records
  WHERE status = 'returned'
    AND rating IS NOT NULL
  GROUP BY book_id
) sub
WHERE b.id = sub.book_id;
