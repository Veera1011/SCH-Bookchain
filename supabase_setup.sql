-- =====================================================================
-- SCH BOOKCHAIN — COMPLETE SUPABASE SETUP
-- Run sections in order: Schema → App Settings → RLS → Triggers → Seed
-- =====================================================================


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 1: EXTENSIONS                                            ║
-- ╚═══════════════════════════════════════════════════════════════════╝

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 2: SCHEMA — TABLES                                       ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- 2.1 Locations
CREATE TABLE IF NOT EXISTS public.locations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  city       TEXT NOT NULL,
  address    TEXT,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.2 Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  email            TEXT NOT NULL,
  role             TEXT NOT NULL DEFAULT 'employee',    -- super_admin | location_admin | manager | employee
  status           TEXT NOT NULL DEFAULT 'pending',     -- pending | active | rejected | suspended
  location_id      UUID REFERENCES public.locations(id) ON DELETE SET NULL,
  manager_id       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  department       TEXT,
  points           INTEGER NOT NULL DEFAULT 0,
  reading_goal     INTEGER NOT NULL DEFAULT 12,
  avatar_url       TEXT,
  fcm_token        TEXT,
  rejection_reason TEXT,
  verified_by      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  verified_at      TIMESTAMPTZ,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.3 Books
CREATE TABLE IF NOT EXISTS public.books (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            TEXT NOT NULL,
  author           TEXT NOT NULL,
  isbn             TEXT,
  description      TEXT,
  genre            TEXT[] NOT NULL DEFAULT '{}',
  language         TEXT NOT NULL DEFAULT 'en',
  location_id      UUID REFERENCES public.locations(id) ON DELETE SET NULL,
  total_copies     INTEGER NOT NULL DEFAULT 1,
  available_copies INTEGER NOT NULL DEFAULT 1,
  cover_url        TEXT,
  ebook_url        TEXT,
  avg_rating       FLOAT8 NOT NULL DEFAULT 0,
  rating_count     INTEGER NOT NULL DEFAULT 0,
  condition        TEXT NOT NULL DEFAULT 'good',        -- good | worn | damaged | lost
  qr_code          TEXT UNIQUE,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.4 Borrow Records
CREATE TABLE IF NOT EXISTS public.borrow_records (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id                     UUID REFERENCES public.books(id) ON DELETE CASCADE,
  book_title                  TEXT NOT NULL,
  user_id                     UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_name                   TEXT NOT NULL,
  location_id                 UUID REFERENCES public.locations(id) ON DELETE SET NULL,
  reason                      TEXT NOT NULL,
  borrowed_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date                    TIMESTAMPTZ NOT NULL,
  returned_at                 TIMESTAMPTZ,
  summary                     TEXT,
  summary_score               INTEGER,
  rating                      INTEGER,
  review                      TEXT,
  is_overdue                  BOOLEAN NOT NULL DEFAULT false,
  status                      TEXT NOT NULL DEFAULT 'borrowed',  -- borrowed | returned | overdue | lost
  points_awarded              INTEGER NOT NULL DEFAULT 0,
  isbn_borrowed_verified_at   TIMESTAMPTZ,   -- timestamp when ISBN was verified at borrow
  isbn_returned_verified_at   TIMESTAMPTZ    -- timestamp when ISBN was verified at return
);

-- 2.5 Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT NOT NULL,
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.6 App Settings (global theme & config — single row)
CREATE TABLE IF NOT EXISTS public.app_settings (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  primary_color   VARCHAR(7) NOT NULL DEFAULT '#1A3557',
  is_dark_mode    BOOLEAN NOT NULL DEFAULT false,
  allowed_domains TEXT[] DEFAULT '{"supplychainhub.com"}',
  gemini_api_key  TEXT,
  updated_at      TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_by      UUID REFERENCES auth.users(id)
);


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 3: ROW LEVEL SECURITY (RLS) POLICIES                    ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- Helper function: check if calling user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('super_admin', 'location_admin')
  );
$$;

-- ── Profiles ──────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_read_own_profile"    ON public.profiles;
DROP POLICY IF EXISTS "admins_read_all_profiles"  ON public.profiles;
DROP POLICY IF EXISTS "users_insert_own_profile"  ON public.profiles;

CREATE POLICY "users_read_own_profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "admins_read_all_profiles"
  ON public.profiles FOR SELECT USING (public.is_admin());

