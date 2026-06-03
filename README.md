# Breast Cancer Survival & Disparity Analysis

I built this project to find out what actually drives breast cancer 
survival outcomes using real patient data from the National Cancer 
Institute. Most portfolio projects use pre-cleaned Kaggle datasets. 
This one uses the same data clinical researchers use — 1.35 million 
real breast cancer patients diagnosed across the US between 2000 and 
2022, accessed directly from the NCI's SEER program.

The short answer to what drives survival: stage at diagnosis, 
followed by race — and the racial gap is not explained by late 
diagnosis alone.

---

## The Problem

Breast cancer is the most common cancer among women in the US. 
Survival outcomes vary dramatically depending on when the cancer 
is caught, who the patient is, and where they live. I wanted to 
quantify exactly how much these factors matter — and whether the 
data would confirm or challenge assumptions about racial disparities 
in cancer outcomes.

---

## Dataset

- SEER Program, National Cancer Institute — seer.cancer.gov
- 1,354,259 real breast cancer patients
- Diagnosed between 2000 and 2022
- Accessed via free registration and data use agreement
- Exported using SEER*Stat software, filtered to ICD-O-3 
  site codes C50.1–C50.9

---

## What I Set Out to Test

Before touching the data I wrote down 4 questions:

H1: Does cancer stage at diagnosis predict survival more 
    than any other factor?

H2: Do Black patients face higher mortality than White 
    patients even when diagnosed at the same stage — 
    ruling out late diagnosis as the only explanation?

H3: Does radiation treatment meaningfully reduce mortality?

H4: Did COVID-19 disrupt cancer screening patterns in 
    a measurable way?

---

## Tools Used

- Python — Pandas, Matplotlib, Seaborn, Lifelines, XGBoost
- MySQL — CTEs, window functions (RANK, LAG, NTILE)
- Tableau — interactive dashboard
- Google Colab — development environment

---

## What I Found

**Overall picture**

917,617 patients were alive at end of study vs 436,642 dead —
a 32.2% mortality rate overall. Roughly 1 in 3 breast cancer 
patients in this dataset did not survive. Patients who died 
survived an average of 73.4 months (~6 years). Patients still 
alive averaged 103.6 months (~8.6 years). The survival months 
histogram showed dead patients concentrated heavily in the 
first 50 months — many deaths happen early after diagnosis.

Diagnoses peaked at age 60-64. Cases were rare below age 30. 
The age distribution confirmed this is predominantly a disease 
of older women in this dataset.

**H1 — Confirmed. Stage is everything.**

The mortality chart by stage was the starkest finding in the 
entire project:

- Distant (cancer spread to other organs): 86.7% mortality
- Regional (spread to nearby lymph nodes): 44.5% mortality
- Localized (contained to breast): 33.0% mortality

That is a 53.7 percentage point gap between distant and 
localized. A patient diagnosed at the distant stage is nearly 
3x more likely to die than one diagnosed at localized stage.

The Kaplan-Meier survival curves made this impossible to 
ignore visually. The distant stage curve drops steeply and 
nearly reaches zero within 100 months. The localized curve 
stays high and gradual across the full follow-up period. 
A log-rank test confirmed the difference is statistically 
significant (p < 0.0001) — not random chance.

The survival quartile SQL analysis reinforced this. The 
bottom 25% of distant stage patients survived only 2.6 
months on average. The top 25% of localized stage patients 
survived 220.5 months — nearly 18 years.

**H2 — Confirmed. The disparity holds at every stage.**

Overall mortality by race:
- Non-Hispanic Black: 38.0%
- Non-Hispanic White: 34.2%
- American Indian/Alaska Native: 32.6%
- Hispanic: 25.2%
- Asian/Pacific Islander: 20.6%

That 3.8 percentage point overall gap between Black and White 
patients is significant. But the more important finding came 
from the stage × race cross-analysis in SQL. Black patients 
had higher mortality than White patients at every single stage 
— Distant, Regional, and Localized. The RANK() OVER 
PARTITION BY window function confirmed Black patients ranked 
first (highest mortality) within every stage group without 
exception.

The Kaplan-Meier curve by race showed the same pattern 
visually. The Black patient survival curve sits below every 
other group across the entire follow-up period. The gap is 
not explained by later diagnosis alone.

**H3 — Partially confirmed, with a caveat.**

Mortality by radiation type:
- No radiation/Unknown: 40.2%
- Refused treatment: 35.9%
- Beam radiation: 24.6%
- Radioactive implants/brachytherapy: 21.1%
- Combination beam + implants: 30.8%

