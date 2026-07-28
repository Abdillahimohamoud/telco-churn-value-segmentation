-- Telco Customer Churn - Value Segmentation Analysis
-- Dataset: IBM/Kaggle Telco Customer Churn (public sample data)
-- Abdillahi Mohamoud

-- step 1. raw staging table. TotalCharges kept as text for now -
-- 11 rows have blank values (all tenure = 0, new customers not billed yet)
CREATE TABLE telco_churn_raw (
    customerID        VARCHAR(20),
    gender             VARCHAR(10),
    SeniorCitizen      TINYINT,
    Partner            VARCHAR(5),
    Dependents         VARCHAR(5),
    tenure             INT,
    PhoneService       VARCHAR(5),
    MultipleLines      VARCHAR(20),
    InternetService    VARCHAR(20),
    OnlineSecurity     VARCHAR(20),
    OnlineBackup       VARCHAR(20),
    DeviceProtection   VARCHAR(20),
    TechSupport        VARCHAR(20),
    StreamingTV        VARCHAR(20),
    StreamingMovies    VARCHAR(20),
    Contract           VARCHAR(20),
    PaperlessBilling   VARCHAR(5),
    PaymentMethod      VARCHAR(30),
    MonthlyCharges     DECIMAL(10,2),
    TotalCharges       VARCHAR(20),
    Churn              VARCHAR(5)
);

-- LOAD DATA LOCAL INFILE '/path/to/WA_Fn-UseC_-Telco-Customer-Churn.csv'
-- INTO TABLE telco_churn_raw
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- step 2. clean up: cast TotalCharges to numeric and drop the 11 blank rows.
-- none of them churned, so nothing lost by removing them.
CREATE TABLE telco_churn_cleaned AS
SELECT
    customerID,
    gender,
    CASE WHEN SeniorCitizen = 1 THEN 'Yes' ELSE 'No' END AS SeniorCitizen,
    Partner,
    Dependents,
    tenure,
    PhoneService,
    MultipleLines,
    InternetService,
    OnlineSecurity,
    OnlineBackup,
    DeviceProtection,
    TechSupport,
    StreamingTV,
    StreamingMovies,
    Contract,
    PaperlessBilling,
    PaymentMethod,
    MonthlyCharges,
    CAST(TRIM(TotalCharges) AS DECIMAL(10,2)) AS TotalCharges,
    Churn
FROM projectone.telco_churn_cleaned
WHERE TRIM(TotalCharges) != '';

-- step 3. sanity check - should be 7032 rows, 1869 churned
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    MIN(TotalCharges) AS min_total,
    MAX(TotalCharges) AS max_total
FROM projectone.telco_churn_cleaned;

-- step 4. top-line numbers for the dashboard summary cards
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) AS active_customers,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS retention_rate_pct,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS monthly_revenue_at_risk
FROM projectone.telco_churn_cleaned;

-- step 5. before picking tier cutoffs, check where the data actually splits.
-- came back p33 = 50.2, p66 = 83.25, so using 50/83 below instead of round numbers.
SELECT
    MIN(MonthlyCharges) AS min_charge,
    MAX(MonthlyCharges) AS max_charge,
    AVG(MonthlyCharges) AS avg_charge,
    (SELECT MonthlyCharges FROM (
        SELECT MonthlyCharges, ROW_NUMBER() OVER (ORDER BY MonthlyCharges) rn, COUNT(*) OVER () cnt
        FROM projectone.telco_churn_cleaned
    ) t WHERE rn = FLOOR(0.33 * cnt)) AS p33,
    (SELECT MonthlyCharges FROM (
        SELECT MonthlyCharges, ROW_NUMBER() OVER (ORDER BY MonthlyCharges) rn, COUNT(*) OVER () cnt
        FROM projectone.telco_churn_cleaned
    ) t WHERE rn = FLOOR(0.66 * cnt)) AS p66
FROM projectone.telco_churn_cleaned;

-- step 6. customer value tiers (Low / Medium / High) using the cutoffs above
SELECT
    CASE
        WHEN MonthlyCharges < 50 THEN 'Low Value'
        WHEN MonthlyCharges BETWEEN 50 AND 83 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_value_tier,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS monthly_revenue_lost
FROM projectone.telco_churn_cleaned
GROUP BY customer_value_tier
ORDER BY monthly_revenue_lost DESC;

-- step 7. high value tier loses the most revenue - drilling into why.
-- breaking down by contract type and payment method
SELECT
    Contract,
    PaymentMethod,
    COUNT(*) AS high_value_churned,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charge,
    ROUND(SUM(MonthlyCharges), 2) AS revenue_lost
FROM projectone.telco_churn_cleaned
WHERE MonthlyCharges > 83 AND Churn = 'Yes'
GROUP BY Contract, PaymentMethod
ORDER BY revenue_lost DESC;

-- step 8. month-to-month + electronic check is the standout segment here -
-- recommendation and reasoning goes in the README, not a query.

-- step 9. rough savings estimate if we retain a slice of that segment
SELECT
    COUNT(*) AS churned_customers,
    ROUND(SUM(MonthlyCharges), 2) AS monthly_revenue_lost,
    ROUND(SUM(MonthlyCharges) * 0.10, 2) AS savings_at_10pct_retention,
    ROUND(SUM(MonthlyCharges) * 0.15, 2) AS savings_at_15pct_retention,
    ROUND(SUM(MonthlyCharges) * 0.20, 2) AS savings_at_20pct_retention
FROM projectone.telco_churn_cleaned
WHERE Churn = 'Yes'
  AND Contract = 'Month-to-month'
  AND PaymentMethod = 'Electronic check'
  AND MonthlyCharges > 83;
