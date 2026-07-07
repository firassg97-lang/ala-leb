-- Feed + filter indexes (safe to re-run)

CREATE INDEX IF NOT EXISTS idx_products_active_published
  ON public.products (is_active, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_user
  ON public.products (user_id, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_wilaya
  ON public.products (wilaya) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_products_type
  ON public.products (product_type) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_products_category_main
  ON public.products (category_main) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_products_category_sub
  ON public.products (category_sub) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_products_category_item
  ON public.products (category_item) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_profiles_username
  ON public.profiles (username);

CREATE INDEX IF NOT EXISTS idx_profiles_shop_feed
  ON public.profiles (account_type, rating_avg DESC)
  WHERE account_type = 'shop';
