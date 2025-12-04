# CSSR System - Quick Start Guide

## 🚀 Launch the System in 2 Steps

### Step 1: Start Computer (First!)

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_computer.sh
```

**Wait for:** "Launching CSSR System Nodes on Computer" message

---

### Step 2: Start Jetson

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_jetson.sh
```

**Wait for:** Face detection to start publishing data

---

## ✅ Pre-Launch Checklist

### On Computer:
- [ ] ROS workspace sourced
- [ ] Pepper robot powered on and connected
- [ ] Network connection stable
- [ ] Virtual environments installed

### On Jetson:
- [ ] RealSense camera connected
- [ ] Network connection to computer working
- [ ] Virtual environment installed

---

## 🔧 Custom IP Addresses

### Computer:
```bash
./start_computer.sh [COMPUTER_IP] [ROBOT_IP] [LAUNCH_CONTROLLER]
# Example:
./start_computer.sh 192.168.1.100 192.168.1.200 true
```

### Jetson:
```bash
./start_jetson.sh [COMPUTER_IP] [JETSON_IP]
# Example:
./start_jetson.sh 192.168.1.100 192.168.1.150
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

---

## ⚠️ Common Issues

| Problem | Solution |
|---------|----------|
| "Cannot connect to roscore" | Ensure computer script is running first |
| "Face detection not found" | Check Jetson camera connection |
| "Robot not reachable" | Verify Pepper robot IP and power |
| "Virtual env missing" | Check paths in launch files |

---

## 📖 Full Documentation

For detailed information, see [README_LAUNCH_SYSTEM.md](README_LAUNCH_SYSTEM.md)

---

## 🎯 Default IP Addresses

- **Computer (ROS Master):** 172.29.111.237
- **Jetson:** 172.29.111.240
- **Pepper Robot:** 172.29.111.230

**Change these in scripts if your network is different!**

---

## ⏱️ Launch Timeline

| Time | What's Happening |
|------|------------------|
| 0s | Robot hardware starting |
| 10s | Jetson camera initializing |
| 20s | Robot localization starting |
| 25s | Robot navigation starting |
| 30s | Speech processing starting |
| 35s | Attention system starting |
| 40s | Gesture system starting |
| 60s | Behavior controller ready |

**Total time to full system ready: ~60 seconds**

---

## 🆘 Emergency Commands

```bash
# Kill all ROS nodes
rosnode kill -a

# Stop roscore
pkill -f rosmaster

# Check what's using network
netstat -tulpn | grep 11311
```

---

**Remember:** Always start Computer first, then Jetson!
