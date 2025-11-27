-- Ejercicio d
SET SQL_SAFE_UPDATES = 0;
UPDATE medication
SET medication.description = CONCAT(medication.description,' Possible discontinuation')
WHERE medication.code 
	NOT IN( SELECT T.code 
		FROM ( SELECT distinct m.code
			FROM medication m 
			JOIN prescribes pres ON pres.medicationid = m.code
			JOIN physician p ON pres.physicianid = p.employeeid
			JOIN affiliated_with aff ON aff.physicianid = p.employeeid
			JOIN department ON department.departmentid = aff.departmentid
			WHERE department.name = 'General Medicine' 
			AND (YEAR(str_to_date(pres.date,'%d/%m/%Y')) = 2023 OR YEAR(str_to_date(pres.date,'%d/%m/%Y')) = 2024)
        ) AS T
)		AND medication.description NOT LIKE '%Possible discontinuation%';
     
    UPDATE medication
    SET medication.description = "N/A";

    SELECT * FROM medication m 
			JOIN prescribes pres ON pres.medicationid = m.code
			JOIN physician p ON pres.physicianid = p.employeeid
			JOIN affiliated_with aff ON aff.physicianid = p.employeeid
			JOIN department ON department.departmentid = aff.departmentid;
    
-- Ejercicio e
SELECT doctor.name,COUNT(*) AS num_intervenciones,SUM(medical_procedure.cost) AS 'coste total',AVG(medical_procedure.cost) AS 'coste promedio'
FROM physician doctor
	JOIN undergoes ON undergoes.physicianid = doctor.employeeid
    JOIN medical_procedure ON undergoes.procedureid = medical_procedure.code
    GROUP BY doctor.employeeid,doctor.name
    ORDER BY num_intervenciones DESC;
    
-- Ejercicio k

-- Añadimos la eliminación por cascada a todas aquellas tablas que tengan como FK el id de un paciente
ALTER TABLE undergoes
ADD FOREIGN KEY (patientId) REFERENCES patient(ssn)
ON DELETE CASCADE;

ALTER TABLE stay
ADD FOREIGN KEY (patientId) REFERENCES patient(ssn)
ON DELETE cascade;

ALTER TABLE prescribes
ADD FOREIGN KEY (patientId) REFERENCES patient(ssn)
ON DELETE cascade;

ALTER TABLE appointments
ADD FOREIGN KEY (patientId) REFERENCES patient(ssn)
ON DELETE cascade;

-- Creamos trigger:
DELIMITER $$
CREATE TRIGGER eliminar_paciente 
BEFORE DELETE ON patient
FOR EACH ROW
BEGIN
	-- No tener citas o procedimientos a futuro.
	DECLARE futuras_citas INTEGER;
    DECLARE futuros_procedimientos INTEGER;
    -- No tener ningún tipo de actividad médica en los últimos tres años (Desde 2025 hasta 2022)
    DECLARE consultas_actuales INTEGER;
    DECLARE procedimientos_actuales integer;
    DECLARE preiscriciones_actuales INTEGER;
    DECLARE estancias_actuales integer;
    -- Calculo de la fecha actual - 3 años para toda la actividad médica actual.
    DECLARE fecha_limite DATE;
    SET fecha_limite = DATE_SUB(CURDATE(), INTERVAL 3 YEAR);
    
    -- Actividad médica futura:
    SELECT COUNT(*) INTO futuras_citas
    FROM appointments
    WHERE patientid = OLD.ssn
    AND str_to_date(appointments.start_dt_time, '%d/%m/%Y') >= CURDATE();
    if futuras_citas > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene futuras citas pendientes';
    END IF;
    
    SELECT COUNT(*) INTO futuros_procedimientos
    FROM undergoes
    WHERE patientid = OLD.ssn
    AND str_to_date(undergoes.date, '%d/%m/%Y') >= CURDATE();
    if futuros_procedimientos > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene futuras procedimientos pendientes';
    END IF;
    
    -- Actividad médica actual
    SELECT COUNT(*) INTO consultas_actuales
    FROM appointments
    WHERE patientid = OLD.ssn
    AND str_to_date(appointments.start_dt_time, '%d/%m/%Y') >= fecha_limite;
    if consultas_actuales > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene 1 o más consultas en estos últimos tres años';
    END IF;
    
    SELECT COUNT(*) INTO procedimientos_actuales
    FROM undergoes
    WHERE patientid = OLD.ssn
    AND str_to_date(undergoes.date, '%d/%m/%Y') >= fecha_limite;
    if procedimientos_actuales > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene 1 o mas procedimientos en estos últimos tres años';
    END IF;
    
    SELECT COUNT(*) INTO preiscriciones_actuales
    FROM prescribes
    WHERE patientid = OLD.ssn
    AND str_to_date(prescribes.date, '%d/%m/%Y') >= fecha_limite;
    if preiscriciones_actuales > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene 1 o más preiscriciones en estos últimos tres años';
    END IF;
    
    SELECT COUNT(*) INTO estancias_actuales
    FROM stay
    WHERE patientid = OLD.ssn
    AND str_to_date(stay.start_time, '%d/%m/%Y') >= fecha_limite;
    if estancias_actuales > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error el paciente no se puede borrar ya que tiene 1 o más estancias en estos últimos tres años';
    END IF;
    END $$
    DELIMITER ;
    

-- Insertamos ejemplos para comprobar que funciona 

-- 1. Paciente 1000: ÉXITO (Solo actividad antigua: 01/01/2020)
INSERT INTO patient VALUES (1000, 'Paciente OK', 'Dir. antigua', '111', 111, 100);
INSERT INTO prescribes VALUES (100, 1000, 400, '01/01/2020', NULL, 10);
INSERT INTO stay VALUES (1, 1000, 101, '01/01/2020', '05/01/2020');

-- 2. Paciente 1001: ERROR Cita Futura (appointmentid = 10)
INSERT INTO patient VALUES (1001, 'Error Cita', 'Dir. nueva', '222', 112, 100);
INSERT INTO appointments VALUES (10, 1001, 200, 100, '01/03/2026', '01/03/2026', 'A101'); 

-- 3. Paciente 1002: ERROR Procedimiento Futuro (stayid = 11)
-- 1. Insertar el Paciente (Si no existe)
INSERT INTO patient VALUES (1002, 'Error Proc. Futuro', 'Dir. nueva', '333', 113, 100);
INSERT INTO stay VALUES (11, 1002, 101, '01/01/2025', '05/01/2025');
INSERT INTO undergoes VALUES (1002, 300, 11, '01/06/2026', 100, 200);

-- 4. Paciente 1003: ERROR Prescripción Reciente (appointmentid = 12)
INSERT INTO patient VALUES (1003, 'Presc. Reciente', 'Dir. nueva', '444', 114, 100);
INSERT INTO appointments VALUES (12, 1003, 200, 100, '01/05/2024', '01/05/2024', 'A102'); 
INSERT INTO prescribes VALUES (100, 1003, 400, '01/05/2024', 12, 10); 

-- 5. Paciente 1004: ERROR Estancia Reciente (stayid = 13)
INSERT INTO patient VALUES (1004, 'Estancia Reciente', 'Dir. nueva', '555', 115, 100);
INSERT INTO stay VALUES (13, 1004, 101, '01/01/2023', '05/01/2023');

DELETE FROM patient WHERE ssn = 1004;
    
    
    
    
    
    
  
    
    
			