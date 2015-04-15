-- -----------------------------------------------------------------------------
-- core functions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_var(pt_var_name text, pt_var_value text)
RETURNS text AS
$BODY$
BEGIN
    PERFORM set_config('demodb.'||pt_var_name, pt_var_value, false);
    RETURN pt_var_value;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_var(pt_var_name text)
RETURNS text AS
$BODY$
BEGIN
    RETURN current_setting('demodb.'||pt_var_name);
EXCEPTION WHEN OTHERS THEN
    RETURN null::text;
END;
$BODY$
LANGUAGE plpgsql;
