-- -----------------------------------------------------------------------------
-- set search path, drop recreatable objects
-- -----------------------------------------------------------------------------

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;


SET search_path = public;


CREATE OR REPLACE FUNCTION public.tmp_drop_recreatable_objects()
RETURNS INTEGER AS $BODY$
DECLARE
  vt_schema  TEXT[] NOT NULL DEFAULT array['public','audit'];
  vt_curstmt TEXT;
  vi_count INTEGER NOT NULL DEFAULT 0;
  BEGIN
  -- drop rules
  FOR vt_curstmt IN
        SELECT 'DROP RULE IF EXISTS '|| quote_ident(r.rulename) ||
               ' ON '|| quote_ident(n.nspname)||'.'||quote_ident(c.relname)||';' as tbl
        FROM pg_catalog.pg_rewrite r, pg_class c, pg_namespace n
        WHERE r.ev_class = c.oid
            and c.relnamespace = n.oid
            AND r.rulename != '_RETURN'
            AND n.nspname IN (SELECT quote_ident(unnest(vt_schema)))
  LOOP
      RAISE NOTICE 'about to drop rule: %', vt_curstmt;
      EXECUTE vt_curstmt;
      vi_count := vi_count+1;  -- increment number of executed statements
  END LOOP;

  -- drop views
  FOR vt_curstmt IN
        SELECT 'DROP VIEW IF EXISTS '||quote_ident(ns.nspname)||'.'||quote_ident(c.relname)||' CASCADE;'
          FROM pg_class c
               INNER JOIN pg_namespace ns ON c.relnamespace = ns.oid
         WHERE c.relkind = 'v'  -- views
           AND ns.nspname IN (SELECT quote_ident(unnest(vt_schema)))
           AND c.relname <> 'pg_stat_statements'
  LOOP
      RAISE NOTICE 'about to drop view: %', vt_curstmt;
      EXECUTE vt_curstmt;
      vi_count := vi_count+1;  -- increment number of executed statements
  END LOOP;

  -- drop types
  FOR vt_curstmt IN
        SELECT 'DROP TYPE IF EXISTS '||quote_ident(nspname)||'.'||quote_ident(typname)||' CASCADE;'
          FROM (
                SELECT DISTINCT t.typname, ns.nspname
                  FROM pg_proc p
                       INNER JOIN pg_type t ON p.prorettype = t.oid
                       INNER JOIN pg_namespace ns ON p.pronamespace = ns.oid
                 WHERE ns.nspname IN (SELECT quote_ident(unnest(vt_schema)))
                   AND t.typtype IN ('c','e','d')  -- only composite, enum, domain types used by functions
               ) disttyp
  LOOP
      RAISE NOTICE 'about to drop type: %', vt_curstmt;
      EXECUTE vt_curstmt;
      vi_count := vi_count+1;  -- increment number of executed statements
  END LOOP;

  -- drop functions
  FOR vt_curstmt IN
        SELECT CASE WHEN p.proisagg IS FALSE THEN 'DROP FUNCTION IF EXISTS '
               ELSE 'DROP AGGREGATE IF EXISTS ' END
               || ' '||quote_ident(ns.nspname)||'.'||quote_ident(p.proname)
               ||'('||COALESCE(pg_get_function_identity_arguments(p.oid),'')||') CASCADE;' AS drp_text
          FROM pg_proc p
               INNER JOIN pg_namespace ns ON p.pronamespace = ns.oid
               INNER JOIN pg_type t ON p.prorettype = t.oid
               inner join pg_language pl on p.prolang = pl.oid
         WHERE ns.nspname IN (SELECT quote_ident(unnest(vt_schema)))
           AND t.typname <> 'trigger' -- not trigger functions
           and pl.lanname NOT IN ('c','internal')
           and ns.nspname NOT LIKE 'pg_%'
           and ns.nspname <> 'information_schema'
           and p.proname NOT IN ('my_id','my_account_id','my_default_storage_id')
         ORDER BY p.proisagg DESC, ns.nspname  -- aggregates first !
  LOOP
      RAISE NOTICE 'about to drop function: %', vt_curstmt;
      EXECUTE vt_curstmt;
      vi_count := vi_count+1;  -- increment number of executed statements
  END LOOP;

  -- drop trigger functions with cascade
  FOR vt_curstmt IN
        SELECT 'DROP FUNCTION IF EXISTS '|| ' '||quote_ident(ns.nspname)||'.'||quote_ident(p.proname)
               ||'('||COALESCE(pg_get_function_identity_arguments(p.oid),'')||') CASCADE;' AS drp_text
          FROM pg_proc p
               INNER JOIN pg_namespace ns ON p.pronamespace = ns.oid
               INNER JOIN pg_type t ON p.prorettype = t.oid
         WHERE ns.nspname IN (SELECT quote_ident(unnest(vt_schema)))
           AND t.typname = 'trigger' -- only trigger functions
  LOOP
      RAISE NOTICE 'about to drop trigger function: %', vt_curstmt;
      EXECUTE vt_curstmt;
      vi_count := vi_count+1;  -- increment number of executed statements
  END LOOP;

  RETURN vi_count;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;


-- function will also delete itself
SELECT public.tmp_drop_recreatable_objects();
