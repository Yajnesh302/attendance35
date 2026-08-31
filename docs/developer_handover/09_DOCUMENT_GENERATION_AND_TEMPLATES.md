# Chapter 09: Automated Document Generation & Certificate Engine

This document details the dynamic legal document generator and certificate engine ([Documents.aspx](file:///e:/attendence/Documents.aspx) / [Documents.aspx.cs](file:///e:/attendence/Documents.aspx.cs)).

---

## 1. Document Engine Architecture

`Documents.aspx` automates the generation of official statutory compliance certificates and covering letters required for vendor billing submissions to finance/audit.

```
+-----------------------------------------------------------------------------------+
| FILTERS: Year [2026] | Month [May] | Category [Skilled] | Contract [GEMC-511...]  |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                    Documents.aspx.cs Backend Data Assembly                         |
|  1. GetCertificateData(...) queries active ContractPeriod & Vendor details        |
|  2. Queries exact active employee count (EmpCount) from EmployeeEngagements       |
|  3. Fetches template strings from CertificateTemplates table                      |
|  4. Replaces dynamic placeholders ({VendorName}, {ContractNo}, {Dates}, etc.)     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                     RENDER / EXPORT INTERFACES (4 DOCUMENTS)                      |
|  - Satisfactory Certificate (Industry partner performance certificate)           |
|  - Covering Letter (Official HR forwarding letter to Purchase/Finance)            |
|  - Format 8 / Wages Annexure (Statutory bill breakdown & EPF annexure)            |
|  - Attendance Certificate (GeM contract deployment certificate)                  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Generated Document Types & Business Rules

### 2.1 Satisfactory Performance Certificate
- **Purpose:** Certifies that the vendor supplied the requisite number of contract employees and that services rendered during the billing month were satisfactory.
- **Key Placeholders:** `{VendorName}`, `{VendorAddress}`, `{Services}`, `{Duration}`, `{WefDate}`, `{ContractNo}`, `{ContractDate}`, `{DatedOn}`, `{EmpCount}`, `{StartDate}`, `{EndDate}`.
- **Signatory:** Configured via `SatSignatory` (e.g. `(Raajita B Reddy)`) and `SatDesignation` (e.g. `Scientist 'F'`).

### 2.2 Official Covering Letter
- **Purpose:** Official memorandum from the Division/Establishment to Purchase / Accounts (`D-FMM/Purchase`) forwarding attendance registers and wage bills for payment processing.
- **Key Placeholders:** `{RefNo}`, `{Year}`, `{Category}`, `{VendorName}`, `{VendorAddress}`, `{StartDate}`, `{EndDate}`, `{Division}`.
- **Authority Tag:** Configured via `CovAuthority` (`For GD, {Division}`).

### 2.3 Format 8 / Wages Annexure
- **Purpose:** Comprehensive financial annexure showing employee-by-employee billable days, gross wages, EPF deductions, GST calculations, and net payable sums.

### 2.4 Attendance Certificate
- **Purpose:** Concise certificate verifying that contract employees performed duties in accordance with the GeM contract terms.

---

## 3. Dynamic Template System (`CertificateTemplates`)

All wording is dynamically decoupled from code and stored in `CertificateTemplates`:

| Template Key | Purpose | Default Boilerplate Text |
| :--- | :--- | :--- |
| `AttDesc1` | Attendance Header | `This is certify that DEO ({Category}) under GeM Contract No: {ContractNo}, dated: {ContractDate}, Dated On: {DatedOn}` |
| `SatDesc1` | Satisfactory Opening | `This is to certify that M/s. <b>{VendorName}</b>, {VendorAddress} is engaged as an Industry Partner in our Establishment to provide Services towards <b>{Services}</b>...` |
| `SatDesc2` | Manpower Count | `The Industry Partner provided <b>{EmpCount}</b> Contract Employees and found working satisfactorily.` |
| `CovSubject` | Letter Subject | `HIRING OF MANPOWER SERVICES` |
| `CovBody` | Letter Body Text | `The copies of the Attendance report along with the wage calculation for {Category} category Contract Employees from M/s. {VendorName}...` |

### Modifying Boilerplate Text
Administrators can modify any document wording directly in the database without recompiling the application:
```sql
UPDATE CertificateTemplates 
SET TemplateValue = 'New approved certificate wording with {VendorName} and {ContractNo}' 
WHERE TemplateKey = 'SatDesc1';
```

---

## 4. Export & Printing Capabilities

`Documents.aspx` supports:
1. **Interactive In-Browser Preview:** Real-time WYSIWYG preview rendered inside printable cards with official establishment styling.
2. **Direct Browser Print:** Injects custom `@media print` stylesheets hiding navigation bars and optimizing margins for A4 paper.
3. **Microsoft Word Export (`.doc`):** Streams HTML MIME payload with `Content-Type: application/msword` and `Content-Disposition: attachment; filename="Satisfactory_Certificate.doc"`.
