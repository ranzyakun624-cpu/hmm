-- License plan support: one-day keys expire 24 hours after first activation;
-- lifetime keys have no expires_at value.

ALTER TABLE public.licenses
    ADD COLUMN IF NOT EXISTS license_type text NOT NULL DEFAULT 'lifetime',
    ADD COLUMN IF NOT EXISTS activated_at timestamptz,
    ADD COLUMN IF NOT EXISTS expires_at timestamptz;

UPDATE public.licenses
   SET license_type = 'lifetime'
 WHERE license_type IS NULL;

ALTER TABLE public.licenses
    ALTER COLUMN license_type SET DEFAULT 'lifetime',
    ALTER COLUMN license_type SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint
        WHERE conname = 'licenses_license_type_check'
          AND conrelid = 'public.licenses'::regclass
    ) THEN
        ALTER TABLE public.licenses
            ADD CONSTRAINT licenses_license_type_check
            CHECK (license_type IN ('1_day', 'lifetime'));
    END IF;
END;
$$;

COMMENT ON COLUMN public.licenses.license_type IS
    'Supported plans: 1_day or lifetime.';
COMMENT ON COLUMN public.licenses.activated_at IS
    'First successful verification time for a 1_day key.';
COMMENT ON COLUMN public.licenses.expires_at IS
    'Expiration timestamp for 1_day keys; NULL before activation and for lifetime keys.';

-- The app verifies through this function and never reads the license table directly.
REVOKE SELECT ON TABLE public.licenses FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.verify_license(p_license_key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    license_row record;
BEGIN
    IF p_license_key IS NULL OR pg_catalog.btrim(p_license_key) = '' THEN
        RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'invalid_key');
    END IF;

        SELECT l.ctid AS row_ctid, l.status, l.license_type, l.activated_at, l.expires_at
            INTO license_row
            FROM public.licenses AS l
         WHERE l.license_key = pg_catalog.btrim(p_license_key)
         LIMIT 1
         FOR UPDATE;

    IF NOT FOUND THEN
        RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    IF pg_catalog.lower(coalesce(license_row.status, '')) NOT IN ('active', 'valid') THEN
        RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'inactive');
    END IF;

    IF license_row.license_type = '1_day' THEN
        IF license_row.activated_at IS NULL AND license_row.expires_at IS NULL THEN
            UPDATE public.licenses
               SET activated_at = pg_catalog.now(),
                   expires_at = pg_catalog.now() + interval '1 day'
             WHERE ctid = license_row.row_ctid
            RETURNING status, license_type, activated_at, expires_at
                 INTO license_row;
        END IF;

        IF license_row.expires_at IS NULL THEN
            RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'inactive');
        END IF;

        IF license_row.expires_at <= pg_catalog.now() THEN
            RETURN pg_catalog.jsonb_build_object(
                'valid', false,
                'reason', 'expired',
                'expires_at', license_row.expires_at
            );
        END IF;

        RETURN pg_catalog.jsonb_build_object(
            'valid', true,
            'reason', 'active',
            'expires_at', license_row.expires_at
        );
    END IF;

    IF license_row.license_type = 'lifetime' THEN
        RETURN pg_catalog.jsonb_build_object('valid', true, 'reason', 'lifetime');
    END IF;

    RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'inactive');
END;
$$;

REVOKE ALL ON FUNCTION public.verify_license(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.verify_license(text) TO anon, authenticated;
