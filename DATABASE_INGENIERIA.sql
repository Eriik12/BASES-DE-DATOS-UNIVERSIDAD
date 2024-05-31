---------------------------------------------------------------------------------------------------------------
-- PARA LA CREACION DE LAS TABLAS SEGUIMOS EL RESPECTIVO ORDEN Y RESPETANDO LAS REFERENCIAS PARA SU CREACION: 
---------------------------------------------------------------------------------------------------------------
create table asignaturas (
	cod_a integer primary key check (cod_a > 0),
	nom_a varchar(50) not null,
	int_h integer check (int_h > 0) not null,
	creditos_a integer check (creditos_a > 0) not null,
    cod_carr integer REFERENCES carreras (cod_carr)
);
-----------------------------------------------------------------------------
create table profesores (
	id_p integer primary key check (id_p > 0),
	nom_p varchar(70) not null,
	profesion varchar(50) not null
);
-----------------------------------------------------------------------------
create table libros (
	isbn integer primary key check (isbn > 0),
	titulo varchar(50) not null,
	edic integer check (edic > 0) not null,
	edit varchar(50) not null
);
-----------------------------------------------------------------------------
create table autores (
	id_a integer primary key check (id_a > 0),
	nom_autor varchar(70) not null,
	nacionalidad varchar(50) not null -- se entiende como país de nacimiento
);
-----------------------------------------------------------------------------
create table carreras (
	id_carr integer primary key check (id_carr > 0),
	nom_carr varchar(50) not null,
	reg_calif boolean not null,
	creditos_c integer check (creditos_c > 0) not null,
	id_p integer references profesores (id_p)
);
-----------------------------------------------------------------------------
create table {ESQUEMA}.estudiantes (
	cod_e bigint primary key check (cod_e > 0),
	nom_e varchar(70) not null,
	dir_e varchar(50) not null,
	tel_e bigint check (tel_e > 0),
	fech_nac date not null,
	id_carr integer references carreras (id_carr)
);
-----------------------------------------------------------------------------
create table escribe (
	isbn integer,
	id_a integer,
	foreign key (isbn) references libros (isbn),
	foreign key (id_a) references autores (id_a),
	primary key (isbn, id_a)
);
-----------------------------------------------------------------------------
create table ejemplares (
	num_ej integer check (num_ej > 0),
	isbn integer,
	foreign key (isbn) references libros (isbn),
	primary key (num_ej, isbn)	
);
-----------------------------------------------------------------------------
create table imparte (
	id_p integer,
	cod_a integer,
	grupo integer check (grupo > 0),
	horario varchar(50) not null,
	foreign key (id_p) references profesores (id_p),
	foreign key (cod_a) references asignaturas (cod_a),
	primary key (id_p, cod_a, grupo)
);
-----------------------------------------------------------------------------
create table {ESQUEMA}.inscribe (
	cod_e bigint references {ESQUEMA}.estudiantes (cod_e),
	cod_a integer,
	id_p integer,
	grupo integer,
	n1 numeric(2,1) check (n1 >= 0.0 and n1 <= 5.0),
	n2 numeric(2,1) check (n2 >= 0.0 and n2 <= 5.0),
	n3 numeric(2,1) check (n3 >= 0.0 and n3 <= 5.0),
	foreign key (id_p, cod_a, grupo) references imparte (id_p, cod_a, grupo),
	primary key (cod_e, cod_a, id_p, grupo)	
);
-----------------------------------------------------------------------------
create table presta (
	cod_es bigint,
	isbn integer,
	num_ej integer,
	fech_p date,
	fech_d date,
	foreign key (isbn, num_ej) references ejemplares (isbn, num_ej),
	primary key (cod_e, isbn, num_ej, fech_p)
);
-----------------------------------------------------------------------------
create table referencia (
	cod_a integer references asignaturas (cod_a),
	isbn integer references libros (isbn),
	primary key (cod_a, isbn)
);
---------------------------------------------------------------------------------------------------------------
-- PROCEDEMOS A LLENAR LA INFORMACION DE LAS TABLAS, PERO COMO LAS BASE DE DATOS ESTA CREADA EN AWS
-- NO ES POSIBLE CREAR MEDIANTE EL COMANDO COPY DESDE PgAdmin, por lo que se usa psql mediante CMD DONDE
-- SE SIGUE EL SIGUIENTE FORMATO:

