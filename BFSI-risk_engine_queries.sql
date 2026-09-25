/* =================================================================================
PROJECT: BFSI Automated Risk & Data Quality Engine
AUTHOR: Vignesh
DESCRIPTION: Automated SQL pipeline to audit raw mortgage payment logs, isolate 
             data corruption (state-reversions), and flag 90-day defaults.
================================================================================= */

-- 1. DATABASE SETUP & MOCK DATA INGESTION
DROP TABLE IF EXISTS payment_logs CASCADE;
DROP TABLE IF EXISTS loan_accounts CASCADE;
DROP TABLE IF EXISTS bank_customers CASCADE;

CREATE TABLE bank_customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(50),
    credit_segment VARCHAR(20)
);

CREATE TABLE loan_accounts (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type VARCHAR(50),
    monthly_due DECIMAL(10,2)
);

CREATE TABLE payment_logs (
    log_id INT PRIMARY KEY,
    loan_id INT,
    report_date DATE,
    account_status VARCHAR(30),
    payment_received DECIMAL(10,2)
);

INSERT INTO bank_customers VALUES
(1, 'Arjun Patel', 'Prime'),
(2, 'Priya Sharma', 'Subprime'),
(3, 'Vikram Singh', 'Prime');

INSERT INTO loan_accounts VALUES
(101, 1, 'Mortgage', 1500.00),
(102, 2, 'Auto Loan', 400.00),
(103, 3, 'Mortgage', 2000.00);

INSERT INTO payment_logs VALUES
(1, 101, '2026-08-01', 'Current', 1500.00),
(2, 101, '2026-09-01', 'Current', 1500.00),
(3, 101, '2026-10-01', 'Current', 1500.00),
(4, 102, '2026-08-01', 'Current', 400.00),
(5, 102, '2026-09-01', '30_Days_Late', 0.00),
(6, 102, '2026-10-01', '60_Days_Late', 0.00),
(7, 102, '2026-11-01', '90_Days_Late', 0.00), 
(8, 103, '2026-08-01', 'Current', 2000.00),
(9, 103, '2026-09-01', '30_Days_Late', 0.00),
(10, 103, '2026-11-01', 'Current', 0.00); 

/* =================================================================================
   PHASE 1: DATA QUALITY GATE
   Objective: Isolate illegal state-reversions (e.g., '30_Days_Late' to 'Current' 
              with 0.00 payment) using Window Functions.
================================================================================= */

WITH status_tracking AS (
    SELECT 
        loan_id, 
        report_date, 
        account_status, 
        payment_received,
        LAG(account_status, 1) OVER(PARTITION BY loan_id ORDER BY report_date ASC) AS prev_status
    FROM payment_logs
)
SELECT *
FROM status_tracking
WHERE account_status = 'Current' 
  AND prev_status = '30_Days_Late' 
  AND payment_received = 0.00;

/* =================================================================================
   PHASE 2: RISK DETECTION ENGINE (3-STRIKE DEFAULT)
   Objective: Create an automated reporting view flagging Non-Performing Assets.
================================================================================= */

CREATE OR REPLACE VIEW vw_defaulted_loans AS
SELECT 
    b.full_name, 
    l.loan_type, 
    p.report_date, 
    p.account_status
FROM payment_logs p
INNER JOIN loan_accounts l ON p.loan_id = l.loan_id
INNER JOIN bank_customers b ON l.customer_id = b.customer_id
WHERE p.account_status = '90_Days_Late';

-- Execute the executive view
SELECT * FROM vw_defaulted_loans;
