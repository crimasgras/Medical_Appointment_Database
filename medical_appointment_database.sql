--
-- PostgreSQL database dump
--

\restrict 8F9G0N3uFdIfWxwXNqlcjwOAu4h79IWQl9QEq7YJOqa13wok18tI367kJFg0ooJ

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-03-14 18:32:36

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 24596)
-- Name: schema; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA schema;


ALTER SCHEMA schema OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 16488)
-- Name: log_appointment_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_appointment_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO appointment_audit(appointment_id, action)
    VALUES (NEW.appointment_id, 'INSERT');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_appointment_insert() OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 16470)
-- Name: schedule_appointment(integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.schedule_appointment(p_patient_id integer, p_doctor_id integer, p_time timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO appointments(patient_id, doctor_id, appointment_time)
    VALUES (p_patient_id, p_doctor_id, p_time);

    RETURN 'Appointment scheduled';

EXCEPTION
    WHEN unique_violation THEN
        RETURN 'This time slot is already booked';
END;
$$;


ALTER FUNCTION public.schedule_appointment(p_patient_id integer, p_doctor_id integer, p_time timestamp without time zone) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 231 (class 1259 OID 16477)
-- Name: appointment_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointment_audit (
    audit_id integer NOT NULL,
    appointment_id integer NOT NULL,
    action character varying(20) NOT NULL,
    action_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.appointment_audit OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16476)
-- Name: appointment_audit_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointment_audit_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointment_audit_audit_id_seq OWNER TO postgres;

--
-- TOC entry 4986 (class 0 OID 0)
-- Dependencies: 230
-- Name: appointment_audit_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointment_audit_audit_id_seq OWNED BY public.appointment_audit.audit_id;


--
-- TOC entry 228 (class 1259 OID 16445)
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    appointment_id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    appointment_time timestamp without time zone NOT NULL,
    status character varying(20) DEFAULT 'scheduled'::character varying,
    CONSTRAINT chk_status CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'cancelled'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16444)
-- Name: appointments_appointment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_appointment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_appointment_id_seq OWNER TO postgres;

--
-- TOC entry 4987 (class 0 OID 0)
-- Dependencies: 227
-- Name: appointments_appointment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_appointment_id_seq OWNED BY public.appointments.appointment_id;


--
-- TOC entry 223 (class 1259 OID 16403)
-- Name: doctors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctors (
    doctor_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150),
    phone character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.doctors OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16390)
-- Name: patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patients (
    patient_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150),
    phone character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.patients OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16471)
-- Name: doctor_schedule; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.doctor_schedule AS
 SELECT a.appointment_id,
    (((d.first_name)::text || ' '::text) || (d.last_name)::text) AS doctor,
    (((p.first_name)::text || ' '::text) || (p.last_name)::text) AS patient,
    a.appointment_time,
    a.status
   FROM ((public.appointments a
     JOIN public.doctors d ON ((a.doctor_id = d.doctor_id)))
     JOIN public.patients p ON ((a.patient_id = p.patient_id)));


ALTER VIEW public.doctor_schedule OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16426)
-- Name: doctor_specialties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctor_specialties (
    doctor_id integer NOT NULL,
    specialty_id integer NOT NULL
);


ALTER TABLE public.doctor_specialties OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16402)
-- Name: doctors_doctor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctors_doctor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doctors_doctor_id_seq OWNER TO postgres;

--
-- TOC entry 4988 (class 0 OID 0)
-- Dependencies: 222
-- Name: doctors_doctor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctors_doctor_id_seq OWNED BY public.doctors.doctor_id;


--
-- TOC entry 220 (class 1259 OID 16389)
-- Name: patients_patient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patients_patient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.patients_patient_id_seq OWNER TO postgres;

--
-- TOC entry 4989 (class 0 OID 0)
-- Dependencies: 220
-- Name: patients_patient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patients_patient_id_seq OWNED BY public.patients.patient_id;


--
-- TOC entry 225 (class 1259 OID 16416)
-- Name: specialties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specialties (
    specialty_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.specialties OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16415)
-- Name: specialties_specialty_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.specialties_specialty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.specialties_specialty_id_seq OWNER TO postgres;

--
-- TOC entry 4990 (class 0 OID 0)
-- Dependencies: 224
-- Name: specialties_specialty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.specialties_specialty_id_seq OWNED BY public.specialties.specialty_id;


--
-- TOC entry 4793 (class 2604 OID 16480)
-- Name: appointment_audit audit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointment_audit ALTER COLUMN audit_id SET DEFAULT nextval('public.appointment_audit_audit_id_seq'::regclass);


--
-- TOC entry 4791 (class 2604 OID 16448)
-- Name: appointments appointment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments ALTER COLUMN appointment_id SET DEFAULT nextval('public.appointments_appointment_id_seq'::regclass);


--
-- TOC entry 4788 (class 2604 OID 16406)
-- Name: doctors doctor_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors ALTER COLUMN doctor_id SET DEFAULT nextval('public.doctors_doctor_id_seq'::regclass);


--
-- TOC entry 4786 (class 2604 OID 16393)
-- Name: patients patient_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients ALTER COLUMN patient_id SET DEFAULT nextval('public.patients_patient_id_seq'::regclass);


