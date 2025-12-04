# CSSR System Launch Documentation

## Overview

This document describes how to launch the CSSR (Cognitive System for Social Robots) system. The system is distributed across two platforms:

1. **Jetson Nano/Xavier** (attached to robot): Runs RealSense camera and face detection
2. **Computer** (workstation): Runs robot interface and all other cognitive nodes

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         COMPUTER (ROS Master)                    │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐         │
│  │   roscore   │  │ Pepper Robot │  │  Jetson Nodes  │         │
│  │  (Master)   │  │  Interface   │  │  (via network) │         │
│  └─────────────┘  └──────────────┘  └────────────────┘         │
│         │               │                    │                  │
│         └───────────────┴────────────────────┘                  │
│                         │                                       │
│         ┌───────────────┴───────────────────┐                  │
│         │                                   │                  │
│  ┌──────▼──────┐                   ┌───────▼────────┐          │
│  │   Sensor    │                   │    Action      │          │
│  │   Layer     │                   │    Layer       │          │
│  │             │                   │                │          │
│  │ • robotLoc  │                   │ • robotNav     │          │
│  │ • soundDet  │                   │ • gesturExec   │          │
│  │ • faceDetect│────┐              │ • textToSpeech │          │
│  │   (Jetson)  │    │              │                │          │
│  │ • speechEvt │    │              └────────────────┘          │
│  │             │    │                      │                   │
│  └─────────────┘    │              ┌───────▼────────┐          │
│                     │              │ Coordination   │          │
│                     └─────────────►│     Layer      │          │
│                                    │                │          │
│                                    │ • overtAttn    │          │
│                                    │ • behaviorCtrl │          │
│                                    │                │          │
│                                    └────────────────┘          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        JETSON (Remote Node)                      │
│                                                                  │
│         ┌────────────────┐         ┌─────────────────┐         │
│         │   RealSense    │────────►│  faceDetection  │         │
│         │     Camera     │         │   (Python +     │         │
│         │                │         │    venv)        │         │
│         └────────────────┘         └─────────────────┘         │
│                                             │                   │
│                                             │                   │
│                                   Publishes to ROS Master       │
│                                   /faceDetection/data           │
│                                             │                   │
└─────────────────────────────────────────────┼───────────────────┘
                                              │
                                              ▼
                                    (Network to Computer)
```

## Quick Start

### Prerequisites

#### On Computer:
- Ubuntu 20.04 with ROS Noetic
- CSSR workspace built (`catkin_make`)
- Virtual environments installed:
  - `cssr4africa_sound_detection_env`
  - `cssr4africa_speech_event_env`
  - `cssr4africa_text_to_speech_env`
- Pepper robot connected and accessible
- Network configured for ROS distributed system

#### On Jetson:
- Ubuntu 20.04 with ROS Noetic (or Ubuntu 18.04 with ROS Melodic)
- CSSR workspace built
- Intel RealSense SDK 2.0 installed
- Virtual environment installed:
  - `cssr4africa_face_person_detection_env`
- RealSense camera connected
- Network configured to reach Computer's roscore

### Step-by-Step Launch Procedure

#### Step 1: Start Computer Nodes

On the **Computer**, run:

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_computer.sh
```

Or with custom IPs:

```bash
./start_computer.sh [COMPUTER_IP] [ROBOT_IP] [LAUNCH_CONTROLLER]
```

**Arguments:**
- `COMPUTER_IP`: IP of computer running roscore (default: 172.29.111.237)
- `ROBOT_IP`: IP of Pepper robot (default: 172.29.111.230)
- `LAUNCH_CONTROLLER`: Whether to launch behavior controller (true/false, default: true)

**Example:**
```bash
./start_computer.sh 192.168.1.100 192.168.1.200 true
```

This script will:
1. ✓ Check ROS workspace
2. ✓ Source ROS environment
3. ✓ Start roscore (if not running)
4. ✓ Configure ROS networking
5. ✓ Check robot connectivity
6. ✓ Launch all computer-side nodes

