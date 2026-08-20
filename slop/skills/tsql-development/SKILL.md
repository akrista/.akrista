---
name: tsql-development
description: "Develops and maintains Transact-SQL (TSQL) objects for Microsoft SQL Server — stored procedures, views, functions, tables, and indexes. Activates when creating, modifying, or debugging SQL files; writing SELECT/INSERT/UPDATE/DELETE queries; designing stored procedures or views; working with JOINs, CTEs, MERGE, or window functions; handling date formatting, type conversions, error handling, or performance tuning; or when the user mentions SQL, TSQL, stored procedure, view, query, table, index, or any database schema work."
license: MIT
metadata:
  author: Jorge Thomas
---

# TSQL Development

## When to Apply

Activate this skill when:

- Creating or modifying `.sql` files
- Writing stored procedures, views, functions, or triggers
- Designing or altering table schemas and indexes
- Writing or debugging SELECT, INSERT, UPDATE, DELETE, or MERGE queries
- Working with date formatting, type conversions, or null handling
- Optimizing query performance or reviewing execution plans

## Formatting

- Use 4 spaces for indentation (never tabs)
- Keywords in UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`, etc.)
- Identifiers in PascalCase or snake_case — be consistent within a file
- Align columns vertically in SELECT statements when it improves readability

## Naming Conventions

| Object | Convention | Example |
|--------|-----------|---------|
| Tables | PascalCase | `CustomerOrders` |
| Views | `view_` or `vw_` prefix | `view_CustomerSummary` |
| Stored Procedures | `sp_` or `usp_` prefix | `usp_GetCustomerOrders` |
| Functions | `fn_` or `ufn_` prefix | `ufn_CalculateTotal` |
| Variables/Parameters | `@` + PascalCase | `@CustomerId`, `@OrderDate` |
| Indexes | `IX_` or `IDX_` prefix | `IX_Orders_OrderDate` |
| Constraints | Descriptive prefix | `PK_Customers`, `FK_Orders_Customers` |

## Header Comments

Every stored procedure, function, and view must include a header block:

```sql
-- =============================================
-- Author: Your Name
-- Create date: YYYY-MM-DD
-- Description: Brief description of the object
-- =============================================
```

## Essential Patterns

### Schema Qualification

Always qualify objects with their schema — write `dbo.Customers`, never just `Customers`. This prevents ambiguity and accidental resolution to the wrong schema.

### SET NOCOUNT ON

Start every stored procedure with `SET NOCOUNT ON` to suppress row-count messages and reduce network overhead.

### Error Handling

Wrap procedural logic in `TRY...CATCH`. Use `THROW` to re-raise errors:

```sql
BEGIN TRY
    -- your logic here
END TRY
BEGIN CATCH
    THROW;
END CATCH
```

### Transactions

Use explicit `BEGIN TRANSACTION` / `COMMIT TRANSACTION` for multi-statement write operations. Always pair with `TRY...CATCH` so the transaction can be rolled back on failure:

```sql
BEGIN TRY
    BEGIN TRANSACTION;
        -- multiple statements
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
```

## Date Column Formatting

When building views or stored procedures whose output is consumed by humans (reports, dashboards, exports), provide **two versions** of each date column:

1. A raw `DATETIME` / `DATE` column for sorting and filtering
2. A formatted `VARCHAR` column using `FORMAT()` with the `dd/MM/yyyy` pattern

This lets consumers sort by the real date while displaying a human-friendly format.

**Example:**

```sql
SELECT
    o.OrderDate,
    FORMAT(o.OrderDate, 'dd/MM/yyyy') AS OrderDateFormatted,
    o.ShipDate,
    FORMAT(o.ShipDate, 'dd/MM/yyyy') AS ShipDateFormatted
FROM dbo.Orders o;
```

**Naming convention for formatted columns:** append `Formatted` to the original column name (e.g., `OrderDate` / `OrderDateFormatted`), or use a contextually clear alias if the view already has an established naming pattern.

When the view or SP is purely for programmatic consumption (API, ETL, joins), skip the formatted column — raw dates are sufficient.

## Type Conversions: Always Use TRY_ Variants

When converting or casting data types, **always use `TRY_CAST` and `TRY_CONVERT`** instead of `CAST` and `CONVERT`. The `TRY_` variants return `NULL` on failure instead of raising an error, which prevents unexpected query failures on dirty or inconsistent data.

| Use | Instead of |
|-----|------------|
| `TRY_CAST(value AS INT)` | `CAST(value AS INT)` |
| `TRY_CONVERT(DATE, value, 103)` | `CONVERT(DATE, value, 103)` |
| `TRY_CAST(value AS DECIMAL(18,2))` | `CAST(value AS DECIMAL(18,2))` |

**Example — safe date conversion:**

```sql
SELECT
    TRY_CONVERT(DATE, RawDateString, 103) AS ParsedDate,
    FORMAT(TRY_CONVERT(DATE, RawDateString, 103), 'dd/MM/yyyy') AS ParsedDateFormatted