--
-- TOC entry 4790 (class 2604 OID 16419)
-- Name: specialties specialty_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialties ALTER COLUMN specialty_id SET DEFAULT nextval('public.specialties_specialty_id_seq'::regclass);


--
-- TOC entry 4980 (class 0 OID 16477)
-- Dependencies: 231
-- Data for Name: appointment_audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointment_audit (audit_id, appointment_id, action, action_time) FROM stdin;
1	5	INSERT	2026-03-04 22:31:17.055855
\.


--
-- TOC entry 4978 (class 0 OID 16445)
-- Dependencies: 228
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (appointment_id, patient_id, doctor_id, appointment_time, status) FROM stdin;
1	1	1	2026-03-05 10:00:00	scheduled
3	1	1	2026-03-06 10:00:00	scheduled
5	1	1	2026-03-06 12:00:00	scheduled
\.


--
-- TOC entry 4976 (class 0 OID 16426)
-- Dependencies: 226
-- Data for Name: doctor_specialties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctor_specialties (doctor_id, specialty_id) FROM stdin;
\.


--
-- TOC entry 4973 (class 0 OID 16403)
-- Dependencies: 223
-- Data for Name: doctors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctors (doctor_id, first_name, last_name, email, phone, created_at) FROM stdin;
1	Ioan	Marin	doc@test.com	\N	2026-03-04 21:54:59.524425
\.


--
-- TOC entry 4971 (class 0 OID 16390)
-- Dependencies: 221
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (patient_id, first_name, last_name, email, phone, created_at) FROM stdin;
1	Ana	Pop	ana@test.com	\N	2026-03-04 21:54:53.94249
2	Mihai	Ionescu	mihai@test.com	\N	2026-03-04 21:54:53.94249
\.


--
-- TOC entry 4975 (class 0 OID 16416)
-- Dependencies: 225
-- Data for Name: specialties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialties (specialty_id, name) FROM stdin;
\.


--
-- TOC entry 4991 (class 0 OID 0)
-- Dependencies: 230
-- Name: appointment_audit_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointment_audit_audit_id_seq', 1, true);


--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 227
-- Name: appointments_appointment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_appointment_id_seq', 5, true);


--
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 222
-- Name: doctors_doctor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctors_doctor_id_seq', 1, true);


--
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 220
-- Name: patients_patient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patients_patient_id_seq', 2, true);


--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 224
-- Name: specialties_specialty_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.specialties_specialty_id_seq', 1, false);


--
-- TOC entry 4816 (class 2606 OID 16487)
-- Name: appointment_audit appointment_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointment_audit
    ADD CONSTRAINT appointment_audit_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 4811 (class 2606 OID 16455)
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (appointment_id);


--
-- TOC entry 4809 (class 2606 OID 16432)
-- Name: doctor_specialties doctor_specialties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_specialties
    ADD CONSTRAINT doctor_specialties_pkey PRIMARY KEY (doctor_id, specialty_id);


--
-- TOC entry 4801 (class 2606 OID 16414)
-- Name: doctors doctors_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_email_key UNIQUE (email);


--
-- TOC entry 4803 (class 2606 OID 16412)
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (doctor_id);


--
-- TOC entry 4797 (class 2606 OID 16401)
-- Name: patients patients_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_email_key UNIQUE (email);


--
-- TOC entry 4799 (class 2606 OID 16399)
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (patient_id);


--
-- TOC entry 4805 (class 2606 OID 16425)
-- Name: specialties specialties_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialties
    ADD CONSTRAINT specialties_name_key UNIQUE (name);


--
-- TOC entry 4807 (class 2606 OID 16423)
-- Name: specialties specialties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialties
    ADD CONSTRAINT specialties_pkey PRIMARY KEY (specialty_id);


--
-- TOC entry 4814 (class 2606 OID 16467)
-- Name: appointments uq_doctor_time; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT uq_doctor_time UNIQUE (doctor_id, appointment_time);


--
-- TOC entry 4812 (class 1259 OID 16468)
-- Name: idx_appointments_doctor_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_doctor_time ON public.appointments USING btree (doctor_id, appointment_time);


--
-- TOC entry 4821 (class 2620 OID 16489)
-- Name: appointments trg_log_appointment_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_appointment_insert AFTER INSERT ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.log_appointment_insert();


--
-- TOC entry 4819 (class 2606 OID 16461)
-- Name: appointments appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id);


--
-- TOC entry 4820 (class 2606 OID 16456)
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id);


--
-- TOC entry 4817 (class 2606 OID 16433)
-- Name: doctor_specialties doctor_specialties_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_specialties
    ADD CONSTRAINT doctor_specialties_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id);


--
-- TOC entry 4818 (class 2606 OID 16438)
-- Name: doctor_specialties doctor_specialties_specialty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_specialties
    ADD CONSTRAINT doctor_specialties_specialty_id_fkey FOREIGN KEY (specialty_id) REFERENCES public.specialties(specialty_id);


-- Completed on 2026-03-14 18:32:36

--
-- PostgreSQL database dump complete
--

\unrestrict 8F9G0N3uFdIfWxwXNqlcjwOAu4h79IWQl9QEq7YJOqa13wok18tI367kJFg0ooJ

