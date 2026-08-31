---
description: Maintain and update PRODUCTION_OPTIMIZATIONS.md whenever production or performance changes are made
---

# Production Optimization Rule

When making any changes related to:
- Database queries, schemas, triggers, sequences, or indexes
- Connection pooling or Web.config configuration
- Caching (server RAM, static files, client browser)
- Performance tuning or N+1 query elimination
- Transaction batching or high-concurrency scaling

You MUST:
1. Update `PRODUCTION_OPTIMIZATIONS.md` in the root of the workspace.
2. Include:
   - What change was made
   - Why the change was made (problem/rationale)
   - What changed after (performance impact)
   - Exact file path and line numbers
3. Ensure all Oracle object names remain strictly $\le 30$ characters (Oracle 11g compatibility).
