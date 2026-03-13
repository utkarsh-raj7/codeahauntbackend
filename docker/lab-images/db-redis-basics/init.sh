#!/bin/bash
sleep 1
redis-cli SET welcome "Hello from Redis lab!"
redis-cli HSET user:1 name "Alice" role "admin" score 95
redis-cli LPUSH tasks "deploy" "test" "build" "plan"
redis-cli ZADD leaderboard 100 "alice" 85 "bob" 92 "carol"
echo "Redis ready. Try: redis-cli PING"
echo "Sample data loaded — strings, hashes, lists, sorted sets"
