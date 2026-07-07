-- Applied to production on 2026-07-05 via MCP (migration: account_deletion_and_security_hardening).
-- Kept here for repo parity.

-- ══════════════════════════════════════════════════════════════
-- 1) FK fix: last_message_sender_id blocked profile deletion (NO ACTION)
-- ══════════════════════════════════════════════════════════════
DO $$
DECLARE cname text;
BEGIN
  SELECT conname INTO cname
  FROM pg_constraint
  WHERE conrelid = 'public.conversations'::regclass
    AND contype = 'f'
    AND EXISTS (
      SELECT 1 FROM pg_attribute a
      WHERE a.attrelid = conrelid AND a.attnum = ANY (conkey)
        AND a.attname = 'last_message_sender_id'
    );
  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.conversations DROP CONSTRAINT %I', cname);
  END IF;
END $$;

ALTER TABLE public.conversations
  ADD CONSTRAINT conversations_last_message_sender_id_fkey
  FOREIGN KEY (last_message_sender_id)
  REFERENCES public.profiles(id) ON DELETE SET NULL;

-- ══════════════════════════════════════════════════════════════
-- 2) Full account deletion (Apple Guideline 5.1.1(v)).
--    Deletes storage files owned by the user, then the auth user;
--    profiles/products/messages/ratings/fcm_tokens/reports follow via FK cascades.
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  DELETE FROM storage.objects WHERE owner_id = uid::text;
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_account() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_account() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- ══════════════════════════════════════════════════════════════
-- 3) Storage: replace open_access (ALL/true for everyone — anyone could
--    delete/overwrite any file) with scoped policies.
-- ══════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "open_access" ON storage.objects;

CREATE POLICY storage_authenticated_select ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id IN ('avatars','products','voice_messages'));

CREATE POLICY storage_authenticated_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('avatars','products','voice_messages'));

CREATE POLICY storage_owner_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (owner_id = auth.uid()::text)
  WITH CHECK (owner_id = auth.uid()::text);

CREATE POLICY storage_owner_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (owner_id = auth.uid()::text);

-- ══════════════════════════════════════════════════════════════
-- 4) messages: sender must also be a participant of the conversation
-- ══════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS messages_insert ON public.messages;
CREATE POLICY messages_insert ON public.messages
  FOR INSERT TO public
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.participant1_id = auth.uid() OR c.participant2_id = auth.uid())
    )
  );

-- ══════════════════════════════════════════════════════════════
-- 5) Internal SECURITY DEFINER functions must not be callable via REST RPC.
--    reset_unread_count stays callable by authenticated (used by the app).
-- ══════════════════════════════════════════════════════════════
REVOKE EXECUTE ON FUNCTION public.update_rating_avg() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_unread_count() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_new_message() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_conversation_last_message() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.check_product_rate_limit() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.check_reports_and_flag() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.send_reengagement_notifications() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reset_unread_count(uuid) FROM PUBLIC, anon;
