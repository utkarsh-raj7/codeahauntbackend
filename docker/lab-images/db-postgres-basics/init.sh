#!/bin/bash
sudo service postgresql start
sudo -u postgres psql -c "CREATE USER labuser WITH PASSWORD 'labpass' SUPERUSER;" 2>/dev/null || true
sudo -u postgres createdb labdb 2>/dev/null || true
psql -U labuser -d labdb << 'SQL'
CREATE TABLE IF NOT EXISTS employees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  salary INTEGER NOT NULL,
  hired_at DATE DEFAULT CURRENT_DATE
);
INSERT INTO employees (name, department, salary) VALUES
  ('Alice', 'Engineering', 95000),
  ('Bob', 'Marketing', 72000),
  ('Carol', 'Engineering', 88000),
  ('Dave', 'HR', 65000),
  ('Eve', 'Engineering', 102000);
SQL
echo "PostgreSQL ready. Connect with: psql -U labuser -d labdb"
