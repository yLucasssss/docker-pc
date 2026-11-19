--
-- PostgreSQL database dump
--

\restrict g1woTjqFZYVj5fY8dA59bqvkwKULJRbFk2cTqEMKRcmVV7Vy6HBTlxVrx4BYdkB

-- Dumped from database version 16.16
-- Dumped by pg_dump version 16.16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alunos; Type: TABLE; Schema: public; Owner: unifeg
--

CREATE TABLE public.alunos (
    id integer NOT NULL,
    nome character varying(120) NOT NULL,
    ra character varying(20) NOT NULL,
    periodo smallint DEFAULT 1 NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.alunos OWNER TO unifeg;

--
-- Name: alunos_id_seq; Type: SEQUENCE; Schema: public; Owner: unifeg
--

CREATE SEQUENCE public.alunos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alunos_id_seq OWNER TO unifeg;

--
-- Name: alunos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unifeg
--

ALTER SEQUENCE public.alunos_id_seq OWNED BY public.alunos.id;


--
-- Name: alunos id; Type: DEFAULT; Schema: public; Owner: unifeg
--

ALTER TABLE ONLY public.alunos ALTER COLUMN id SET DEFAULT nextval('public.alunos_id_seq'::regclass);


--
-- Data for Name: alunos; Type: TABLE DATA; Schema: public; Owner: unifeg
--

COPY public.alunos (id, nome, ra, periodo, criado_em) FROM stdin;
1	Ana Souza	2021001	8	2026-11-19 00:05:14.620516
2	Bruno Lima	2021002	8	2026-11-19 00:05:14.620516
3	Carla Prado	2021003	8	2026-11-19 00:05:14.620516
\.


--
-- Name: alunos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unifeg
--

SELECT pg_catalog.setval('public.alunos_id_seq', 3, true);


--
-- Name: alunos alunos_pkey; Type: CONSTRAINT; Schema: public; Owner: unifeg
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT alunos_pkey PRIMARY KEY (id);


--
-- Name: alunos alunos_ra_key; Type: CONSTRAINT; Schema: public; Owner: unifeg
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT alunos_ra_key UNIQUE (ra);


--
-- PostgreSQL database dump complete
--

\unrestrict g1woTjqFZYVj5fY8dA59bqvkwKULJRbFk2cTqEMKRcmVV7Vy6HBTlxVrx4BYdkB
