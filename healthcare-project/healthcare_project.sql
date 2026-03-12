# ---------------------------------------------------------
# Create Database for Healthcare Project
# ---------------------------------------------------------
CREATE DATABASE healthcare;
USE healthcare;

# View the raw dataset table imported from CSV
SELECT * FROM healthcare_dataset;


# ---------------------------------------------------------
# Create Patient Table
# This table stores basic patient information
# ---------------------------------------------------------
CREATE TABLE patient_dataset (
Patient_name VARCHAR(50),
Age INT,
Gender VARCHAR(10),
BloodType VARCHAR(5),
RoomNumber INT
);

# Insert patient data from the main healthcare dataset
INSERT INTO patient_dataset (
    Patient_name,
    Age,
    Gender,
    BloodType,
    RoomNumber
)
SELECT
    h.`Name` AS Patient_name,
    h.Age AS Age,
    h.Gender AS Gender,
    h.`Blood Type` AS BloodType,
    h.`Room Number` AS RoomNumber
FROM healthcare_dataset h;



# ---------------------------------------------------------
# Create Doctors Table
# Stores doctor names and associated hospital
# ---------------------------------------------------------
CREATE TABLE doctors_dataset (
doctor_name VARCHAR(50),
hospital VARCHAR(50)
);

# Insert doctor information from the main dataset
INSERT INTO doctors_dataset (
doctor_name,
hospital
)
SELECT
    h.Doctor AS doctor_name,
    h.Hospital AS hospital
FROM healthcare_dataset h;



# ---------------------------------------------------------
# Create Appointment Table
# Stores patient admission details and appointment records
# ---------------------------------------------------------
CREATE TABLE appointment_dataset (
patient_appointed VARCHAR(30),
doctors_appointment VARCHAR(30),
Date_of_Admission VARCHAR(30),
admission_type VARCHAR(50),
date_of_discharge VARCHAR(50)
);

# Insert appointment records
INSERT INTO appointment_dataset (
patient_appointed,
doctors_appointment,
Date_of_Admission,
admission_type,
date_of_discharge
)
SELECT
    h.`Name` AS patient_appointed,
    h.`Doctor` AS doctors_appointment,
    h.`Date of Admission` AS Date_of_Admission,
    h.`Admission Type` AS admission_type,
    h.`Discharge Date` AS date_of_discharge
FROM healthcare_dataset h;



# ---------------------------------------------------------
# Create Treatment Table
# Contains patient medical condition and treatment details
# ---------------------------------------------------------
CREATE TABLE treatment_dataset (
patient_name VARCHAR(30),
medical_condition VARCHAR(30),
test_result VARCHAR(50),
medication VARCHAR(50)
);

# Insert treatment information from the dataset
INSERT INTO treatment_dataset (
    patient_name,
    medical_condition,
    test_result,
    medication
)
SELECT
    h.`Name` AS patient_name,
    h.`Medical Condition` AS medical_condition,
    h.`Test Results` AS test_result,
    h.`Medication` AS medication
FROM healthcare_dataset h;



# ---------------------------------------------------------
# Create Billing Table
# Stores insurance provider and billing amount
# ---------------------------------------------------------
CREATE TABLE billing_dataset (
patient_name VARCHAR(30),
insurance_provided VARCHAR(30),
billing_amount VARCHAR(50)
);

# Insert billing information
INSERT INTO billing_dataset (
 patient_name,
 insurance_provided,
 billing_amount
)
SELECT
	h.`Name` AS patient_name,
    h.`Insurance Provider` AS insurance_provided,
    h.`Billing Amount` AS billing_amount
FROM healthcare_dataset h;



# =========================================================
# ANALYTICAL QUERIES
# =========================================================


# ---------------------------------------------------------
# 1️⃣ Average Treatment Cost per Department
# Calculates the average billing amount for each medical condition
# ---------------------------------------------------------
CREATE TABLE average_Treatment_cost_per_department(
department VARCHAR(20),
average_cost FLOAT
);

INSERT INTO average_treatment_cost_per_department (department, average_cost)

SELECT
    t.medical_condition AS department,
    AVG(b.billing_amount) AS average_cost
FROM treatment_dataset t
JOIN billing_dataset b
ON t.patient_name = b.patient_name
GROUP BY t.medical_condition
ORDER BY average_cost DESC;



# ---------------------------------------------------------
# 2️⃣ Top Performing Doctor Per Month
# Counts how many patients each doctor treated per month
# ---------------------------------------------------------
CREATE TABLE Top_performing_doctor_per_month (
    month_year VARCHAR(10),
    top_doctor VARCHAR(50),
    performing_count INT
);

INSERT INTO Top_performing_doctor_per_month
(month_year, top_doctor, performing_count)

SELECT
DATE_FORMAT(a.Date_of_Admission,'%Y-%m') AS month_year,
d.doctor_name AS top_doctor,
COUNT(*) AS performing_count
FROM doctors_dataset d
JOIN appointment_dataset a
ON a.doctors_appointment = d.doctor_name
GROUP BY month_year, d.doctor_name
ORDER BY performing_count DESC;



# ---------------------------------------------------------
# 3️⃣ Readmission Rate Analysis
# Identifies patients who were admitted again after discharge
# Uses LEAD() window function to detect the next admission
# ---------------------------------------------------------
CREATE TABLE Readmission_rate_analysis (
patient_name VARCHAR(30),
first_admission VARCHAR(30),
second_admission VARCHAR(30)
);

INSERT INTO Readmission_rate_analysis
(patient_name, first_admission, second_admission)

SELECT
p.Patient_name,
a.Date_of_Admission AS first_admission,
LEAD(a.Date_of_Admission) OVER(
    PARTITION BY p.Patient_name
    ORDER BY a.Date_of_Admission
) AS second_admission
FROM patient_dataset p
JOIN appointment_dataset a
ON p.Patient_name = a.patient_appointed;


