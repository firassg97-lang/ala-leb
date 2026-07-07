-- RLS is auto-enabled on new tables in this project; add the missing SELECT
-- policy so clients can read the daily start_position. Writes stay blocked
-- (no INSERT/UPDATE/DELETE policy) so only the cron (postgres role) can update.
DROP POLICY IF EXISTS display_settings_select ON public.display_settings;
CREATE POLICY display_settings_select
  ON public.display_settings
  FOR SELECT
  TO public
  USING (true);

-- Clients have no business triggering the daily shuffle on demand. Only
-- pg_cron (postgres role) should run it.
REVOKE EXECUTE ON FUNCTION public.lebesty_compute_start_position() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.lebesty_compute_start_position() FROM anon, authenticated;
