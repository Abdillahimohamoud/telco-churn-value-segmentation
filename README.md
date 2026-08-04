# Telco Customer Churn — Value-Based Segmentation Analysis

## Business Problem

Customer churn is a standard metric almost every company tracks, but headline churn rate alone doesn't tell you where the real financial damage is happening. Losing 100 customers paying $20/month is a very different problem than losing 20 customers paying $100/month — yet most churn analyses treat every lost customer the same way.

This project asks a sharper question: **which customers leaving actually cost the business the most money, and why?**

## Dataset

Public IBM/Kaggle Telco Customer Churn dataset — 7,043 customers of a fictional telecom company, including account details (tenure, contract type, payment method), services subscribed, monthly/total charges, and churn status.

## Data Cleaning

`TotalCharges` was stored as text instead of a number, and 11 records had blank values. All 11 belonged to customers with zero tenure — brand new sign-ups with no billing history yet — and none had churned. I cast the column to numeric and dropped these 11 rows; at under 0.2% of the dataset with zero churn signal, removing them doesn't affect the analysis.

## Method

1. Calculated top-line KPIs: total customers, churn rate, retention rate, total revenue, revenue at risk.
2. Before splitting customers into value tiers, checked the actual distribution of `MonthlyCharges` rather than picking round numbers. The 33rd and 66th percentiles came out to $50.20 and $83.25, so tiers were set at $50 and $83 — Low, Medium, High Value — giving three roughly equal-sized groups instead of arbitrary bands.
3. Measured churn rate and revenue lost within each tier.
4. For the tier losing the most revenue, cross-cut churned customers by contract type and payment method to find where the loss concentrates.
5. Estimated the financial impact of a retention effort targeted at that specific segment.

## Findings

Churn rate rises with customer value, not the other way around:

| Tier | Customers | Churn Rate | Revenue Lost |
|---|---|---|---|
| Low Value | 2,288 | 15.78% | $12,110.90 |
| Medium Value | 2,343 | 29.32% | $48,543.15 |
| High Value | 2,401 | 34.19% | $78,476.80 |

High Value customers make up 34% of the customer base but account for **56% of all revenue lost to churn** — the highest-paying customers are leaving at more than twice the rate of the lowest-paying ones.

Drilling into that High Value group specifically, one combination stands out: customers on **month-to-month contracts paying by electronic check**. This single segment accounts for 469 churned customers and $44,129.90 in lost monthly revenue — 56% of all High Value revenue loss, more than five times the next-largest segment (month-to-month with bank transfer).

Contract length matters more than payment method on its own: month-to-month contracts appear in every one of the top loss segments, while one-year and two-year contracts show consistently lower churn and lower dollar impact across the board, regardless of payment method.

## Recommendation

Retention efforts should prioritize high-value customers ($83+/month) on month-to-month contracts, particularly those paying by electronic check — this segment alone drives the majority of high-value revenue loss and is more concentrated than any other group in the data.

Two concrete actions:
- **Contract upgrade incentives** — a discount or perk for switching from month-to-month to a one-year term, since longer contracts show far lower churn across every value tier.
- **Autopay migration** — incentivize the switch from electronic check to automatic bank or credit card payment, since that shift correlates with lower churn in this data.

This is a data-driven observation, not a causal claim — the dataset shows correlation between payment method/contract type and churn, not the underlying reason why. Further investigation (e.g., customer surveys) would be needed to confirm the cause before designing a full retention campaign.

## Estimated Impact

If a targeted retention campaign recovered 10–20% of the month-to-month, electronic-check, high-value segment, that would protect an estimated **$4,413–$8,826 in monthly recurring revenue**, or roughly **$53,000–$106,000 annually** — without needing to discount or intervene across the entire customer base.

## Tools Used

MySQL (data cleaning, segmentation, cross-cut analysis). Power BI dashboard in progress.


## Dashboard

![Overview](page1_overview.<img width="1342" height="777" alt="image" src="https://github.com/user-attachments/assets/30b7b5db-f7fb-4b3d-a72f-a2c7729a1be6" />
)
![Value Tier Breakdown](page2_value_tiers.png)
![Root Cause Analysis](page3_root_cause.png)
![Recommendation & Impact](page4_recommendation.png)

Full interactive file: [telco_churn_analysis.pbix](telco_churn_analysis.pbix)
