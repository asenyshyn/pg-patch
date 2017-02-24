-- -----------------------------------------------------------------------------
-- General db schema tests
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION tests.test_schema_general()
  RETURNS SETOF text AS
$$
BEGIN
    -- perform safety check so function can be run with tap tests
    IF get_var('tests_safety_check_value') != now()::text THEN
        RAISE EXCEPTION 'test function can be run only with tap (e.g. runtests)';
    END IF;

    -- check db owner
    RETURN NEXT db_owner_is(current_database(), 'demodb');

    -- -------- schema: public
    RETURN NEXT has_function('public'::name, 'get_login_id', array['']);
    RETURN NEXT has_function('public'::name, 'set_login_id', array['uuid']);
    RETURN NEXT has_function('public'::name, 'raise_exception', array['text', 'character varying']);

    -- check that i_ functions are security definer

    -- RETURN QUERY
    -- SELECT is_definer(n.nspname, p.proname, 'interface function '||n.nspname||'.'||p.proname||' is security definer')
    --   FROM pg_catalog.pg_namespace n
    --   JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid
    --  WHERE n.nspname IN ('public');
    --    AND substr(p.proname, 1,2) = 'i_';

    RETURN;

END;
$$
LANGUAGE plpgsql VOLATILE;
