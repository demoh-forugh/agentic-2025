# PostgreSQL Query Examples for n8n

This guide provides ready-to-use SQL queries for the PostgreSQL nodes in your n8n workflows.

---

## 🔌 Connection Setup

Before using these queries, ensure you have configured the PostgreSQL credential in n8n:

- **Host**: `postgres` (inside Docker) or `localhost` (outside Docker)
- **Port**: `5432`
- **Database**: `workshop_db`
- **User**: `workshop`
- **Password**: `workshop_password` (from your `.env` file)

---

## 📊 Customer Service Queries

### Fetch All Open Tickets

```sql
SELECT 
    id,
    customer_email,
    subject,
    message,
    priority,
    status,
    category,
    sentiment_score,
    created_at,
    updated_at
FROM customer_tickets
WHERE status = 'open'
ORDER BY 
    CASE priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END,
    created_at ASC;
```

**Use Case**: Get all open tickets sorted by priority and age for processing.

---

### Fetch High Priority Tickets Only

```sql
SELECT 
    id,
    customer_email,
    subject,
    message,
    priority,
    category,
    created_at
FROM customer_tickets
WHERE status = 'open'
  AND priority = 'high'
ORDER BY created_at ASC;
```

**Use Case**: Focus on urgent tickets first.

---

### Get Tickets by Category

```sql
SELECT 
    id,
    customer_email,
    subject,
    message,
    priority,
    created_at
FROM customer_tickets
WHERE category = 'technical_support'
  AND status = 'open'
ORDER BY created_at DESC;
```

**Use Case**: Route tickets to specialized teams.

**Available Categories**:
- `technical_support`
- `billing`
- `feature_request`
- `bug_report`
- `general`

---

### Update Ticket with AI Analysis

```sql
UPDATE customer_tickets
SET 
    sentiment_score = {{ $json.sentiment_score }},
    category = '{{ $json.category }}',
    priority = '{{ $json.priority }}',
    updated_at = CURRENT_TIMESTAMP
WHERE id = {{ $json.ticket_id }}
RETURNING *;
```

**Use Case**: Update ticket after AI analysis in previous node.

**Note**: Use `{{ $json.field_name }}` to reference data from previous n8n nodes.

---

### Insert AI-Generated Response

```sql
INSERT INTO customer_responses (
    ticket_id,
    response_text,
    response_type
) VALUES (
    {{ $json.ticket_id }},
    '{{ $json.response_text }}',
    'ai_generated'
)
RETURNING id, ticket_id, created_at;
```

**Use Case**: Save AI-generated response for review before sending.

---

### Get Ticket with All Responses

```sql
SELECT 
    t.id,
    t.customer_email,
    t.subject,
    t.message,
    t.priority,
    t.status,
    t.category,
    t.sentiment_score,
    t.created_at,
    json_agg(
        json_build_object(
            'response_id', r.id,
            'response_text', r.response_text,
            'response_type', r.response_type,
            'created_at', r.created_at
        ) ORDER BY r.created_at DESC
    ) AS responses
FROM customer_tickets t
LEFT JOIN customer_responses r ON t.id = r.ticket_id
WHERE t.id = {{ $json.ticket_id }}
GROUP BY t.id;
```

**Use Case**: Get complete ticket history with all responses.

---

### Close Ticket

```sql
UPDATE customer_tickets
SET 
    status = 'closed',
    updated_at = CURRENT_TIMESTAMP
WHERE id = {{ $json.ticket_id }}
RETURNING *;
```

**Use Case**: Mark ticket as resolved.

---

### Get Ticket Statistics

```sql
SELECT 
    status,
    priority,
    COUNT(*) as ticket_count,
    AVG(sentiment_score) as avg_sentiment,
    MIN(created_at) as oldest_ticket,
    MAX(created_at) as newest_ticket
FROM customer_tickets
GROUP BY status, priority
ORDER BY status, priority;
```

**Use Case**: Dashboard metrics and reporting.

---

## 💼 Sales & Analytics Queries

### Fetch All Sales Data

```sql
SELECT 
    id,
    transaction_date,
    customer_id,
    product_name,
    category,
    amount,
    region,
    sales_rep,
    created_at
FROM sales_data
ORDER BY transaction_date DESC;
```

**Use Case**: Get all sales records for analysis.

---

### Sales by Region

```sql
SELECT 
    region,
    COUNT(*) as total_transactions,
    SUM(amount) as total_revenue,
    AVG(amount) as avg_transaction_value,
    MIN(amount) as min_sale,
    MAX(amount) as max_sale
FROM sales_data
GROUP BY region
ORDER BY total_revenue DESC;
```

**Use Case**: Regional performance analysis.