-- psql -U postgres -d {database_{FACULTAD}} -h {HOST_NAME / ADDRESS } -p {PUERTO: DEFAULT 5432}
-- -c "\copy {NOMBRE_TABLA} ({COLUMNAS_TABLA}) FROM '{RUTA}' DELIMITER ',' CSV HEADER NULL '';"

-- COMO EJEMPLO TENEMOS:

-- psql -U postgres -d database_Ingenieria -h fac-ingenieriaa.c7u24qsquqpy.us-east-2.rds.amazonaws.com -p 5432 
-- -c "\copy ingenieria_electronica.estudiantes (cod_e, nom_e, dir_e, tel_e, fech_nac, id_carr)  
-- FROM 'C:\INGENIERIA\EstudiantesElectonica.csv' DELIMITER ',' CSV HEADER NULL '';"
---------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
-- VISTAS PREDEFINIDAS:
-- SE CREAN VISTAS PREDEFINIDAS TALES COMO estudiantes_ingenieria y inscribe_estudiantes PARA VISUALIZAR LOS
-- ESTUDIANTES DE TODAS LAS CARRERAS DEBIDO A QUE ESTAN EN DIFERENTES ESQUEMAS.
---------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
-- FUNCIONES PREDEFINIDAS:
-- SE CREA UNA FUNCION PREDEFINADA PARA LA TABLA PRESTA, DEBIDO A QUE ESTA DEBE VALIDAR LA INFORMACION DE LOS
-- ESTUDIANTES DE TODAS LAS FACULTADES, POR LO QUE SIEMPRE QUE SE INGRESA LA INFORMACION SE VERFICA QUE EL
-- ESTUDIANTE EXISTA. SIMULANDO UNA REFERENCIA ENTRE SERVIDORES, O EN ESTE CASO INSTANCIAS DE AWS.
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_estudiante() RETURNS TRIGGER AS $$
BEGIN    
    PERFORM ei.cod_e FROM estudiantes_ingenieria ei WHERE ei.cod_e = NEW.cod_es;
    IF FOUND THEN
	    RAISE NOTICE 'El estudiante con cod_e % pertenece a la facultad de Ingeniería', NEW.cod_es;
        RETURN NEW;
    END IF;

    PERFORM cod_e FROM dblink(
        'dbname=database_Artes host=fac-artes.c7u24qsquqpy.us-east-2.rds.amazonaws.com port=5432 user=postgres password=postgres',
        format('SELECT cod_e FROM Estudiantes_Artes ea WHERE ea.cod_e = %L', NEW.cod_es)
    ) AS t2(cod_e BIGINT);
    IF FOUND THEN
		RAISE NOTICE 'El estudiante con cod_e % pertenece a la facultad de Artes', NEW.cod_es;
        RETURN NEW;
    END IF;

    PERFORM cod_e FROM dblink(
        'dbname=database_Ciencias host=fac-ciencias.c7u24qsquqpy.us-east-2.rds.amazonaws.com port=5432 user=postgres password=postgres',
        format('SELECT cod_e FROM Estudiantes_Ciencias ec WHERE ec.cod_e = %L', NEW.cod_es)
    ) AS t2(cod_e BIGINT);
    IF FOUND THEN
		RAISE NOTICE 'El estudiante con cod_e % pertenece a la facultad de Ciencias', NEW.cod_es;
        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'El estudiante con cod_e % no existe en ninguna facultad', NEW.cod_es;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_estudiante
BEFORE INSERT OR UPDATE ON public.presta
FOR EACH ROW EXECUTE FUNCTION validate_estudiante();