-- Critical for registration: allow users to create their own profile row
CREATE POLICY "users_insert_own_profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ── Locations ──────────────────────────────────────────────────────────
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "locations_read_all" ON public.locations;
CREATE POLICY "locations_read_all"
  ON public.locations FOR SELECT USING (true);

-- ── Books ──────────────────────────────────────────────────────────────
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "books_read_all"    ON public.books;
DROP POLICY IF EXISTS "admins_write_books" ON public.books;
CREATE POLICY "books_read_all"
  ON public.books FOR SELECT USING (true);
CREATE POLICY "admins_write_books"
  ON public.books FOR ALL USING (public.is_admin());

-- ── Borrow Records ─────────────────────────────────────────────────────
ALTER TABLE public.borrow_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users_read_own_borrows"   ON public.borrow_records;
DROP POLICY IF EXISTS "users_insert_own_borrows" ON public.borrow_records;
DROP POLICY IF EXISTS "users_update_own_borrows" ON public.borrow_records;
DROP POLICY IF EXISTS "admins_all_borrows"       ON public.borrow_records;
CREATE POLICY "users_read_own_borrows"
  ON public.borrow_records FOR SELECT USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "users_insert_own_borrows"
  ON public.borrow_records FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "users_update_own_borrows"
  ON public.borrow_records FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "admins_all_borrows"
  ON public.borrow_records FOR ALL USING (public.is_admin());

-- ── Notifications ──────────────────────────────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users_read_own_notifications" ON public.notifications;
CREATE POLICY "users_read_own_notifications"
  ON public.notifications FOR SELECT USING (auth.uid() = user_id);

-- ── App Settings ───────────────────────────────────────────────────────
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read app settings"          ON public.app_settings;
DROP POLICY IF EXISTS "Super admins can update app settings"  ON public.app_settings;
DROP POLICY IF EXISTS "Super admins can insert app settings"  ON public.app_settings;
CREATE POLICY "Anyone can read app settings"
  ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "Super admins can update app settings"
  ON public.app_settings FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'));
CREATE POLICY "Super admins can insert app settings"
  ON public.app_settings FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'));


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 4: TRIGGERS                                              ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- ── Trigger 1: Auto-update available_copies on borrow / return ──────
CREATE OR REPLACE FUNCTION manage_book_copies()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'borrowed' THEN
      UPDATE books SET available_copies = GREATEST(available_copies - 1, 0)
      WHERE id = NEW.book_id;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- borrowed → decrement
    IF OLD.status <> 'borrowed' AND NEW.status = 'borrowed' THEN
      UPDATE books SET available_copies = GREATEST(available_copies - 1, 0)
      WHERE id = NEW.book_id;
    -- returned/lost → increment
    ELSIF OLD.status IN ('borrowed', 'overdue') AND NEW.status IN ('returned', 'lost') THEN
      UPDATE books SET available_copies = LEAST(available_copies + 1, total_copies)
      WHERE id = NEW.book_id;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_manage_book_copies ON borrow_records;
CREATE TRIGGER trg_manage_book_copies
  AFTER INSERT OR UPDATE OF status ON borrow_records
  FOR EACH ROW EXECUTE FUNCTION manage_book_copies();

-- ── Trigger 2: Auto-recalculate avg_rating & rating_count on return ─
CREATE OR REPLACE FUNCTION update_book_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rating IS NOT NULL AND NEW.status = 'returned' THEN
    UPDATE books
    SET
      avg_rating   = (SELECT ROUND(AVG(rating)::numeric, 2)
                      FROM borrow_records
                      WHERE book_id = NEW.book_id AND status = 'returned' AND rating IS NOT NULL),
      rating_count = (SELECT COUNT(*)
                      FROM borrow_records
                      WHERE book_id = NEW.book_id AND status = 'returned' AND rating IS NOT NULL)
    WHERE id = NEW.book_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_book_rating ON borrow_records;
CREATE TRIGGER trg_update_book_rating
  AFTER INSERT OR UPDATE OF rating, status ON borrow_records
  FOR EACH ROW EXECUTE FUNCTION update_book_rating();


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 5: SEED DATA                                             ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- 5.1 Default app settings row (only one row ever exists)
INSERT INTO public.app_settings (id, primary_color, is_dark_mode)
VALUES ('00000000-0000-0000-0000-000000000001', '#1A3557', false)
ON CONFLICT (id) DO NOTHING;

