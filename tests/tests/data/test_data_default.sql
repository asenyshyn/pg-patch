-- -----------------------------------------------------------------------------
-- default file data test
-- -----------------------------------------------------------------------------

-- CREATE OR REPLACE FUNCTION tests.test_data_default()
--   RETURNS SETOF text AS
-- $$
-- BEGIN
--     -- perform safety check so function can be run with tap tests
--     IF get_var('tests_safety_check_value') != now()::text THEN
--         RAISE EXCEPTION 'test function can be run only with tap (e.g. runtests)';
--     END IF;


--     RETURN;

-- END;
-- $$
-- LANGUAGE plpgsql VOLATILE;
