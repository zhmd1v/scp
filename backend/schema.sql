
-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11 (Debian 16.11-1.pgdg13+1)

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
-- Name: auth_group; Type: TABLE; Schema: public; Owner: scp_user
--
--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--

--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: scp_user
--


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--



--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: scp_user
--

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--

--
-- Name: authtoken_token; Type: TABLE; Schema: public; Owner: scp_user
--

--
-- Name: catalog_products; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.catalog_products (
    id bigint NOT NULL,
    display_order integer NOT NULL,
    is_featured boolean NOT NULL,
    added_at timestamp with time zone NOT NULL,
    catalog_id bigint NOT NULL,
    product_id bigint NOT NULL
);



--
-- Name: catalog_products_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--

--
-- Name: catalogs; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.catalogs (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    supplier_id bigint NOT NULL
);




--
-- Name: catalogs_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--



--
-- Name: categories; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    parent_id bigint
);



--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--

--
-- Name: chat_conversation; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.chat_conversation (
    id bigint NOT NULL,
    conversation_type character varying(32) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    consumer_id bigint,
    created_by_id bigint,
    order_id bigint,
    supplier_id bigint NOT NULL,
    assigned_staff_id bigint
);




--
-- Name: chat_conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--



--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.chat_message (
    id bigint NOT NULL,
    text text NOT NULL,
    attachment character varying(100),
    sent_at timestamp with time zone NOT NULL,
    is_read boolean NOT NULL,
    conversation_id bigint NOT NULL,
    sender_id bigint NOT NULL
);



--
-- Name: chat_message_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--



--
-- Name: complaints_complaint; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.complaints_complaint (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    complaint_type character varying(20) NOT NULL,
    status character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    consumer_id bigint NOT NULL,
    order_id bigint,
    supplier_id bigint NOT NULL,
    escalation_level character varying(20) NOT NULL,
    escalation_reason text,
    escalated_by_id bigint,
    escalated_at timestamp with time zone
);




--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--




--
-- Name: complaints_complaintescalation; Type: TABLE; Schema: public; Owner: scp_user
--



--
-- Name: complaints_complaintescalation_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--



--
-- Name: complaints_complaintresponse; Type: TABLE; Schema: public; Owner: scp_user
--

--
-- Name: complaints_complaintresponse_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--




--
-- Name: consumer_profiles; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.consumer_profiles (
    id bigint NOT NULL,
    business_name character varying(255) NOT NULL,
    business_type character varying(20) NOT NULL,
    address text NOT NULL,
    city character varying(100) NOT NULL,
    registration_number character varying(100),
    user_id bigint NOT NULL
);


-- Name: consumer_supplier_links; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.consumer_supplier_links (
    id bigint NOT NULL,
    status character varying(20) NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    approved_at timestamp with time zone,
    notes text,
    approved_by_id bigint,
    consumer_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    assigned_sales_rep_id bigint
);

CREATE TABLE public.orders_order (
    id bigint NOT NULL,
    status character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    requested_delivery_date date,
    delivery_address text NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    notes text NOT NULL,
    consumer_id bigint NOT NULL,
    delivery_option_id bigint,
    supplier_id bigint NOT NULL
);



--
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: scp_user
--


--
-- Name: orders_orderitem; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.orders_orderitem (
    id bigint NOT NULL,
    quantity numeric(10,2) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    remark character varying(255) NOT NULL,
    order_id bigint NOT NULL,
    product_id bigint NOT NULL
);




--
-- Name: orders_orderstatushistory; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.orders_orderstatushistory (
    id bigint NOT NULL,
    old_status character varying(20) NOT NULL,
    new_status character varying(20) NOT NULL,
    changed_at timestamp with time zone NOT NULL,
    comment text NOT NULL,
    changed_by_id bigint,
    order_id bigint NOT NULL
);


--
-- Name: product_discounts; Type: TABLE; Schema: public; Owner: scp_user
--




--
-- Name: product_images; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.product_images (
    id bigint NOT NULL,
    image character varying(100) NOT NULL,
    uploaded_at timestamp with time zone NOT NULL,
    product_id bigint NOT NULL
);

--
-- Name: products; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    sku character varying(100),
    unit character varying(10) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    stock_quantity numeric(10,2) NOT NULL,
    minimum_order_quantity numeric(10,2) NOT NULL,
    is_available boolean NOT NULL,
    image character varying(100),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    category_id bigint,
    supplier_id bigint NOT NULL
);




--
-- Name: supplier_profiles; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.supplier_profiles (
    id bigint NOT NULL,
    company_name character varying(255) NOT NULL,
    registration_number character varying(100) NOT NULL,
    address text NOT NULL,
    city character varying(100) NOT NULL,
    description text,
    logo character varying(100),
    is_verified boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);



--
-- Name: supplier_staff; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.supplier_staff (
    id bigint NOT NULL,
    "position" character varying(100),
    supplier_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: scp_user
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL,
    user_type character varying(20) NOT NULL,
    phone character varying(20),
    is_verified boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

