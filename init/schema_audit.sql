--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.4
-- Dumped by pg_dump version 9.3.5
-- Started on 2014-09-23 17:52:40

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 7 (class 2615 OID 1022761)
-- Name: audit; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO postgres;

SET search_path = audit, pg_catalog;

--
-- TOC entry 204 (class 1255 OID 1022887)
-- Name: audit_func(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_old_data TEXT = NULL;
    v_new_data TEXT = NULL;
    op CHAR = 'O';
BEGIN

    IF (TG_OP = 'UPDATE') THEN
        op = 'U';
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.action (schema_name, table_name, user_name, action, old_data, new_data, query) VALUES
            (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, op, v_old_data, v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        op = 'D';
        v_old_data := ROW(OLD.*);
        INSERT INTO audit.action (schema_name, table_name, user_name, action, old_data, query) VALUES
            (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, op, v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        op = 'I';
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.action (schema_name, table_name, user_name, action, new_data,query) VALUES
            (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, 'I', v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.AUDIT_FUNC] - Other action occurred: %, at %',TG_OP, now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.AUDIT_FUNC] - UDF ERROR [DATA EXCEPTION] - 1SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        IF (op = 'D') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.AUDIT_FUNC] - UDF ERROR [UNIQUE] - 2SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        IF (op = 'D') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.AUDIT_FUNC] - UDF ERROR [OTHER] - 3SQLSTATE: %, SQLERRM: %', SQLSTATE, SQLERRM;
        IF (op = 'D') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
END;
$$;


ALTER FUNCTION audit.audit_func() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 174 (class 1259 OID 1022763)
-- Name: action; Type: TABLE; Schema: audit; Owner: postgres; Tablespace: 
--

CREATE TABLE action (
    schema_name text NOT NULL,
    table_name text NOT NULL,
    user_name text,
    ctime timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    action character(1) NOT NULL,
    old_data text,
    new_data text,
    query text,
    CONSTRAINT action_action_check CHECK ((action = ANY (ARRAY['I'::bpchar, 'D'::bpchar, 'U'::bpchar, 'T'::bpchar])))
)
WITH (fillfactor=100);


ALTER TABLE audit.action OWNER TO postgres;

--
-- TOC entry 1874 (class 1259 OID 1022833)
-- Name: action_ctime_date_idx; Type: INDEX; Schema: audit; Owner: postgres; Tablespace: 
--

CREATE INDEX action_ctime_date_idx ON action USING btree (((ctime)::date));


-- Completed on 2014-09-23 17:52:43

--
-- PostgreSQL database dump complete
--

