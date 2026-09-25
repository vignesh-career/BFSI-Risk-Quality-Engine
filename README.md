# BFSI Automated Risk & Data Quality Engine

## Business Objective
In the Mortgage and BFSI sector, manual auditing of nightly data feeds leads to missed delinquencies and corrupted risk models. This project engineers an automated SQL pipeline to audit raw mainframe payment logs, isolate data corruption, and flag non-performing assets (NPAs) for executive review.

## Tech Stack
* **Database:** PostgreSQL
* **Techniques Used:** Window Functions (`LAG`), Common Table Expressions (CTEs), Aggregations, Outer/Inner Joins, View Creation, Defensive Programming (`COALESCE`).

## Architecture & Logic

### 1. Data Quality Gate (State-Reversion Anomaly Detection)
Engineered a CTE using Window Functions to track historical account states. The gate automatically isolates "Ghost in the Machine" system errors—instances where a loan illegally reverts from '30_Days_Late' to 'Current' without a corresponding payment.

### 2. Risk Detection Engine (The 3-Strike Rule)
Joined relational customer and portfolio dimension tables to the daily logs to flag accounts breaching the '90_Days_Late' threshold, generating a targeted hit-list for the collections department.

### 3. Executive Reporting
Packaged the final risk detection logic into an automated SQL `VIEW` (`vw_defaulted_loans`), allowing BI tools (Power BI/Tableau) to query live default metrics without exposing analysts to raw, unstructured data.
