-- -----------------------------------------------------------------------------
-- _v schema tests
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION tests.test_schema_v()
  RETURNS SETOF text AS
$$
BEGIN
    -- perform safety check so function can be run with tap tests
    IF get_var('tests_safety_check_value') != now()::text THEN
        RAISE EXCEPTION 'test function can be run only with tap (e.g. runtests)';
    END IF;

    -- check if schema exists
    RETURN NEXT has_schema('_v');

    -- tables
    RETURN NEXT has_table('_v'::name, 'patches'::name);
    RETURN NEXT has_table('_v'::name, 'patch_history'::name);
    RETURN NEXT has_table('_v'::name, 'application_name'::name);

    -- functions
    RETURN NEXT has_function('_v'::name, 'register_patch'::name, array['text', 'text', 'text[]', 'text[]']);
    RETURN NEXT has_function('_v'::name, 'register_patch'::name, array['text', 'text', 'text[]']);
    RETURN NEXT has_function('_v'::name, 'register_patch'::name, array['text', 'text']);
    RETURN NEXT has_function('_v'::name, 'unregister_patch'::name, array['text']);

    RETURN;

END;
$$
LANGUAGE plpgsql VOLATILE;
