-- 1. Add 'allowed_domains' to 'app_settings'
ALTER TABLE public.app_settings 
ADD COLUMN IF NOT EXISTS allowed_domains text[] DEFAULT '{"supplychainhub.com"}';

-- Ensure the single settings row has the default domain if it was already inserted
UPDATE public.app_settings 
SET allowed_domains = '{"supplychainhub.com"}'
WHERE id = '00000000-0000-0000-0000-000000000001' AND allowed_domains IS NULL;

-- 2. Insert Super Admin User into auth.users
-- We use a DO block to safely insert and retrieve the new user ID
DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
  admin_email text := 'veeramanikandan.e@supplychainhub.com';
  admin_password text := 'Veera32@35';
BEGIN
  -- Only insert if the user doesn't already exist
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
    
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      new_user_id,
      'authenticated',
      'authenticated',
      admin_email,
      crypt(admin_password, gen_salt('bf')),
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );

    -- 3. Insert into public.profiles
    -- At this point, the insert into auth.users might have triggered an auto-profile creation 
    -- if you have a trigger for that. We will UPSERT into public.profiles to be safe.
    INSERT INTO public.profiles (
      id,
      name,
      email,
      role,
      status,
      points,
      reading_goal,
      is_active,
      created_at
    ) VALUES (
      new_user_id,
      'Veeramanikandan E',
      admin_email,
      'super_admin',
      'active',
      0,
      12,
      true,
      now()
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'super_admin',
      status = 'active',
      is_active = true,
      name = 'Veeramanikandan E';

  ELSE
    RAISE NOTICE 'User % already exists in auth.users', admin_email;
    
    -- Ensure existing user has super_admin role if they exist
    UPDATE public.profiles 
    SET role = 'super_admin', status = 'active', is_active = true
    WHERE email = admin_email;
  END IF;
END $$;
