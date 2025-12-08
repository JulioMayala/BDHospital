-- Ej 3.1

CREATE VIEW medicamentos_prescritos 
AS SELECT med.code, med.name, med.brand, patient.name AS paciente, pres.date, doctor.name As doctor, patient.ssn AS id_paciente
FROM medication med
	JOIN prescribes pres ON pres.medicationid = med.code
    JOIN patient ON patient.ssn = pres.patientid
    JOIN physician doctor ON doctor.employeeid = pres.physicianid;

SELECT * FROM medicamentos_prescritos;
    
-- 3.2 Creación de usuario y darle permisos de lectura de la vista

CREATE USER 'prueba123' IDENTIFIED BY 'SQL123';
	
GRANT SELECT ON medicamentos_prescritos TO 'prueba123';

SHOW GRANTS FOR 'prueba123';