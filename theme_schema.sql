-- 1. Create App Settings Table
CREATE TABLE public.app_settings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  primary_color varchar(7) NOT NULL DEFAULT '#1A3557',
  is_dark_mode boolean NOT NULL DEFAULT false,
  allowed_domains text[] DEFAULT '{"supplychainhub.com"}',
  gemini_api_key text,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_by uuid REFERENCES auth.users(id)
);

-- 2. Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- 3. Everyone can read settings
CREATE POLICY "Anyone can read app settings"
  ON public.app_settings FOR SELECT
  USING (true);

-- 4. Only super_admins can update settings
CREATE POLICY "Super admins can update app settings"
  ON public.app_settings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- 5. Only super_admins can insert initial settings
CREATE POLICY "Super admins can insert app settings"
  ON public.app_settings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- 6. Insert default theme row (We only ever want one row in this table)
INSERT INTO public.app_settings (id, primary_color, is_dark_mode) 
VALUES ('00000000-0000-0000-0000-000000000001', '#1A3557', false)
ON CONFLICT (id) DO NOTHING;
