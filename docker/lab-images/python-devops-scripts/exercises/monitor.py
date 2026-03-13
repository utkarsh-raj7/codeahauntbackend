"""
Build a system monitor that:
1. Uses psutil to get CPU and memory usage
2. Polls every 5 seconds
3. Writes metrics to a log file
4. Alerts (print WARNING) if CPU > 80% or memory > 90%
"""
import psutil, time, datetime

def get_metrics():
    return {
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "timestamp": datetime.datetime.now().isoformat()
    }

def monitor(log_file="metrics.log", interval=5):
    # TODO: implement the monitoring loop
    pass

if __name__ == "__main__":
    monitor()