-- 5.2 Seed Admin User
-- (Change email/password before running)
DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
  admin_email  text := 'veeramanikandan.e@supplychainhub.com';
  admin_pass   text := 'Veera32@35';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      new_user_id, 'authenticated', 'authenticated', admin_email,
      crypt(admin_pass, gen_salt('bf')),
      now(), now(), now(), '', '', '', ''
    );

    INSERT INTO public.profiles (id, name, email, role, status, points, reading_goal, is_active, created_at)
    VALUES (new_user_id, 'Veeramanikandan E', admin_email, 'super_admin', 'active', 0, 12, true, now())
    ON CONFLICT (id) DO UPDATE SET role = 'super_admin', status = 'active', is_active = true;
  ELSE
    RAISE NOTICE 'User % already exists. Ensuring super_admin role.', admin_email;
    UPDATE public.profiles SET role = 'super_admin', status = 'active', is_active = true
    WHERE email = admin_email;
  END IF;
END $$;

-- 5.3 Mock Locations
INSERT INTO public.locations (id, name, city, address, is_active) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Main Branch Library',  'Chennai',       '123 Book St',  true),
  ('22222222-2222-2222-2222-222222222222', 'Downtown Campus',      'Bangalore',     '456 Tech Ave', true)
ON CONFLICT (id) DO NOTHING;

-- 5.4 Mock Auth Users
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
VALUES
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'admin@sch.com',    crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'employee@sch.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- 5.5 Mock Profiles
INSERT INTO public.profiles (id, name, email, role, status, location_id, department, points, reading_goal, is_active) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Admin User',    'admin@sch.com',    'super_admin', 'active', '11111111-1111-1111-1111-111111111111', 'IT',        150, 24, true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Employee User', 'employee@sch.com', 'employee',    'active', '11111111-1111-1111-1111-111111111111', 'Marketing',  20, 12, true)
ON CONFLICT (id) DO NOTHING;

-- 5.6 Mock Books
INSERT INTO public.books (title, author, isbn, description, genre, language, location_id, total_copies, available_copies, condition, avg_rating, rating_count, is_active)
VALUES
  ('Clean Code',               'Robert C. Martin', '9780132350884', 'A Handbook of Agile Software Craftsmanship',          ARRAY['Technology','Programming'],  'en', '11111111-1111-1111-1111-111111111111', 5, 5, 'good', 4.8, 120, true),
  ('The Pragmatic Programmer', 'Andrew Hunt',      '9780201616224', 'From Journeyman to Master',                           ARRAY['Technology','Career'],        'en', '11111111-1111-1111-1111-111111111111', 3, 2, 'good', 4.9, 300, true),
  ('Leading Change',           'John P. Kotter',   '9781422186435', 'A classic guide to leading organisational change',    ARRAY['Leadership','Management'],    'en', '22222222-2222-2222-2222-222222222222', 2, 2, 'good', 4.5,  45, true),
  ('Design Patterns',          'Erich Gamma',      '9780201633610', 'Elements of Reusable Object-Oriented Software',       ARRAY['Technology','Programming'],  'en', '11111111-1111-1111-1111-111111111111', 4, 4, 'good', 4.6, 215, true),
  ('Thinking, Fast and Slow',  'Daniel Kahneman',  '9780374533557', 'Human judgment and decision-making explained',        ARRAY['Psychology','Self-Help'],     'en', '22222222-2222-2222-2222-222222222222', 1, 1, 'good', 4.7, 500, true)
ON CONFLICT DO NOTHING;


-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SECTION 6: ONE-TIME DATA FIXES / BACK-FILLS                     ║
-- ║  (Run once to fix any data that existed before triggers)          ║
-- ╚═══════════════════════════════════════════════════════════════════╝

-- 6.1 Re-sync available_copies from live borrow data
UPDATE public.books b
SET available_copies = (
  b.total_copies - (
    SELECT COUNT(*) FROM public.borrow_records br
    WHERE br.book_id = b.id AND br.status IN ('borrowed', 'overdue')
  )
)
WHERE b.is_active = true;

-- 6.2 Back-fill avg_rating & rating_count from existing reviews
UPDATE public.books b
SET
  avg_rating   = sub.avg_r,
  rating_count = sub.cnt
FROM (
  SELECT book_id,
         ROUND(AVG(rating)::numeric, 2) AS avg_r,
         COUNT(*)                        AS cnt
  FROM public.borrow_records
  WHERE status = 'returned' AND rating IS NOT NULL
  GROUP BY book_id
) sub
WHERE b.id = sub.book_id;
