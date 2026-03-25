-- Create and select the database
create database ibm_hr;
use ibm_hr;
-- View raw dataset
select * from `wa_fn-usec_-hr-employee-attrition`;
-- Rename table for easier usage
RENAME TABLE `wa_fn-usec_-hr-employee-attrition` TO hr_employee_attrition;
select * from hr_employee_attrition;
-- Fix encoding issue in column name (Age)
ALTER TABLE hr_employee_attrition
CHANGE `ï»¿Age` Age INT;
-- Create structured employee table
create table employee_details (
Employee_Number int,
age int,
gender varchar(10),
job_role varchar(30),
Marital_Status varchar(30),
Department varchar(30),
DistanceFromHome int,
education int,
EducationField varchar(30),
MonthlyIncome int,
NumCompaniesWorked int,
EmployeeCount int,
TotalWorkingYears int,
TrainingTimesLastYear int,
PercentSalaryHike int,
PerformanceRating int);

-- Insert cleaned and selected columns from raw dataset
insert into employee_details  (
Employee_Number,
age,
gender,
job_role,
Marital_Status,
Department,
DistanceFromHome,
education,
EducationField,
MonthlyIncome,
NumCompaniesWorked,
EmployeeCount,
TotalWorkingYears,
TrainingTimesLastYear,
PercentSalaryHike,
PerformanceRating)
select
h.EmployeeNumber as Employee_Number  ,
h.Age as age ,
h.gender as gender ,
h.JobLevel as job_role,
h.MaritalStatus as Marital_Status,
h.Department as Department ,
h.DistanceFromHome as DistanceFromHome,
h.education as education  ,
h.EducationField as  EducationField,
h.MonthlyIncome as MonthlyIncome,
h.NumCompaniesWorked as NumCompaniesWorked  ,
h.EmployeeCount as EmployeeCount ,
h.TotalWorkingYears as TotalWorkingYears,
h.TrainingTimesLastYear as TrainingTimesLastYear,
h.PercentSalaryHike as PercentSalaryHike,
h.PerformanceRating as PerformanceRating
from
hr_employee_attrition h;
-- Add column for average years per company
ALTER TABLE employee_details
MODIFY avg_years_per_company DECIMAL(5,2);
-- Calculate average tenure per company
UPDATE employee_details
SET avg_years_per_company = 
    CASE 
        WHEN NumCompaniesWorked = 0 THEN NULL
        ELSE TotalWorkingYears / NumCompaniesWorked
    END;
-- Department-level information
CREATE TABLE department_details(
Employee_Number int,
Department varchar(20),
JobLevel int,
JobRole varchar(30)
);
ALTER TABLE department_details
MODIFY Department VARCHAR(50);

insert into department_details(
Employee_Number ,
Department ,
JobLevel ,
JobRole 
)
select
h.EmployeeNumber as Employee_Number,
h.Department as Department  ,
h.JobLevel as JobLevel ,
h.JobRole as JobRole 
from
hr_employee_attrition h;

-- Attrition-related metrics
CREATE TABLE attrition_details(
Employee_Number int,
attrition varchar(10),
EnvironmentSatisfaction int,
JobSatisfaction int,
RelationshipSatisfaction int,
YearsSinceLastPromotion int
);

insert into attrition_details(
Employee_Number ,
attrition ,
EnvironmentSatisfaction ,
JobSatisfaction ,
RelationshipSatisfaction ,
YearsSinceLastPromotion 
)
select
h.EmployeeNumber as Employee_Number,
h.attrition as attrition ,
h.EnvironmentSatisfaction as EnvironmentSatisfaction ,
h.JobSatisfaction as JobSatisfaction ,
h.RelationshipSatisfaction as RelationshipSatisfaction,
h.YearsSinceLastPromotion asYearsSinceLastPromotion 
from
hr_employee_attrition h;
-- Promotion and work conditions
CREATE TABLE promotion_details(
Employee_Number int,
Over18 varchar(1),
OverTime varchar(5),
PercentSalaryHike int,
BusinessTravel varchar(20),
NumCompaniesWorked int,
JobInvolvement int,
StandardHours int
);
insert into promotion_details(
Employee_Number,
Over18 ,
OverTime,
PercentSalaryHike,
BusinessTravel,
NumCompaniesWorked ,
JobInvolvement ,
StandardHours 
)
select
h.EmployeeNumber as Employee_Number,
h.Over18 as Over18   ,
h.OverTime as OverTime,
h.PercentSalaryHike as PercentSalaryHike,
h.BusinessTravel as BusinessTravel,
h.NumCompaniesWorked as NumCompaniesWorked ,
h.JobInvolvement as JobInvolvement ,
h.StandardHours as StandardHours 
from 
hr_employee_attrition h;

-- Attendance-related salary metrics
CREATE TABLE attendance_details(
Employee_Number int,
HourlyRate int,
DailyRate int,
MonthlyRate int
);

insert into attendance_details( 
Employee_Number ,
HourlyRate ,
DailyRate ,
MonthlyRate
)
select 
h.EmployeeNumber as Employee_Number,
h.HourlyRate as HourlyRate ,
h.DailyRate as DailyRate,
h.MonthlyRate as MonthlyRate
from 
hr_employee_attrition h;


 create table Predict_attrition_risk (
Employee_Number int,
attrition_result varchar(10)
);
ALTER TABLE Predict_attrition_risk
MODIFY attrition_result VARCHAR(20);
-- Classify employees into risk categories
insert into Predict_attrition_risk (
Employee_Number,
attrition_result
)
SELECT 
    Employee_Number,
    CASE 
        WHEN MonthlyIncome < 3000 
             AND PercentSalaryHike > 15 
        THEN 'High Risk'

        WHEN MonthlyIncome BETWEEN 3000 AND 6000 
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS attrition_result
FROM employee_details;  
      

