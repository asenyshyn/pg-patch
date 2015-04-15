-- default users/roles
CREATE ROLE anonymous LOGIN
    NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE anonymous
  SET search_path = public, pg_catalog;