#### Step 2: Start Jetson Nodes

On the **Jetson**, run:

```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_jetson.sh
```

Or with custom IPs:

```bash
./start_jetson.sh [COMPUTER_IP] [JETSON_IP]
```

**Arguments:**
- `COMPUTER_IP`: IP of computer running roscore (default: 172.29.111.237)
- `JETSON_IP`: IP of this Jetson (default: 172.29.111.240)

**Example:**
```bash
./start_jetson.sh 192.168.1.100 192.168.1.150
```

This script will:
1. ✓ Check ROS workspace
2. ✓ Source ROS environment
3. ✓ Configure ROS networking to connect to Computer's roscore
4. ✓ Check RealSense camera connection
5. ✓ Launch camera and face detection

---

## Launch Files Reference

### 1. cssrSystemLaunchJetson.launch

**Location:** `cssr_system/launch/cssrSystemLaunchJetson.launch`

**Purpose:** Launches camera and face detection on Jetson

**Nodes Launched:**
1. RealSense camera driver
2. Face detection (with virtual environment)

**Key Parameters:**
- `ros_master_ip`: IP of computer running roscore
- `jetson_ip`: IP of this Jetson
- `face_person_detection_env_path`: Path to virtual environment
- `color_width`, `color_height`, `color_fps`: Camera settings
- `depth_width`, `depth_height`, `depth_fps`: Depth camera settings
- `align_depth`: Align depth to color (default: true)

**Usage:**
```bash
roslaunch cssr_system cssrSystemLaunchJetson.launch \
    ros_master_ip:=172.29.111.237 \
    jetson_ip:=172.29.111.240
```

---

### 2. cssrSystemLaunchComputer.launch

**Location:** `cssr_system/launch/cssrSystemLaunchComputer.launch`

**Purpose:** Launches robot interface and all cognitive nodes on computer

**Launch Sequence (with delays):**

| Time | Node | Dependencies | Virtual Env |
|------|------|--------------|-------------|
| 0s | Robot Actuators | Pepper robot | No |
| 0s | Robot Sensors | Pepper robot | No |
| 20s | robotLocalization | Camera, odometry | No |
| 25s | robotNavigation | robotLocalization | No |
| 20s | soundDetection | Audio nodes | Yes (sound_detection_env) |
| 30s | speechEvent | soundDetection | Yes (speech_event_env) |
| 20s | textToSpeech | Robot actuators | Yes (text_to_speech_env) |
| 35s | overtAttention | faceDetection, soundDetection, robotLocalization | No |
| 40s | gestureExecution | overtAttention, robotLocalization | No |
| 60s | behaviorController | All nodes | No |

**Key Parameters:**
- `robot_ip`: Pepper robot IP (default: 172.29.111.230)
- `roscore_ip`: Computer IP running roscore (default: 172.29.111.237)
- `network_interface`: Network interface name (default: wlp0s20f3)
- `launch_controller`: Launch behavior controller (default: true)
- `launch_actuators`: Launch robot actuators (default: true)
- `launch_sensors`: Launch robot sensors (default: true)
- `launch_audio_nodes`: Launch audio nodes (default: true)
- `initial_robot_x`, `initial_robot_y`, `initial_robot_theta`: Initial robot pose

**Usage:**
```bash
roslaunch cssr_system cssrSystemLaunchComputer.launch \
    robot_ip:=172.29.111.230 \
    roscore_ip:=172.29.111.237 \
    launch_controller:=true
```

---

### 3. cssrSystemLaunchRobot.launch

**Location:** `cssr_system/launch/cssrSystemLaunchRobot.launch`

**Purpose:** Launches only robot hardware interface (standalone)

**Use Case:** When you want to test robot hardware without cognitive nodes

**Usage:**
```bash
roslaunch cssr_system cssrSystemLaunchRobot.launch \
    robot_ip:=172.29.111.230 \
    camera:=realsense
```

---

### 4. cssrSystemLaunchMission.launch