---

### Sales by Product Category

```sql
SELECT 
    category,
    COUNT(*) as units_sold,
    SUM(amount) as total_revenue,
    AVG(amount) as avg_price
FROM sales_data
GROUP BY category
ORDER BY total_revenue DESC;
```

**Use Case**: Product category performance.

---

### Top Sales Representatives

```sql
SELECT 
    sales_rep,
    COUNT(*) as deals_closed,
    SUM(amount) as total_revenue,
    AVG(amount) as avg_deal_size,
    MAX(amount) as largest_deal
FROM sales_data
GROUP BY sales_rep
ORDER BY total_revenue DESC
LIMIT 10;
```

**Use Case**: Sales team leaderboard.

---

### Sales Trend by Date

```sql
SELECT 
    transaction_date,
    COUNT(*) as transactions,
    SUM(amount) as daily_revenue,
    AVG(amount) as avg_transaction
FROM sales_data
WHERE transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY transaction_date
ORDER BY transaction_date DESC;
```

**Use Case**: 30-day sales trend analysis.

---

### Insert New Sale

```sql
INSERT INTO sales_data (
    transaction_date,
    customer_id,
    product_name,
    category,
    amount,
    region,
    sales_rep
) VALUES (
    '{{ $json.date }}',
    '{{ $json.customer_id }}',
    '{{ $json.product }}',
    '{{ $json.category }}',
    {{ $json.amount }},
    '{{ $json.region }}',
    '{{ $json.sales_rep }}'
)
RETURNING *;
```

**Use Case**: Log new sales from CRM or webhook.

---

### High-Value Transactions

```sql
SELECT 
    transaction_date,
    customer_id,
    product_name,
    amount,
    region,
    sales_rep
FROM sales_data
WHERE amount > 1000
ORDER BY amount DESC;
```

**Use Case**: Identify and track high-value deals.

---

## 📈 Report Management Queries

### Save Generated Report

```sql
INSERT INTO processed_reports (
    report_type,
    report_data,
    generated_by
) VALUES (
    '{{ $json.report_type }}',
    '{{ $json.report_data }}'::jsonb,
    'n8n_workflow_{{ $workflow.id }}'
)
RETURNING id, report_type, created_at;
```

**Use Case**: Store AI-generated reports with metadata.

---

### Fetch Recent Reports

```sql
SELECT 
    id,
    report_type,
    report_data,
    generated_by,
    created_at
FROM processed_reports
ORDER BY created_at DESC
LIMIT 10;
```

**Use Case**: Retrieve recently generated reports.

---

### Get Reports by Type

```sql
SELECT 
    id,
    report_data,
    generated_by,
    created_at
FROM processed_reports
WHERE report_type = 'monthly_sales_summary'
ORDER BY created_at DESC;
```

**Use Case**: Filter reports by type.

---

## 🔍 Advanced Query Patterns

### Parameterized Query with Multiple Conditions

```sql
SELECT *
FROM customer_tickets
WHERE 1=1
  AND ($1::text IS NULL OR status = $1)
  AND ($2::text IS NULL OR priority = $2)
  AND ($3::text IS NULL OR category = $3)
ORDER BY created_at DESC;
```

**Parameters in n8n**:
- `$1`: `{{ $json.status || null }}`
- `$2`: `{{ $json.priority || null }}`
- `$3`: `{{ $json.category || null }}`

**Use Case**: Flexible filtering based on available parameters.

---

### Bulk Insert with UNNEST

```sql
INSERT INTO customer_tickets (
    customer_email,
    subject,
    message,
    priority,
    category
)
SELECT * FROM UNNEST(
    ARRAY[{{ $json.tickets.map(t => `'${t.email}'`).join(',') }}]::text[],
    ARRAY[{{ $json.tickets.map(t => `'${t.subject}'`).join(',') }}]::text[],
    ARRAY[{{ $json.tickets.map(t => `'${t.message}'`).join(',') }}]::text[],
    ARRAY[{{ $json.tickets.map(t => `'${t.priority}'`).join(',') }}]::text[],
    ARRAY[{{ $json.tickets.map(t => `'${t.category}'`).join(',') }}]::text[]
)
RETURNING *;
```

**Use Case**: Insert multiple tickets in one query.

---

### Conditional Update (Upsert)

```sql
INSERT INTO customer_tickets (
    customer_email,
    subject,
    message,
    priority,
    status
) VALUES (
    '{{ $json.email }}',
    '{{ $json.subject }}',
    '{{ $json.message }}',
    '{{ $json.priority }}',
    'open'
)
ON CONFLICT (customer_email, subject)
DO UPDATE SET
    message = EXCLUDED.message,
    priority = EXCLUDED.priority,
    updated_at = CURRENT_TIMESTAMP
RETURNING *;
```

