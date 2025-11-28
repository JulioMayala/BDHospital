-- CONSULTAS --
-- b) Resolver en SQL la consulta: Obtener el nombres de los doctores, los medicamentos y la
-- fecha de prescripción de los mismos de aquellos doctores que están afiliados al departamento
-- de “General Medicine” y que han recetado algún medicamento en el año 2023 o 2024.
SELECT ph.name AS doctor_name, m.name AS medication_name, pr.date AS prescription_date
FROM physician ph
JOIN prescribes pr ON ph.employeeid = pr.physicianid
JOIN medication m ON pr.medicationid = m.code
JOIN affiliated_with af ON ph.employeeid = af.physicianid
JOIN department d ON af.departmentid = d.departmentid
WHERE d.name = 'General Medicine'
AND (pr.date LIKE '%2023' OR pr.date LIKE '%2024'); -- Viendo el formato, se ve que el año es lo último
                      
-- c) Resolver en SQL la consulta: Obtener el nombre del paciente con el ingreso más largo y
-- el paciente con el ingreso más corto en el hospital, mostrando para cada uno su nombre,
-- el número de habitación donde estuvo ingresado, así como el piso y bloque de la misma,
-- la duración de la estancia en días y el tipo de estancia (más largo o más corto).                      
SELECT p.name AS nombre_paciente, r.roomnumber AS num_habitacion, r.blockfloorid AS piso, 
	   r.blockcodeid AS bloque, (s.end_time - s.start_time) AS dias_estancia, 'mas largo' AS tipo
FROM patient p
JOIN stay s ON p.ssn = s.patientid
JOIN room r ON s.roomid = r.roomnumber
WHERE (s.end_time - s.start_time) = (SELECT MAX(s2.end_time - s2.start_time) FROM stay s2)

UNION

SELECT p.name AS nombre_paciente, r.roomnumber AS num_habitacion, r.blockfloorid AS piso,
	   r.blockcodeid AS bloque, (s.end_time - s.start_time) AS dias_estancia, 'mas corto' AS tipo
FROM patient p
JOIN stay s ON p.ssn = s.patientid
JOIN room r ON s.roomid = r.roomnumber
WHERE (s.end_time - s.start_time) = (SELECT MIN(s2.end_time - s2.start_time) FROM stay s2);

-- d) Resolver en SQL la consulta: Actualizar la descripción de los medicamentos agregando la
-- nota de "Possible discontinuation" (posible descatalogación) a aquellos que no han sido rece-
-- tados durante los últimos dos años por doctores pertenecientes al departamento de "General
-- Medicine", evitando además incluir aquellos que ya contengan dicha advertencia en su des-
-- cripción actual.
UPDATE medication m
SET m.description = CONCAT(m.description, ' - Possible discontinuation')
WHERE m.code NOT IN (
    SELECT DISTINCT pr.medicationid FROM prescribes pr
    JOIN physician ph ON pr.physicianid = ph.employeeid
    JOIN affiliated_with af ON ph.employeeid = af.physicianid
    JOIN department d ON af.departmentid = d.departmentid
    WHERE d.name = 'General Medicine' AND pr.date >= '2023/11/26'
)
AND m.description NOT LIKE '%Possible discontinuation';

-- e) Resolver en SQL la consulta: Obtener un listado detallado de los doctores del hospital, 
-- mostrando para cada uno su nombre, el número total de procedimientos realizados, el coste
-- total de dichos procedimientos y el coste promedio por procedimiento. Los resultados deben
-- estar ordenados de mayor a menor según el número de procedimientos realizados.
SELECT sub.name AS nombre_doctor, sub.total_procedimientos, sub.coste_total, sub.coste_promedio
FROM (SELECT ph.employeeid, ph.name, COUNT(u.procedureid) AS total_procedimientos, SUM(mp.cost) AS coste_total,
             AVG(mp.cost) AS coste_promedio
      FROM physician ph
      JOIN undergoes u ON ph.employeeid = u.physicianid
      JOIN medical_procedure mp ON u.procedureid = mp.code
      GROUP BY ph.employeeid, ph.name
     ) AS sub
ORDER BY sub.total_procedimientos DESC;