**Location:** `cssr_system/launch/cssrSystemLaunchMission.launch`

**Purpose:** Launches all cognitive nodes (original unified launch file)

**Note:** This launch file assumes everything runs on one computer. Use `cssrSystemLaunchComputer.launch` and `cssrSystemLaunchJetson.launch` for distributed setup.

**Usage:**
```bash
roslaunch cssr_system cssrSystemLaunchMission.launch launch_controller:=true
```

---

## Node Dependencies

### Dependency Graph

```
RealSense Camera (Jetson)
    ↓
faceDetection (Jetson)
    ↓
    ├─────────────────────────────────┐
    │                                 │
    ▼                                 ▼
overtAttention  ←─── soundDetection ← naoqi_driver (audio)
    │                     ↓
    │                 speechEvent
    │
    ├─── robotLocalization ← RealSense Camera + Odometry
    │           ↓
    │       robotNavigation
    │
    ├─── gestureExecution
    │
    └─────────────┐
                  ▼
          behaviorController ← All nodes
                  ↑
          textToSpeech
```

### Critical Dependencies

1. **robotLocalization** requires:
   - RealSense camera (from Jetson)
   - Robot odometry (`/naoqi_driver/odom`)
   - Joint states

2. **robotNavigation** requires:
   - robotLocalization pose

3. **overtAttention** requires:
   - faceDetection data (from Jetson)
   - soundDetection direction
   - robotLocalization pose

4. **gestureExecution** requires:
   - overtAttention mode
   - robotLocalization pose

5. **speechEvent** requires:
   - soundDetection audio signal

6. **behaviorController** requires:
   - **ALL** other nodes

---

## Network Configuration

### ROS Environment Variables

#### On Computer (ROS Master):
```bash
export ROS_MASTER_URI=http://172.29.111.237:11311
export ROS_IP=172.29.111.237
```

#### On Jetson (Remote Node):
```bash
export ROS_MASTER_URI=http://172.29.111.237:11311  # Point to Computer
export ROS_IP=172.29.111.240                        # Jetson's IP
```

### Firewall Configuration

Ensure the following ports are open on both Computer and Jetson:

- **11311**: ROS Master
- **33691-33710**: ROS node communication (typical range)

**Ubuntu Firewall (UFW):**
```bash
sudo ufw allow 11311/tcp
sudo ufw allow 33691:33710/tcp
```

### Network Testing

#### Test roscore connection from Jetson:
```bash
# On Computer
roscore

# On Jetson (in another terminal)
export ROS_MASTER_URI=http://[COMPUTER_IP]:11311
export ROS_IP=[JETSON_IP]
rostopic list
```

If `rostopic list` works, the network is configured correctly.

---

## Troubleshooting

### Problem: "Cannot connect to roscore"

**Solution:**
1. Ensure roscore is running on Computer
2. Check `ROS_MASTER_URI` is set correctly on Jetson
3. Test network connectivity: `ping [COMPUTER_IP]`
4. Check firewall settings (port 11311)

### Problem: "Face detection not publishing"

**Solution:**
1. Check RealSense camera connection: `lsusb | grep Intel`
2. Verify virtual environment exists
3. Check ROS topics: `rostopic list | grep faceDetection`
4. View face detection logs: `rosnode list` then `rosnode info faceDetection`

### Problem: "Robot localization failing"

**Solution:**
1. Ensure RealSense camera is running (check on Jetson)
2. Verify robot odometry: `rostopic echo /naoqi_driver/odom`
3. Check ArUco markers are visible in camera view
4. Restart robotLocalization node

### Problem: "Nodes starting too fast, dependencies not met"

**Solution:**
The launch files use fixed delays. If your system is slower, you may need to increase delays:

Edit `cssrSystemLaunchComputer.launch` and increase `sleep` values:
```xml
<!-- Example: Increase from 25s to 30s -->
launch-prefix="bash -c 'sleep 30; $0 $@'"
```

### Problem: "Virtual environment not found"