Patients who received beam radiation had 24.6% mortality vs 
40.2% for untreated patients. The pattern suggests radiation 
helps. But this is correlation, not causation — patients who 
received no radiation may have had inoperable or very advanced 
cancers where radiation was not viable. The ML model ranked 
radiation fifth out of seven features at 0.05 importance, 
suggesting it matters but is not the dominant predictor 
after controlling for stage and age.

**H4 — Confirmed. COVID left a visible mark.**

The yearly diagnosis trend line showed a clear and sudden 
drop in 2020 — a 15.3% decline, the largest single-year 
fall in the entire 22-year dataset. The LAG() window 
function query in SQL confirmed this precisely. The 
following year showed a sharp recovery spike as delayed 
screenings caught up. For a dataset covering 1.35 million 
patients over 22 years, a 15% swing in a single year is 
not noise. It reflects real and measurable disruption in 
healthcare access.

---

## Correlation Analysis

The heatmap revealed key relationships. survival_months and 
year_diagnosis had a -0.69 correlation — the strongest in 
the dataset. This does not mean recent patients are dying 
faster. It means they have shorter follow-up time since they 
were diagnosed more recently. vital_status_binary and 
year_diagnosis showed -0.39, consistent with improving 
treatments over time. histologic_type showed near-zero 
correlation with everything — limited standalone predictive 
value.

---

## Machine Learning Model

I trained an XGBoost binary classifier to predict mortality 
using features available at diagnosis: age group, sex, year 
of diagnosis, cancer stage, radiation type, and race. I 
deliberately excluded survival months — that is only known 
after the outcome and would be data leakage.

Results on a 270,000+ patient test set:
- AUC: 0.863
- Accuracy: 79%
- Recall (deaths): 75%
- Precision (deaths): 65%

The ROC curve hugs the top-left corner closely. The 
confusion matrix showed 147,863 correct alive predictions 
and 65,137 correct death predictions. The 22,191 missed 
deaths (false negatives) are the clinical concern — patients 
the model failed to flag as high risk.

In a medical context recall matters more than precision. 
Missing a high-risk patient costs far more than a false 
alarm. The model catches 75% of actual deaths.

Feature importance: year_diagnosis (0.33), summary_stage 
(0.30), age_group (0.24), grade (0.05), radiation (0.05), 
race (0.027), sex (0.005). Race ranked low in ML importance 
but was clinically significant in survival analysis — a 
reminder that statistical importance and clinical importance 
are not the same thing.

---

## SQL Analysis

Wrote 8 analytical queries in MySQL against the full 
1.35M patient dataset:

- Overall summary: 32.2% mortality, average survival 
  across all patients
- Mortality by stage and by race independently
- Stage × race cross-analysis confirming disparity 
  at every stage
- RANK() OVER PARTITION — Black patients ranked #1 
  mortality at every stage
- LAG() CTE — year-over-year change confirming 
  -15.3% drop in 2020
- NTILE(4) CTE — survival quartiles by stage
- CASE WHEN risk classification into High, Medium, 
  Low risk categories

---

## Dashboard

Interactive Tableau dashboard with four views: mortality 
rate by cancer stage, yearly diagnosis trend, mortality 
rate by race, and average survival by age group.

[View Dashboard](https://public.tableau.com/views/breast_cancer_dashboard_17801073582100/Dashboard1)

---

## How to Run

1. Register at seer.cancer.gov and sign the data use agreement
2. Export breast cancer cases using SEER*Stat (filter to 
   C50.1–C50.9, select 17 Registries 2000-2022 database)
3. Upload the exported file to Google Colab
4. Run `breast_cancer_analysis.ipynb`
5. Import `breast_cancer_cleaned.csv` into MySQL 
   using `cancer.sql`
6. Connect Tableau to the exported summary CSVs

---

## Repository

- `breast_cancer_analysis.ipynb` — full analysis notebook
- `cancer.sql` — all 8 SQL queries
- `visualizations/` — all charts and plots
- `README.md` — you are here

---

## Status

✅ 1.35M patient records cleaned and validated
✅ 12 EDA and survival visualizations with findings
✅ 8 SQL queries with CTEs and window functions
✅ Kaplan-Meier + Cox PH survival analysis
✅ XGBoost model AUC 0.863 on 270K+ test patients
✅ Tableau dashboard published
✅ Racial disparity confirmed at every cancer stage

---

## Author

**Lisha Netam**
[LinkedIn](https://www.linkedin.com/in/lisha-netam-aab580258) · lisha.netam.met22@itbhu.ac.in
