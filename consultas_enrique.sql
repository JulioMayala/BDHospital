-- h) Resolver en SQL la consulta: Obtener para cada medicamento (codigo y nombre) 
--    el numero total de veces que ha sido prescrito, el nombre del doctor que mas
--    lo ha recetado (si existen empates mostrar todos los doctores empatados), y
--    la dosis promedio recetada. Ordenar los resultados de mayor a menor segun el
--    numero total de prescripciones. Tener en cuenta que si existen empates entre
--    los doctores se tienen que mostrar todos los doctores, cada uno en una fila
--    distinta.

SELECT m.name AS med_name, p.name AS phys_name, med_data.total_pres_count, med_data.avg_dose
FROM medication m
INNER JOIN (
			SELECT medicationid, physicianid, COUNT(*) AS pres_count
	  	   	FROM prescribes A
	  	   	GROUP BY medicationid, physicianid
			HAVING pres_count = (
				   			  	 SELECT MAX(pres_count)
								 FROM (
								 	   SELECT medicationid, physicianid, COUNT(*) AS pres_count
						               FROM prescribes P
									   WHERE A.medicationid = P.medicationid
									   GROUP BY medicationid, physicianid
								      ) B
				   			  	)
		   ) med_phy ON m.code = med_phy.medicationid
INNER JOIN physician p ON p.employeeid = med_phy.physicianid
INNER JOIN (
			SELECT medicationid, COUNT(*) AS total_pres_count, AVG(dose) AS avg_dose
			FROM prescribes
			GROUP BY medicationid
	  	   ) med_data ON m.code = med_data.medicationid
ORDER BY med_data.total_pres_count DESC

	  
-- i) Resolver en SQL la consulta: Obtener el nombre de los medicamentos que han
--    sido prescritos por todos los doctores pertenecientes a mas de un departamento
--    diferente.

SELECT m.name
FROM medication m
WHERE NOT EXISTS (
	  	  		  SELECT DISTINCT medicationid, physicianid
	              FROM prescribes p
			      WHERE m.code = p.medicationid
				  AND NOT EXISTS (
                                  SELECT DISTINCT physicianid
                                  FROM affiliated_with a
							      WHERE p.physicianid = a.physicianid
                                  GROUP BY physicianid
                                  HAVING COUNT(*) > 1
				                 )
	              GROUP BY medicationid, physicianid
                 )
AND m.code IN (
		   	   SELECT medicationid
			   FROM prescribes
			  )

-- m) Codifica una funcion almacenada denominada calc stay cost que calcule y
-- devuelva el coste total de una estancia pasada como parametro. Para
-- determinar dicho coste, considera que las habitaciones de tipo ICU tienen
-- un coste de 500e/dıa, las Single de 300e/dıa, las Double de 150e/dıa y
-- otros tipos de habitaciones tienen un coste de 100e/dıa. Para determinar
-- la duracion de una estancia busca informacion a cerca de las funciones
-- DATEDIFF y STR TO DATE. Incluye tambien todas las sentencias SQL necesarias
-- para probar la funcion almacenada.

DELIMITER $$
CREATE FUNCTION calc_stay_cost(stay_id int)
RETURNS INTEGER
DETERMINISTIC
BEGIN
	DECLARE euros INTEGER;
	DECLARE days_spent INTEGER;
	DECLARE room_type VARCHAR(8);
	
	SELECT DATEDIFF(STR_TO_DATE(end_time, '%d/%m/%Y'), STR_TO_DATE(start_time, '%d/%m/%Y')) INTO days_spent
	FROM stay
	WHERE stayid = stay_id;

	SELECT roomtype INTO room_type
	FROM room
	WHERE roomnumber IN (SELECT roomid FROM stay WHERE stayid = stay_id);

	CASE
	WHEN room_type LIKE 'UCI'    THEN SET euros = days_spent * 500;
	WHEN room_type LIKE 'Single' THEN SET euros = days_spent * 300;
	WHEN room_type LIKE 'Double' THEN SET euros = days_spent * 150;
	END CASE;

	return euros;
END$$

DELIMITER ;

SELECT s.stayid, r.roomnumber, s.start_time, s.end_time, r.roomtype, calc_stay_cost(stayid) 
FROM stay s INNER JOIN room r ON s.roomid = r.roomnumber
