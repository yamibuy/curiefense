CREATE DATABASE curiefense;
\c curiefense
create extension hstore;

create table logs (
    -- ROW ID??
    rowid       bigserial   NOT NULL,
    RequestId   TEXT        NOT NULL,
    Timestamp   TIMESTAMPTZ NOT NULL,
    Scheme      TEXT        NOT NULL,
    Authority   TEXT        NOT NULL,
    Method      TEXT        NOT NULL,
    Path        TEXT        NOT NULL,
    RXTimers    JSONB       NOT NULL,
    TXTimers    JSONB       NOT NULL,
    Upstream    JSONB       NOT NULL,
    Downstream  JSONB       NOT NULL,
    TLS         JSONB       NOT NULL,
    Request     JSONB       NOT NULL,
    Response    JSONB       NOT NULL,
    Metadata    JSONB       NOT NULL
);

GRANT CONNECT ON DATABASE curiefense TO logserver_ro;
GRANT USAGE ON SCHEMA public TO logserver_ro;
GRANT SELECT ON TABLE "public"."logs" to logserver_ro;
