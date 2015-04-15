DO
LANGUAGE plpgsql $BODY$
DECLARE
    vt_patch_name CONSTANT TEXT := '1.1-add-table-demo-table2';
BEGIN

    IF NOT _v.unregister_patch(vt_patch_name) THEN
       RETURN;
    END IF;

    -- rollback DDL
    DROP TABLE public.demo_table2;

END;
$BODY$;
