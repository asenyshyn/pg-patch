DO
LANGUAGE plpgsql $BODY$
DECLARE
    vt_patch_name CONSTANT TEXT := '1.2-add-audit';
BEGIN

    IF NOT _v.unregister_patch(vt_patch_name) THEN
       RETURN;
    END IF;

    -- rollback DDL
    DROP SCHEMA audit CASCADE;
    DROP EXTENSION hstore;

END;
$BODY$;
