#!/bin/bash
sleep 2
mongosh --quiet << 'JS'
use labdb
db.users.insertMany([
  { name: "Alice", role: "admin", scores: [95, 88, 91] },
  { name: "Bob", role: "student", scores: [72, 65, 78] },
  { name: "Carol", role: "student", scores: [88, 92, 85] }
])
db.products.insertMany([
  { name: "Laptop", price: 999, tags: ["electronics", "computing"] },
  { name: "Desk", price: 299, tags: ["furniture", "office"] }
])
JS
echo "MongoDB ready. Connect: mongosh labdb"