-- ROL ESTUDIANTE :
---------------------------------------------------------------------------------------------------------------
-- SEGUIMOS CON LA CREACION DEL ROL DE ESTUDIANTE MEDIANTE FUNCIONES PARA AUTOMATIZAR EL PROCESO: 
---------------------------------------------------------------------------------------------------------------
CREATE ROLE estudiante;

CREATE OR REPLACE FUNCTION addEstudiante(cod_e TEXT) RETURNS VOID AS $$
BEGIN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', cod_e, cod_e);
    EXECUTE format('GRANT estudiante TO %I', cod_e);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION addEstudianteRol() RETURNS VOID AS $$
DECLARE
    estudiante RECORD;
BEGIN
    FOR estudiante IN
        SELECT cod_e
        FROM estudiantes_ingenieria
    LOOP
        PERFORM addEstudiante(estudiante.cod_e::TEXT);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT addEstudianteRol();

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE EL ESTUDIANTE VEA SUS NOTAS Y TENGA PERMISO PARA VISUALIZARLAS:
---------------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS notas;
CREATE VIEW notas AS
SELECT cod_e, nom_e, nom_a, n1, n2, n3, 
       COALESCE(n1,0)*0.35 + COALESCE(n2,0)*0.35 + COALESCE(n3,0)*0.3 AS def
FROM inscribe_Estudiantes 
NATURAL JOIN asignaturas 
NATURAL JOIN estudiantes_ingenieria
WHERE cod_e = current_user::bigint;

GRANT SELECT ON notas TO estudiante;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE EL ESTUDIANTE VEA LIBROS Y AUTORES : 
---------------------------------------------------------------------------------------------------------------
CREATE VIEW libros_autores AS
SELECT * FROM LIBROS ls
NATURAL JOIN ESCRIBE
NATURAL JOIN autores

GRANT SELECT ON libros_autores TO estudiante;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE EL ESTUDIANTE VEA SUS PRESTAMOS:
---------------------------------------------------------------------------------------------------------------
CREATE VIEW prestamos AS
SELECT * from presta
WHERE cod_es = current_user::bigint;

GRANT SELECT ON prestamos TO estudiante;


-- ROL PROFESOR :
---------------------------------------------------------------------------------------------------------------
-- SEGUIMOS CON LA CREACION DEL ROL DE PROFESOR MEDIANTE FUNCIONES PARA AUTOMATIZAR EL PROCESO: 
---------------------------------------------------------------------------------------------------------------

CREATE ROLE profesor;

CREATE OR REPLACE FUNCTION addProfesor(id_p TEXT) RETURNS VOID AS $$
BEGIN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', id_p, id_p);
    EXECUTE format('GRANT profesor TO %I', id_p);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION addProfesorRol() RETURNS VOID AS $$
DECLARE
    profesor RECORD;
BEGIN
    FOR profesor IN
        SELECT id_p
        FROM Profesores
    LOOP
        PERFORM addProfesor(profesor.id_p::TEXT);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT addProfesorRol();
---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE EL PROFESOR VEA Y ACTUALICE LAS NOTAS DE CADA ESTUDIANTE:
---------------------------------------------------------------------------------------------------------------
CREATE VIEW ver_notas_estudiante_profesor AS
SELECT cod_a, nom_a, cod_e, nom_e, n1, n2, n3, 
       COALESCE(n1,0)*0.35 + COALESCE(n2,0)*0.35 + COALESCE(n3,0)*0.3 AS def
FROM inscribe_estudiantes 
NATURAL JOIN asignaturas 
NATURAL JOIN estudiantes_ingenieria
NATURAL JOIN profesores
WHERE id_p = current_user::integer
ORDER BY cod_a, cod_e;

GRANT USAGE ON SCHEMA {ESQUEMA} TO profesor;
GRANT SELECT, UPDATE ON ver_notas_estudiante_profesor TO profesor;
GRANT UPDATE ON {ESQUEMA}.inscribe TO profesor;
---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA FUNCION PARA QUE EL PROFESOR PUEDA ACTUALIZAR LAS NOTAS:
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION Actualizar_Notas_Estudiantes()
RETURNS TRIGGER AS $$
DECLARE
    updated_rows INT := 0;