-- f) Resolver en SQL la consulta: Obtener los doctores (nombre y posición) que han realizado
-- todos los procedimientos médicos con coste superior a 5000 y que haya realizado más de 3
-- procedimientos médicos de cualquiera de los tipos en total.
SELECT ph.name AS nombre_doctor, ph.position AS posicion
FROM physician ph
WHERE (SELECT COUNT(*) FROM medical_procedure mp
       WHERE mp.cost > 5000
	   AND mp.code NOT IN (SELECT u.procedureid FROM undergoes u
						   WHERE u.physicianid = ph.employeeid)) = 0
AND (SELECT COUNT(*) FROM undergoes u2
	 WHERE u2.physicianid = ph.employeeid) > 3;
    
-- g) Resolver en SQL la consulta: Obtener el personal de enfermería que siempre han estado
-- asignadas a turnos en el mismo sitio (bloque y piso) y que además, si han participado en
-- procedimientos médicos, siempre haya sido con el mismo doctores.
SELECT n.employeeid AS identificador, n.name AS nombre_enfermera, n.position AS posición
FROM nurse n
JOIN on_call oc ON n.employeeid = oc.nurseid
LEFT JOIN undergoes u ON n.employeeid = u.assistingnurseid
GROUP BY n.employeeid, n.name, n.position
HAVING COUNT(DISTINCT oc.blockfloorid) = 1 AND COUNT(DISTINCT oc.blockcodeid) = 1 
AND (COUNT(u.physicianid) = 0 OR COUNT(DISTINCT u.physicianid) = 1);

-- h) Resolver en SQL la consulta: Obtener para cada medicamento (código y nombre) el número
-- total de veces que ha sido prescrito, el nombre del doctor que más lo ha recetado (si existen
-- empates mostrar todos los doctores empatados), y la dosis promedio recetada. Ordenar los
-- resultados de mayor a menor según el número total de prescripciones. Tener en cuenta que
-- si existen empates entre los doctores se tienen que mostrar todos los doctores, cada uno en
-- una fila distinta.
SELECT m.code AS codigo_medicamento, m.name AS nombre_medicamento, t.total_prescripciones, t.dosis_promedio,
       ph.name AS doctor_que_mas_receto
FROM (SELECT pr.medicationid, COUNT(*) AS total_prescripciones, AVG(pr.dose) AS dosis_promedio,
        (SELECT MAX(x.cnt_doctor)
         FROM (SELECT COUNT(*) AS cnt_doctor
			   FROM prescribes pr2
			   WHERE pr2.medicationid = pr.medicationid
               GROUP BY pr2.physicianid) AS x) AS max_doctor_count
      FROM prescribes pr
      GROUP BY pr.medicationid) AS t
JOIN medication m ON m.code = t.medicationid
JOIN prescribes pr ON pr.medicationid = t.medicationid
JOIN physician ph ON ph.employeeid = pr.physicianid
GROUP BY m.code, m.name, t.total_prescripciones, t.dosis_promedio, ph.employeeid, ph.name, t.max_doctor_count
HAVING COUNT(*) = t.max_doctor_count
ORDER BY t.total_prescripciones DESC;

-- i) Resolver en SQL la consulta: Obtener el nombre de los medicamentos que han sido prescritos 
-- por todos los doctores pertenecientes a más de un departamento diferente.
SELECT m.name AS nombre_medicamento
FROM prescribes pr
JOIN medication m ON m.code = pr.medicationid
WHERE pr.physicianid IN (SELECT physicianid
                         FROM affiliated_with
						 GROUP BY physicianid
						 HAVING COUNT(DISTINCT departmentid) > 1)
GROUP BY m.name
HAVING COUNT(DISTINCT pr.physicianid) = (SELECT COUNT(*) 
										 FROM (SELECT af.physicianid
											   FROM affiliated_with af
											   GROUP BY af.physicianid
											   HAVING COUNT(DISTINCT af.departmentid) > 1) AS multi_docs);