**Solution:**
1. Check virtual environment path in launch file
2. Create missing virtual environment:
   ```bash
   cd ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs
   python3 -m venv cssr4africa_[name]_env
   source cssr4africa_[name]_env/bin/activate
   pip install -r requirements.txt
   ```

### Problem: "Behavior controller not responding"

**Solution:**
1. Check all dependent nodes are running: `rosnode list`
2. Verify all services are available: `rosservice list`
3. Check behaviorController logs: `rosnode info behaviorController`
4. Ensure mission specification file is correct

---

## Advanced Usage

### Launching Specific Nodes Only

If you want to launch only specific nodes, you can modify the launch files or use individual launch commands:

```bash
# Launch only robot hardware
roslaunch cssr_system cssrSystemLaunchRobot.launch

# Launch robot localization separately
rosrun cssr_system robotLocalization
```

### Debugging Individual Nodes

To debug a specific node, launch it separately with verbose output:

```bash
# Example: Debug face detection
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_face_person_detection_env/bin/activate
rosrun cssr_system face_detection_application.py
```

### Changing Camera Resolution

Edit `cssrSystemLaunchJetson.launch`:

```xml
<arg name="color_width"     default="1280" />  <!-- Change from 640 -->
<arg name="color_height"    default="720" />   <!-- Change from 480 -->
```

**Note:** Higher resolution increases processing load on Jetson.

### Running Without Behavior Controller

For testing individual nodes without the full mission system:

```bash
# On Computer
./start_computer.sh [COMPUTER_IP] [ROBOT_IP] false
```

This launches all nodes except behaviorController.

---

## System Requirements

### Computer (Workstation)

- **OS**: Ubuntu 20.04 LTS
- **ROS**: Noetic
- **CPU**: Intel i5 or better (i7 recommended)
- **RAM**: 8GB minimum (16GB recommended)
- **GPU**: NVIDIA GPU recommended for neural TTS models
- **Network**: Ethernet or WiFi with stable connection

### Jetson Nano/Xavier

- **OS**: Ubuntu 20.04 (L4T)
- **ROS**: Noetic
- **RAM**: 4GB minimum (Nano), 8GB+ (Xavier)
- **Storage**: 32GB+ SD card or NVMe
- **USB**: USB 3.0 port for RealSense camera
- **Network**: Ethernet or WiFi with stable connection to Computer

---

## Virtual Environments

### Location

All virtual environments should be in:
```
~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/
```

### Required Virtual Environments

1. **cssr4africa_face_person_detection_env** (Python 3.10)
   - Used by: faceDetection, personDetection
   - Requirements: opencv-python, mediapipe, numpy, onnxruntime-gpu

2. **cssr4africa_sound_detection_env** (Python 3.8)
   - Used by: soundDetection
   - Requirements: scipy, soundfile, webrtcvad, noisereduce

3. **cssr4africa_speech_event_env** (Python 3.8)
   - Used by: speechEvent
   - Requirements: nemo-toolkit, torch, transformers

4. **cssr4africa_text_to_speech_env** (Python 3.10)
   - Used by: textToSpeech
   - Requirements: TTS, pyyaml

### Creating Virtual Environments

See `cssr4africa_virtual_envs/README.md` for detailed installation instructions.

---

## Maintenance

### Updating Launch Configuration

To change IP addresses permanently:

1. Edit default values in launch files:
   ```bash
   vim cssr_system/launch/cssrSystemLaunchComputer.launch
   ```

2. Or edit scripts:
   ```bash
   vim cssr_system/scripts/start_computer.sh
   ```

### Adding New Nodes

To add a new node to the launch system:

1. Add node to appropriate launch file
2. Set correct delay based on dependencies
3. Add virtual environment if needed
4. Update this documentation

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review ROS logs: `~/.ros/log/latest/`
3. Check node status: `rosnode list` and `rosnode info [node_name]`
4. Contact CSSR development team

---

## License

Copyright © 2024 CSSR4Africa Project
