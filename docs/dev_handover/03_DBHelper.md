# 03 - DBHelper.cs (The Core Data Access Layer)

**File:** Utils/DBHelper.cs - 1,791 lines

---

## What Is DBHelper?

DBHelper is a static utility class that handles every single database operation in the entire application. No other file opens an Oracle connection on its own - they all go through DBHelper. Think of it as the gatekeeper between the application code and the Oracle database.

