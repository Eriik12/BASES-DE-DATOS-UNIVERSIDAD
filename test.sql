CREATE OR REPLACE FUNCTION validate_estudiante() RETURNS TRIGGER AS $$
BEGIN    
    -- Verificar existencia del estudiante en la facultad de Ingeniería (local)
    PERFORM ei.cod_e FROM estudiantes_ingenieria ei WHERE ei.cod_e = NEW.cod_e;
    IF FOUND THEN
        RETURN NEW;
    END IF;

    -- Verificar existencia del estudiante en la facultad de Artes (remoto)
    PERFORM cod_e FROM dblink(
        'dbname=database_Artes host=fac-artes.c7u24qsquqpy.us-east-2.rds.amazonaws.com port=5432 user=postgres password=postgres',
        format('SELECT cod_e FROM Estudiantes_Artes ea WHERE ea.cod_e = %L', NEW.cod_e)
    ) AS t2(cod_e BIGINT);
    IF FOUND THEN
        RETURN NEW;
    END IF;

    -- Si el estudiante no se encuentra en ninguna facultad, lanzar una excepción
    RAISE EXCEPTION 'El estudiante con cod_e % no existe en ninguna facultad', NEW.cod_e;
    
    RETURN NULL; -- Esto es redundante ya que el trigger está configurado como BEFORE y no AFTER
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_estudiante
BEFORE INSERT OR UPDATE ON public.presta
FOR EACH ROW EXECUTE FUNCTION validate_estudiante();

INSERT INTO PRESTA (cod_es, isbn, num_ej, fech_p, fech_d)
VALUES (20191004101, 100100100,1,'1/1/2001','1/1/20001');
