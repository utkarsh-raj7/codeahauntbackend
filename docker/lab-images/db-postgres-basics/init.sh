#!/bin/bash
# ═══════════════════════════════════════════════
# PostgreSQL Basics — Lab Init
# ═══════════════════════════════════════════════

# Start PostgreSQL
sudo service postgresql start 2>/dev/null || sudo pg_ctlcluster 14 main start 2>/dev/null

# Wait for PG to be ready
for i in {1..10}; do
    sudo -u postgres pg_isready -q && break
    sleep 1
done

# Create user and database
sudo -u postgres psql -c "CREATE USER labuser WITH PASSWORD 'labpass' SUPERUSER;" 2>/dev/null || true
sudo -u postgres createdb -O labuser labdb 2>/dev/null || true

# Seed with realistic data
psql -U labuser -d labdb << 'SQL'
-- Employees table
CREATE TABLE IF NOT EXISTS employees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  department TEXT NOT NULL,
  salary INTEGER NOT NULL,
  hired_at DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true
);

INSERT INTO employees (name, email, department, salary, hired_at) VALUES
  ('Alice Johnson', 'alice@company.com', 'Engineering', 95000, '2022-03-15'),
  ('Bob Smith', 'bob@company.com', 'Marketing', 72000, '2021-06-01'),
  ('Carol Williams', 'carol@company.com', 'Engineering', 88000, '2023-01-10'),
  ('Dave Brown', 'dave@company.com', 'HR', 65000, '2020-11-20'),
  ('Eve Davis', 'eve@company.com', 'Engineering', 102000, '2019-07-08'),
  ('Frank Miller', 'frank@company.com', 'Sales', 78000, '2022-09-12'),
  ('Grace Lee', 'grace@company.com', 'Engineering', 110000, '2018-04-03'),
  ('Henry Wilson', 'henry@company.com', 'Marketing', 69000, '2023-05-22'),
  ('Ivy Taylor', 'ivy@company.com', 'HR', 71000, '2021-02-14'),
  ('Jack Anderson', 'jack@company.com', 'Sales', 82000, '2020-08-30')
ON CONFLICT (email) DO NOTHING;

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER REFERENCES employees(id),
  product TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO orders (employee_id, product, amount, status) VALUES
  (1, 'Laptop', 1299.99, 'completed'),
  (2, 'Monitor', 449.50, 'completed'),
  (3, 'Keyboard', 129.00, 'shipped'),
  (1, 'Mouse', 59.99, 'pending'),
  (5, 'Headset', 199.00, 'completed'),
  (4, 'Webcam', 89.00, 'shipped'),
  (6, 'Desk', 549.00, 'pending'),
  (3, 'Chair', 399.00, 'completed')
ON CONFLICT DO NOTHING;
SQL

# Create GUIDE.md
cat > ~/GUIDE.md << 'GUIDE'
# 🗄 PostgreSQL Basics — Exercise Guide

## Objective
Learn SQL queries: SELECT, filtering, JOINs, aggregation, and data manipulation.

## Connect
```bash
psql -U labuser -d labdb
```

## Exercises

### 1. Explore the Database
```sql
\dt                                    -- List tables
\d employees                           -- Describe table structure
SELECT * FROM employees;               -- View all employees
SELECT * FROM orders;                  -- View all orders
```

### 2. Filtering & Sorting
```sql
SELECT name, department, salary FROM employees WHERE department = 'Engineering';
SELECT name, salary FROM employees WHERE salary > 80000 ORDER BY salary DESC;
SELECT * FROM employees WHERE hired_at > '2022-01-01';
SELECT * FROM employees WHERE name LIKE 'A%' OR name LIKE 'E%';
```

### 3. Aggregation
```sql
SELECT department, COUNT(*) as count, AVG(salary)::int as avg_salary
FROM employees GROUP BY department ORDER BY avg_salary DESC;

SELECT department, MAX(salary) - MIN(salary) as salary_range
FROM employees GROUP BY department;

SELECT COUNT(*) as total, SUM(amount) as revenue FROM orders WHERE status = 'completed';
```

### 4. JOINs
```sql
SELECT e.name, o.product, o.amount, o.status
FROM employees e JOIN orders o ON e.id = o.employee_id
ORDER BY o.amount DESC;

SELECT e.name, COALESCE(SUM(o.amount), 0) as total_spent
FROM employees e LEFT JOIN orders o ON e.id = o.employee_id
GROUP BY e.name ORDER BY total_spent DESC;
```

### 5. Data Manipulation
```sql
INSERT INTO employees (name, email, department, salary) 
VALUES ('Your Name', 'you@company.com', 'Engineering', 90000);

UPDATE employees SET salary = salary * 1.10 WHERE department = 'HR';

DELETE FROM orders WHERE status = 'pending';

-- Verify your changes
SELECT * FROM employees ORDER BY id DESC LIMIT 3;
```

## Useful Commands
- `\q` — quit psql
- `\dt` — list tables
- `\d tablename` — describe table
- `\x` — toggle expanded display
- `\timing` — toggle query timing
GUIDE

# Welcome banner
echo ""
echo -e "\033[1;33m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;33m║    🗄  PostgreSQL Basics                  ║\033[0m"
echo -e "\033[1;33m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[32m✅ PostgreSQL running\033[0m"
echo -e "\033[33m📊 Database:\033[0m  labdb (2 tables, 18 rows)"
echo -e "\033[33m🔗 Connect:\033[0m   psql -U labuser -d labdb"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: psql -U labuser -d labdb\033[0m"
echo ""
