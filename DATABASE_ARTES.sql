CREATE EXTENSION IF NOT EXISTS dblink;


CREATE OR REPLACE FUNCTION send_to_presta(
    p_cod_e BIGINT,
    p_isbn BIGINT,
    p_num_ej INTEGER,
    p_fech_p DATE,
    p_fech_d DATE
)
RETURNS VOID AS $$
DECLARE
    conn_str TEXT;
BEGIN
    -- Connection string to the remote database
    conn_str := 'dbname=database_Ingenieria host=fac-ingenieriaa.c7u24qsquqpy.us-east-2.rds.amazonaws.com port=5432 user=postgres password=postgres';

    -- Perform the insert using dblink
    PERFORM dblink(
        conn_str,
        format(
            'INSERT INTO presta (cod_es, isbn, num_ej, fech_p, fech_d) VALUES (%L, %L, %L, %L, %L)',
            p_cod_e, p_isbn, p_num_ej, p_fech_p, p_fech_d
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error inserting into remote PRESTA table: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


SELECT send_to_presta(20191004201, 100100100, 1, '2001-11-01', '2002-01-01');

