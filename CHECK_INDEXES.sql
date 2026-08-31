-- =============================================================================
-- SCRIPT: CHECK_INDEXES.sql
-- PURPOSE: Verify status of all 18 Performance Indexes in Attendance DB (Oracle 11g+)
-- RUN IN: Oracle SQL Developer / SQL*Plus / DBeaver / Toad
-- =============================================================================

SET LINESIZE 200;
SET PAGESIZE 100;
COLUMN INDEX_NAME FORMAT A25;
COLUMN TABLE_NAME FORMAT A22;
COLUMN STATUS FORMAT A10;
COLUMN UNIQUENESS FORMAT A10;
COLUMN INDEXED_COLUMNS FORMAT A55;

PROMPT =====================================================================;
PROMPT  1. ACTIVE PERFORMANCE INDEXES STATUS (Total 18 Expected)
PROMPT =====================================================================;

SELECT 
    i.index_name, 
    i.table_name, 
    i.status, 
    i.uniqueness
FROM user_indexes i
WHERE i.index_name LIKE 'IDX_%'
ORDER BY i.table_name, i.index_name;

PROMPT ;
PROMPT =====================================================================;
PROMPT  2. INDEXED COLUMNS AND POSITION DETAILS
PROMPT =====================================================================;

SELECT 
    ic.index_name, 
    ic.table_name, 
    ic.column_position,
    ic.column_name
FROM user_ind_columns ic
WHERE ic.index_name LIKE 'IDX_%'
ORDER BY ic.table_name, ic.index_name, ic.column_position;

PROMPT ;
PROMPT =====================================================================;
PROMPT  3. FULL CHECKLIST & HEALTH AUDIT (Validates Expected vs Existing)
PROMPT =====================================================================;

WITH ExpectedIndexes AS (
    SELECT 'IDX_ATT_YEAR_MONTH' AS idx_name, 'ATTENDANCE' AS tbl_name, '(Year, Month, StatusValue, EmpID)' AS cols FROM DUAL UNION ALL
    SELECT 'IDX_ATT_EMP_DATE', 'ATTENDANCE', '(EmpID, Year, Month)' FROM DUAL UNION ALL
    SELECT 'IDX_ATT_PERIOD', 'ATTENDANCE', '(ContractPeriodId)' FROM DUAL UNION ALL
    SELECT 'IDX_ATTREM_EMP_DATE', 'ATTENDANCEREMARKS', '(EmpID, RemarkDate)' FROM DUAL UNION ALL
    SELECT 'IDX_POCREM_YEAR_MONTH', 'ATTPOCEDITREMARKS', '(Year, Month, EmpID)' FROM DUAL UNION ALL
    SELECT 'IDX_CATSHARE_SHARED', 'CATEGORYSHAREGRANT', '(SharedWithPCNO, IsActive)' FROM DUAL UNION ALL
    SELECT 'IDX_CP_TIER_STATUS', 'CONTRACTPERIODS', '(TierId, Status, StartDate, EndDate)' FROM DUAL UNION ALL
    SELECT 'IDX_ENG_PERIOD_END', 'EMPLOYEEENGAGEMENTS', '(ContractPeriodId, EndDate)' FROM DUAL UNION ALL
    SELECT 'IDX_ENG_EMP_TIER', 'EMPLOYEEENGAGEMENTS', '(EmpID, TierId)' FROM DUAL UNION ALL
    SELECT 'IDX_ENG_DATES', 'EMPLOYEEENGAGEMENTS', '(StartDate, EndDate)' FROM DUAL UNION ALL
    SELECT 'IDX_LEAVECRED_EMP', 'EMPLOYEELEAVECREDITS', '(EmpID, ContractPeriodId, EffectiveDate)' FROM DUAL UNION ALL
    SELECT 'IDX_EMP_TIER_STATUS', 'EMPLOYEES', '(TierId, Status)' FROM DUAL UNION ALL
    SELECT 'IDX_EMP_DIV_STATUS', 'EMPLOYEES', '(DivId, Status)' FROM DUAL UNION ALL
    SELECT 'IDX_EMP_HIST_ID', 'EMPLOYEES', '(EmployeeHistoryId)' FROM DUAL UNION ALL
    SELECT 'IDX_EMP_CURR_ENG', 'EMPLOYEES', '(CurrentEngagementId)' FROM DUAL UNION ALL
    SELECT 'IDX_NOTICES_CAT_DATE', 'NOTICES', '(Category, CreatedAt)' FROM DUAL UNION ALL
    SELECT 'IDX_USERDIVS_PCNO', 'USERDIVISIONS', '(PCNO, DivId)' FROM DUAL UNION ALL
    SELECT 'IDX_USERTIERS_PCNO', 'USERTIERS', '(PCNO, TierId)' FROM DUAL
)
SELECT 
    e.idx_name AS "EXPECTED_INDEX",
    e.tbl_name AS "TARGET_TABLE",
    e.cols     AS "INDEXED_COLUMNS",
    NVL(u.status, 'MISSING') AS "STATUS",
    CASE 
        WHEN u.status = 'VALID' THEN 'OK - HEALTHY'
        WHEN u.status IS NULL THEN 'NOT CREATED'
        ELSE 'NEEDS REBUILD'
    END AS "HEALTH_CHECK"
FROM ExpectedIndexes e
LEFT JOIN user_indexes u ON UPPER(e.idx_name) = UPPER(u.index_name)
ORDER BY e.tbl_name, e.idx_name;
