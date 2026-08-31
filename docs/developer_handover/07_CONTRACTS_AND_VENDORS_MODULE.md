# Chapter 07: Contracts & Vendor Ecosystem Module

This document details the vendor management registry ([Vendors.aspx](file:///e:/attendence/Vendors.aspx) / [Vendors.aspx.cs](file:///e:/attendence/Vendors.aspx.cs)) and the GeM contract period lifecycle engine ([Contracts.aspx](file:///e:/attendence/Contracts.aspx) / [Contracts.aspx.cs](file:///e:/attendence/Contracts.aspx.cs)).

---

## 1. Vendor Master Registry ([Vendors.aspx](file:///e:/attendence/Vendors.aspx))

The Vendor module maintains master profiles for manpower contractor agencies and enforces a structured escalation contact hierarchy.

### 1.1 Vendor Entity Architecture
- **Table:** `Vendors`
- **Auto-Generated Master ID:** `GenerateNextMasterId()` produces formatted alphanumeric IDs (e.g. `'VND_001'`).
- **Unique Constraints:** `Name` and `MasterId` must be strictly unique.
- **Active Status Indicator:** A vendor is dynamically active if they possess at least one open `ContractPeriods` row (`Status = 'Active'`).

### 1.2 Dynamic Escalation Contact Matrix (`VendorContacts`)
Each vendor can register an unlimited number of escalation levels (`Priority 1..N`):

```
+-----------------------------------------------------------------------------------+
|                        VENDOR ESCALATION CONTACT MATRIX                           |
+----------+---------------+----------------+--------------------+------------------+
| Priority | Contact Name  | Phone Number   | Email Address      | Postal Address   |
+----------+---------------+----------------+--------------------+------------------+
| 1 (Prim) | Rajesh Kumar  | +91 9876543210 | rajesh@vendor.com  | Main Office, BLR | (Required)
| 2 (L2)   | S. Sharma     | +91 9876543211 | (Optional)         | (Optional)       | (Name/Phone Req)
| 3 (L3)   | Director Desk | +91 9876543212 | (Optional)         | (Optional)       | (Name/Phone Req)
+----------+---------------+----------------+--------------------+------------------+
```

#### Validation Rules:
- **Priority 1 (Primary Contact):** Name, Phone, Email, and Address are **strictly mandatory**.
- **Priority 2+ (Escalation Levels):** Name and Phone are **mandatory**; Email and Address are optional.
- Persisted via `hfVendorContacts` JSON payload and upserted into `VendorContacts` in an atomic transaction.

---

## 2. GeM Contract Periods Engine ([Contracts.aspx](file:///e:/attendence/Contracts.aspx))

`Contracts.aspx` manages formal Government e-Marketplace (GeM) contract execution periods.

### 2.1 Contract Lifecycle Wizard

```
+-----------------------------------------------------------------------------------+
| STEP 1: Contract Details       STEP 2: Vendor Mapping      STEP 3: Stint Enroll   |
| - GeM Contract ID (e.g. GEMC)  - Select Awarded Vendor(s)  - Select Employees     |
| - Tier / Category Classification- Consortium Vendors       - Create Initial Stints|
| - Start Date & Expiration Date - Notes / Terms             - Link Prev Stints     |
+-----------------------------------------------------------------------------------+
```

### 2.2 Contract Period Schema & Constraints
- **Table:** `ContractPeriods`
- **Unique Constraint:** `(TierId, StartDate)` – Only one active contract period can commence on a given date per skill tier.
- **Status Codes:** `'Active'` (currently running) or `'Closed'` (concluded or expired).

---

## 3. Contract Extensions Pipeline (`ContractExtensions`)

When a government contract period is officially extended:
1. The administrator clicks **Extend Contract** on `Contracts.aspx`.
2. Enters the `NewEndDate` and justification notes.
3. `Contracts.aspx.cs` executes within an atomic transaction:
   ```sql
   -- 1. Insert audit log
   INSERT INTO ContractExtensions (ContractPeriodId, OldEndDate, NewEndDate, ExtensionDate)
   VALUES (:ContractPeriodId, :OldEndDate, :NewEndDate, SYSTIMESTAMP);

   -- 2. Update Contract Period
   UPDATE ContractPeriods SET EndDate = :NewEndDate WHERE Id = :ContractPeriodId;

   -- 3. Extend all active employee engagements under this period
   UPDATE EmployeeEngagements 
   SET EndDate = :NewEndDate 
   WHERE ContractPeriodId = :ContractPeriodId AND EndDate = :OldEndDate;

   -- 4. Update employee master records
   UPDATE Employees 
   SET ContractEndDate = :NewEndDate 
   WHERE CurrentEngagementId IN (SELECT Id FROM EmployeeEngagements WHERE ContractPeriodId = :ContractPeriodId);
   ```

---

## 4. Automated Contract Auto-Closing Engine

To guarantee that expired contracts never allow lingering unbilled attendance, `DBHelper.AutoCloseExpiredContracts()` runs in a background thread on every page load:

```
[Contract EndDate < TRUNC(SYSDATE)]
               |
               v
1. Update ContractPeriods SET Status = 'Closed' WHERE Id = :Id
               |
2. Find Active EmployeeEngagements under this period (EndDate IS NULL)
               |
3. Update EmployeeEngagements: EndDate = :PeriodEndDate, EndReason = 'Contract Expired'
               |
4. Update Employees: Status = 'Relieved', ContractEndDate = :PeriodEndDate
```

*Result:* Seamless, autonomous end-of-contract lifecycle enforcement without manual administrator intervention.
