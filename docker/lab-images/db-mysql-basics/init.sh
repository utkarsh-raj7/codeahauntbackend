#!/bin/bash
sleep 2
mysql -u root -plabpass << 'SQL'
CREATE DATABASE IF NOT EXISTS shopdb;
USE shopdb;
CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  price DECIMAL(10,2),
  stock INT
);
INSERT INTO products (name, price, stock) VALUES
  ('Laptop', 999.99, 50),
  ('Mouse', 29.99, 200),
  ('Keyboard', 79.99, 150);
CREATE USER IF NOT EXISTS 'labuser'@'localhost' IDENTIFIED BY 'labpass';
GRANT ALL ON shopdb.* TO 'labuser'@'localhost';
SQL
echo "MySQL ready. Connect: mysql -u labuser -plabpass shopdb"
