-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUMS
CREATE TYPE user_role AS ENUM 
  ('super_admin','location_admin','manager','employee');

CREATE TYPE user_status AS ENUM 
  ('pending','active','rejected','suspended');

CREATE TYPE borrow_status AS ENUM 
  ('borrowed','returned','overdue','lost');

CREATE TYPE book_condition AS ENUM 
  ('good','worn','damaged','lost');

CREATE TYPE request_status AS ENUM 
  ('pending','approved','rejected','ordered','added');

-- LOCATIONS
CREATE TABLE locations (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       text NOT NULL,
  city       text NOT NULL,
  address    text,
  is_active  boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- PROFILES
CREATE TABLE profiles (
  id               uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name             text NOT NULL,
  email            text NOT NULL,
  role             user_role DEFAULT 'employee',
  status           user_status DEFAULT 'pending',
  location_id      uuid REFERENCES locations(id),
  manager_id       uuid REFERENCES profiles(id),
  department       text,
  points           integer DEFAULT 0,
  reading_goal     integer DEFAULT 12,
  avatar_url       text,
  fcm_token        text,
  rejection_reason text,
  verified_by      uuid REFERENCES profiles(id),
  verified_at      timestamptz,
  is_active        boolean DEFAULT true,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- BOOKS
CREATE TABLE books (
  id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title            text NOT NULL,
  author           text NOT NULL,
  isbn             text,
  description      text,
  genre            text[] DEFAULT '{}',
  language         text DEFAULT 'en',
  location_id      uuid REFERENCES locations(id) NOT NULL,
  total_copies     integer DEFAULT 1,
  available_copies integer DEFAULT 1,
  cover_url        text,
  ebook_url        text,
  avg_rating       numeric(3,2) DEFAULT 0,
  rating_count     integer DEFAULT 0,
  condition        book_condition DEFAULT 'good',
  qr_code          text UNIQUE DEFAULT uuid_generate_v4()::text,
  added_by         uuid REFERENCES profiles(id),
  is_active        boolean DEFAULT true,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- BORROW RECORDS
CREATE TABLE borrow_records (
  id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id        uuid REFERENCES books(id) NOT NULL,
  book_title     text NOT NULL,
  user_id        uuid REFERENCES profiles(id) NOT NULL,
  user_name      text NOT NULL,
  location_id    uuid REFERENCES locations(id) NOT NULL,
  reason         text NOT NULL,
  borrowed_at    timestamptz DEFAULT now(),
  due_date       timestamptz NOT NULL,
  returned_at    timestamptz,
  summary        text,
  summary_score  integer,
  rating         integer CHECK (rating BETWEEN 1 AND 5),
  review         text,
  is_overdue     boolean DEFAULT false,
  status         borrow_status DEFAULT 'borrowed',
  points_awarded integer DEFAULT 0,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- BADGES
CREATE TABLE badges (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug          text UNIQUE NOT NULL,
  name          text NOT NULL,
  description   text,
  icon          text,
  points_reward integer DEFAULT 0
);

CREATE TABLE user_badges (
  id        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id   uuid REFERENCES profiles(id) NOT NULL,
  badge_id  uuid REFERENCES badges(id) NOT NULL,
  earned_at timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

-- BOOK REQUESTS
CREATE TABLE book_requests (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  requested_by uuid REFERENCES profiles(id) NOT NULL,
  location_id  uuid REFERENCES locations(id) NOT NULL,
  title        text NOT NULL,
  author       text,
  reason       text NOT NULL,
  status       request_status DEFAULT 'pending',
  approved_by  uuid REFERENCES profiles(id),
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

-- WAITLIST
CREATE TABLE waitlist (
  id        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id   uuid REFERENCES books(id) NOT NULL,
  user_id   uuid REFERENCES profiles(id) NOT NULL,
  joined_at timestamptz DEFAULT now(),
  UNIQUE(book_id, user_id)
);

-- NOTIFICATIONS
CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    uuid REFERENCES profiles(id) NOT NULL,
  title      text NOT NULL,
  body       text NOT NULL,
  type       text NOT NULL,
  data       jsonb,
  is_read    boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- CHALLENGES
CREATE TABLE challenges (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         text NOT NULL,
  description   text,
  start_date    timestamptz NOT NULL,
  end_date      timestamptz NOT NULL,
  target_books  integer NOT NULL,
  genre_filter  text[],
  points_reward integer DEFAULT 50,
  created_by    uuid REFERENCES profiles(id)
);

CREATE TABLE challenge_participants (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id uuid REFERENCES challenges(id) NOT NULL,
  user_id      uuid REFERENCES profiles(id) NOT NULL,
  joined_at    timestamptz DEFAULT now(),
  completed_at timestamptz,
  UNIQUE(challenge_id, user_id)
);

-- ─── TRIGGERS ────────────────────────────────────────────

-- Auto update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER books_updated_at 
  BEFORE UPDATE ON books
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER profiles_updated_at 
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER borrow_records_updated_at 
  BEFORE UPDATE ON borrow_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Decrement copies on borrow
CREATE OR REPLACE FUNCTION on_borrow_created()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE books SET available_copies = available_copies - 1
  WHERE id = NEW.book_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_borrow_created 
  AFTER INSERT ON borrow_records
  FOR EACH ROW EXECUTE FUNCTION on_borrow_created();

-- Increment copies + award points on return
CREATE OR REPLACE FUNCTION on_borrow_returned()
RETURNS TRIGGER AS $$
DECLARE pts integer := 0;
BEGIN
  IF NEW.status = 'returned' AND OLD.status != 'returned' THEN
    UPDATE books SET available_copies = available_copies + 1
    WHERE id = NEW.book_id;
    pts := 10;
    IF NEW.summary IS NOT NULL AND length(NEW.summary) > 100 THEN
      pts := pts + 20;
    END IF;
    IF NEW.returned_at < NEW.due_date THEN
      pts := pts + 5;
    END IF;
    UPDATE profiles SET points = points + pts WHERE id = NEW.user_id;
    NEW.points_awarded := pts;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_borrow_returned 
  BEFORE UPDATE ON borrow_records
  FOR EACH ROW EXECUTE FUNCTION on_borrow_returned();

-- Update book avg rating on review
CREATE OR REPLACE FUNCTION update_book_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rating IS NOT NULL THEN
    UPDATE books SET
      avg_rating = (
        SELECT AVG(rating) FROM borrow_records 
        WHERE book_id = NEW.book_id AND rating IS NOT NULL),
      rating_count = (
        SELECT COUNT(*) FROM borrow_records 
        WHERE book_id = NEW.book_id AND rating IS NOT NULL)
    WHERE id = NEW.book_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_rating 
  AFTER UPDATE ON borrow_records
  FOR EACH ROW 
  WHEN (NEW.rating IS DISTINCT FROM OLD.rating)
  EXECUTE FUNCTION update_book_rating();

-- Notify user when admin approves or rejects
CREATE OR REPLACE FUNCTION on_profile_status_changed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status != OLD.status THEN
    IF NEW.status = 'active' THEN
      INSERT INTO notifications(user_id, title, body, type)
      VALUES (
        NEW.id,
        '✅ Account Approved!',
        'Your SCH Books account has been approved. Welcome aboard! You now have full access.',
        'account_approved'
      );
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO notifications(user_id, title, body, type)
      VALUES (
        NEW.id,
        '❌ Account Not Approved',
        COALESCE(
          'Your registration was not approved. Reason: ' || NEW.rejection_reason,
          'Your registration was not approved. Please contact HR for more information.'
        ),
        'account_rejected'
      );
    ELSIF NEW.status = 'suspended' THEN
      INSERT INTO notifications(user_id, title, body, type)
      VALUES (
        NEW.id,
        '⚠️ Account Suspended',
        COALESCE(
          'Your account has been suspended. Reason: ' || NEW.rejection_reason,
          'Your account has been suspended. Please contact your admin.'
        ),
        'account_suspended'
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profile_status_changed
  AFTER UPDATE ON profiles
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION on_profile_status_changed();

-- ─── ROW LEVEL SECURITY ───────────────────────────────────

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE books              ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_records     ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges        ENABLE ROW LEVEL SECURITY;

-- Helper function: get current user status
CREATE OR REPLACE FUNCTION current_user_status()
RETURNS user_status AS $$
  SELECT status FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function: get current user role
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Profiles: any authenticated user can read all profiles
--           (needed so pending users can still load their own profile)
--           user can update own row; admins can do all
CREATE POLICY "profiles_read_all" ON profiles 
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "profiles_update_own" ON profiles 
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "profiles_admin_all" ON profiles 
  FOR ALL USING (
    current_user_role() IN ('super_admin','location_admin')
  );

-- Books: ONLY active users can read books
CREATE POLICY "books_read_active_only" ON books 
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND
    current_user_status() = 'active' AND
    is_active = true
  );

CREATE POLICY "books_admin_write" ON books 
  FOR ALL USING (
    current_user_role() IN ('super_admin','location_admin')
  );

-- Borrow records: ONLY active users
CREATE POLICY "borrow_read" ON borrow_records 
  FOR SELECT USING (
    current_user_status() = 'active' AND
    (
      auth.uid() = user_id OR
      current_user_role() IN ('super_admin','location_admin','manager')
    )
  );

CREATE POLICY "borrow_insert_active_only" ON borrow_records 
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    current_user_status() = 'active'
  );

CREATE POLICY "borrow_update" ON borrow_records 
  FOR UPDATE USING (
    auth.uid() = user_id OR
    current_user_role() IN ('super_admin','location_admin')
  );

-- Locations: all authenticated users can read
CREATE POLICY "locations_read" ON locations 
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "locations_admin_write" ON locations 
  FOR ALL USING (current_user_role() = 'super_admin');

-- Notifications: own only
CREATE POLICY "notifs_own" ON notifications 
  FOR ALL USING (auth.uid() = user_id);

-- User badges: own or admin
CREATE POLICY "badges_read" ON user_badges 
  FOR SELECT USING (
    auth.uid() = user_id OR
    current_user_role() IN ('super_admin','location_admin')
  );

-- ─── INDEXES ─────────────────────────────────────────────

CREATE INDEX idx_books_location 
  ON books(location_id);

CREATE INDEX idx_books_available 
  ON books(available_copies) WHERE available_copies > 0;

CREATE INDEX idx_borrow_user 
  ON borrow_records(user_id);

CREATE INDEX idx_borrow_status 
  ON borrow_records(status);

CREATE INDEX idx_borrow_due 
  ON borrow_records(due_date) WHERE status = 'borrowed';

CREATE INDEX idx_notifs_user_unread 
  ON notifications(user_id, is_read) WHERE is_read = false;

CREATE INDEX idx_profiles_status 
  ON profiles(status);

CREATE INDEX idx_profiles_location 
  ON profiles(location_id);

-- ─── SEED DATA ────────────────────────────────────────────

INSERT INTO badges (slug, name, description, icon, points_reward) VALUES
  ('first_chapter',    'First Chapter',    'Borrowed your first book',               '📖', 10),
  ('bookworm',         'Bookworm',         'Returned 5 books with summaries',        '🐛', 25),
  ('speed_reader',     'Speed Reader',     'Returned 3 books 5+ days early',         '⚡', 20),
  ('deep_thinker',     'Deep Thinker',     '3 summaries with AI score >= 9',         '🧠', 40),
  ('genre_explorer',   'Genre Explorer',   'Read books from 5 different genres',     '🗺️', 30),
  ('loyal_reader',     'Loyal Reader',     'Active borrows in 6 consecutive months', '💎', 50),
  ('champion',         'Champion',         'Top 3 on leaderboard for any month',     '🏆', 60),
  ('knowledge_sharer', 'Knowledge Sharer', 'Summary endorsed 10 times',              '✨', 35);