BEGIN

    UPDATE ingenieria_catastral.inscribe
    SET n1 = COALESCE(NEW.n1, n1),
        n2 = COALESCE(NEW.n2, n2),
        n3 = COALESCE(NEW.n3, n3)
    WHERE cod_e = NEW.cod_e AND id_p = current_user::integer
    RETURNING 1 INTO updated_rows;
    
    IF updated_rows > 0 THEN
	    RAISE NOTICE 'El estudiante con cod_e % le fue actualizada su nota', NEW.cod_e;
        RETURN NEW;
    END IF;

    UPDATE ingenieria_de_sistemas.inscribe
    SET n1 = COALESCE(NEW.n1, n1),
        n2 = COALESCE(NEW.n2, n2),
        n3 = COALESCE(NEW.n3, n3)
    WHERE cod_e = NEW.cod_e AND id_p = current_user::integer
    RETURNING 1 INTO updated_rows;
    
    IF updated_rows > 0 THEN
	    RAISE NOTICE 'El estudiante con cod_e % le fue actualizada su nota', NEW.cod_e;
        RETURN NEW;
    END IF;

    UPDATE ingenieria_electronica.inscribe
    SET n1 = COALESCE(NEW.n1, n1),
        n2 = COALESCE(NEW.n2, n2),
        n3 = COALESCE(NEW.n3, n3)
    WHERE cod_e = NEW.cod_e AND id_p = current_user::integer
    RETURNING 1 INTO updated_rows;
    
    IF updated_rows > 0 THEN
	    RAISE NOTICE 'El estudiante con cod_e % le fue actualizada su nota', NEW.cod_e;
        RETURN NEW;
    END IF;

    UPDATE ingenieria_electrica.inscribe
    SET n1 = COALESCE(NEW.n1, n1),
        n2 = COALESCE(NEW.n2, n2),
        n3 = COALESCE(NEW.n3, n3)
    WHERE cod_e = NEW.cod_e AND id_p = current_user::integer
    RETURNING 1 INTO updated_rows;
    
    IF updated_rows > 0 THEN
	    RAISE NOTICE 'El estudiante con cod_e % le fue actualizada su nota', NEW.cod_e;
        RETURN NEW;
    END IF;
	
    UPDATE ingenieria_industrial.inscribe
    SET n1 = COALESCE(NEW.n1, n1),
        n2 = COALESCE(NEW.n2, n2),
        n3 = COALESCE(NEW.n3, n3)
    WHERE cod_e = NEW.cod_e AND id_p = current_user::integer
    RETURNING 1 INTO updated_rows;
    
    IF updated_rows > 0 THEN
	    RAISE NOTICE 'El estudiante con cod_e % le fue actualizada su nota', NEW.cod_e;
        RETURN NEW;
    END IF;

    IF updated_rows < 1 THEN
	    RAISE NOTICE 'El estudiante con cod_e % no inscribio materias con usted', NEW.cod_e;
        RETURN NEW;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Actualizar_Notas_Estudiantes_Trigger
INSTEAD OF UPDATE ON notasProfe
FOR EACH ROW
EXECUTE FUNCTION Actualizar_Notas_Estudiantes();

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE PUEDA VER LAS ASIGNATURAS QUE DICTA:
---------------------------------------------------------------------------------------------------------------

CREATE VIEW asignaturas_que_dicta AS
SELECT id_p, cod_a, grupo, horario, nom_a, int_h, creditos_a FROM imparte
NATURAL JOIN asignaturas
WHERE id_p = current_user::integer; 

GRANT SELECT ON asignaturas_que_dicta TO profesor;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE VEA LA LISTA DE SUS ESTUDIANTES:
---------------------------------------------------------------------------------------------------------------
CREATE VIEW lista_estudiantes AS
SELECT nom_a, cod_e, nom_e, grupo from inscribe_estudiantes
NATURAL JOIN asignaturas
NATURAL JOIN estudiantes_ingenieria
WHERE id_p = current_user::integer
ORDER BY nom_a;

