# Jira Agile Analytics - SQL Project 📊

## About the Project
An analytical simulation for a Scrum Team. The goal of this project is to monitor team performance (Velocity), code quality (Bug Ratio), and workload distribution using SQL.

This project solves a common business problem: *"How to measure team efficiency when raw data in Jira/Ticket System is unstructured?"*

## Technologies & SQL Techniques 🛠️
*   **Database:** MS SQL Server (T-SQL)
*   **Analysis:** Window Functions (`LAG`, `RANK`), CTEs (`WITH`), Aggregation (`GROUP BY`, `HAVING`)
*   **Data Cleaning:** `COALESCE`, `TRIM`, `UPPER`, `CAST`
*   **Reporting:** `CASE WHEN`, `UNION ALL`

## Key Reports & KPIs 📈
The `project_analysis.sql` script generates the following insights:
1.  **Sprint Velocity:** Total Story Points delivered in each sprint.
2.  **Performance Trend:** Month-over-Month comparison using Window Functions to track velocity changes.
3.  **Quality Assurance (Bug Ratio):** Percentage of bugs vs. new features delivered.
4.  **Workload Analysis:** Employee ranking based on delivered value.

## How to run? ▶️
Copy the content of `project_analysis.sql` into any SQL editor (e.g., Azure Data Studio or SSMS) and execute the script. It will automatically create the table structure and populate it with sample data for analysis.

---
*Author: Michał Kośka*
