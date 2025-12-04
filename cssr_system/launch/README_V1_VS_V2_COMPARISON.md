# CSSR System Launch: Version 1 vs Version 2 Comparison

## Overview

The CSSR distributed launch system comes in two architectures:

- **Version 1 (V1)**: Computer as ROS Master
- **Version 2 (V2)**: Jetson as ROS Master

Both versions launch the same nodes with the same functionality. The only difference is **which machine runs roscore** and acts as the ROS Master.

---

## Architecture Comparison

### Version 1: Computer as ROS Master

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPUTER (ROS Master) ★                       │
│                                                                  │
│  ┌─────────────┐                                                │
│  │  roscore    │◄───────────────────┐                           │
│  │  (Master)   │                    │                           │
│  └──────┬──────┘                    │                           │
│         │                           │                           │
│  ┌──────▼──────────────┐            │                           │
│  │  All cognitive      │            │                           │
│  │  nodes (8 nodes)    │            │                           │
│  │  • robotLocalization│            │                           │
│  │  • robotNavigation  │            │                           │
│  │  • soundDetection   │            │                           │
│  │  • speechEvent      │            │                           │
│  │  • textToSpeech     │            │                           │
│  │  • overtAttention   │            │                           │
│  │  • gestureExecution │            │                           │
│  │  • behaviorController│           │                           │
│  └─────────────────────┘            │                           │
│         ▲                           │                           │
└─────────┼───────────────────────────┼───────────────────────────┘
          │                           │
          │ (subscribes to)           │ (registers with)
          │                           │
┌─────────┼───────────────────────────┼───────────────────────────┐
│         │                           │            JETSON         │
│  ┌──────┴──────────────┐            │                           │
│  │  • RealSense Camera │            │                           │
│  │  • faceDetection    │────────────┘                           │
│  │    (remote node)    │                                        │
│  └─────────────────────┘                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Computer runs roscore (ROS Master)
- Computer hosts parameter server
- Jetson connects as remote node
- Computer makes ROS service calls
- Computer manages mission execution

---

### Version 2: Jetson as ROS Master

```
┌─────────────────────────────────────────────────────────────────┐
│                      JETSON (ROS Master) ★                       │
│                                                                  │
│  ┌─────────────┐                                                │
│  │  roscore    │◄───────────────────┐                           │
│  │  (Master)   │                    │                           │
│  └──────┬──────┘                    │                           │
│         │                           │                           │
│  ┌──────▼──────────────┐            │                           │
│  │  • RealSense Camera │            │                           │
│  │  • faceDetection    │            │                           │
│  └─────────────────────┘            │                           │
│         ▲                           │                           │
└─────────┼───────────────────────────┼───────────────────────────┘
          │                           │
          │ (subscribes to)           │ (registers with)
          │                           │
┌─────────┼───────────────────────────┼───────────────────────────┐
│         │                           │          COMPUTER         │
│  ┌──────┴──────────────┐            │                           │
│  │  All cognitive      │            │                           │
│  │  nodes (8 nodes)    │────────────┘                           │
│  │  (remote nodes)     │                                        │
│  │  • robotLocalization│                                        │
│  │  • robotNavigation  │                                        │
│  │  • soundDetection   │                                        │
│  │  • speechEvent      │                                        │
│  │  • textToSpeech     │                                        │
│  │  • overtAttention   │                                        │
│  │  • gestureExecution │                                        │
│  │  • behaviorController│                                       │
│  └─────────────────────┘                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Jetson runs roscore (ROS Master)
- Jetson hosts parameter server
- Computer connects as remote node
- Jetson manages ROS infrastructure
- Computer still executes cognitive processing

---

## Quick Reference Table

| Feature | Version 1 | Version 2 |
|---------|-----------|-----------|
| **ROS Master** | Computer | Jetson |
| **roscore runs on** | Computer | Jetson |
| **Parameter Server on** | Computer | Jetson |
| **Jetson nodes** | Camera + faceDetection | Camera + faceDetection |
| **Computer nodes** | 8 cognitive nodes | 8 cognitive nodes |
| **Start sequence** | Computer first, then Jetson | Jetson first, then Computer |
| **Network dependency** | Jetson → Computer | Computer → Jetson |
| **Use case** | Computer-centric control | Robot-centric autonomy |

---

## Files Comparison

### Version 1 Files

| File | Purpose |
|------|---------|
| `cssrSystemLaunchComputer.launch` | Launch file for Computer (ROS Master) |
| `cssrSystemLaunchJetson.launch` | Launch file for Jetson (remote node) |
| `start_computer.sh` | Startup script for Computer (starts roscore) |
| `start_jetson.sh` | Startup script for Jetson (connects to Computer) |

### Version 2 Files

| File | Purpose |
|------|---------|
| `cssrSystemLaunchJetson_v2_master.launch` | Launch file for Jetson (ROS Master) |
| `cssrSystemLaunchComputer_v2_remote.launch` | Launch file for Computer (remote node) |
| `start_jetson_v2_master.sh` | Startup script for Jetson (starts roscore) |
| `start_computer_v2_remote.sh` | Startup script for Computer (connects to Jetson) |

---

## Startup Procedure Comparison

### Version 1 Startup

**Step 1: On Computer**
```bash
./start_computer.sh
# Starts roscore on Computer
# Launches 8 cognitive nodes
```

**Step 2: On Jetson**
```bash
./start_jetson.sh
# Connects to Computer's roscore
# Launches camera + face detection
```

**Network Setup (V1):**
- Computer: `ROS_MASTER_URI=http://COMPUTER_IP:11311`
- Jetson: `ROS_MASTER_URI=http://COMPUTER_IP:11311`