GRANT SELECT ON lista_estudiantes TO profesor;

---------------------------------------------------------------------------------------------------------------
-- DAMOS PERMISO PARA QUE PUEDA VER LOS LIBROS Y AUTORES ANTERIORMENTE CREADA:
---------------------------------------------------------------------------------------------------------------
GRANT SELECT ON libros_autores TO profesor;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE EL PROFESOR PUEDA ACTUALIZAR Y VER SU INFORMACION PERSONAL:
---------------------------------------------------------------------------------------------------------------
CREATE VIEW informacion_personal_profesor AS
SELECT * from profesores
WHERE id_p = current_user::integer

CREATE OR REPLACE FUNCTION Actualizar_Informacion_Profesor()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profesores
    SET nom_p = COALESCE(NEW.nom_p, nom_p),
        profesion = COALESCE(NEW.profesion, profesion),
        tel_p = COALESCE(NEW.tel_p, tel_p)
    WHERE id_p = OLD.id_p;
 	RAISE NOTICE 'su informacion a sido actualizada con exito';
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Actualizar_Informacion_Profesor_Trigger
INSTEAD OF UPDATE ON informacion_personal_profesor
FOR EACH ROW
EXECUTE FUNCTION Actualizar_Informacion_Profesor();

GRANT SELECT, UPDATE ON informacion_personal_profesor TO profesor;

GRANT USAGE ON SCHEMA public TO profesor;

GRANT SELECT, UPDATE ON TABLE profesores TO profesor;

-- ROL BIBLIOTECARIO :
---------------------------------------------------------------------------------------------------------------
-- SEGUIMOS CON LA CREACION DEL ROL DE BIBLIOTECARIO:
---------------------------------------------------------------------------------------------------------------
CREATE ROLE bibliotecario LOGIN PASSWORD 'bibliotecario';

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE INSERTE, ACTUALICE Y ELIMINE LOS PRESTAMOS
---------------------------------------------------------------------------------------------------------------

CREATE VIEW prestamos_bibliotecario AS
SELECT * FROM presta
GRANT USAGE ON SCHEMA public TO bibliotecario;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ejemplares TO bibliotecario;

CREATE OR REPLACE FUNCTION bibliotecario_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO presta (cod_es, isbn, num_ej, fech_p, fech_d)
    VALUES (NEW.cod_es, NEW.isbn, NEW.num_ej, NEW.fech_p, NEW.fech_d);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bibliotecario_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE presta
    SET cod_es = NEW.cod_es,
        isbn = NEW.isbn,
        num_ej = NEW.num_ej,
        fech_p = NEW.fech_p,
        fech_d = NEW.fech_d
    WHERE cod_es = OLD.cod_es AND isbn = OLD.isbn AND num_ej = OLD.num_ej;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bibliotecario_delete()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM presta
    WHERE cod_es = OLD.cod_es AND isbn = OLD.isbn AND num_ej = OLD.num_ej AND fech_p = OLD.fech_p;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_insert_presta
INSTEAD OF INSERT ON prestamos_bibliotecario
FOR EACH ROW
EXECUTE FUNCTION bibliotecario_insert();

CREATE TRIGGER trigger_update_presta
INSTEAD OF UPDATE ON prestamos_bibliotecario
FOR EACH ROW
EXECUTE FUNCTION bibliotecario_update();

CREATE TRIGGER trigger_delete_presta
INSTEAD OF DELETE ON prestamos_bibliotecario
FOR EACH ROW
EXECUTE FUNCTION bibliotecario_delete();

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE VEA EJEMPLARES:
---------------------------------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE libros, escribe, autores TO bibliotecario;

GRANT SELECT ON libros_autores TO bibliotecario;

