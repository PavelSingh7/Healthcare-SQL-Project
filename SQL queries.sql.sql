select * from payers;
select * from supplies;
select * from immunizations;
select* from conditions;
select * from encounters;
select* from patients;


--lets check total number of patients
Select COUNT(*) as Total_Number
from patients

-- lets check the patients based on their Age Group
SELECT
    AgeGroup,
    GENDER,
    COUNT(*) AS PatientCount
FROM (
    SELECT
        CASE
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 0 AND 4 THEN '0-4'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 5 AND 14 THEN '5-14'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 15 AND 24 THEN '15-24'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 25 AND 34 THEN '25-34'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 35 AND 44 THEN '35-44'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 45 AND 54 THEN '45-54'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) BETWEEN 55 AND 64 THEN '55-64'
            WHEN DATEDIFF(YEAR, birthdate, ISNULL(deathdate, GETDATE())) >= 65 THEN '65+'
            ELSE 'Unknown'
        END AS AgeGroup,
        GENDER
    FROM patients
) AS Subquery
GROUP BY AgeGroup, GENDER
ORDER BY AgeGroup, GENDER;

--average age of the patients
Select  AVG(DATEDIFF(YEAR,BIRTHDATE,ISNULL(DEATHDATE,GETDATE()))) AS AVERAGE_AGE
from patients;

--Number of enconters 
Select ENCOUNTERCLASS,COUNT(ENCOUNTERCLASS) AS Number_of_Encounters from encounters
Group by ENCOUNTERCLASS
Order by COUNT(ENCOUNTERCLASS) DESC;

--average time of stay in hospital 
Select 
ENCOUNTERCLASS, AVG(DATEDIFF(MINUTE,START,STOP)) as Average_minute_stay
from encounters
GROUP BY ENCOUNTERCLASS
Order by Average_minute_stay DESC;


-- number of encounter based on month
SELECT 
    MONTH(CAST(START AS DATETIME)) AS Month_of_year,
    ENCOUNTERCLASS,
    COUNT(ENCOUNTERCLASS) AS Number_of_Encounters
FROM encounters
GROUP BY MONTH(CAST(START AS DATETIME)), ENCOUNTERCLASS
ORDER BY  ENCOUNTERCLASS , Month_of_year;


--6.average base cost per encounter.
select ENCOUNTERCLASS,AVG(BASE_ENCOUNTER_COST) as Average_cost
from encounters
Group by ENCOUNTERCLASS;

--- Patients Analysis
--Timeline of a patients based on his encounters and conditions
SELECT 'Encounter' AS event_type, START AS event_date, DESCRIPTION AS event_description
FROM encounters
WHERE PATIENT = '00126cb9-8460-4747-e302-c3609684531e'
UNION
SELECT 'Condition' AS event_type, START AS event_date, DESCRIPTION AS event_description
FROM conditions
WHERE PATIENT = '00126cb9-8460-4747-e302-c3609684531e'
ORDER BY event_date, event_type DESC;

--	Identify patients with a history of hospital readmission:
WITH PatientEncounterCounts AS (
    SELECT PATIENT, COUNT(*) AS encounter_count
    FROM encounters
    GROUP BY PATIENT
    HAVING COUNT(*) > 1
)

SELECT patients.Id, patients.FIRST, PatientEncounterCounts.encounter_count
FROM patients 
JOIN PatientEncounterCounts  ON patients.Id = PatientEncounterCounts.PATIENT;

-- Analyze the association between specific conditions and subsequent encounters
SELECT c.DESCRIPTION AS condition_description,
       e.ENCOUNTERCLASS AS encounter_type,
       COUNT(*) AS occurrence_count
FROM conditions c
JOIN encounters e ON c.PATIENT = e.PATIENT
WHERE c.DESCRIPTION IN ('Sprain of ankle', 'Hypertension') 
GROUP BY c.DESCRIPTION, e.ENCOUNTERCLASS
ORDER BY c.DESCRIPTION, e.ENCOUNTERCLASS;

--Cost Analysis:
--Total Healthcare Expenses Per Patient:
SELECT p.Id, p.FIRST, CAST(SUM(e.TOTAL_CLAIM_COST) AS DECIMAL(10, 2)) AS total_expenses
FROM patients p
LEFT JOIN encounters e ON p.Id = e.PATIENT
GROUP BY p.Id, p.FIRST
ORDER BY total_expenses DESC;

--Top Payers by Total Reimbursements:
Select payers.NAME ,CAST(Sum(encounters.PAYER_COVERAGE) AS decimal(10,2)) AS Total_Reimbursement
from payers
inner join encounters
on payers.Id=encounters.PAYER
Group by payers.NAME
Order by Total_Reimbursement DESC;

--Average Reimbursement per Procedure:

SELECT e.DESCRIPTION As Encounter_Desciption, Cast(AVG(e.PAYER_COVERAGE) As decimal(10,2)) AS avg_reimbursement
FROM encounters e
GROUP BY e.DESCRIPTION
ORDER BY avg_reimbursement DESC;

