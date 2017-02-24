-- ------------------------------------------------------------------------- --
-- ------------------ startup and setup function --------------------------- --
-- ------------------------------------------------------------------------- --

-- once before all tests
CREATE OR REPLACE FUNCTION tests.startup()
RETURNS SETOF text AS
$$
BEGIN
    -- set tests safety check value
    PERFORM set_var('tests_safety_check_value', now()::text);
    RETURN;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

/*
-- before each test
CREATE OR REPLACE FUNCTION tests.setup_test()
RETURNS SETOF text AS
$$
BEGIN
    RETURN;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;


-- after each test
CREATE OR REPLACE FUNCTION tests.teardown_test()
RETURNS SETOF text AS
$$
BEGIN
    RETURN;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
*/

-- once after all tests
CREATE OR REPLACE FUNCTION tests.shutdown()
RETURNS SETOF text AS
$$
BEGIN
    -- clear tests safety check value
    PERFORM set_var('tests_safety_check_value', '');
    RETURN;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
