-- -----------------------------------------------------------------------------
-- Run tests
-- -----------------------------------------------------------------------------

BEGIN;

-- modify search_path for current transaction
DO
LANGUAGE plpgsql
$$
DECLARE
    vb_has_tap bool;
BEGIN

    SELECT setting ILIKE '%tap%' AS have_tap
      INTO vb_has_tap
      FROM pg_settings
     WHERE name = 'search_path';

    IF vb_has_tap = false OR vb_has_tap IS NULL THEN
        PERFORM set_config('search_path', current_setting('search_path') || ', tap', true);
    END IF;

END;
$$;

SELECT * FROM runtests('tests','^test');
