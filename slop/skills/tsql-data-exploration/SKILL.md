---
name: tsql-data-exploration
description: "Explores and queries SQL Server databases using MCP connections powered by dbhub (bytebase/dbhub). Activates when the user wants to inspect table structures, run SELECT queries, validate views or stored procedures, explore data, debug query results, check row counts, compare data across databases, export query results, or when the user mentions database names, table names, or asks to 'check the data', 'run a query', 'look at the table', or 'validate the view'."
license: MIT
metadata:
  author: Jorge Thomas
---

# TSQL Data Exploration

## When to Apply

Activate this skill when:

- Exploring or querying data in any of the project's SQL Server databases
- Validating that a view or stored procedure returns correct results
- Inspecting table schemas, column types, or relationships
- Debugging unexpected query results or data inconsistencies
- Comparing data across databases
- Exporting query results for analysis or reporting

## MCP Provider

This project uses [`dbhub`](https://github.com/bytebase/dbhub) (`@bytebase/dbhub`) as its MCP provider — one dbhub server instance per database, each exposing two tools: `execute_sql` and `search_objects`. See dbhub's own README for the tools required to run it on your OS.

Connections are declared as MCP servers named after the database they point to (e.g. `SourceSystemDB`, `CentralDataWarehouse`). Set these up in a project-level `.mcp.json` (never committed — see `.gitignore` rules in `AGENTS.md`); copy `.mcp.json.example` and fill in your `.env` credentials. If your servers instead live in your global Claude Code config, the same server names and tools apply.

### MCP Connections (SQL Server, unless noted)

Naming is illustrative — adjust to whatever MCP server names your project actually uses.

| MCP Server | Purpose |
|------------|---------|
| `SourceSystemDB` | Core operational data, per-client views (e.g., `view_client_a`, `view_client_b`), and stored procedures |
| `CentralDataWarehouse` | Centralized/consolidated data and cross-client views (e.g., Client A, Client B) |
| `AppPortal` / `AppPortal_ClientA` | Main app data and client-specific operations |
| `AppPortalV2` / `AppPortalV2_Customer` | Next-gen app and customer-specific data |
| `AppPortalV2_Qa` / `AppPortalV2_Customer_Qa` | QA counterparts of the above |
| `AppSecondary` | Secondary/complementary application data |
| `AppStatusTracker` | Status tracking application |
| `AppFieldOps` | Field operations application |
| `AppStaging` | Testing/staging application |
| `AppDataFeedA` / `AppDataFeedB` | Additional integration data feeds |
| `SpecialtyDataDB` | Specialty domain dataset (e.g. a non-SQL-Server engine like MariaDB) |

Not every database needs to be enabled for every task — enable only the MCP servers relevant to what you're working on.

### MCP Tools Reference

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `search_objects` | List/inspect schemas, tables, views, columns, procedures, functions, indexes (`object_type` + optional `pattern`, `table`, `schema`, `detail_level`) | First step when exploring an unfamiliar database, or to check a table's/procedure's structure before writing JOINs |
| `execute_sql` | Run any SQL statement — SELECT, INSERT/UPDATE/DELETE, DDL | Exploring data, validating results, debugging views, and (with caution — confirm with user first) modifying data or schema |

`search_objects` replaces the old `list_tables`/`describe_table` split — pass `object_type: "table"` with no pattern to list tables, or `object_type: "column"` with `table`+`schema` to describe one. `execute_sql` replaces `read_query`/`write_query`/`export_query`/`create_table`/`alter_table`/`drop_table` — there's no dedicated export tool, so export by running the query and writing the result to a file yourself when needed. There's no `append_insight` equivalent — note findings in your response to the user instead.

## Exploration Workflow

Follow this sequence when exploring an unfamiliar area of the database:

### 1. Understand the Schema

Start by listing tables and describing the ones relevant to the task:

```
search_objects (object_type: table) → identify relevant tables → search_objects (object_type: column, table: <name>) for each
```

Pay attention to column types, nullable columns, and foreign key relationships — they inform how to write correct JOINs and WHERE clauses.

### 2. Sample the Data

Run a quick `SELECT TOP 10` to understand what the data actually looks like:

```sql
SELECT TOP 10 * FROM dbo.TableName;
```

This is the one place where `SELECT *` is acceptable — you're exploring, not building production queries. Look for patterns in the data: null values, date formats, unexpected values, encoding issues.

### 3. Validate or Debug

When validating a view or stored procedure, compare its output against the source tables:

- Check row counts match expectations
- Verify JOINs aren't producing duplicates (compare `COUNT(*)` vs `COUNT(DISTINCT key)`)
- Confirm date columns display correctly in both raw and formatted versions
- Ensure `TRY_CAST` / `TRY_CONVERT` handles edge cases in the actual data

### 4. Document Findings

When you discover something important — a data quality issue, an unexpected pattern, or a business rule embedded in the data — call it out explicitly in your response to the user. There's no dedicated MCP tool for this; the finding lives in the conversation.

## Query Guidelines for Exploration

### Date Columns

When querying views or SPs meant for human consumption, expect and verify two versions of each date column:

- A raw `DATETIME` / `DATE` column (for sorting/filtering)
- A `FORMAT(column, 'dd/MM/yyyy')` formatted column (for display)

If a human-facing view is missing the formatted version, flag it as something to fix.

### Type Safety

When exploring data that may have mixed or dirty types, use `TRY_CAST` / `TRY_CONVERT` in your exploratory queries too:

```sql
-- Check how many rows would fail a conversion
SELECT COUNT(*) AS FailedConversions
FROM dbo.ImportedRecords
WHERE TRY_CAST(AmountString AS DECIMAL(18,2)) IS NULL
    AND AmountString IS NOT NULL;
```

### Cross-Database Comparison

When comparing data across databases, you cannot JOIN across MCP connections. Instead:

1. Run the query on each database separately
2. Export results if needed
3. Compare key metrics (row counts, sums, date ranges) manually

### Performance-Aware Exploration

- Use `TOP` to limit results during exploration — avoid pulling entire tables
- Add `WHERE` filters early to narrow the dataset
- If a query is slow, check if the filtered columns have indexes via `search_objects` (`object_type: index`)

## Write Operations

Before executing any write via `execute_sql` (INSERT, UPDATE, DELETE, DDL):

1. Run a SELECT via `execute_sql` first to preview exactly which rows will be affected — show this to the user
2. Present a summary: *"This change will affect N rows in [table]. Do you confirm execution?"*
3. Wait for explicit confirmation before executing the write — never proceed on silence or ambiguity
4. For multi-statement operations, wrap in a `BEGIN TRANSACTION` and explain the rollback plan to the user before starting
5. Use `OUTPUT` clause to capture what was changed
6. After execution, show the row count affected and a sample of changed rows

## Common Tasks

### Validate a View After Modification

```sql
-- Check row count
SELECT COUNT(*) AS TotalRows FROM dbo.view_ExampleView;

-- Sample output
SELECT TOP 20 * FROM dbo.view_ExampleView ORDER BY SomeDateColumn DESC;

-- Verify date formatting is present
SELECT TOP 5
    SomeDateColumn,
    SomeDateColumnFormatted
FROM dbo.view_ExampleView;
```

### Check for Data Quality Issues

```sql
-- Find nulls in critical columns
SELECT COUNT(*) AS NullCount
FROM dbo.SomeTable
WHERE ImportantColumn IS NULL;

-- Find conversion failures
SELECT *
FROM dbo.SomeTable
WHERE TRY_CAST(StringColumn AS INT) IS NULL
    AND StringColumn IS NOT NULL;
```

### Compare Row Counts Across Related Tables

```sql
SELECT
    'Orders' AS TableName, COUNT(*) AS RowCount FROM dbo.Orders
UNION ALL
SELECT
    'OrderDetails', COUNT(*) FROM dbo.OrderDetails;
```
