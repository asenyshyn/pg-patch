-- psql -Xq -h 127.0.0.1 -p 5432 -d demodb -U demodb_owner -f tools/sql/db_check.sql  -v appname='demodb'
-- check database precoditions
set pgpatch_vars.appname = :"appname";
set pgpatch_vars.db_check_result = '';


DO language plpgsql $$
DECLARE
    va_schemas text[];
BEGIN
    -- am I db owner?
    IF session_user <> (SELECT pg_catalog.pg_get_userbyid(datdba)
                          FROM pg_catalog.pg_database
                         WHERE datname = current_database())
    THEN
        RAISE EXCEPTION '%', 'User '||session_user||' is not owner of database '||current_database();
    END IF;

    -- any versioning please?
    IF EXISTS (SELECT 1
                 FROM pg_catalog.pg_namespace n
                WHERE n.nspname !~ '^pg_'
                  AND n.nspname <> 'information_schema'
                  AND n.nspname = '_v')
    THEN
        BEGIN
            -- what's your name?
            IF ( SELECT name FROM _v.application_name ) <> current_setting('pgpatch_vars.appname') THEN
                RAISE EXCEPTION '%',
                      format('Database contains application different than %L',
                             current_setting('pgpatch_vars.appname')
                      );
            ELSE
                -- patch
                PERFORM set_config('pgpatch_vars.db_check_result', 'P', false);
            END IF;
        EXCEPTION WHEN undefined_table THEN
            RAISE EXCEPTION '%', 'Table _v.application_name does not exist. ';
        END;
    ELSE
        -- No versioning? any schemas?

        SELECT array_agg(n.nspname::text)
          INTO va_schemas
          FROM pg_catalog.pg_namespace n
         WHERE n.nspname !~ '^pg_'
           AND n.nspname <> 'information_schema';

        IF array_length(va_schemas, 1) = 1 AND va_schemas[1] = 'public' THEN
            -- only public? any tables?
            IF EXISTS ( SELECT 1
                          FROM pg_catalog.pg_class c
                          JOIN pg_catalog.pg_namespace n
                            ON c.relnamespace = n.oid
                           AND n.nspname = 'public'
                           AND c.relkind IN ('r', 'v', 'f', 'S')
                         WHERE NOT EXISTS (SELECT 1 FROM pg_depend d WHERE c.oid = d.objid AND d.deptype = 'e'))
            THEN
                RAISE EXCEPTION '%', format('Database %L is not empty',current_database());
            ELSE
                -- install versioning
                PERFORM set_config('pgpatch_vars.db_check_result', 'I', false);
                NULL;
            END IF;
        ELSIF array_length(va_schemas, 1) >= 1 THEN
            RAISE EXCEPTION '%', format('Database %L is not empty',current_database());
        END IF;
    END IF;

END;
$$;

select current_setting('pgpatch_vars.db_check_result');
