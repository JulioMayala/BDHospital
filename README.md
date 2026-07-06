# Hospital Database Management System ("La Última Esperanza")

## About the Project
Team-based academic project focused on the architecture, management, and data exploitation of a high-capacity hospital. The system ranges from the conceptual design of the information to the implementation of complex business logic in the database and data export through a backend layer.

## Architecture and Technologies
* **Database:** MySQL / MariaDB.
* **Modeling:** Entity-Relationship (ER) Diagram using Chen notation.
* **Backend:** Java (Data access and export).
* **Infrastructure:** Containerized database deployment using Docker.

## Main Technical Features

### 1. Complex Data Modeling
Design and implementation of a relational model supporting the operations of multiple departments:
* Management of patients, doctors, nursing staff, and on-call shifts.
* Control of consultations, medical prescriptions, and automatic dispensers.
* Oncology module: control of chemotherapy cycles, bed/chair management, and internal logistics.
* Traceability of stays and medical procedures.

### 2. Database Business Logic (Advanced SQL)
* **Security and Integrity Triggers:** Development of triggers to prevent accidental deletion of patients with active medical histories (3-year control window) and strict validation of valid medical certifications before scheduling interventions.
* **Stored Functions:** Implementation of functions such as `calc_stay_cost` and `total_cost_patient` for dynamic calculation of hospital costs (differentiating room types such as ICU, double, etc.).
* **Stored Procedures:** Creation of the `physician_report` procedure to automatically generate plain text reports of patient histories and prescriptions per doctor.

### 3. Application and Export Layer (Java)
Development of a Java program connected to the database that allows querying medical prescription views and exporting the filtered results by patient to **CSV** and **XML** formats.
