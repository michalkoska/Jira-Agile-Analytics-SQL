/*
===============================================================================
PROJECT: Jira Agile Analytics Simulator
AUTHOR: Micha³ Koœka
DESCRIPTION: 
    This script simulates a Jira database environment for a Scrum Team.
    It performs data cleaning, KPI calculation (Velocity, Bug Ratio), 
    and advanced trend analysis using Window Functions.
===============================================================================
*/

-- =============================================
-- 1. DATABASE SETUP (DDL)
-- =============================================

-- Clean up previous tables if they exist
DROP TABLE IF EXISTS zadania;
DROP TABLE IF EXISTS sprinty;

-- Create Sprint Table (Time Frames)
CREATE TABLE sprinty (
    id_sprintu INT PRIMARY KEY,
    nazwa VARCHAR(50),
    data_start DATE,
    data_koniec DATE,
    cel_sprintu VARCHAR(100)
);

-- Create Tasks Table (Jira Tickets)
CREATE TABLE zadania (
    id_zadania INT IDENTITY(1,1) PRIMARY KEY,
    tytul VARCHAR(100),
    typ VARCHAR(20),        -- Raw data contains dirty strings (e.g., ' Bug', 'story')
    status VARCHAR(20),     -- 'Done', 'In Progress', 'To Do'
    story_points INT,       -- Can be NULL for Bugs
    przypisany_do VARCHAR(50),
    id_sprintu INT          -- Foreign Key
);

-- =============================================
-- 2. DATA INJECTION (DML)
-- =============================================

INSERT INTO sprinty VALUES 
(1, 'Sprint Alpha', '2024-01-01', '2024-01-14', 'Payment Gateway'),
(2, 'Sprint Beta ', '2024-01-15', '2024-01-28', 'Performance Optimization'),
(3, 'Sprint Gamma', '2024-01-29', '2024-02-11', 'New User Dashboard');

INSERT INTO zadania (tytul, typ, status, story_points, przypisany_do, id_sprintu) VALUES
-- Sprint 1
('Stripe API Integration', 'Story', 'Done', 8, 'Janusz Dev', 1),
('Login Form Fix', 'Bug', 'Done', NULL, 'Piotr Tester', 1),
('CSS Alignment', ' Bug', 'Done', NULL, 'Anna Front', 1), -- Dirty data (space)
('Database Setup', 'Story', 'Done', 5, 'Janusz Dev', 1),

-- Sprint 2
('Cache Implementation', 'Story', 'Done', 5, 'Janusz Dev', 2),
('Refactoring', 'Story', 'In Progress', 3, 'Janusz Dev', 2),
('Critical 500 Error', 'BUG', 'Done', NULL, 'Piotr Tester', 2), -- Dirty data (CAPS)
('Header Redesign', 'story ', 'Done', 3, 'Anna Front', 2),

-- Sprint 3
('Export to PDF', 'Story', 'Done', 8, 'Anna Front', 3),
('Mobile View Fix', 'Bug', 'In Progress', NULL, 'Piotr Tester', 3),
('Analytics Module', 'Story', 'To Do', 13, 'Janusz Dev', 3);


-- =============================================
-- 3. ANALYTICAL QUERIES
-- =============================================

-- REPORT 1: Data Cleaning & Standardization
-- Problem: Raw data has inconsistent naming (' Bug', 'BUG') and NULL points.
-- Solution: Using UPPER, TRIM and COALESCE to standardize data.
SELECT 
    tytul,
    UPPER(TRIM(typ)) AS clean_type,
    COALESCE(story_points, 0) AS clean_points,
    status
FROM zadania;


-- REPORT 2: Sprint Velocity (Key Scrum Metric)
-- Goal: Calculate total Story Points delivered ('Done') in each Sprint.
SELECT 
    s.nazwa AS sprint_name,
    SUM(COALESCE(z.story_points, 0)) AS total_points_delivered
FROM sprinty s
JOIN zadania z ON s.id_sprintu = z.id_sprintu
WHERE z.status = 'Done'
GROUP BY s.nazwa;


-- REPORT 3: Quality Assurance (Bug Ratio Analysis)
-- Goal: Analyze the proportion of Bugs vs Stories in each Sprint.
-- Technique: Using Conditional Aggregation (Pivot logic).
SELECT 
    s.nazwa AS sprint_name,
    SUM(CASE WHEN z.typ LIKE '%Bug%' THEN 1 ELSE 0 END) AS bugs_count,
    SUM(CASE WHEN z.typ LIKE '%Story%' THEN 1 ELSE 0 END) AS stories_count,
    -- Calculate Bug Percentage (CAST to float to avoid integer division)
    CAST(SUM(CASE WHEN z.typ LIKE '%Bug%' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS bug_percentage
FROM sprinty s
JOIN zadania z ON s.id_sprintu = z.id_sprintu
GROUP BY s.nazwa;


-- REPORT 4: Team Workload & Performance
-- Goal: Identify top performers based on completed Story Points.
SELECT 
    przypisany_do AS employee,
    COUNT(*) AS tasks_assigned,
    SUM(COALESCE(story_points, 0)) AS total_points_completed
FROM zadania
WHERE status = 'Done'
GROUP BY przypisany_do
ORDER BY total_points_completed DESC;


-- REPORT 5: Velocity Trend Analysis (Advanced)
-- Goal: Compare current sprint performance with the previous one (Month-over-Month).
-- Technique: CTE + Window Function (LAG).

WITH Sprint_Metrics AS (
    SELECT 
        s.nazwa,
        s.data_start,
        SUM(COALESCE(z.story_points, 0)) AS velocity
    FROM sprinty s
    JOIN zadania z ON s.id_sprintu = z.id_sprintu
    WHERE z.status = 'Done'
    GROUP BY s.nazwa, s.data_start
)
SELECT 
    nazwa,
    velocity AS current_velocity,
    -- Look at the previous row to get previous sprint velocity
    LAG(velocity) OVER (ORDER BY data_start) AS previous_velocity,
    -- Calculate the difference
    velocity - LAG(velocity) OVER (ORDER BY data_start) AS velocity_change
    --The first row results in NULL for trend analysis as there is no prior period to compare with
FROM Sprint_Metrics;


-- REPORT 6: Urgent Issues Audit (UNION ALL)
-- Goal: Create a single list of all items that need immediate attention.
-- Items: 1. Unassigned tasks, 2. Critical bugs.
SELECT tytul AS task_name, 'Unassigned' AS issue_reason
FROM zadania
WHERE przypisany_do IS NULL

UNION ALL

SELECT tytul AS task_name, 'Critical Bug' AS issue_reason
FROM zadania
WHERE typ LIKE '%Bug%' AND status != 'Done';


-- REPORT 7: Developer Ranking (RANK)
-- Goal: Rank developers by the amount of Story Points they delivered.
-- Technique: Window Function RANK() to handle ties.
SELECT 
    przypisany_do, 
    SUM(story_points) AS total_points,
    RANK() OVER (ORDER BY SUM(story_points) DESC) AS performance_rank
FROM zadania
WHERE status = 'Done' AND przypisany_do IS NOT NULL
GROUP BY przypisany_do;