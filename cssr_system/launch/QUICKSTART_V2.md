# CSSR System - Quick Start Guide (Version 2: Jetson as Master)

## 🚀 Launch the System in 2 Steps

### Step 1: Start Jetson (First!)

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_jetson_v2_master.sh
```

**Wait for:** "roscore started successfully" and "Face detection" messages

---

### Step 2: Start Computer

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_computer_v2_remote.sh
```

**Wait for:** "Launching CSSR System Nodes on Computer" message

---

## ✅ Pre-Launch Checklist

### On Jetson (ROS Master):
- [ ] RealSense camera connected
- [ ] ROS workspace sourced
- [ ] Virtual environment installed
- [ ] Network connection stable

### On Computer (Remote Node):
- [ ] Pepper robot powered on and connected
- [ ] Network connection to Jetson working
- [ ] Virtual environments installed
- [ ] ROS workspace sourced

---

## 🔧 Custom IP Addresses

### Jetson:
```bash
./start_jetson_v2_master.sh [JETSON_IP]
# Example:
./start_jetson_v2_master.sh 192.168.1.240
```

### Computer:
```bash
./start_computer_v2_remote.sh [JETSON_IP] [COMPUTER_IP] [ROBOT_IP] [LAUNCH_CONTROLLER]
# Example:
./start_computer_v2_remote.sh 192.168.1.240 192.168.1.100 192.168.1.200 true
```

---

## 📊 Verify System is Running

```bash
# Check all nodes are running
rosnode list

# Should see:
# /faceDetection           (from Jetson)
# /robotLocalization       (from Computer)
# /robotNavigation         (from Computer)
# /soundDetection          (from Computer)
# /speechEvent             (from Computer)
# /textToSpeech            (from Computer)
# /overtAttention          (from Computer)
# /gestureExecution        (from Computer)
# /behaviorController      (from Computer)
```

---

## 🛑 Stop the System

Press `Ctrl+C` in each terminal where you launched the scripts.

**To stop roscore on Jetson:**
```bash
pkill -f rosmaster
```

---

## ⚠️ Common Issues

| Problem | Solution |
|---------|----------|
| "Cannot connect to roscore" | Ensure Jetson script is running first |
| "Face detection not found" | Check Jetson camera connection |
| "Robot not reachable" | Verify Pepper robot IP and power |
| "Virtual env missing" | Check paths in launch files |

---

## 🔄 Switching from Version 1 to Version 2

If you were using Version 1 (Computer as Master):

1. **Stop Version 1:**
   ```bash
   # Stop all nodes (Ctrl+C)
   # On Computer: pkill -f rosmaster
   ```

2. **Start Version 2:**
   ```bash
   # On Jetson: ./start_jetson_v2_master.sh
   # On Computer: ./start_computer_v2_remote.sh
   ```

---

## 📖 Full Documentation

- Version comparison: `README_V1_VS_V2_COMPARISON.md`
- Full system docs: `README_LAUNCH_SYSTEM.md`
- Validation: `VALIDATION_CHECKLIST.md`

---

## 🎯 Default IP Addresses

- **Jetson (ROS Master):** 172.29.111.240
- **Computer:** 172.29.111.237
- **Pepper Robot:** 172.29.111.230

**Change these in scripts if your network is different!**

---

## ⏱️ Launch Timeline

| Time | What's Happening |
|------|------------------|
| 0s | Jetson: roscore starts |
| 5s | Jetson: Camera initializing |
| 10s | Jetson: Face detection ready |
| 15s | Computer: Connecting to Jetson |
| 20s | Computer: Robot hardware starting |
| 25s | Computer: Robot localization starting |
| 30s | Computer: Navigation starting |
| 35s | Computer: Speech processing starting |
| 40s | Computer: Attention system starting |
| 45s | Computer: Gesture system starting |
| 60s | Computer: Behavior controller ready |

**Total time to full system ready: ~60 seconds**

---

## 🆘 Emergency Commands

```bash
# Kill all ROS nodes
rosnode kill -a

# Stop roscore on Jetson
ssh jetson@JETSON_IP "pkill -f rosmaster"

# Check what's using ROS port
netstat -tulpn | grep 11311
```

---

## 💡 Why Version 2?

Version 2 (Jetson as Master) is better for:
- ✅ Robot autonomy
- ✅ Embedded operation
- ✅ Mobile robots
- ✅ Production deployment
- ✅ Reduced network dependency

**See `README_V1_VS_V2_COMPARISON.md` for detailed comparison.**

---

## 🔗 Network Setup

**On Jetson (automatic in script):**
```bash
export ROS_MASTER_URI=http://172.29.111.240:11311  # Jetson as master
export ROS_IP=172.29.111.240
```

**On Computer (automatic in script):**
```bash
export ROS_MASTER_URI=http://172.29.111.240:11311  # Points to Jetson
export ROS_IP=172.29.111.237
```

---

**Remember:** Always start Jetson first (ROS Master), then Computer!

---

## ✨ Benefits of Version 2

| Benefit | Description |
|---------|-------------|
| **Robot Autonomy** | Robot can operate with just Jetson |
| **Better Uptime** | Jetson stays with robot, more reliable |
| **Edge Processing** | Camera data processed locally |
| **Graceful Degradation** | System works even if Computer disconnects |
| **Mobile Friendly** | Ideal for robots that move around |

---

**Need the Computer as Master instead?** Use Version 1 files:
- `start_computer.sh` (Computer as master)
- `start_jetson.sh` (Jetson as remote)
