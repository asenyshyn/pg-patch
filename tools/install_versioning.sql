BEGIN;

-- This file adds versioning support to database it will be loaded to.
-- It requires that PL/pgSQL is already loaded - will raise exception otherwise.
-- All versioning "stuff" (tables, functions) is in "_v" schema.

-- All functions are defined as 'RETURNS SETOF INT4' to be able to make them to RETURN literaly nothing (0 rows).
-- >> RETURNS VOID<< IS similar, but it still outputs "empty line" in psql when calling.

CREATE SCHEMA _v;
COMMENT ON SCHEMA _v IS 'Schema for versioning data and functionality.';

CREATE TABLE _v.patch_history (
patch_date timestamp NOT NULL DEFAULT now(),
revision   text,
branch     text,
PRIMARY KEY (patch_date, revision)
);
COMMENT ON TABLE _v.patch_history             IS 'Contains history of dates and revisions of applied pathces';
COMMENT ON COLUMN _v.patch_history.patch_date IS 'Date when pach was applied.';
COMMENT ON COLUMN _v.patch_history.revision   IS 'patch revision';
COMMENT ON COLUMN _v.patch_history.branch     IS 'branch name';

CREATE TABLE _v.patches (
    patch_name  TEXT        PRIMARY KEY,
    applied_ts  TIMESTAMP   NOT NULL DEFAULT now(),
    author      TEXT        NOT NULL,
    applied_by  TEXT        NOT NULL,
    applied_from INET       NOT NULL,
    requires    TEXT[],
    conflicts   TEXT[]
);
COMMENT ON TABLE _v.patches              IS 'Contains information about what patches are currently applied on database.';
COMMENT ON COLUMN _v.patches.patch_name  IS 'Name of patch, has to be unique for every patch.';
COMMENT ON COLUMN _v.patches.applied_ts  IS 'When the patch was applied.';
COMMENT ON COLUMN _v.patches.applied_by  IS 'Who applied this patch (PostgreSQL username)';
COMMENT ON COLUMN _v.patches.requires    IS 'List of patches that are required for given patch.';
COMMENT ON COLUMN _v.patches.conflicts   IS 'List of patches that conflict with given patch.';

CREATE OR REPLACE FUNCTION _v.register_patch( IN in_patch_name TEXT, IN in_author TEXT, IN in_requirements TEXT[], in_conflicts TEXT[]) RETURNS boolean AS $$
DECLARE
    t_text   TEXT;
    t_text_a TEXT[];
    i INT4;
BEGIN
    -- locking patches table is moved to executing script.
    -- Thanks to this we know only one patch will be applied at a time
    -- LOCK TABLE _v.patches IN EXCLUSIVE MODE;

    RAISE WARNING 'CHECKING PATCH %...', in_patch_name;

    IF in_patch_name IS NULL OR TRIM(in_patch_name) = '' THEN
        RAISE EXCEPTION 'Cannot register patch. Name is null or empty.';
    END IF;

    IF in_author IS NULL OR TRIM(in_author) = '' THEN
        RAISE EXCEPTION 'Cannot register patch. Author is not specified.';
    END IF;

    SELECT patch_name INTO t_text FROM _v.patches WHERE patch_name = in_patch_name;
    IF FOUND THEN
        RAISE WARNING 'Patch % is already applied!', in_patch_name;
        RETURN FALSE;
    END IF;

    t_text_a := ARRAY( SELECT patch_name FROM _v.patches WHERE patch_name = any( in_conflicts ) );
    IF array_upper( t_text_a, 1 ) IS NOT NULL THEN
        RAISE EXCEPTION 'Versioning patches conflict. Conflicting patche(s) installed: %.', array_to_string( t_text_a, ', ' );
    END IF;

    IF array_upper( in_requirements, 1 ) IS NOT NULL THEN
        t_text_a := '{}';
        FOR i IN array_lower( in_requirements, 1 ) .. array_upper( in_requirements, 1 ) LOOP
            SELECT patch_name INTO t_text FROM _v.patches WHERE patch_name = in_requirements[i];
            IF NOT FOUND THEN
                t_text_a := t_text_a || in_requirements[i];
            END IF;
        END LOOP;
        IF array_upper( t_text_a, 1 ) IS NOT NULL THEN
            RAISE EXCEPTION 'Missing prerequisite(s): %.', array_to_string( t_text_a, ', ' );
        END IF;
    END IF;

    INSERT INTO _v.patches (patch_name, applied_ts, author, applied_by, applied_from, requires, conflicts )
           VALUES ( in_patch_name, now(), in_author, current_user, inet_client_addr(), coalesce( in_requirements, '{}' ), coalesce( in_conflicts, '{}' ) );
    RETURN TRUE;
END;
$$ language plpgsql;
COMMENT ON FUNCTION _v.register_patch( TEXT, TEXT, TEXT[], TEXT[] ) IS 'Function to register patches in database. Raises exception if there are conflicts, prerequisites are not installed or the migration has already been installed.';

-- without conflicts
CREATE OR REPLACE FUNCTION _v.register_patch( TEXT, TEXT, TEXT[] ) RETURNS boolean AS $$
    SELECT _v.register_patch( $1, $2, $3, NULL );
$$ language sql;
COMMENT ON FUNCTION _v.register_patch( TEXT, TEXT, TEXT[] ) IS 'Wrapper to allow registration of patches without conflicts.';

-- without required patches and confilcts
CREATE OR REPLACE FUNCTION _v.register_patch( TEXT, TEXT ) RETURNS boolean AS $$
    SELECT _v.register_patch( $1, $2, NULL, NULL );
$$ language sql;
COMMENT ON FUNCTION _v.register_patch( TEXT, TEXT ) IS 'Wrapper to allow registration of patches without requirements and conflicts.';

-- remove patch
CREATE OR REPLACE FUNCTION _v.unregister_patch( IN in_patch_name TEXT ) RETURNS boolean AS $$
DECLARE
    i        INT4;
    t_text_a TEXT[];
BEGIN
    -- Thanks to this we know only one patch will be applied at a time
    LOCK TABLE _v.patches IN EXCLUSIVE MODE;

    t_text_a := ARRAY( SELECT patch_name FROM _v.patches WHERE in_patch_name = ANY( requires ) );
    IF array_upper( t_text_a, 1 ) IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot uninstall %, as it is required by: %.', in_patch_name, array_to_string( t_text_a, ', ' );
    END IF;

    DELETE FROM _v.patches WHERE patch_name = in_patch_name;
    GET DIAGNOSTICS i = ROW_COUNT;
    IF i < 1 THEN
        RAISE EXCEPTION 'Patch % is not installed, so it can''t be uninstalled!', in_patch_name;
    END IF;

    RETURN true;
END;
$$ language plpgsql;
COMMENT ON FUNCTION _v.unregister_patch( TEXT ) IS 'Function to unregister patches in database. Dies if the patch is not registered, or if unregistering it would break dependencies.';

COMMIT;
