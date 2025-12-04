-- Consulta F: Obtener los doctores (nombre y posición) que han realizado
-- todos los procedimientos médicos con coste superior a 5000 y que haya realizado más de 3
-- procedimientos médicos de cualquiera de los tipos en total.
SELECT name, position
FROM physician
WHERE employeeid IN (SELECT physicianid
					FROM undergoes u JOIN medical_procedure m ON u.procedureid = m.code
					WHERE cost>5000
					GROUP BY physicianid
					HAVING (COUNT(DISTINCT procedureid) =(SELECT COUNT(DISTINCT code)
							FROM medical_procedure
							WHERE cost>5000) 
							AND physicianid IN (SELECT physicianid
									FROM undergoes
									GROUP BY physicianid
									HAVING COUNT(*)>3))) ;
-- Uno los undergoes con los procedimientos y elijo aquellos que cuesten más de 5000, los agrupo por doctor y
-- cuento cuantos diferentes ha realizado cada uno, luego elijo aquellos doctores que su número de diferentes
-- coincida con el número de tratamientos caros y hayan realizado más de 3. Uno a doctores y obtengo nombre y posición

	
-- Consulta G: Obtener el personal de enfermería que siempre han estado asignadas a turnos en el mismo sitio (bloque y piso) 
-- y que además, si han participado en procedimientos médicos, siempre haya sido con el mismo doctor.
SELECT nurseid
FROM on_call o LEFT JOIN undergoes u ON o.nurseid=u.assistingnurseid
GROUP BY nurseid
HAVING (COUNT(DISTINCT blockcodeid)=1 
	AND COUNT(DISTINCT blockfloorid)=1 
    AND COUNT(DISTINCT physicianid)<=1);
-- Se hace un left join de las tablas on_call y undergoes ya que aquellas enfermeras que no tengan procedimiento pero
-- si que mantengan el turno son validas, agrupo por enfermeras y filtro con las condiciones solicitadas en el enunciado.


-- Consulta L: Codifica una función almacenada denominada total_cost_patient que calcule y devuelva el coste
-- total acumulado de todos los procedimientos médicos registrados en la tabla undergoes que un paciente,
-- pasado como parámetro, haya recibido. Infiere los tipos de datos tanto del coste total
-- como del identificador del paciente a partir de los datos con los que las tablas fueron creadas.
DELIMITER $$
CREATE FUNCTION total_cost_patient(pcpid INTEGER)
RETURNS INTEGER
DETERMINISTIC
BEGIN
	DECLARE total INTEGER;
    SELECT sum(m.cost) INTO total
    FROM undergoes u JOIN medical_procedure m ON u.procedureid=m.code
    WHERE u.patientid=pcpid;
	IF total IS NULL THEN
		SET total = 0;
	END IF;
    RETURN (total);
END $$
DELIMITER ;

-- Haciendo uso de la función, liste los datos del paciente que mayor coste total acumulado en procedimientos médicos.
	SELECT *, total_cost_patient(p.ssn)
	FROM patient p
	WHERE total_cost_patient(p.ssn) =(SELECT MAX(total_cost_patient(ssn))
	FROM patient)
