# CSSR System - Validation Checklist

Use this checklist to validate your CSSR system installation and launch configuration.

## Pre-Launch Validation

### Environment Setup

#### Computer
- [ ] Ubuntu 20.04 installed
- [ ] ROS Noetic installed: `rosversion -d` returns "noetic"
- [ ] Workspace exists: `ls ~/workspace/pepper_rob_ws`
- [ ] Workspace built: `ls ~/workspace/pepper_rob_ws/devel/setup.bash`
- [ ] CSSR package found: `rospack find cssr_system`

#### Jetson
- [ ] Ubuntu 20.04 (L4T) installed
- [ ] ROS Noetic installed: `rosversion -d` returns "noetic"
- [ ] Workspace exists: `ls ~/workspace/pepper_rob_ws`
- [ ] Workspace built: `ls ~/workspace/pepper_rob_ws/devel/setup.bash`
- [ ] RealSense SDK installed: `realsense-viewer` launches

---

### Virtual Environments

#### Computer
Run these commands to verify virtual environments exist:

```bash
VENV_BASE=~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs

# Check sound detection env
ls $VENV_BASE/cssr4africa_sound_detection_env/bin/activate
# Check speech event env
ls $VENV_BASE/cssr4africa_speech_event_env/bin/activate
# Check text to speech env
ls $VENV_BASE/cssr4africa_text_to_speech_env/bin/activate
```

- [ ] cssr4africa_sound_detection_env exists
- [ ] cssr4africa_speech_event_env exists
- [ ] cssr4africa_text_to_speech_env exists

#### Jetson
```bash
VENV_BASE=~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs

# Check face person detection env
ls $VENV_BASE/cssr4africa_face_person_detection_env/bin/activate
```

- [ ] cssr4africa_face_person_detection_env exists

---

### Hardware Connectivity

#### Pepper Robot
```bash
# Test ping to robot
ping -c 3 172.29.111.230
```

- [ ] Pepper robot is powered on
- [ ] Pepper robot is reachable via network
- [ ] Pepper robot IP is correct (update if different)

#### RealSense Camera (on Jetson)
```bash
# Check USB connection
lsusb | grep Intel

# Test camera (optional)
realsense-viewer
```

- [ ] RealSense camera connected to Jetson USB 3.0 port
- [ ] RealSense camera detected by system
- [ ] Camera streams work in realsense-viewer

---

### Network Configuration

#### Computer
```bash
# Check IP address
ip addr show

# Check hostname resolution
hostname -I
```

- [ ] Computer IP address noted: ________________
- [ ] Computer can reach Jetson: `ping [JETSON_IP]`
- [ ] Firewall allows port 11311: `sudo ufw status`

#### Jetson
```bash
# Check IP address
ip addr show

# Check hostname resolution
hostname -I
```

- [ ] Jetson IP address noted: ________________
- [ ] Jetson can reach Computer: `ping [COMPUTER_IP]`
- [ ] Firewall allows port 11311: `sudo ufw status`

---

### Launch Files

#### Verify launch files exist
```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/launch

ls -la cssrSystemLaunchJetson.launch
ls -la cssrSystemLaunchComputer.launch
ls -la cssrSystemLaunchRobot.launch
ls -la cssrSystemLaunchMission.launch
```

- [ ] cssrSystemLaunchJetson.launch exists
- [ ] cssrSystemLaunchComputer.launch exists
- [ ] cssrSystemLaunchRobot.launch exists
- [ ] cssrSystemLaunchMission.launch exists

#### Verify scripts exist and are executable
```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts

ls -la start_computer.sh
ls -la start_jetson.sh
```

- [ ] start_computer.sh exists and is executable (-rwxr-xr-x)
- [ ] start_jetson.sh exists and is executable (-rwxr-xr-x)

---

## Launch Validation

### Test 1: Launch Computer Nodes

#### Execute
```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_computer.sh
```

#### Validate
In a new terminal:
```bash
# Wait 30 seconds, then check nodes
rosnode list
```

- [ ] roscore is running
- [ ] /naoqi_driver node is running
- [ ] /robotLocalization node is running
- [ ] /robotNavigation node is running
- [ ] /soundDetection node is running
- [ ] /speechEvent node is running
- [ ] /textToSpeech node is running
- [ ] /overtAttention node is running
- [ ] /gestureExecution node is running

#### Check for Errors
```bash
# View rosout for any error messages
rostopic echo /rosout | grep -i error
```

- [ ] No critical errors in rosout

---

### Test 2: Launch Jetson Nodes

#### Execute
On Jetson:
```bash
cd ~/workspace/pepper_rob_ws/src/cssr4africa_global/cssr_system/scripts
./start_jetson.sh
```

#### Validate
In a new terminal on Jetson (or Computer):
```bash
# Wait 15 seconds, then check nodes
rosnode list | grep -i face

# Check camera topics
rostopic list | grep camera

# Check face detection topic
rostopic list | grep faceDetection
```

- [ ] /camera/color/image_raw topic exists
- [ ] /camera/depth/image_rect_raw topic exists
- [ ] /faceDetection node is running
- [ ] /faceDetection/data topic is publishing