**Note**: Requires unique constraint on `(customer_email, subject)`.

**Use Case**: Update existing ticket or create new one.

---

### Date Range Query

```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as tickets_created,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) as tickets_closed,
    AVG(sentiment_score) as avg_sentiment
FROM customer_tickets
WHERE created_at >= '{{ $json.start_date }}'
  AND created_at < '{{ $json.end_date }}'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Use Case**: Time-based ticket metrics.

---

### Join Query for Complex Analysis

```sql
SELECT 
    t.id,
    t.customer_email,
    t.subject,
    t.priority,
    t.status,
    t.created_at,
    COUNT(r.id) as response_count,
    MAX(r.created_at) as last_response_at,
    EXTRACT(EPOCH FROM (MAX(r.created_at) - t.created_at))/3600 as hours_to_respond
FROM customer_tickets t
LEFT JOIN customer_responses r ON t.id = r.ticket_id
WHERE t.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY t.id
HAVING COUNT(r.id) > 0
ORDER BY hours_to_respond ASC;
```

**Use Case**: Calculate response time metrics.

---

## 🛠️ Utility Queries

### Check Table Row Counts

```sql
SELECT 
    'customer_tickets' as table_name,
    COUNT(*) as row_count
FROM customer_tickets
UNION ALL
SELECT 
    'customer_responses' as table_name,
    COUNT(*) as row_count
FROM customer_responses
UNION ALL
SELECT 
    'sales_data' as table_name,
    COUNT(*) as row_count
FROM sales_data
UNION ALL
SELECT 
    'processed_reports' as table_name,
    COUNT(*) as row_count
FROM processed_reports;
```

**Use Case**: Database health check and monitoring.

---

### List All Tables

```sql
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Use Case**: Discover available tables.

---

### Get Table Schema

```sql
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'customer_tickets'
ORDER BY ordinal_position;
```

**Use Case**: Understand table structure.

---

### Test Database Connection

```sql
SELECT 
    current_database() as database,
    current_user as user,
    version() as postgres_version,
    NOW() as current_time;
```

**Use Case**: Verify connection and database info.

---

## 💡 Best Practices

### 1. **Use Parameterized Queries**

✅ **Good**:
```sql
WHERE id = {{ $json.ticket_id }}
```

❌ **Avoid**:
```sql
WHERE id = '{{ $json.ticket_id }}'  -- Can cause SQL injection
```

---

### 2. **Escape String Values**

When inserting user-provided text, escape single quotes:

```sql
'{{ $json.message.replace(/'/g, "''") }}'
```

Or use n8n's built-in SQL escaping in the PostgreSQL node settings.

---

### 3. **Use RETURNING Clause**

Always use `RETURNING *` or `RETURNING id` to get the inserted/updated data:

```sql
INSERT INTO customer_tickets (...) VALUES (...)
RETURNING *;
```

This allows you to use the result in subsequent nodes.

---

### 4. **Add Error Handling**

In your n8n workflow:
- Add an "Error Trigger" node to catch SQL errors
- Use "IF" node to check for empty results
- Log errors to a monitoring system

---

### 5. **Index Your Queries**

The `init-db.sql` already includes indexes for:
- `customer_tickets.status`
- `customer_tickets.priority`
- `customer_tickets.created_at`
- `sales_data.transaction_date`
- `sales_data.region`

Use these fields in your `WHERE` clauses for better performance.

---

### 6. **Limit Large Result Sets**

Always use `LIMIT` when fetching data for processing:

```sql
SELECT * FROM customer_tickets
WHERE status = 'open'
ORDER BY created_at ASC
LIMIT 100;
```

---

### 7. **Use Transactions for Multiple Operations**

For workflows that update multiple tables, use the "Execute Query" mode with transaction support.

---

## 🔗 Related Resources

- **Workflow Examples**: See `workflows/05-customer-service-db.json` for complete implementation
- **Database Schema**: See `examples/init-db.sql` for table definitions
- **n8n PostgreSQL Node Docs**: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/

---

## 🚀 Quick Start Checklist

1. ✅ Import workflow `05-customer-service-db.json`
2. ✅ Configure PostgreSQL credential in n8n
3. ✅ Test connection with: `SELECT COUNT(*) FROM customer_tickets;`
4. ✅ Copy a query from this guide
5. ✅ Paste into PostgreSQL node in your workflow
6. ✅ Replace `{{ $json.field }}` with your actual data
7. ✅ Execute and verify results

---

**Need help?** Check the [Troubleshooting Guide](../TROUBLESHOOTING.md) or [Workflow README](../../workflows/README.md).