-- j) Codifica un trigger que garantice que únicamente los doctores con la formación adecuada y
-- actualizada puedan programar nuevas intervenciones médicas para las que se han certifica -
-- do. Es decir, que el certificado sea valido para la fecha del procedimiento que va a realizar.
-- Diferenciar mediante mensajes de error específicos entre ambos casos: los que el doctor no
-- posee la certificación requerida y aquellos en los que la certificación existe pero se encuentra
-- caducada. Incluir las sentencias SQL para probar el trigger con todos los casos (i.e. que se
-- se pueda dar de alta correctamente y ambos errores).
DELIMITER $$

CREATE TRIGGER check_physician_certification
BEFORE INSERT ON undergoes FOR EACH ROW
BEGIN
    DECLARE cert_count INT;
    DECLARE cert_expires VARCHAR(10);
    DECLARE procedure_date_converted DATE;
    DECLARE cert_expires_converted DATE;
    
    -- Verificar si el médico tiene la certificación para el procedimiento
    SELECT COUNT(*) INTO cert_count FROM trained_in t
    WHERE t.physicianid = NEW.physicianid AND t.treatmentid = NEW.procedureid;
    -- Si no tiene la certificación, lanzar error
    IF cert_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El doctor no posee la certificación requerida para este procedimiento';
    END IF;
    -- Si tiene la certificación, verificar que esté vigente
    -- Usamos MAX para obtener la certificación más reciente (por si hay varias)
    SELECT MAX(certificationexpires) INTO cert_expires FROM trained_in t
    WHERE t.physicianid = NEW.physicianid AND t.treatmentid = NEW.procedureid;
    -- Convertir las fechas para compararlas
    SET procedure_date_converted = STR_TO_DATE(NEW.date, '%d/%m/%Y');
    SET cert_expires_converted = STR_TO_DATE(cert_expires, '%d/%m/%Y');
    -- Verificar si la certificación está caducada
    IF procedure_date_converted > cert_expires_converted THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La certificación del doctor para este procedimiento se encuentra caducada';
    END IF;
END$$

DELIMITER ;

SELECT * FROM physician; 

-- CASO 1: INSERCIÓN CORRECTA --
-- El doctor 3 (Christopher Turk) tiene el certificado para el procedimiento 1 
-- y además la fecha expiración es después de la fecha indicada.
INSERT INTO undergoes(patientid, procedureid, stayid, date, physicianid, assistingnurseid)
VALUES (100000001, 1, 3215, '15/05/2008', 3, 101);

-- Verificar que se insertó correctamente
SELECT * FROM undergoes 
WHERE patientid = 100000001 AND procedureid = 1 AND date = '15/05/2008';

-- CASO 2: ERROR - Doctor SIN certificación para el procedimiento --
-- El doctor 4 (Percival Cox) NO tiene certificación para el procedimiento 1
-- Esto debería lanzar el error: "El doctor no posee la certificación requerida"
INSERT INTO undergoes(patientid, procedureid, stayid, date, physicianid, assistingnurseid)
VALUES (100000001, 1, 3215, '15/05/2008', 4, 101);

-- CASO 3: ERROR - Doctor con certificación CADUCADA --
-- El doctor 6 (Todd Quinlan) tiene certificación para el procedimiento 5
-- pero expira el 31/12/2007, y vamos a programar para el 15/05/2008
-- Esto debería lanzar el error: "La certificación se encuentra caducada"
INSERT INTO undergoes(patientid, procedureid, stayid, date, physicianid, assistingnurseid)
VALUES (100000001, 5, 3215, '15/05/2008', 6, 101);

-- n) Codifica un procedimiento almacenado denominado physician_report que permita generar
-- un reporte de texto con los pacientes atendidos por un doctor y las medicinas que les han
-- prescrito. El procedimiento recibirá como entrada el identificador del doctor y el rango de
-- fechas sobre las que se desea generar el informe. Se dispondrá de un parámetro de salida
-- de tipo TEXT que contendrá el un informe como el que se muestra a continuación:
-- INFORME DE John Dorian
-- John Smith (24/4/2008)
-- # Procrastin-X
-- John Smith (25/4/2008)
-- # No medications prescribed
-- La primera linea indicará el nombre del doctor. En las lineas sucesivas se indicaría el nombre
-- del paciente atendido y la fecha en la que atendió así como los nombres de los medicamentos
-- prescritos en la consulta. Si no se recetó ningún medicamento se indicará “No medications
-- prescribed”. Las consultas deberán ordenarse cronológicamente. Incluye también todas las
-- sentencias SQL necesarias para probar el procedimiento almacenado.
DELIMITER $$

