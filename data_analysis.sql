-- Cálculo de estadísticas descriptivas básicas para comprender la distribución de los datos y sus características

-- Número total de viajes realizados = 5.561.981
SELECT COUNT(ride_id) AS total_viajes FROM cyclistic_2023;

-- Media = '00:15:29'
SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(ride_length))) AS media
FROM cyclistic_2023;

-- Mediana = '00:09:47'
SELECT ride_length AS mediana
FROM (
    SELECT 
        ride_length,
        @rownum := @rownum + 1 AS 'row_number',
        @total_rows := @rownum
    FROM 
        cyclistic_2023
    CROSS JOIN 
        (SELECT @rownum := 0) r
    ORDER BY 
        ride_length
) AS datos_sorted,
(SELECT @total_rows) AS total_rows
WHERE 
    datos_sorted.row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));

-- Desviación estándar = '00:31:09' Existe una dispersión notable en la duración de los viajes, lo que implica que las duraciones pueden variar bastante entre sí
SELECT SEC_TO_TIME(STDDEV(TIME_TO_SEC(ride_length))) AS desviacion_estandar
FROM cyclistic_2023;

-- El mínimo es '00:01:00' y el máximo '23:59:52' lo que verifica la limpieza de valores atípicos realizada anteriormente
SELECT 'minimo' AS calculo, SEC_TO_TIME(MIN(TIME_TO_SEC(ride_length))) AS duracion
FROM cyclistic_2023
UNION
SELECT 'maximo' AS calculo, SEC_TO_TIME(MAX(TIME_TO_SEC(ride_length))) AS duracion
FROM cyclistic_2023;
 
-- Segmentación de usuarios para profundizar en cómo ciertas características o comportamientos difieren entre ellos

-- Número y porcentaje de viajes por tipo de bicicleta y usuario
SELECT
  rideable_type,
  member_casual,
  COUNT(*) AS viajes,
  COUNT(*) * 100 / (SELECT COUNT(*) FROM cyclistic_2023) AS porcentaje
FROM cyclistic_2023
GROUP BY rideable_type, member_casual
ORDER BY member_casual;

-- Media de la duración de los viajes por tipo de usuario
SELECT member_casual, 
       SEC_TO_TIME(ROUND(AVG(TIME_TO_SEC(ride_length)))) AS media_duracion_viaje
FROM cyclistic_2023
GROUP BY member_casual;

-- Estaciones de inicio más populares según el tipo de usuario
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS viajes
FROM cyclistic_2023
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY viajes DESC;

-- Diez estaciones de inicio más populares entre los usuarios miembros
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS viajes
FROM cyclistic_2023
WHERE member_casual = 'member'
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY viajes DESC
LIMIT 11;

-- Diez estaciones de inicio más populares entre los usuarios casuales
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS viajes
FROM cyclistic_2023
WHERE member_casual = 'casual'
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY viajes DESC
LIMIT 11;

-- Rutas más populares combinando la estación de inicio y la de final según el tipo de usuario
SELECT member_casual, CONCAT(start_station_name, ' to ', end_station_name) AS ruta, COUNT(*) AS viajes
FROM cyclistic_2023
GROUP BY ruta, member_casual
ORDER BY viajes DESC;

-- Análisis de tendencias temporales para comprender cómo los patrones de uso varían a lo largo del tiempo

-- Número de viajes a lo largo del día según el tipo de usuario
SELECT HOUR(started_at) AS hora, 
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS viajes_miembro,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS viajes_casual
FROM cyclistic_2023
GROUP BY HOUR(started_at)
ORDER BY hora;

-- Duración media de los viajes a lo largo del día según el tipo de usuario
SELECT HOUR(started_at) AS hora,
       SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) ELSE NULL END))) AS media_duracion_miembro,
       SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) ELSE NULL END))) AS media_duracion_casual
FROM cyclistic_2023
GROUP BY HOUR(started_at)
ORDER BY hora;

-- Número de viajes por día de la semana según el tipo de usuario
SELECT day_of_week,
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS viajes_miembro,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS viajes_casual
FROM cyclistic_2023
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Duración media de los viajes según día de la semana y tipo de usuario
SELECT
    day_of_week,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) END))) AS media_duracion_miembro,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) END))) AS media_duracion_casual
FROM cyclistic_2023
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Número de viajes por mes según el tipo de usuario
SELECT
    DATE_FORMAT(started_at, '%Y-%m') AS mes,
    SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS viajes_miembro,
    SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS viajes_casual
FROM cyclistic_2023
GROUP BY DATE_FORMAT(started_at, '%Y-%m');

-- Duración media de los viajes según el mes y tipo de usuario
SELECT
    DATE_FORMAT(started_at, '%Y-%m') AS mes,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) END))) AS media_duracion_miembro,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) END))) AS media_duracion_casual
FROM cyclistic_2023
GROUP BY DATE_FORMAT(started_at, '%Y-%m')
ORDER BY DATE_FORMAT(started_at, '%Y-%m');
