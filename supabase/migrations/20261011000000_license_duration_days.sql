-- Extend timed licenses from one fixed day to custom 1–30 day plans.
-- Lifetime remains indefinite and has no duration or expiry.

ALTER TABLE public.licenses
    ADD COLUMN IF NOT EXISTS duration_days integer;

ALTER TABLE public.licenses
    DROP CONSTRAINT IF EXISTS licenses_license_type_check,
    DROP CONSTRAINT IF EXISTS licenses_duration_days_check;

-- Preserve existing one-day licenses, including their activation/expiry timestamps.
UPDATE public.licenses
   SET license_type = 'duration',
       duration_days = 1
 WHERE license_type = '1_day';

ALTER TABLE public.licenses
    ADD CONSTRAINT licenses_license_type_check
        CHECK (
            (license_type = 'lifetime' AND duration_days IS NULL)
            OR (
                license_type = 'duration'
                AND duration_days IS NOT NULL
                AND duration_days BETWEEN 1 AND 30
            )
        ),
    ADD CONSTRAINT licenses_duration_days_check
        CHECK (duration_days IS NULL OR duration_days BETWEEN 1 AND 30);

ALTER TABLE public.licenses
    ALTER COLUMN license_type SET DEFAULT 'lifetime';

COMMENT ON COLUMN public.licenses.duration_days IS
    'Timed license duration in days (1–30); NULL for lifetime licenses.';
COMMENT ON COLUMN public.licenses.license_type IS
    'Supported plans: duration (1–30 days) or lifetime.';

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

    SELECT l.ctid AS row_ctid,
           l.status,
           l.license_type,
           l.duration_days,
           l.activated_at,
           l.expires_at
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

    IF license_row.license_type = 'duration' THEN
        IF license_row.duration_days IS NULL
           OR license_row.duration_days < 1
           OR license_row.duration_days > 30 THEN
            RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'inactive');
        END IF;

        IF license_row.activated_at IS NULL AND license_row.expires_at IS NULL THEN
            UPDATE public.licenses
               SET activated_at = pg_catalog.now(),
                   expires_at = pg_catalog.now() + (interval '1 day' * license_row.duration_days)
             WHERE ctid = license_row.row_ctid
            RETURNING activated_at, expires_at
                 INTO license_row.activated_at, license_row.expires_at;
        END IF;

        IF license_row.expires_at IS NULL THEN
            RETURN pg_catalog.jsonb_build_object('valid', false, 'reason', 'inactive');
        END IF;

        IF license_row.expires_at <= pg_catalog.now() THEN
            RETURN pg_catalog.jsonb_build_object(
                'valid', false,
                'reason', 'expired',
                'duration_days', license_row.duration_days,
                'expires_at', license_row.expires_at
            );
        END IF;

        RETURN pg_catalog.jsonb_build_object(
            'valid', true,
            'reason', 'active',
            'duration_days', license_row.duration_days,
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
