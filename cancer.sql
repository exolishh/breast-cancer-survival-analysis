CREATE DATABASE breast_cancer_analysis;
USE breast_cancer_analysis;

CREATE TABLE breast_cancer (
    age_group VARCHAR(20),
    sex VARCHAR(10),
    year_diagnosis INT,
    primary_site VARCHAR(100),
    histologic_type INT,
    grade VARCHAR(50),
    summary_stage VARCHAR(50),
    vital_status VARCHAR(10),
    survival_months FLOAT,
    cause_specific_death VARCHAR(100),
    radiation VARCHAR(100),
    race VARCHAR(100),
    vital_status_binary INT,
    grade_known INT,
    grade_clean VARCHAR(50)
);

USE breast_cancer_analysis;
SHOW TABLES;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/breast_cancer_cleaned.csv'
INTO TABLE breast_cancer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM breast_cancer;

USE breast_cancer_analysis;
#Overall summary statistics
SELECT 
    COUNT(*) AS total_patients,
    SUM(vital_status_binary) AS total_deaths,
    ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct,
    ROUND(AVG(survival_months), 1) AS avg_survival_months,
    MIN(year_diagnosis) AS first_year,
    MAX(year_diagnosis) AS last_year
FROM breast_cancer;

#Mortality rate by cancer stage
SELECT 
    summary_stage,
    COUNT(*) AS total_patients,
    SUM(vital_status_binary) AS total_deaths,
    ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct,
    ROUND(AVG(survival_months), 1) AS avg_survival_months
FROM breast_cancer
GROUP BY summary_stage
ORDER BY mortality_rate_pct DESC;

#Mortality rate by race
SELECT 
    race,
    COUNT(*) AS total_patients,
    SUM(vital_status_binary) AS total_deaths,
    ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct,
    ROUND(AVG(survival_months), 1) AS avg_survival_months
FROM breast_cancer
WHERE race != 'Unknown'
GROUP BY race
HAVING COUNT(*) > 100
ORDER BY mortality_rate_pct DESC;

#Mortality by stage AND race combined
SELECT 
    summary_stage,
    race,
    COUNT(*) AS total_patients,
    ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct,
    ROUND(AVG(survival_months), 1) AS avg_survival_months
FROM breast_cancer
WHERE summary_stage IN ('Localized', 'Regional', 'Distant')
    AND race IN ('Non-Hispanic Black', 'Non-Hispanic White', 
                 'Hispanic (All Races)', 'Non-Hispanic Asian or Pacific Islander')
GROUP BY summary_stage, race
ORDER BY summary_stage, mortality_rate_pct DESC;

#Window function: Rank races by mortality within each stage
SELECT 
    summary_stage,
    race,
    total_patients,
    mortality_rate_pct,
    RANK() OVER (PARTITION BY summary_stage 
                 ORDER BY mortality_rate_pct DESC) AS mortality_rank
FROM (
    SELECT 
        summary_stage,
        race,
        COUNT(*) AS total_patients,
        ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct
    FROM breast_cancer
    WHERE summary_stage IN ('Localized', 'Regional', 'Distant')
        AND race IN ('Non-Hispanic Black', 'Non-Hispanic White',
                     'Hispanic (All Races)', 'Non-Hispanic Asian or Pacific Islander')
    GROUP BY summary_stage, race
) ranked
ORDER BY summary_stage, mortality_rank;

#CTE: Year over year change in diagnoses
WITH yearly_cases AS (
    SELECT 
        year_diagnosis,
        COUNT(*) AS total_cases,
        SUM(vital_status_binary) AS total_deaths
    FROM breast_cancer
    GROUP BY year_diagnosis
),
yoy_change AS (
    SELECT 
        year_diagnosis,
        total_cases,
        total_deaths,
        LAG(total_cases) OVER (ORDER BY year_diagnosis) AS prev_year_cases,
        ROUND((total_cases - LAG(total_cases) OVER (ORDER BY year_diagnosis)) 
              / LAG(total_cases) OVER (ORDER BY year_diagnosis) * 100, 1) AS yoy_change_pct
    FROM yearly_cases
)
SELECT * FROM yoy_change
ORDER BY year_diagnosis;

# CTE: Survival percentile by stage
WITH survival_stats AS (
    SELECT 
        summary_stage,
        survival_months,
        vital_status,
        NTILE(4) OVER (PARTITION BY summary_stage 
                       ORDER BY survival_months) AS survival_quartile,
        ROUND(AVG(survival_months) OVER 
              (PARTITION BY summary_stage), 1) AS avg_survival_by_stage,
        ROUND(MAX(survival_months) OVER 
              (PARTITION BY summary_stage), 1) AS max_survival_by_stage
    FROM breast_cancer
    WHERE summary_stage IN ('Localized', 'Regional', 'Distant')
)
SELECT 
    summary_stage,
    survival_quartile,
    COUNT(*) AS patients,
    ROUND(AVG(survival_months), 1) AS avg_survival_months,
    avg_survival_by_stage,
    max_survival_by_stage
FROM survival_stats
GROUP BY summary_stage, survival_quartile, 
         avg_survival_by_stage, max_survival_by_stage
ORDER BY summary_stage, survival_quartile;

#High risk patient profile using CTE + CASE
WITH patient_risk AS (
    SELECT 
        age_group,
        race,
        summary_stage,
        radiation,
        survival_months,
        vital_status_binary,
        CASE 
            WHEN summary_stage = 'Distant' THEN 'High Risk'
            WHEN summary_stage = 'Regional' 
                AND race = 'Non-Hispanic Black' THEN 'High Risk'
            WHEN summary_stage = 'Regional' THEN 'Medium Risk'
            WHEN summary_stage = 'Localized' THEN 'Low Risk'
            ELSE 'Unknown'
        END AS risk_category
    FROM breast_cancer
)
SELECT 
    risk_category,
    COUNT(*) AS total_patients,
    ROUND(AVG(vital_status_binary) * 100, 1) AS mortality_rate_pct,
    ROUND(AVG(survival_months), 1) AS avg_survival_months
FROM patient_risk
WHERE risk_category != 'Unknown'
GROUP BY risk_category
ORDER BY mortality_rate_pct DESC;
