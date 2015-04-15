--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.5
-- Dumped by pg_dump version 9.3.5
-- Started on 2015-04-15 11:36:00

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 173 (class 3079 OID 11750)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 1946 (class 0 OID 0)
-- Dependencies: 173
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 172 (class 1259 OID 16440)
-- Name: demo_table; Type: TABLE; Schema: public; Owner: sam; Tablespace:
--

CREATE TABLE demo_table (
    id bigint NOT NULL,
    val1 integer,
    val2 text
);


ALTER TABLE public.demo_table OWNER TO sam;

--
-- TOC entry 171 (class 1259 OID 16438)
-- Name: demo_table_id_seq; Type: SEQUENCE; Schema: public; Owner: sam
--

CREATE SEQUENCE demo_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.demo_table_id_seq OWNER TO sam;

--
-- TOC entry 1947 (class 0 OID 0)
-- Dependencies: 171
-- Name: demo_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sam
--

ALTER SEQUENCE demo_table_id_seq OWNED BY demo_table.id;


--
-- TOC entry 1826 (class 2604 OID 16443)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sam
--

ALTER TABLE ONLY demo_table ALTER COLUMN id SET DEFAULT nextval('demo_table_id_seq'::regclass);


--
-- TOC entry 1938 (class 0 OID 16440)
-- Dependencies: 172
-- Data for Name: demo_table; Type: TABLE DATA; Schema: public; Owner: sam
--

COPY demo_table (id, val1, val2) FROM stdin;
\.


--
-- TOC entry 1948 (class 0 OID 0)
-- Dependencies: 171
-- Name: demo_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sam
--

SELECT pg_catalog.setval('demo_table_id_seq', 1, false);


--
-- TOC entry 1828 (class 2606 OID 16448)
-- Name: demo_table_pkey; Type: CONSTRAINT; Schema: public; Owner: sam; Tablespace:
--

ALTER TABLE ONLY demo_table
    ADD CONSTRAINT demo_table_pkey PRIMARY KEY (id);


--
-- TOC entry 1945 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2015-04-15 11:36:00

--
-- PostgreSQL database dump complete
--
