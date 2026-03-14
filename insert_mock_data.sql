-- Run this script in your Supabase SQL Editor to insert mock data

-- 1. Insert Mock Locations
-- We define specific UUIDs so we can reference them in profiles and books
INSERT INTO public.locations (id, name, city, address, is_active)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Main Branch Library', 'New York', '123 Book St', true),
  ('22222222-2222-2222-2222-222222222222', 'Downtown Campus', 'San Francisco', '456 Tech Ave', true);


-- 2. Insert mock auth.users (Supabase Requirement)
-- Before putting data in `profiles`, the user MUST exist in `auth.users` because of the foreign key constraint
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
VALUES
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'admin1@admin.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'user1@user.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;


-- 3. Insert Mock Profiles
-- Matching the UUIDs we just created in auth.users
INSERT INTO public.profiles (id, name, email, role, status, location_id, department, points, reading_goal, is_active)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Super Admin', 'admin1@admin.com', 'super_admin', 'active', '11111111-1111-1111-1111-111111111111', 'IT', 150, 24, true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Regular User', 'user1@user.com', 'employee', 'active', '11111111-1111-1111-1111-111111111111', 'Marketing', 20, 12, true);


-- 4. Insert Mock Books
INSERT INTO public.books (title, author, isbn, description, genre, language, location_id, total_copies, available_copies, condition, avg_rating, rating_count, is_active)
VALUES
  ('Clean Code', 'Robert C. Martin', '9780132350884', 'A Handbook of Agile Software Craftsmanship', ARRAY['Technology', 'Programming'], 'en', '11111111-1111-1111-1111-111111111111', 5, 5, 'new', 4.8, 120, true),
  ('The Pragmatic Programmer', 'Andrew Hunt', '9780201616224', 'From Journeyman to Master', ARRAY['Technology', 'Career'], 'en', '11111111-1111-1111-1111-111111111111', 3, 2, 'good', 4.9, 300, true),
  ('Leading Change', 'John P. Kotter', '9781422186435', 'A classic on leadership', ARRAY['Leadership', 'Management'], 'en', '22222222-2222-2222-2222-222222222222', 2, 2, 'fair', 4.5, 45, true),
  ('Design Patterns', 'Erich Gamma', '9780201633610', 'Elements of Reusable Object-Oriented Software', ARRAY['Technology', 'Programming'], 'en', '11111111-1111-1111-1111-111111111111', 4, 4, 'good', 4.6, 215, true),
  ('Thinking, Fast and Slow', 'Daniel Kahneman', '9780374533557', 'A book about human judgment and decision-making', ARRAY['Psychology', 'Self-Help'], 'en', '22222222-2222-2222-2222-222222222222', 1, 1, 'good', 4.7, 500, true);

-- Add some borrow records using the ids from above
INSERT INTO public.borrow_records (book_id, book_title, user_id, user_name, location_id, reason, borrowed_at, due_date, status)
SELECT b.id, b.title, p.id, p.name, b.location_id, 'Need to learn new patterns for upcoming project', now(), now() + interval '14 days', 'borrowed'
FROM public.books b, public.profiles p
WHERE b.title = 'The Pragmatic Programmer' AND p.name = 'Regular User'
LIMIT 1;

-- Update available copies since we just "borrowed" one
UPDATE public.books SET available_copies = available_copies - 1 WHERE title = 'The Pragmatic Programmer';
