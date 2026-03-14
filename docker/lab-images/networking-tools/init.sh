#!/bin/bash
# ═══════════════════════════════════════════════
# Networking Tools — Lab Init
# ═══════════════════════════════════════════════

# Create sample config files
mkdir -p ~/exercises

cat > ~/exercises/hosts.txt << 'EOF'
google.com
github.com
cloudflare.com
example.com
1.1.1.1
8.8.8.8
EOF

cat > ~/exercises/check_hosts.sh << 'SH'
#!/bin/bash
# Check connectivity to hosts from hosts.txt
while read host; do
    printf "%-20s " "$host"
    if ping -c 1 -W 2 "$host" &>/dev/null; then
        echo "✅ reachable"
    else
        echo "❌ unreachable"
    fi
done < ~/exercises/hosts.txt
SH
chmod +x ~/exercises/check_hosts.sh

# Create GUIDE.md
cat > ~/GUIDE.md << 'GUIDE'
# 🌐 Networking Tools — Exercise Guide

## Objective
Master network diagnostic tools: ping, dig, traceroute, curl, netstat, and ss.

## Exercises

### 1. Basic Connectivity (ping)
```bash
ping -c 4 google.com              # Send 4 pings
ping -c 3 -i 0.5 cloudflare.com   # Faster interval
ping -c 1 8.8.8.8                  # Ping by IP
bash ~/exercises/check_hosts.sh    # Check all hosts
```

### 2. DNS Lookups (dig/nslookup)
```bash
dig google.com                     # Full DNS query
dig google.com +short              # Just the IP
dig MX google.com                  # Mail server records
dig NS github.com                  # Nameserver records
nslookup example.com               # Alternative DNS lookup
dig @1.1.1.1 github.com           # Query specific DNS server
```

### 3. Route Tracing (traceroute)
```bash
traceroute -m 10 google.com       # Trace route (max 10 hops)
traceroute -n 8.8.8.8             # Numeric only (faster)
mtr -c 5 --report google.com     # Better traceroute (if available)
```

### 4. HTTP Requests (curl)
```bash
curl -I https://httpbin.org/get          # HTTP headers only
curl -s https://httpbin.org/ip           # Your public IP
curl -s https://httpbin.org/headers      # Request headers
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"name": "lab-user"}'              # POST request
curl -w "\nTime: %{time_total}s\n" -o /dev/null -s https://google.com  # Measure time
```

### 5. Port & Connection Analysis
```bash
ss -tlnp                           # Listening TCP ports
ss -tunap                          # All connections
netstat -rn                        # Routing table 
ip addr show                       # Network interfaces
ip route show                      # Routes
cat /etc/resolv.conf               # DNS config
```

## Tools Reference
| Tool | Purpose |
|------|---------|
| `ping` | Test connectivity |
| `dig` | DNS queries |
| `traceroute` | Route tracing |
| `curl` | HTTP requests |
| `ss` / `netstat` | Connection info |
| `ip` | Interface/route config |
GUIDE

# Welcome banner
echo ""
echo -e "\033[1;36m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║    🌐 Networking Tools                   ║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m🛠  Tools:\033[0m     ping, dig, curl, traceroute, ss, netstat"
echo -e "\033[33m📂 Scripts:\033[0m   ~/exercises/check_hosts.sh"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: ping -c 3 google.com\033[0m"
echo ""
echo "done"
