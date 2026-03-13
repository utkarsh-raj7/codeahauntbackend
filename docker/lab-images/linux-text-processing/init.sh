#!/bin/bash
mkdir -p ~/data
cat > ~/data/users.csv << 'CSV'
id,name,role,score
1,alice,admin,95
2,bob,student,72
3,carol,student,88
4,dave,instructor,91
5,eve,student,63
CSV
cat > ~/data/server.log << 'LOG'
2026-03-01 10:00:01 INFO  Server started on port 3000
2026-03-01 10:00:05 INFO  Database connected
2026-03-01 10:01:22 ERROR Failed to process request: timeout
2026-03-01 10:02:11 WARN  Memory usage at 80%
2026-03-01 10:03:44 ERROR Disk write failed on /dev/sdb
2026-03-01 10:04:01 INFO  Backup completed successfully
LOG
echo "Files ready in ~/data/"
