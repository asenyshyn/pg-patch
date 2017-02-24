-- -----------------------------------------------------------------------------
-- Roles tests
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION tests.test_schema_roles()
  RETURNS SETOF text AS
$$
BEGIN
    -- perform safety check so function can be run with tap tests
    IF get_var('tests_safety_check_value') != now()::text THEN
        RAISE EXCEPTION 'test function can be run only with tap (e.g. runtests)';
    END IF;

    RETURN NEXT has_role('demodb_owner');
    RETURN NEXT has_role('demodb_user');

    RETURN;

END;
$$
LANGUAGE plpgsql VOLATILE;
