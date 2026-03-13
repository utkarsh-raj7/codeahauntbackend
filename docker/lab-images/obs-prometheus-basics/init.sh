#!/bin/bash
/opt/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/tmp/prometheus-data &>/tmp/prometheus.log &
sleep 2
echo "Prometheus running on http://localhost:9090"
echo "Tasks:"
echo "1. Open: curl http://localhost:9090/api/v1/status/config"
echo "2. Try PromQL: curl 'http://localhost:9090/api/v1/query?query=up'"