---

### Version 2 Startup

**Step 1: On Jetson**
```bash
./start_jetson_v2_master.sh
# Starts roscore on Jetson
# Launches camera + face detection
```

**Step 2: On Computer**
```bash
./start_computer_v2_remote.sh
# Connects to Jetson's roscore
# Launches 8 cognitive nodes
```

**Network Setup (V2):**
- Jetson: `ROS_MASTER_URI=http://JETSON_IP:11311`
- Computer: `ROS_MASTER_URI=http://JETSON_IP:11311`

---

## When to Use Each Version

### Use Version 1 (Computer as Master) When:

✅ **Computer is more reliable**
- Computer has better uptime
- Computer has stable power supply
- Computer is the central control station

✅ **Computer-centric development**
- Primary development happens on computer
- Easier to debug from computer
- Most tools run on computer

✅ **Heavy processing on Computer**
- Computer handles most computation
- Jetson is lightweight (just camera + detection)
- Centralized logging and monitoring

✅ **Network reliability**
- Computer has stable network connection
- Jetson may have intermittent connectivity

### Use Version 2 (Jetson as Master) When:

✅ **Robot autonomy is priority**
- Robot should operate independently
- Minimize dependency on external computer
- Robot-centric architecture

✅ **Jetson is always-on**
- Jetson is embedded in robot
- Jetson has reliable power (robot battery)
- Computer may be optional/auxiliary

✅ **Edge computing focus**
- Processing at the robot edge
- Reduced latency for sensor data
- Local decision making

✅ **Computer is optional**
- System can run with just Jetson (camera + face detection)
- Computer provides additional processing when available
- Graceful degradation if computer disconnects

✅ **Mobile robot deployment**
- Robot moves around with Jetson
- Computer is stationary base station
- Jetson maintains state as robot moves

---

## Performance Considerations

### Version 1 Performance

| Aspect | Impact |
|--------|--------|
| **Latency** | Camera data travels Jetson → Computer (one hop) |
| **Bandwidth** | High (camera streams to Computer) |
| **Processing** | Distributed (camera on Jetson, processing on Computer) |
| **Robustness** | Computer failure = system failure |
| **Scalability** | Easy to add more computers |

### Version 2 Performance

| Aspect | Impact |
|--------|--------|
| **Latency** | Camera data processed locally on Jetson |
| **Bandwidth** | Lower (only detection results sent to Computer) |
| **Processing** | Distributed (camera + detection on Jetson) |
| **Robustness** | Computer failure = degraded operation (still has camera) |
| **Scalability** | Easy to add more Jetsons (multiple robots) |

---

## Network Configuration Details