FROM dbo.ImportedRecords;
```

The only exception is when you are 100% certain the source data is clean and the conversion cannot fail (e.g., casting between compatible numeric types within a controlled CTE). Even then, prefer `TRY_` unless there's a measurable performance reason not to.

## Query Writing Best Practices

### Columns

- Never use `SELECT *` in production code — explicitly list every column
- Use meaningful table aliases (`o` for Orders, `c` for Customers) and reference them consistently

### Joins

- Prefer `INNER JOIN` / `LEFT JOIN` syntax over comma-separated joins
- Use `EXISTS` instead of `IN` for subquery existence checks — it short-circuits and performs better

### Null Handling

- Use `ISNULL(column, default)` for simple two-argument null replacement
- Use `COALESCE(a, b, c)` when you need to chain multiple fallback values

### Set Operations

- Use `UNION ALL` instead of `UNION` when you know duplicates are not a concern — it avoids an expensive distinct sort

### CTEs and Window Functions

- Use CTEs (`WITH ... AS`) to break complex queries into readable steps
- Use `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()` for ranking and pagination
- Use `CROSS APPLY` / `OUTER APPLY` when you need to join against a table-valued expression per row

### MERGE for Upserts

Use the `MERGE` statement for insert-or-update patterns. Pair with the `OUTPUT` clause to capture affected rows when needed.

## Performance Considerations

- Create indexes on foreign keys and frequently filtered columns
- Avoid wrapping columns in functions inside `WHERE` clauses — this prevents index usage. Instead, transform the comparison value.
- Use `TOP` or `OFFSET...FETCH NEXT` for pagination
- Use `WITH (NOLOCK)` only when stale reads are acceptable — never on financial or transactional data
- For dynamic SQL, use `EXEC sp_executesql @sql, @params` with parameters — never concatenate user input into SQL strings

## Security

- Always use parameterized queries — never build SQL via string concatenation
- Grant minimum required permissions (principle of least privilege)
- Use schema-level security when appropriate
- Prefer parameterized stored procedures over ad-hoc queries for application access

## Stored Procedure Template

```sql
-- =============================================
-- Author: Your Name
-- Create date: YYYY-MM-DD
-- Description: Brief description
-- =============================================
CREATE PROCEDURE dbo.usp_ExampleProcedure
    @CustomerId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            o.OrderId,
            o.OrderDate,
            FORMAT(o.OrderDate, 'dd/MM/yyyy') AS OrderDateFormatted,
            o.TotalAmount,
            o.Status
        FROM dbo.Orders o
        WHERE o.CustomerId = @CustomerId
            AND (@StartDate IS NULL OR o.OrderDate >= @StartDate)
            AND (@EndDate IS NULL OR o.OrderDate <= @EndDate)
        ORDER BY o.OrderDate DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
```

## View Template

```sql
-- =============================================
-- Author: Your Name
-- Create date: YYYY-MM-DD
-- Description: Brief description
-- =============================================
CREATE VIEW dbo.view_CustomerOrderSummary
AS
SELECT
    c.CustomerId,
    c.CustomerName,
    o.OrderDate,
    FORMAT(o.OrderDate, 'dd/MM/yyyy') AS OrderDateFormatted,
    o.TotalAmount,
    TRY_CAST(o.Discount AS DECIMAL(18,2)) AS Discount
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId;
```

## Validation Before Finalizing

This is the canonical validation workflow — other project-specific skills can reference this section instead of repeating it.

Before writing or updating any SQL file on disk, validate the core query logic against real data:

1. Extract the core SELECT from the SP or view (strip the `CREATE`/`ALTER` wrapper)
2. Add `TOP 20` to limit results
3. Run it via the MCP `execute_sql` tool on the target database (see `tsql-data-exploration`)
4. Show the results to the user: row count, column names, sample rows, data formats
5. Wait for explicit user confirmation that the output looks correct
6. Only then write the file to disk

If the query fails, fix it and re-run before showing results — never present broken SQL for approval.

**If the query times out** (common on heavy views): simplify — query a source table directly to verify the filter column values exist, or drop the `ORDER BY`. The goal is to confirm the logic is sound, not to replicate the full object's performance.

**Format for sharing results:**
```
🔍 MCP validation completed (execute_sql):
- Rows returned: N
- Columns: col1, col2, col3, ...
- Data sample: [first 3-5 relevant rows]

Do the results look correct? Do you confirm creating the file?
```

## Common Pitfalls

- Using `CAST` / `CONVERT` instead of `TRY_CAST` / `TRY_CONVERT` — leads to hard failures on dirty data
- Missing the formatted date column on human-facing views — forces consumers to format dates themselves
- Forgetting `SET NOCOUNT ON` — causes unnecessary row-count messages
- Using `SELECT *` — breaks when columns change and hides intent
- Missing schema qualification — can resolve to the wrong schema
- Wrapping columns in functions in WHERE clauses — kills index usage
- Using `UNION` when `UNION ALL` would suffice — adds unnecessary sort overhead
- String-concatenated dynamic SQL — SQL injection risk