#### Test Data Flow
```bash
# Check face detection is publishing
rostopic hz /faceDetection/data
```

- [ ] Face detection topic is publishing (should show rate > 0 Hz)

---

### Test 3: Behavior Controller Launch

#### Execute
If behavior controller was not launched (launch_controller:=false), launch it separately:
```bash
# Wait until all other nodes are running (60+ seconds after computer launch)
rosrun cssr_system behaviorController
```

#### Validate
```bash
# Check behavior controller node
rosnode list | grep behaviorController

# Check services are available
rosservice list | grep -E "(gestureExecution|overtAttention|robotNavigation|textToSpeech)"
```

- [ ] /behaviorController node is running
- [ ] Required services are available:
  - [ ] /gestureExecution/perform_gesture
  - [ ] /overtAttention/set_mode
  - [ ] /robotNavigation/set_goal
  - [ ] /textToSpeech/say_text

---

### Test 4: Node Communication

#### Test Face Detection → Overt Attention
```bash
# Check overtAttention is receiving face detection data
rostopic echo /overtAttention/mode
```

- [ ] Overt attention mode changes based on face detection

#### Test Sound Detection → Speech Event
```bash
# Make sound near robot and check
rostopic echo /soundDetection/signal -n 1
rostopic echo /speechEvent/text
```

- [ ] Sound detection publishes audio signal
- [ ] Speech event transcribes speech (if speech detected)

#### Test Robot Localization → Robot Navigation
```bash
# Check localization pose is publishing
rostopic echo /robotLocalization/pose -n 1
```

- [ ] Robot localization publishes pose

---

### Test 5: End-to-End Mission Test

#### Execute Simple Mission
```bash
# Call text-to-speech service to verify system is responsive
rosservice call /textToSpeech/say_text "text: 'Hello, I am ready'"
```

- [ ] Robot speaks "Hello, I am ready"

#### Test Navigation
```bash
# Set a navigation goal (example coordinates)
rosservice call /robotNavigation/set_goal "x: 1.0
y: 0.5
theta: 0.0"
```

- [ ] Robot navigates to specified position (or attempts to)

#### Test Gesture Execution
```bash
# Perform a gesture
rosservice call /gestureExecution/perform_gesture "gesture_type: 'nod'"
```

- [ ] Robot executes nod gesture

---

## Performance Validation

### Check CPU Usage
```bash
# On Computer
top -b -n 1 | grep -E "(rosmaster|robot|cssr)"

# On Jetson
top -b -n 1 | grep -E "(faceDetection|camera)"
```

- [ ] CPU usage is reasonable (< 80% sustained)
- [ ] No nodes consuming excessive CPU

### Check Memory Usage
```bash
# On Computer
free -h

# On Jetson
free -h
```

- [ ] Memory usage is reasonable (< 90%)
- [ ] No memory leaks (check over 5 minutes)

### Check Network Latency
```bash
# From Jetson, check latency to Computer
ping -c 100 [COMPUTER_IP] | tail -5
```

- [ ] Average latency < 10ms (local network)
- [ ] No significant packet loss (< 1%)

---

## Troubleshooting Validation

### Test ROS Network Recovery

#### Simulate Network Disconnection
```bash
# On Jetson, temporarily disable network
sudo ifconfig [interface] down
sleep 5
sudo ifconfig [interface] up
```

- [ ] Nodes reconnect after network recovery
- [ ] No permanent errors after reconnection

### Test Node Crash Recovery

#### Kill a non-critical node
```bash
# Kill sound detection
rosnode kill /soundDetection

# Restart it
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_sound_detection_env/bin/activate
rosrun cssr_system sound_detection_application.py
```

- [ ] Node restarts successfully
- [ ] Dependent nodes continue working

---

## Final Validation

### Complete System Check

Run this command to generate a system report:

```bash
#!/bin/bash
echo "=== CSSR System Status Report ==="
echo "Date: $(date)"
echo ""
echo "=== Running Nodes ==="
rosnode list
echo ""
echo "=== Active Topics ==="
rostopic list
echo ""
echo "=== Available Services ==="
rosservice list | grep -E "(gestureExecution|overtAttention|robotNavigation|textToSpeech|speechEvent)"
echo ""
echo "=== Node Status ==="
for node in robotLocalization robotNavigation soundDetection speechEvent textToSpeech overtAttention gestureExecution behaviorController faceDetection; do
    echo -n "$node: "
    rosnode info /$node &> /dev/null && echo "✓ Running" || echo "✗ Not running"
done
```

- [ ] All required nodes are running
- [ ] All required topics are publishing
- [ ] All required services are available

---

## Sign-off

Once all checkboxes are marked, your CSSR system is validated and ready for use!

**Validated by:** ________________

**Date:** ________________

**Notes:**
```
[Add any notes about your specific configuration, known issues, or customizations]
```

---

## Reference

For issues encountered during validation, see:
- [README_LAUNCH_SYSTEM.md](README_LAUNCH_SYSTEM.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick reference guide
- ROS logs: `~/.ros/log/latest/`
