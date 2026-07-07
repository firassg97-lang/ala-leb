-- Singleton table holding the daily-rotating start_position for the home feed.
-- Only one row (id=1) exists, only the cron writes to it, clients only read.

CREATE TABLE IF NOT EXISTS public.display_settings (
  id INTEGER PRIMARY KEY DEFAULT 1,
  start_position INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT display_settings_singleton CHECK (id = 1)
);

INSERT INTO public.display_settings (id, start_position)
VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

GRANT SELECT ON public.display_settings TO anon, authenticated;

-- Computes "most recent 4 AM Africa/Tunis" cutoff, counts older approved+active
-- products, picks a random offset in [0, count), and writes it to display_settings.
CREATE OR REPLACE FUNCTION public.lebesty_compute_start_position()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cutoff TIMESTAMPTZ;
  total  INTEGER;
  pos    INTEGER;
BEGIN
  cutoff := (date_trunc('day', timezone('Africa/Tunis', NOW())) + INTERVAL '4 hours')
            AT TIME ZONE 'Africa/Tunis';
  IF NOW() < cutoff THEN
    cutoff := cutoff - INTERVAL '1 day';
  END IF;

  SELECT COUNT(*) INTO total
  FROM public.products
  WHERE published_at < cutoff
    AND is_active = TRUE
    AND COALESCE(nsfw_status, 'approved') = 'approved';

  IF total > 0 THEN
    pos := floor(random() * total)::int;
  ELSE
    pos := 0;
  END IF;

  UPDATE public.display_settings
  SET start_position = pos,
      updated_at     = NOW()
  WHERE id = 1;
END;
$$;

-- Africa/Tunis is UTC+1 year-round (no DST), so 4 AM Tunis == 3 AM UTC.
DO $$
DECLARE
  jid BIGINT;
BEGIN
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'lebesty_daily_start_position';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;
END $$;

SELECT cron.schedule(
  'lebesty_daily_start_position',
  '0 3 * * *',
  $cmd$SELECT public.lebesty_compute_start_position();$cmd$
);

SELECT public.lebesty_compute_start_position();
