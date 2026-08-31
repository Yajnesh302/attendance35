# Chapter 08: Payroll Calculations, Wage Orders & Statutory Engine

This document details the wage orders management interface ([Wages.aspx](file:///e:/attendence/Wages.aspx) / [Wages.aspx.cs](file:///e:/attendence/Wages.aspx.cs)) and the monthly attendance payroll calculation engine ([Calculation.aspx](file:///e:/attendence/Calculation.aspx) / [Calculation.aspx.cs](file:///e:/attendence/Calculation.aspx.cs)).

---

## 1. Wage Orders & Statutory Revisions ([Wages.aspx](file:///e:/attendence/Wages.aspx))

The **Wages Module** records statutory minimum wage revisions gazetted by government/directorate orders, as well as statutory employee provident fund (EPF) and Goods and Services Tax (GST) ceilings.

```
+-----------------------------------------------------------------------------------+
|                            WAGE REVISION ARCHITECTURE                             |
+-----------------------------------------------------------------------------------+
|  WageOrders Table                                                                 |
|  - Id (PK), OrderId ("WO/2026/04"), MainCategoryId (FK), EffectiveDate            |
|  - OrderDetails ("Revised minimum wages w.e.f 01-April-2026")                     |
+-----------------------------------------+-----------------------------------------+
                                          |
                               (1 : N Category Rates)
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|  CategoryWages Table                                                              |
|  - Id (PK), WageOrderId (FK), TierId (FK -> Tiers.Id), WageRate (e.g. 980.50/day) |
+-----------------------------------------------------------------------------------+
```

### Point-in-Time Wage Rate Resolution
When calculating payroll for month $M$, the system does not merely take the "current" wage; it evaluates the historical wage rate active on that specific month using window functions:
```sql
SELECT cw.TierId, cw.WageRate,
       ROW_NUMBER() OVER (PARTITION BY cw.TierId ORDER BY wo.EffectiveDate DESC, wo.CreatedAt DESC, cw.Id DESC) AS rn
FROM CategoryWages cw
JOIN WageOrders wo ON cw.WageOrderId = wo.Id
WHERE wo.EffectiveDate <= :LastDayOfMonth
```

---

## 2. Statutory Deduction Orders (`StatutoryOrders`)

Manages legal statutory rates and contribution ceilings:

| Parameter | Default Seed Value | Statutory Rule & Calculation Formula |
| :--- | :---: | :--- |
| **`EpfRate`** | `13.00%` | EPF contribution rate applied to base eligible wage. |
| **`EpfLimit`** | `Rs. 15,000.00` | Maximum monthly salary ceiling eligible for EPF computation. |
| **`EpfCappedAmount`** | `Rs. 1,950.00` | Statutory monthly contribution ceiling: $15,000 \times 13\% = 1,950$. |
| **`GstRate`** | `18.00%` | Goods & Services Tax levied on total invoice value. |

---

## 3. Monthly Payroll Calculation Engine ([Calculation.aspx](file:///e:/attendence/Calculation.aspx))

`Calculation.aspx` reconciles raw daily attendance into billable days and monetary wage bills.

### 3.1 Data Flow & Processing Steps (`GetCalculationData`)

```
[User selects Year, Month, Tier, and Division on Calculation.aspx]
                              |
                              v
1. Resolve Active ContractPeriodId & Wage Rate for target month
                              |
2. Query Active Employees with valid EmployeeEngagements in target month
                              |
3. Query Attendance Matrix for Target Month (Present, Paid Leaves, Holidays)
                              |
4. Query CalculationOverrides Table (Manual Day Adjustments)
                              |
5. Apply Wage Formula & Statutory Math
                              |
6. Render Interactive Calculation Matrix on UI
```

---

### 3.2 Billable Days & Mathematical Formulas

$$\text{Calculated Working Days} = \sum \text{Present Days} + \sum \text{Paid Leaves (CL/EL)} + \sum \text{Declared Holidays}$$

$$\text{Final Days} = \begin{cases} \text{CalculationOverrides.FinalDays} & \text{if manual override exists} \\ \text{Calculated Working Days} & \text{otherwise} \end{cases}$$

$$\text{Gross Wages} = \text{Final Days} \times \text{Daily Wage Rate}$$

$$\text{EPF Contribution} = \min\left(\text{Gross Wages} \times \text{EpfRate},\, \text{EpfCappedAmount}\right)$$

$$\text{Total Invoice Bill} = (\text{Gross Wages} + \text{EPF} + \text{Agency Service Charge}) \times (1 + \text{GstRate})$$

---

## 4. Manual Wage & Day Adjustments

Administrators have the authority to make controlled manual adjustments:

### 4.1 Billable Days Override (`CalculationOverrides`)
- **Table:** `CalculationOverrides`
- **Primary Key:** `(Year, Month, TierId, EmpID)`
- **Rule:** If an employee worked overtime or required exceptional compensation adjustment, the administrator keys in `FinalDays` and a mandatory `Remarks` reason. The calculation grid immediately highlights overridden cells in amber.

### 4.2 Monthly Wage Override (`CalculationWages`)
- **Table:** `CalculationWages`
- **Primary Key:** `(Year, Month, TierId)`
- **Rule:** Overrides the standard wage order rate specifically for month $M$ without altering the master `WageOrders` record.
