/*
 * Do not change this code except lines containing patch name, author name
 * and lines between ## patch functionality start, functionality end.
 * DO NOT CHANGE names of variables, because there are scripts that use them.
 */

DO
LANGUAGE plpgsql $BODY$
DECLARE

    /*
     * CHANGE PATCH NAME AND AUTHOR
     */
     -- patch name should be the same as file name
    vt_patch_name CONSTANT TEXT   := '1.2-add-audit';
    vt_author     CONSTANT TEXT   := 'Author Name (author@email.net)';  -- Patch author

    -- ! PUT REQUIRED PATCHES HERE
    va_depend_on           TEXT[] := ARRAY['1.1-add-table-demo-table2']::TEXT[];
    -- ! PUT CONFLICTING PATCHES HERE
    --va_conflict_with       TEXT[] -- reserved for future

BEGIN

    -- try to register patch, skip if already applied
    IF NOT _v.register_patch(vt_patch_name, vt_author, va_depend_on) THEN
        RETURN;
    END IF;

    -- ## patch fuctionality start here  ##
    CREATE EXTENSION hstore;
    CREATE SCHEMA audit;
    CREATE TABLE audit.logged_actions (
        event_id bigserial primary key,
        schema_name text not null,
        table_name text not null,
        relid oid not null,
        session_user_name text,
        action_tstamp_tx TIMESTAMP WITH TIME ZONE NOT NULL,
        action_tstamp_stm TIMESTAMP WITH TIME ZONE NOT NULL,
        action_tstamp_clk TIMESTAMP WITH TIME ZONE NOT NULL,
        transaction_id bigint,
        application_name text,
        client_addr inet,
        client_port integer,
        client_query text,
        action TEXT NOT NULL CHECK (action IN ('I','D','U', 'T')),
        row_data hstore,
        changed_fields hstore,
        statement_only boolean not null
    );

    CREATE INDEX logged_actions_relid_idx ON audit.logged_actions(relid);
    CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON audit.logged_actions(action_tstamp_stm);
    CREATE INDEX logged_actions_action_idx ON audit.logged_actions(action);

    -- ## patch functionality ends here  ##

END;
$BODY$;