-- ROL COORDINADOR :
---------------------------------------------------------------------------------------------------------------
-- SEGUIMOS CON LA CREACION DEL ROL DE COORDINADOR (TENER EN CUENTA QUE YA EXISTE EL PROFESOR):
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION addCoordinador(id_p TEXT) RETURNS VOID AS $$
BEGIN
    EXECUTE format('GRANT coordinador TO %I', id_p);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION addCoordinadorRol() RETURNS VOID AS $$
DECLARE
    carreras RECORD;
BEGIN
    FOR carreras IN
        SELECT id_p
        FROM carreras
    LOOP
        PERFORM addCoordinador(carreras.id_p::TEXT);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT addCoordinadorRol();
---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE INSERTE, ACTUALICE Y ELIMINE LA INFORMACION DE SUS ESTUDIANTES 
---------------------------------------------------------------------------------------------------------------

GRANT USAGE ON SCHEMA ingenieria_electronica TO "11003";
GRANT USAGE ON SCHEMA ingenieria_de_sistemas TO "11006";
GRANT USAGE ON SCHEMA ingenieria_catastral TO "11013";
GRANT USAGE ON SCHEMA ingenieria_industrial TO "11017";
GRANT USAGE ON SCHEMA ingenieria_electrica TO "11025";

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_electronica.estudiantes TO "11003";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_de_sistemas.estudiantes TO "11006";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_catastral.estudiantes TO "11013";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_industrial.estudiantes TO "11017";
GRANT INSERT, UPDATE, DELETE ON TABLE ingenieria_electrica.estudiantes TO "11025";

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LA VISTA PARA QUE INSERTE, ACTUALICE Y ELIMINE LAS NOTAS DE SUS ESTUDIANTES
---------------------------------------------------------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_electronica.inscribe TO "11003";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_de_sistemas.inscribe TO "11006";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_catastral.inscribe TO "11013";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_industrial.inscribe TO "11017";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ingenieria_electrica.inscribe TO "11025";

---------------------------------------------------------------------------------------------------------------
-- CREAMOS UN LOG PARA REGISTRAR CADA OPERACION QUE HAGA EN ESTUDIANTES Y INSCRIBE:
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_changes() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log_table (table_name, operation, user_name, details)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        current_user,
        row_to_json(NEW)
    );
	RAISE NOTICE 'La informacion de la tabla: %, y la operacion: % ha sido efectuada con exito',
    TG_TABLE_NAME,
    TG_OP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS log_table (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation TEXT,
    user_name TEXT,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);

GRANT USAGE, SELECT ON SEQUENCE log_table_log_id_seq TO "11025";
GRANT USAGE, SELECT ON SEQUENCE log_table_log_id_seq TO "11003";
GRANT USAGE, SELECT ON SEQUENCE log_table_log_id_seq TO "11006";
GRANT USAGE, SELECT ON SEQUENCE log_table_log_id_seq TO "11013";
GRANT USAGE, SELECT ON SEQUENCE log_table_log_id_seq TO "11017";

GRANT INSERT, UPDATE ON TABLE log_table TO "11025";
GRANT INSERT, UPDATE ON TABLE log_table TO "11003";
GRANT INSERT, UPDATE ON TABLE log_table TO "11006";
GRANT INSERT, UPDATE ON TABLE log_table TO "11013";
GRANT INSERT, UPDATE ON TABLE log_table TO "11017";


CREATE TRIGGER log_changes_estudiantes_electronica
AFTER INSERT OR UPDATE ON ingenieria_electronica.estudiantes
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_estudiantes_de_sistemas
AFTER INSERT OR UPDATE ON ingenieria_de_sistemas.estudiantes
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_estudiantes_catastral
AFTER INSERT OR UPDATE ON ingenieria_catastral.estudiantes
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_estudiantes_industrial
AFTER INSERT OR UPDATE ON ingenieria_industrial.estudiantes
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_estudiantes_electrica
AFTER INSERT OR UPDATE ON ingenieria_electrica.estudiantes
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_inscribe_electronica
AFTER INSERT OR UPDATE ON ingenieria_electronica.inscribe
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_inscribe_de_sistemas
AFTER INSERT OR UPDATE ON ingenieria_de_sistemas.inscribe
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_inscribe_catastral
AFTER INSERT OR UPDATE ON ingenieria_catastral.inscribe
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_inscribe_industrial
AFTER INSERT OR UPDATE ON ingenieria_industrial.inscribe
FOR EACH ROW EXECUTE FUNCTION log_changes();