-- Compare employee salary with department average
SELECT 
    Employee_Number,
    Department,
    MonthlyIncome,
    
    AVG(MonthlyIncome) OVER(PARTITION BY Department) AS MonthlyIncomey,

    CASE 
        WHEN AVG(MonthlyIncome) OVER(PARTITION BY Department) < 6000
        THEN 'High Risk'
        ELSE 'Low Risk'
    END AS MonthlyIncome

FROM employee_details;

-- Compare current salary with previous employee (ordered)
SELECT 
    Employee_Number,
    NumCompaniesWorked,
    MonthlyIncome,
    LAG(MonthlyIncome) OVER(ORDER BY NumCompaniesWorked) AS prev_salary
FROM employee_details;


-- Divide employees into salary quartiles
SELECT 
    Employee_Number,
    MonthlyIncome,
    NTILE(4) OVER (ORDER BY MonthlyIncome) AS salary_quartile
FROM employee_details;

-- Find years since last promotion
SELECT 
    Employee_Number,
    MAX(YearsSinceLastPromotion) AS years_no_promo
FROM attrition_details
GROUP BY Employee_Number;


-- Compare employee salary with department average + promotion gap

SELECT 
    e.Employee_Number,
    e.Department,
    e.MonthlyIncome,
    e.YearsSinceLastPromotion,
    CASE 
        WHEN e.MonthlyIncome < dept_avg_salary
             AND e.YearsSinceLastPromotion > 3
		THEN 'High Risk'
        ELSE 'Low Risk'
    END AS Attrition_Risk
FROM employee_details e

JOIN (
    SELECT 
        Department,
        AVG (MonthlyIncome) AS dept_avg_salary
    FROM employee_details
    GROUP BY Department 
) d ON e.Department = d.Department;





INSERT INTO Predict_attrition_risk (
    Employee_Number,
    attrition_result
)
SELECT 
    Employee_Number,
    CASE 
        WHEN MonthlyIncome < 3000 
             AND PercentSalaryHike > 15 
        THEN 'High Risk'

        WHEN MonthlyIncome BETWEEN 3000 AND 6000 
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END
FROM employee_details;

-- Estimate previous salary before hike
SELECT 
    Employee_Number,
    MonthlyIncome,
    PercentSalaryHike,

    ROUND(
        MonthlyIncome / (1 + PercentSalaryHike / 100), 
    2) AS estimated_previous_salary

FROM employee_details;


-- Calculate salary growth amount

SELECT 
    Employee_Number,
    MonthlyIncome,
    PercentSalaryHike,

    MonthlyIncome - 
    (MonthlyIncome / (1 + PercentSalaryHike / 100)) 
    AS salary_growth

FROM employee_details;

-- Calculate growth_status amount
SELECT 
    Employee_Number,
    YearsSinceLastPromotion,
    MonthlyIncome,

    CASE 
        WHEN YearsSinceLastPromotion > 3 THEN 'Stagnant Salary'
        ELSE 'Growing Salary'
    END AS growth_status

FROM employee_details;

-- Categorize promotion delay
SELECT 
    Employee_Number,
    MonthlyIncome,
    PercentSalaryHike,
    YearsSinceLastPromotion,

    CASE 
        WHEN PercentSalaryHike < 10 
             AND YearsSinceLastPromotion > 3 
        THEN 'Low Growth'

        WHEN PercentSalaryHike BETWEEN 10 AND 20 
        THEN 'Moderate Growth'

        ELSE 'High Growth'
    END AS salary_growth_category

FROM employee_details;


-- Average salary and hike per department
SELECT 
    Department,
    AVG(PercentSalaryHike) AS avg_hike,
    AVG(MonthlyIncome) AS avg_salary
FROM employee_details
GROUP BY Department;

-- Categorize promotion delay

SELECT 
    Employee_Number,
    MonthlyIncome,
    NTILE(4) OVER(ORDER BY MonthlyIncome) AS salary_quartile
FROM employee_details;

-- Categorize years before last promotion

SELECT 
    Employee_Number,
    avg_years_per_company,
    YearsSinceLastPromotion,
    avg_years_per_company - YearsSinceLastPromotion AS years_before_last_promo

FROM employee_details;

-- Categorize promotion_gap_category
SELECT 
    Employee_Number,
    YearsSinceLastPromotion,

    CASE 
        WHEN YearsSinceLastPromotion >= 5 THEN 'High Delay'
        WHEN YearsSinceLastPromotion BETWEEN 2 AND 4 THEN 'Moderate Delay'
        ELSE 'Low Delay'
    END AS promotion_gap_category

FROM employee_details;



-- Categorize avg_promotion_gap by department

SELECT 
    Department,
    AVG(YearsSinceLastPromotion) AS avg_promotion_gap
FROM employee_details
GROUP BY Department;


-- Promotion gap risk with performance


SELECT 
    Employee_Number,
    Department,
    PerformanceRating,
    YearsSinceLastPromotion,

    CASE 
        WHEN PerformanceRating >= 4 
             AND YearsSinceLastPromotion > 3 
        THEN 'High Risk (Promotion Delay)'

        WHEN YearsSinceLastPromotion BETWEEN 2 AND 3 
        THEN 'Moderate Risk'

        ELSE 'Low Risk'
    END AS promotion_gap_risk

FROM employee_details;






 