# Network Testing Guide for Drones in SDN

## Quick Status Check

### 1. Verify Containers Are Running
```bash
docker ps
# Should show:
# - ryu-controller (Up)
# - mininet-wifi (Up)
```

### 2. Check Ryu Controller Logs
```bash
docker logs ryu-controller
# Should show:
# - loading app /app/ryu_app.py
# - instantiating app SimpleSwitch13
# - OFPHandler loaded
```

---

## Testing Scenarios

### Test 1: Basic Connectivity (No Network)
**Purpose:** Verify containers can communicate

```bash
# Test 1A: Ping Ryu controller from your host
curl -v http://localhost:8080/stats/switches

# Expected: JSON response (even if empty [])
```

### Test 2: Test Ryu REST API
**Purpose:** Check Ryu is serving REST endpoints

```bash
# Get connected switches
curl http://localhost:8080/stats/switches

# Get flow table statistics (when switches connect)
curl http://localhost:8080/stats/flow/[DPID]

# Get port statistics
curl http://localhost:8080/stats/port/[DPID]
```

### Test 3: Test Mininet-WiFi Network Topology
**Purpose:** Create a simulated drone network and verify connectivity

**Step 1: Enter mininet container and run topology**
```bash
# Open terminal 1
docker exec -it mininet-wifi bash

# Inside container, run the topology
cd /root
python3 /app/wifi_topo.py
```

**Step 2: Run network tests (in mininet CLI)**
```
# Inside mininet> CLI:

# Test basic connectivity
mininet> sta1 ping -c 3 sta2

# Test OpenFlow flow table
mininet> sta1 ovs-ofctl dump-flows br-ap1

# Test switch connection to controller
mininet> sta1 ovs-vsctl get-controller br-ap1

# List all hosts
mininet> nodes

# View node details
mininet> dump
```

### Test 4: Monitor Controller Events
**Purpose:** See real-time Ryu controller activity

```bash
# Terminal 2: Watch Ryu logs
docker logs -f ryu-controller

# Should show when:
# - Switches connect/disconnect
# - Packets are processed
# - Flows are installed
```

### Test 5: Verify OpenFlow Version
**Purpose:** Ensure switches support OpenFlow 1.3

```bash
# Inside mininet CLI:
mininet> sta1 ovs-ofctl --version

# Or from container:
docker exec mininet-wifi ovs-ofctl --version
```

### Test 6: Network Performance Test
**Purpose:** Measure bandwidth between drones

```bash
# Inside mininet CLI:

# Terminal 1: Start iperf server on sta2
mininet> sta2 iperf -s -p 5001

# Terminal 2: Run iperf client from sta1
mininet> sta1 iperf -c 10.0.0.2 -p 5001 -t 10
```

### Test 7: Packet Inspection
**Purpose:** Debug packet flow

```bash
# Inside mininet CLI:

# Monitor traffic on access point
mininet> sta1 tcpdump -i ap1-sta1 -n

# Or from another mininet CLI tab
mininet> sta1 ping -c 5 sta2
```

---

## Expected Results

### Successful Network Behavior
✅ Containers running  
✅ Ryu controller responding to REST API  
✅ Mininet topology creates without errors  
✅ Ping between stations succeeds  
✅ OpenFlow flows are installed on switches  
✅ Controller receives switch connect/packet-in events  

### Common Issues & Fixes

| Issue | Symptom | Fix |
|-------|---------|-----|
| Controller not responding | Curl timeout | `docker logs ryu-controller` - check for errors |
| Ping fails | Connection refused | Verify `RemoteController` IP matches docker network |
| Flows not installed | tcpdump shows unhandled packets | Check Ryu app is loaded in logs |
| Mininet won't start | Docker exec fails | Verify mininet-wifi container is running |
| OVS won't connect to controller | ovs-vsctl shows empty controller | Check controller IP and port 6633 is accessible |

---

## Detailed Topology Testing

### Test the Full Wifi Topology (wifi_topo.py)

**Prerequisites:**
- Both containers running
- Network bridge configured (sdn-net)

**Steps:**

1. **Start monitoring (Terminal 1)**
```bash
docker logs -f ryu-controller
```

2. **Run topology (Terminal 2)**
```bash
docker exec -it mininet-wifi python3 /app/wifi_topo.py
```

3. **Test in mininet CLI (Terminal 2, after > appears)**
```
mininet> nodes
# Should show: c1 ap1 sta1 sta2 s1

mininet> ifconfig
# View IP addresses

mininet> sta1 ip link show
# Check wireless interfaces

mininet> ap1 ovs-ofctl show br-ap1
# View OpenFlow switch details

mininet> pingall
# Test all connectivity

mininet> net
# View topology graph
```

---

## Advanced Testing

### Test 1: Flow Table Analysis
```bash
# Inside mininet CLI:
mininet> sta1 ovs-ofctl dump-flows br-ap1 -O OpenFlow13
# Shows all installed flows in detailed format
```

### Test 2: Controller Packet Rate
```bash
# Inside mininet CLI:
mininet> sta1 ping -f sta2  # Flood ping
# Monitor Ryu logs for packet-in rate
```

### Test 3: Multi-Switch Network
Modify wifi_topo.py to add more APs:
```python
ap1 = net.addAccessPoint('ap1', ssid='ssid-ap1', ...)
ap2 = net.addAccessPoint('ap2', ssid='ssid-ap2', ...)
net.addLink(ap1, ap2)  # Connect APs
```

### Test 4: Mobility Simulation
```python
# In mininet CLI with position tracking:
mininet> py sta1.setPosition('100,100,0')
mininet> py sta2.setPosition('200,200,0')
mininet> sta1 ping sta2
```

---

## Success Checklist

- [ ] Docker containers running (`docker ps`)
- [ ] Ryu controller logs show app loaded
- [ ] REST API responds (`curl http://localhost:8080/stats/switches`)
- [ ] Mininet topology starts without errors
- [ ] pingall succeeds in mininet CLI
- [ ] ovs-ofctl shows switch connected to controller
- [ ] Ryu logs show switch_features event
- [ ] OpenFlow 1.3 flows appear in dump-flows output
- [ ] Iperf bandwidth test completes
- [ ] Packet inspection with tcpdump works

---

## Cleanup

```bash
# Exit mininet CLI
mininet> exit

# Stop all containers
docker compose down

# View container logs after stopping
docker logs mininet-wifi
docker logs ryu-controller

# Restart fresh
docker compose up -d
```
