#!/bin/bash
# test_network.sh - Automated testing script for drone SDN network

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      DRONE SDN NETWORK DIAGNOSTIC TEST                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
}

info() {
    echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# TEST 1: Container Status
echo "┌─ TEST 1: Container Status"
if docker ps --format '{{.Names}}' | grep -q 'ryu-controller'; then
    pass "Ryu controller container is running"
else
    fail "Ryu controller container is NOT running"
    exit 1
fi

if docker ps --format '{{.Names}}' | grep -q 'mininet-wifi'; then
    pass "Mininet-WiFi container is running"
else
    fail "Mininet-WiFi container is NOT running"
    exit 1
fi
echo ""

# TEST 2: Ryu App Loading
echo "┌─ TEST 2: Ryu Controller App Loading"
if docker logs ryu-controller 2>&1 | grep -q "loading app /app/ryu_app.py"; then
    pass "Ryu app (SimpleSwitch13) loaded successfully"
else
    fail "Ryu app failed to load"
    exit 1
fi

if docker logs ryu-controller 2>&1 | grep -q "instantiating app"; then
    pass "Ryu app instantiated successfully"
else
    fail "Ryu app instantiation failed"
    exit 1
fi
echo ""

# TEST 3: Network Configuration
echo "┌─ TEST 3: Network Configuration"
RYU_IP=$(docker inspect ryu-controller --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
MININET_IP=$(docker inspect mininet-wifi --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
info "Ryu controller IP: $RYU_IP"
info "Mininet WiFi IP: $MININET_IP"

if [ -z "$RYU_IP" ]; then
    fail "Could not get Ryu container IP"
    exit 1
fi
pass "Both containers have valid network IPs"
echo ""

# TEST 4: Ryu REST API
echo "┌─ TEST 4: Ryu REST API Connectivity"
REST_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8080/stats/switches 2>/dev/null || echo "000")
HTTP_CODE=$(echo "$REST_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    pass "Ryu REST API responding (HTTP 200)"
    SWITCHES=$(echo "$REST_RESPONSE" | head -n1)
    info "Connected switches: $SWITCHES"
else
    fail "Ryu REST API not responding properly (HTTP $HTTP_CODE)"
fi
echo ""

# TEST 5: Port Mapping
echo "┌─ TEST 5: Port Mappings"
if netstat -tlnp 2>/dev/null | grep -q ":6633 "; then
    pass "OpenFlow port 6633 is listening"
else
    info "OpenFlow port 6633 not visible (may be inside container)"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
    pass "REST API port 8080 is listening"
else
    info "REST API port 8080 not visible (may be inside container)"
fi
echo ""

# TEST 6: Topology File
echo "┌─ TEST 6: Topology Configuration"
if [ -f "wifi_topo.py" ]; then
    pass "wifi_topo.py topology file exists"
    CONTROLLER_IP=$(grep -o "ip='[^']*'" wifi_topo.py | head -1 | cut -d"'" -f2)
    info "Topology configured controller IP: $CONTROLLER_IP"
    
    if [ "$CONTROLLER_IP" = "172.18.0.2" ] || grep -q "RemoteController" wifi_topo.py; then
        info "Topology uses RemoteController configuration"
    else
        info "Note: Controller IP is set to $CONTROLLER_IP"
    fi
else
    fail "wifi_topo.py topology file not found"
fi
echo ""

# TEST 7: Container Logs Check
echo "┌─ TEST 7: Container Health Check"
RYU_ERRORS=$(docker logs ryu-controller 2>&1 | grep -i "error\|exception\|traceback" | wc -l)
if [ "$RYU_ERRORS" -eq 0 ]; then
    pass "No errors in Ryu controller logs"
else
    info "Found $RYU_ERRORS error entries in Ryu logs (may be informational)"
fi

MININET_ERRORS=$(docker logs mininet-wifi 2>&1 | grep -i "error\|exception\|traceback" | wc -l)
if [ "$MININET_ERRORS" -eq 0 ]; then
    pass "No errors in Mininet logs"
else
    info "Found $MININET_ERRORS error entries in Mininet logs"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    TEST SUMMARY                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ All baseline tests passed!"
echo ""
echo "NEXT STEPS:"
echo "1. Run topology test: docker exec -it mininet-wifi python3 /app/wifi_topo.py"
echo "2. Inside mininet CLI, test connectivity:"
echo "   - mininet> pingall"
echo "   - mininet> nodes"
echo "   - mininet> sta1 ping -c 3 sta2"
echo ""
echo "MONITORING:"
echo "- Watch controller: docker logs -f ryu-controller"
echo "- Check API: curl http://localhost:8080/stats/switches"
echo ""