### Version 1 Network Setup

**Computer:**
```bash
export ROS_MASTER_URI=http://172.29.111.237:11311  # Points to itself
export ROS_IP=172.29.111.237                        # Computer IP
```

**Jetson:**
```bash
export ROS_MASTER_URI=http://172.29.111.237:11311  # Points to Computer
export ROS_IP=172.29.111.240                        # Jetson IP
```

### Version 2 Network Setup

**Jetson:**
```bash
export ROS_MASTER_URI=http://172.29.111.240:11311  # Points to itself
export ROS_IP=172.29.111.240                        # Jetson IP
```

**Computer:**
```bash
export ROS_MASTER_URI=http://172.29.111.240:11311  # Points to Jetson
export ROS_IP=172.29.111.237                        # Computer IP
```

---

## Migration Between Versions

### Switching from V1 to V2

1. **Stop V1 system:**
   ```bash
   # Stop all nodes (Ctrl+C in both terminals)
   # On Computer: pkill -f rosmaster
   ```

2. **Start V2 system:**
   ```bash
   # On Jetson first:
   ./start_jetson_v2_master.sh

   # Then on Computer:
   ./start_computer_v2_remote.sh
   ```

### Switching from V2 to V1

1. **Stop V2 system:**
   ```bash
   # Stop all nodes (Ctrl+C in both terminals)
   # On Jetson: pkill -f rosmaster
   ```

2. **Start V1 system:**
   ```bash
   # On Computer first:
   ./start_computer.sh

   # Then on Jetson:
   ./start_jetson.sh
   ```

**Note:** The nodes and functionality are identical. Only the ROS Master location changes.

---

## Troubleshooting Comparison

### V1: "Computer's roscore not accessible from Jetson"

**Solution:**
1. Check Computer is running: `ssh user@computer "pgrep rosmaster"`
2. Check firewall on Computer: `sudo ufw status`
3. Test connectivity: `ping COMPUTER_IP` from Jetson
4. Verify `ROS_MASTER_URI` on Jetson points to Computer

### V2: "Jetson's roscore not accessible from Computer"

**Solution:**
1. Check Jetson is running: `ssh user@jetson "pgrep rosmaster"`
2. Check firewall on Jetson: `sudo ufw status`
3. Test connectivity: `ping JETSON_IP` from Computer
4. Verify `ROS_MASTER_URI` on Computer points to Jetson

---

## Recommendations

### For Production Deployment: **Version 2** ✓

**Reasons:**
- Robot autonomy (Jetson stays with robot)
- Embedded system reliability
- Reduced network dependency
- Better for mobile robots
- Graceful degradation (works without Computer)

### For Development: **Version 1** ✓

**Reasons:**
- Easier debugging from powerful computer
- Better logging and monitoring
- Centralized control
- Easier to restart/modify nodes
- Better IDE integration on Computer

### For Research/Lab: **Either Version**

Choose based on:
- Which machine is more stable in your setup
- Where you do most development
- Your network infrastructure
- Your robot deployment model

---

## Summary

Both versions provide the **same functionality** with the **same nodes**. The choice between V1 and V2 depends on:

1. **Reliability**: Which machine is more stable?
2. **Architecture**: Computer-centric vs Robot-centric?
3. **Use case**: Development, production, or research?
4. **Network**: Which direction is more reliable?
5. **Deployment**: Stationary vs mobile robot?

**Most Common Choice**: **Version 1** for development, **Version 2** for deployment.

You can easily switch between versions without code changes—just use different launch scripts!

---

## Quick Decision Guide

**Choose Version 1 if:**
- Computer is your main control station
- You develop primarily on the computer
- Computer has better reliability

**Choose Version 2 if:**
- Robot should be autonomous
- Jetson is always-on with the robot
- Computer is optional/auxiliary

**Still unsure?** Start with **Version 1** (easier for debugging) and switch to Version 2 when deploying.

---

## Support

For either version:
- Full documentation: `README_LAUNCH_SYSTEM.md`
- Quick start: `QUICKSTART.md`
- Validation: `VALIDATION_CHECKLIST.md`

Questions? Check the troubleshooting section in the main README.