CREATE PROCEDURE physician_report(IN physician_id INT, IN initial_date VARCHAR(10), IN final_date VARCHAR(10), OUT report_text TEXT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE patient_name VARCHAR(20);
    DECLARE appointment_date VARCHAR(10);
    DECLARE appointment_id INT;
    DECLARE medication_name VARCHAR(20);
    DECLARE has_medication INT;
    -- Cursor para recorrer las citas del médico en el rango de fechas
    DECLARE appointment_cursor CURSOR FOR
        SELECT a.appointmentid, p.name, a.start_dt_time FROM appointments a
		JOIN patient p ON a.patientid = p.ssn
        WHERE a.physicianid = physician_id
		AND STR_TO_DATE(a.start_dt_time, '%d/%m/%Y') BETWEEN STR_TO_DATE(initial_date, '%d/%m/%Y') AND STR_TO_DATE(final_date, '%d/%m/%Y')
        ORDER BY STR_TO_DATE(a.start_dt_time, '%d/%m/%Y');
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Inicializar el reporte con el nombre del médico
	SELECT CONCAT('INFORME DE ', ph.name, '\n') INTO report_text FROM physician ph
	WHERE ph.employeeid = physician_id;
    -- Abrir el cursor
    OPEN appointment_cursor;
    read_loop: LOOP
        FETCH appointment_cursor INTO appointment_id, patient_name, appointment_date;
        IF done THEN
            LEAVE read_loop;
        END IF;
        -- Añadir nombre del paciente y fecha
        SET report_text = CONCAT(report_text, patient_name, ' (', appointment_date, ')\n');
        -- Verificar si hay medicamentos prescritos para esta cita
		SELECT COUNT(*) INTO has_medication FROM prescribes
		WHERE appointmentid = appointment_id;
		IF has_medication > 0 THEN
            -- Añadir los medicamentos prescritos
            BEGIN
                DECLARE med_done INT DEFAULT FALSE;
                DECLARE med_cursor CURSOR FOR
                
				SELECT m.name FROM prescribes pr
				JOIN medication m ON pr.medicationid = m.code
				WHERE pr.appointmentid = appointment_id;
                    
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET med_done = TRUE;
                
                OPEN med_cursor;
                med_loop: LOOP
                    FETCH med_cursor INTO medication_name;
                    IF med_done THEN
                        LEAVE med_loop;
                    END IF;
                    SET report_text = CONCAT(report_text, '  # ', medication_name, '\n');
                END LOOP;
                
                CLOSE med_cursor;
            END;
        ELSE
            -- No hay medicamentos prescritos
            SET report_text = CONCAT(report_text, '  # No medications prescribed\n');
        END IF;
        -- Añadir línea en blanco entre citas
        SET report_text = CONCAT(report_text, '\n');
    END LOOP;
    
    CLOSE appointment_cursor;
END $$

DELIMITER ;

-- Probar con el médico John Dorian (ID=1) en abril de 2008
CALL physician_report(1, '01/04/2008', '30/04/2008', @report1);
SELECT @report1;

CALL physician_report(2, '01/01/2023', '31/12/2023', @report2);
SELECT @report2;

CALL physician_report(9, '01/04/2008', '30/04/2008', @report3);
SELECT @report3;

-- Ver las citas y prescripciones para verificar de John Dorian (ID = 1)
SELECT a.appointmentid, p.name AS patient, ph.name AS physician, a.start_dt_time, m.name AS medication
FROM appointments a
JOIN patient p ON a.patientid = p.ssn
JOIN physician ph ON a.physicianid = ph.employeeid
LEFT JOIN prescribes pr ON a.appointmentid = pr.appointmentid
LEFT JOIN medication m ON pr.medicationid = m.code
WHERE ph.employeeid = 1
AND STR_TO_DATE(a.start_dt_time, '%d/%m/%Y') BETWEEN '2008-04-01' AND '2008-04-30'
ORDER BY STR_TO_DATE(a.start_dt_time, '%d/%m/%Y');


