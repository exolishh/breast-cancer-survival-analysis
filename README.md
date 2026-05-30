# Breast Cancer Survival & Disparity Analysis

## Project Overview
End-to-end healthcare analytics project analyzing survival outcomes, 
health disparities, and mortality prediction using real-world SEER 
data from the National Cancer Institute (1.3M+ patients, 2000-2022).

## Business Questions
- Which factors most affect breast cancer survival?
- Do racial disparities persist after controlling for cancer stage?
- Can we predict patient mortality using clinical features?
- What impact did COVID-19 have on cancer diagnoses?

## Dataset
- **Source:** SEER (Surveillance, Epidemiology and End Results Program) — NCI
- **Size:** 1,354,259 patients
- **Period:** 2000–2022
- **Features:** Age, race, stage, treatment, survival months, vital status

## Tools & Technologies
| Tool | Purpose |
|---|---|
| Python (Pandas, NumPy) | Data cleaning & EDA |
| Scikit-learn, XGBoost | Machine learning |
| Lifelines | Survival analysis |
| MySQL | Data storage & querying |
| Tableau | Interactive dashboard |
| Google Colab | Development environment |

## Project Structure
- notebooks/ — Jupyter notebook with full analysis
- sql/ — MySQL queries
- visualizations/ — All charts and plots
- README.md — Project documentation

## Key Findings
1. **Stage is the strongest predictor** — Distant stage patients have 84.6% 
mortality vs 32% for Localized
2. **Racial disparity confirmed** — Non-Hispanic Black patients have 41.2% 
mortality vs 33.3% for White patients — disparity persists at every stage
3. **COVID-19 impact** — 2020 showed -15.3% drop in diagnoses, largest 
single-year decline in the dataset
4. **ML Model** — XGBoost achieved ROC-AUC of 0.863 on 270,852 test patients

## Machine Learning Results
| Metric             | Score |
|---------------===--|-------|
| ROC-AUC            | 0.863 |
| Accuracy           | 79%   |
| Recall (Deaths)    | 75%   |
| Precision (Deaths) | 65%   |

## Survival Analysis
- Kaplan-Meier curves show clear separation between stages
- Log-rank test confirms difference is statistically significant (p < 0.0001)
- Non-Hispanic Black patients show consistently lower survival across all stages

## How to Run
1. Request SEER data access at seer.cancer.gov
2. Export breast cancer cases using SEER*Stat
3. Run `breast_cancer_analysis.ipynb` in Google Colab
4. Import cleaned CSV into MySQL using provided SQL script
5. Connect Tableau to MySQL for dashboard

## Author
Lisha Netam
Data Analyst | Healthcare Analytics  
www.linkedin.com/in/lisha-netam-aab580258 | lisha.netam.met22@itbhu.ac.in
