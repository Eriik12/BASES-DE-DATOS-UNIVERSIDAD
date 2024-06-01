# PROYECTO FINAL BASES DE DATOS

Este proyecto consiste en la gestión de tres bases de datos creadas en PostgreSQL para la gestión académica de la Universidad Distrital Francisco José de Caldas.

A continuación, se detallan los aspectos más relevantes del proyecto:

## INFORMACIÓN A TENER EN CUENTA

Las bases de datos fueron creadas con instancias de Amazon. Por motivos de seguridad, no se mostrará la contraseña para la conexión con el usuario "ADMIN".

Las referencias en los esquemas de SQL, tales como `{}`, representan información relevante que debe ser cambiada para ejecutar la función o permisos pertinentes.

## Creación de Tablas

Se crearon varias tablas siguiendo un orden y respetando las referencias entre ellas. Fueron organizadas para evitar problemas en su creación.

## Llenado de Información

La información se llenó en las tablas utilizando comandos SQL mediante `psql`. Debido a que la base de datos está alojada en AWS, se utilizó psql a través de CMD siguiendo un formato específico especificado en los scripts.

## Vistas Predefinidas

Se crearon vistas predefinidas para facilitar la visualización de datos según el rol del usuario. Se destacan las vistas `estudiantes_ingenieria` e `inscribe_estudiantes` para visualizar estudiantes de diferentes carreras. Debido a que hay diferentes esquemas para cada carrera.

## Funciones Predefinidas

Se crearon funciones predefinidas para realizar validaciones y acciones específicas en la base de datos. Por ejemplo, la función `validate_estudiante()` verifica la existencia de un estudiante antes de realizar ciertas operaciones entre instancias (servidores o facultades).

## Configuración de Roles

Se configuraron roles específicos con permisos adecuados para acceder y manipular los datos en la base de datos. Se crearon roles como `estudiante`, `profesor`, `bibliotecario` y `coordinador`, cada uno con sus respectivos privilegios.

## Funcionalidades Adicionales

Se implementaron funcionalidades adicionales, como la creación de registros de log para registrar operaciones, la creación de triggers para automatizar ciertas acciones, y la gestión de información personal para profesores y estudiantes.

## Permisos y Seguridad

Se establecieron permisos detallados para cada rol, garantizando que cada usuario tenga acceso solo a la información relevante para su función específica. Se controló el acceso a tablas, vistas y funciones para mantener la seguridad de la base de datos.

## Conexión Real

Podemos conectarnos a las siguientes instancias con las credenciales:

- Facultad de Ingeniería:
  - Instancia: `fac-ingenieriaa.c7u24qsquqpy.us-east-2.rds.amazonaws.com`
  - Usuario: `ingresar_ingenieria`
  - Contraseña: `ingresar_ingenieria`

- Facultad de Ciencias:
  - Instancia: `fac-ciencias.c7u24qsquqpy.us-east-2.rds.amazonaws.com`
  - Usuario: `ingresar_ciencias`
  - Contraseña: `ingresar_ciencias`

- Facultad de Artes:
  - Instancia: `fac-artes.c7u24qsquqpy.us-east-2.rds.amazonaws.com`
  - Usuario: `ingresar_artes`
  - Contraseña: `ingresar_artes`