CREATE TRIGGER log_changes_inscribe_electrica
AFTER INSERT OR UPDATE ON ingenieria_electrica.inscribe
FOR EACH ROW EXECUTE FUNCTION log_changes();

---------------------------------------------------------------------------------------------------------------
-- DAMOS PERMISO PARA QUE PUEDA VER LIBROS Y AUTORES
---------------------------------------------------------------------------------------------------------------
GRANT SELECT ON libros_autores TO estudiante;

---------------------------------------------------------------------------------------------------------------
-- DAMOS PERMISO PARA QUE PUEDA VER SUS PRESTAMOS
---------------------------------------------------------------------------------------------------------------
GRANT SELECT ON prestamos TO estudiante;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LOS PERMISOS PARA QUE EDITE IMPARTE Y ADMINISTRAR LA INFORMACION.
---------------------------------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE imparte TO coordinador;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LOS PERMISOS PARA QUE ADMINISTRE LIBROS Y AUTORES
---------------------------------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON TABLE libros, autores TO coordinador;

---------------------------------------------------------------------------------------------------------------
-- CREAMOS LOS PERMISOS PARA QUE ADMINISTRE REFERENCIAS
---------------------------------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON TABLE referencia TO coordinador;

---------------------------------------------------------------------------------------------------------------
-- CREAR VISTA PARA ADICIONAR, MODIFICAR Y BORRAR DE SOLO SU CARRERA
---------------------------------------------------------------------------------------------------------------
GRANT SELECT, UPDATE, DELETE ON editar_materias TO coordinador

CREATE VIEW editar_materias AS
SELECT asig.cod_a, asig.nom_a, asig.int_h, asig.creditos_a, im.grupo, im.horario 
FROM asignaturas asig
NATURAL JOIN carreras carr
LEFT JOIN imparte im ON im.cod_a = asig.cod_a
WHERE carr.id_p = current_user::integer;

CREATE OR REPLACE FUNCTION insertar_editar_materias() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO asignaturas (cod_a, nom_a, int_h, creditos_a)
    VALUES (NEW.cod_a, NEW.nom_a, NEW.int_h, NEW.creditos_a)
    ON CONFLICT (cod_a) DO NOTHING;

select * from inscribe_estudiantes
    
    INSERT INTO imparte (cod_a, grupo, horario)
    VALUES (NEW.cod_a, NEW.grupo, NEW.horario)
    ON CONFLICT (cod_a, grupo) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION actualizar_editar_materias() RETURNS TRIGGER AS $$
BEGIN
    UPDATE asignaturas
    SET nom_a = NEW.nom_a, int_h = NEW.int_h, creditos_a = NEW.creditos_a
    WHERE cod_a = OLD.cod_a;
    
    UPDATE imparte
    SET grupo = NEW.grupo, horario = NEW.horario
    WHERE cod_a = OLD.cod_a;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION borrar_editar_materias() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM imparte
    WHERE cod_a = OLD.cod_a;
    
    DELETE FROM asignaturas
    WHERE cod_a = OLD.cod_a;
    
    RETURN OLD;
END;

$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_insertar_editar_materias
INSTEAD OF INSERT ON editar_materias
FOR EACH ROW
EXECUTE FUNCTION insertar_editar_materias();

CREATE TRIGGER trigger_actualizar_editar_materias
INSTEAD OF UPDATE ON editar_materias
FOR EACH ROW
EXECUTE FUNCTION actualizar_editar_materias();

CREATE TRIGGER trigger_borrar_editar_materias
INSTEAD OF DELETE ON editar_materias
FOR EACH ROW
EXECUTE FUNCTION borrar_editar_materias();