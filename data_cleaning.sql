-- Creación de la base de datos y la tabla
CREATE SCHEMA IF NOT EXISTS cyclistic;

USE cyclistic;

CREATE TABLE cyclistic_2023 (
    ride_id VARCHAR(50),
    rideable_type VARCHAR(20),
    started_at DATETIME,
    ended_at DATETIME,
    start_station_name VARCHAR(100),
    start_station_id VARCHAR(50),
    end_station_name VARCHAR(100),
    end_station_id VARCHAR(50),
    start_lat VARCHAR(255),
    start_lng VARCHAR(255),
    end_lat VARCHAR(255),
    end_lng VARCHAR(255),
    member_casual VARCHAR(50)
);

-- Se importan los datos de los 12 archivos CSV a la base de datos
SHOW VARIABLES LIKE "local_infile";

SET GLOBAL local_infile=1; -- Para habilitar la carga de datos desde un archivo local

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\202301-divvy-tripdata.csv"
INTO TABLE cyclistic_2023 
FIELDS TERMINATED BY "," 
IGNORE 1 ROWS

-- Verificación de la estructura de la tabla
DESCRIBE cyclistic_2023; 

-- Comprobación de que el número de registros de la tabla combinada coincide con la suma de las tablas individuales: 5.718.902 registros
SELECT COUNT(*)
FROM cyclistic_2023;

-- Comprobación del número de columnas
SELECT COUNT(*) AS num_columnas
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'cyclistic' AND TABLE_NAME = 'cyclistic_2023';

-- Creación de un índice para acelerar la velocidad de carga de las consultas
CREATE INDEX index_ride_id ON cyclistic_2023 (ride_id);

-- Identificación de valores duplicados en la columna ride_id
SELECT ride_id, COUNT(*) AS duplicados
FROM cyclistic_2023
GROUP BY ride_id
HAVING COUNT(*) > 1
ORDER BY duplicados DESC, ride_id;

-- Eliminación de 46 filas con valores duplicados en la columna ride_id
DELETE FROM cyclistic_2023
WHERE ride_id IN (
    SELECT ride_id
    FROM (
        SELECT ride_id
        FROM cyclistic_2023
        GROUP BY ride_id
        HAVING COUNT(*) > 1
    ) AS duplicados
);

-- Identificación de registros en blanco y nulos en la columna ride_id. No existe ninguno
SELECT *
FROM cyclistic_2023
WHERE ride_id = '' OR ride_id IS NULL;

-- Comprobación de los tipos de bicicleta en la columna rideable_type
SELECT DISTINCT rideable_type
FROM cyclistic_2023;

-- La consulta anterior devuelve tres tipos de bicicleta: electric_bike, classic_bike, docked_bike. docked_bike es un tipo de classic_bike, por lo que se cambia para que solo existan dos tipos de bicicleta, afectando a 78.270 registros.
UPDATE cyclistic_2023
SET rideable_type = 'classic_bike'
WHERE rideable_type = 'docked_bike';

-- Identificación de registros en blanco y nulos en la columna rideable_type. No existe ninguno
SELECT *
FROM cyclistic_2023
WHERE rideable_type = '' OR rideable_type IS NULL;

-- Identificación de filas en las que la hora de started_at es más tarde que la de ended_at, lo cual es un error
SELECT *
FROM cyclistic_2023
WHERE started_at > ended_at;

-- Eliminación de 272 filas en las que started_at es mayor que ended_at
DELETE FROM cyclistic_2023
WHERE started_at > ended_at;

-- Identificación de valores atípicos en las columnas started_at y ended_at. Se han considerado como atípicos los viajes que tienen como duración menos de un minuto o más de un día.
SELECT *
FROM cyclistic_2023
WHERE TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60 
OR TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400; -- 86400 segundos equivalen a 24 horas

-- Eliminación de 155.727 filas con valores atípicos
DELETE FROM cyclistic_2023
WHERE TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60 
OR TIMESTAMPDIFF(SECOND, started_At, ended_at) > 86400;

-- A partir de las columnas started_at y ended_at, se crea la columna ride_length
ALTER TABLE cyclistic_2023
ADD ride_length TIME;

-- Se calcula la duración de cada viaje en formato HH:MM:SS
UPDATE cyclistic_2023
SET ride_length = TIMEDIFF(ended_at, started_at);

-- Verificación de la columna ride_length
SELECT started_at, ended_at, ride_length
FROM cyclistic_2023
LIMIT 20

-- Identificación de registros en blanco y nulos en la columna ride_length. No existe ninguno
SELECT *
FROM cyclistic_2023
WHERE ride_length = '' OR ride_length IS NULL;

-- A partir de la columna started_at, se crea la columna day_of_week
ALTER TABLE cyclistic_2023
ADD day_of_week VARCHAR(20);

-- Se identifica el día de la semana en que inició cada viaje
UPDATE cyclistic_2023
SET day_of_week = DAYNAME(started_at);

-- Verificación del resultado de la consulta anterior
SELECT started_at, day_of_week
FROM cyclistic_2023
LIMIT 10;

-- Comprobación de que en la columna member_casual solo hay dos opciones
SELECT DISTINCT member_casual
FROM cyclistic_2023;

-- Eliminación de caracteres especiales en la columna "member_casual"
UPDATE cyclistic_2023
SET member_casual = REPLACE(member_casual, '\r', '');

-- Identificación de registros con dos o más espacios extras entre palabras en las columnas start_station_name y end_station_name
SELECT *
FROM cyclistic_2023
WHERE start_station_name REGEXP '[[:space:]]{2,}' OR end_station_name REGEXP '[[:space:]]{2,}';

-- Eliminación de los espacios extra entre palabras en 8 registros de las columnas start_station_name y end_station_name
UPDATE cyclistic_2023
SET start_station_name = REPLACE(start_station_name, '  ', ' '),
    end_station_name = REPLACE(end_station_name, '  ', ' ')
WHERE start_station_name LIKE '%  %' OR end_station_name LIKE '%  %';

-- Comprobación de valores nulos o en blanco en la columna start_station_name en el caso de bicicletas clásicas. Este tipo de bicicleta debe comenzar en una estación designada, a diferencia de las bicicletas eléctricas, para las cuales no es obligatorio
SELECT *
FROM cyclistic_2023
WHERE (start_station_name IS NULL OR start_station_name = '') 
AND rideable_type = 'classic_bike';


-- Eliminación de 876 filas con valores nulos o en blanco en la columna start_station_name en el caso de bicicletas clásicas
DELETE FROM cyclistic_2023
WHERE (start_station_name IS NULL OR start_station_name = '') 
AND rideable_type = 'classic_bike';
