-- LEBESTY: full clean rebuild (no RLS)

DROP TABLE IF EXISTS public.ratings CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

DELETE FROM auth.users;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  language TEXT DEFAULT 'fr',
  wilaya TEXT DEFAULT '',
  account_type TEXT DEFAULT 'user',
  phone TEXT,
  avatar_url TEXT,
  shop_type TEXT,
  shop_lat DOUBLE PRECISION,
  shop_lng DOUBLE PRECISION,
  rating_avg DOUBLE PRECISION DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_type TEXT NOT NULL,
  category_main TEXT NOT NULL,
  category_sub TEXT NOT NULL,
  category_item TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  taille TEXT,
  condition TEXT NOT NULL,
  is_original BOOLEAN DEFAULT FALSE,
  price NUMERIC(10,2) NOT NULL,
  wilaya TEXT NOT NULL,
  main_image_url TEXT NOT NULL,
  images JSONB DEFAULT '[]',
  is_active BOOLEAN DEFAULT TRUE,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  participant2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message_type TEXT DEFAULT 'text',
  content TEXT,
  media_url TEXT,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_title TEXT,
  product_image_url TEXT,
  product_price NUMERIC(10,2),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rater_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rated_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rater_id, rated_id)
);

GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.products TO anon, authenticated;
GRANT ALL ON public.conversations TO anon, authenticated;
GRANT ALL ON public.messages TO anon, authenticated;
GRANT ALL ON public.ratings TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, username, language, wilaya, account_type,
    phone, shop_type, shop_lat, shop_lng
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::text, 8)),
    COALESCE(NEW.raw_user_meta_data->>'language', 'fr'),
    COALESCE(NEW.raw_user_meta_data->>'wilaya', ''),
    COALESCE(NEW.raw_user_meta_data->>'account_type', 'user'),
    NULLIF(NEW.raw_user_meta_data->>'phone', ''),
    NULLIF(NEW.raw_user_meta_data->>'shop_type', ''),
    NULLIF(NEW.raw_user_meta_data->>'shop_lat', '')::double precision,
    NULLIF(NEW.raw_user_meta_data->>'shop_lng', '')::double precision
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
