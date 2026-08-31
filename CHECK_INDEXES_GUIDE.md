# How to Check Database Indexes in Oracle

This guide explains how to verify that all performance indexes are created and active in your Oracle Database.

---

## Quick Method: Run `CHECK_INDEXES.sql`

You can run the script [CHECK_INDEXES.sql](file:///e:/attendence/CHECK_INDEXES.sql) directly in your database tool (Oracle SQL Developer, DBeaver, PL/SQL Developer, SQL*Plus, or Toad).

It runs a comprehensive audit of all 18 performance indexes, showing whether each index is `VALID` or `MISSING`.

---

## Method 1: List All Custom Performance Indexes

Run this query connected to your Attendance database schema:

```sql
SELECT 
    index_name, 
    table_name, 
    status, 
    uniqueness
FROM user_indexes 
WHERE index_name LIKE 'IDX_%'
ORDER BY table_name, index_name;
```

### Expected Output:
You should see all 18 indexes with status **`VALID`**:

| Index Name | Table Name | Status | Uniqueness |
| :--- | :--- | :--- | :--- |
| `IDX_ATT_EMP_DATE` | `ATTENDANCE` | VALID | NONUNIQUE |
| `IDX_ATT_PERIOD` | `ATTENDANCE` | VALID | NONUNIQUE |
| `IDX_ATT_YEAR_MONTH` | `ATTENDANCE` | VALID | NONUNIQUE |
| `IDX_ATTREM_EMP_DATE` | `ATTENDANCEREMARKS` | VALID | NONUNIQUE |
| `IDX_POCREM_YEAR_MONTH` | `ATTPOCEDITREMARKS` | VALID | NONUNIQUE |
| `IDX_CATSHARE_SHARED` | `CATEGORYSHAREGRANT` | VALID | NONUNIQUE |
| `IDX_CP_TIER_STATUS` | `CONTRACTPERIODS` | VALID | NONUNIQUE |
| `IDX_ENG_DATES` | `EMPLOYEEENGAGEMENTS` | VALID | NONUNIQUE |
| `IDX_ENG_EMP_TIER` | `EMPLOYEEENGAGEMENTS` | VALID | NONUNIQUE |
| `IDX_ENG_PERIOD_END` | `EMPLOYEEENGAGEMENTS` | VALID | NONUNIQUE |
| `IDX_LEAVECRED_EMP` | `EMPLOYEELEAVECREDITS` | VALID | NONUNIQUE |
| `IDX_EMP_CURR_ENG` | `EMPLOYEES` | VALID | NONUNIQUE |
| `IDX_EMP_DIV_STATUS` | `EMPLOYEES` | VALID | NONUNIQUE |
| `IDX_EMP_HIST_ID` | `EMPLOYEES` | VALID | NONUNIQUE |
| `IDX_EMP_TIER_STATUS` | `EMPLOYEES` | VALID | NONUNIQUE |
| `IDX_NOTICES_CAT_DATE` | `NOTICES` | VALID | NONUNIQUE |
| `IDX_USERDIVS_PCNO` | `USERDIVISIONS` | VALID | NONUNIQUE |
| `IDX_USERTIERS_PCNO` | `USERTIERS` | VALID | NONUNIQUE |

> **What does `VALID` mean?**  
> `VALID` means the index is active, healthy, and being utilized by the Oracle Cost-Based Optimizer (CBO) to speed up queries.

---

## Method 2: Check Columns and Column Order in Each Index

Composite indexes depend on column order. To verify column positions:

```sql
SELECT 
    index_name, 
    table_name, 
    column_position,
    column_name
FROM user_ind_columns 
WHERE index_name LIKE 'IDX_%'
ORDER BY table_name, index_name, column_position;
```

---

## Method 3: Check a Specific Index (e.g. `IDX_EMP_CURR_ENG`)

To check one individual index:

```sql
SELECT index_name, table_name, status 
FROM user_indexes 
WHERE index_name = 'IDX_EMP_CURR_ENG';
```

- If **1 row returned** with `STATUS = 'VALID'`: The index exists and is working.
- If **0 rows returned**: The index has not been created yet.

---

## Method 4: How C# Code Automatically Verifies & Creates Indexes

You don't need to manually create indexes every time. In [`Utils/DBHelper.cs`](file:///e:/attendence/Utils/DBHelper.cs), the `EnsureSchema()` method runs on application startup:

```csharp
private static void EnsureIndexExists(OracleConnection conn, string indexName, string createIndexSql)
{
    try
    {
        string checkSql = "SELECT COUNT(*) FROM USER_INDEXES WHERE UPPER(INDEX_NAME) = UPPER(:IndexName)";
        using (OracleCommand cmd = new OracleCommand(checkSql, conn))
        {
            cmd.Parameters.Add("IndexName", indexName.ToUpper().Trim());
            object result = cmd.ExecuteScalar();
            if (result != null && Convert.ToInt32(result) == 0)
            {
                // Index is missing -> Auto-create it!
                using (OracleCommand createCmd = new OracleCommand(createIndexSql, conn))
                {
                    createCmd.ExecuteNonQuery();
                }
            }
        }
    }
    catch (Exception ex)
    {
        System.Diagnostics.Debug.WriteLine($"Note on index {indexName}: {ex.Message}");
    }
}
```

---

## Method 5: Viewing Indexes in GUI Tools (Oracle SQL Developer / DBeaver)

1. Open your database tool (e.g., **Oracle SQL Developer**).
2. Connect to your database.
3. In the left connection tree, expand **Tables**.
4. Click on any table (for example, `EMPLOYEES` or `ATTENDANCE`).
5. On the right side, click the **Indexes** tab.
6. You will see the index names (`IDX_EMP_CURR_ENG`, `IDX_ATT_YEAR_MONTH`, etc.) along with the indexed column list.
