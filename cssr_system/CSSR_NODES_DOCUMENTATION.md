# CSSR4Africa System - Node Documentation

**Version:** 2.0
**Last Updated:** 2025-12-16
**Author:** Ibrahim Jimoh (ioj@andrew.cmu.edu)

---

## Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [Hardware Architecture](#hardware-architecture)
3. [Node Launch Order](#node-launch-order)
4. [Node Descriptions](#node-descriptions)
   - [Jetson Nodes](#jetson-nodes)
   - [Computer Nodes](#computer-nodes)
5. [Node Dependencies](#node-dependencies)
6. [Virtual Environments](#virtual-environments)
7. [Network Configuration](#network-configuration)
8. [Troubleshooting](#troubleshooting)

---

## System Architecture Overview

The CSSR4Africa system is a **distributed robotic cognitive architecture** designed to enable culturally sensitive social interactions using a Pepper robot. The system runs across **two compute platforms**:

1. **Jetson Nano/Xavier** - Handles camera and computationally intensive perception tasks
2. **Computer** - Runs ROS master, robot interface, and all cognitive modules

### Design Principles

- **Distributed Processing**: Offload perception to Jetson for better performance
- **Modular Architecture**: Each cognitive function is a separate ROS node
- **Dependency-Aware Launch**: Nodes launch in order based on dependencies
- **Virtual Environments**: Python nodes use isolated environments for dependency management

---

## Hardware Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ROS Network                              │
│                    ROS_MASTER_URI: Computer                      │
└─────────────────────────────────────────────────────────────────┘
        │                          │                       │
   ┌────▼──────┐          ┌────────▼────────┐     ┌──────▼──────┐
   │  JETSON   │          │    COMPUTER     │     │   PEPPER    │
   │  (Slave)  │          │   (ROS Master)  │     │   ROBOT     │
   └───────────┘          └─────────────────┘     └─────────────┘

   • RealSense        • roscore                    • Actuators
     Camera           • Robot Interface            • Sensors
   • Face Detection   • All Cognitive Nodes        • Audio I/O
                      • Navigation                 • Odometry
                      • Behavior Control           • Joint States
```

### Network Configuration

| Device   | Default IP      | Role             | ROS Components                    |
|----------|-----------------|------------------|-----------------------------------|
| Computer | 172.29.111.237  | ROS Master       | roscore, cognitive nodes          |
| Jetson   | 172.29.111.240  | ROS Slave        | Camera, face detection            |
| Pepper   | 172.29.111.230  | Robot Platform   | Hardware interface via NAOqi SDK  |

---

## Node Launch Order

Nodes must launch in a specific order to satisfy dependencies:

### Jetson Launch Sequence

| Step | Node               | Wait Time | Purpose                              |
|------|--------------------|-----------|--------------------------------------|
| 0    | roscore            | -         | Start ROS master (on Computer)       |
| 1    | realsense2_camera  | 0s        | Intel RealSense D435 camera driver   |
| 2    | faceDetection      | 10s       | Face detection using camera stream   |

### Computer Launch Sequence

| Step | Node                | Wait Time | Dependencies                                |
|------|---------------------|-----------|---------------------------------------------|
| 0    | Robot Bringup       | 0s        | Pepper actuators and sensors                |
| 1    | robotLocalization   | 20s       | Camera, odometry, joint states              |
| 2    | robotNavigation     | 25s       | robotLocalization                           |
| 3    | soundDetection      | 20s       | naoqi_driver audio topics                   |
| 4    | speechEvent         | 30s       | soundDetection                              |
| 5    | textToSpeech        | 20s       | Robot actuators                             |
| 6    | overtAttention      | 35s       | faceDetection, soundDetection, robotLocalization |
| 7    | gestureExecution    | 40s       | overtAttention, robotLocalization           |
| 8    | behaviorController  | 60s       | ALL nodes (mission orchestrator)            |

---

## Node Descriptions

## Jetson Nodes

### 1. realsense2_camera

**Purpose:** Interface with Intel RealSense D435 depth camera

**Type:** C++ ROS driver (external package)

**Package:** `realsense2_camera`

**Launch Parameters:**
```xml
<arg name="color_width"     value="640" />
<arg name="color_height"    value="480" />
<arg name="color_fps"       value="15" />
<arg name="depth_width"     value="640" />
<arg name="depth_height"    value="480" />
<arg name="depth_fps"       value="15" />
<arg name="align_depth"     value="true" />
<arg name="enable_sync"     value="true" />
```

**Published Topics:**
- `/camera/color/image_raw` - RGB color stream (640x480 @ 15Hz)
- `/camera/depth/image_rect_raw` - Depth stream aligned to color
- `/camera/color/camera_info` - Camera calibration data

**Hardware Requirements:**
- Intel RealSense D435 camera
- USB 3.0 connection
- Jetson Nano/Xavier with RealSense SDK installed

**Dependencies:** None (first to launch)

**Notes:**
- `align_depth=true` ensures depth and color frames are pixel-aligned
- `enable_sync=true` synchronizes color and depth streams

---

### 2. faceDetection

**Purpose:** Detect human faces in camera stream and publish face positions

**Type:** Python application

**Package:** `cssr_system`

**Executable:** `face_detection_application.py`

**Namespace:** `faceDetection`

**Virtual Environment:** `cssr4africa_face_person_detection_env`

**Wait Time:** 10 seconds (for camera initialization)

**Launch Command:**
```bash
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_face_person_detection_env/bin/activate
rosrun cssr_system face_detection_application.py
```

**Subscribed Topics:**
- `/camera/color/image_raw` - RGB camera stream from RealSense
- `/camera/depth/image_rect_raw` - Depth data for 3D position calculation

**Published Topics:**
- `/faceDetection/face_detected` - Face detection events with 3D positions
- `/faceDetection/face_image` (optional) - Annotated image with face bounding boxes

**ROS Parameters:**
- `/faceDetection/camera` - Camera type ("realsense" or "pepper")
- `/faceDetection/unit_tests` - Enable test mode (default: false)

**Dependencies:**
- realsense2_camera (camera stream)
- Python libraries: OpenCV, dlib, face_recognition, numpy

**Algorithm:**
Uses dlib's HOG (Histogram of Oriented Gradients) face detector or CNN-based detector for robust face detection in varying lighting conditions.

**Performance:**
- Detection rate: ~15 Hz
- Range: 0.5m - 4m
- Field of view: 69° × 42° (RealSense D435)

---

## Computer Nodes

### 3. Robot Bringup (naoqi_driver & naoqi_dcm_driver)

**Purpose:** Interface with Pepper robot hardware (sensors and actuators)

**Type:** C++ ROS drivers

**Packages:** `naoqi_driver`, `naoqi_dcm_driver`, `pepper_description`, `pepper_control`

**Components:**

#### a) Actuators Group
- **pepper_upload.launch** - Loads robot URDF model
- **pepper_control_trajectory.launch** - Joint trajectory controller
- **naoqi_dcm_driver** - Low-level motor control interface

#### b) Sensors Group
- **naoqi_driver_node** - Main sensor driver (cameras, lasers, sonar, IMU)
- **naoqiAudioPublisher.py** - Audio stream publisher (Python 3)
- **naoqiAudio.py** - Audio recorder (Python 2)

**Launch Parameters:**
```xml
<arg name="robot_ip"            default="172.29.111.230" />
<arg name="robot_port"          default="9559" />
<arg name="roscore_ip"          default="172.29.111.237" />
<arg name="network_interface"   default="wlp0s20f3" />
<arg name="launch_actuators"    default="true" />
<arg name="launch_sensors"      default="true" />
<arg name="launch_audio_nodes"  default="true" />
```

**Published Topics (Sensors):**
- `/naoqi_driver/camera/front/image_raw` - Front camera (Pepper's head)
- `/naoqi_driver/camera/bottom/image_raw` - Bottom camera
- `/naoqi_driver/laser` - Laser scanner data
- `/naoqi_driver/sonar` - Sonar distance measurements
- `/naoqi_driver/odom` - Odometry (wheel encoders)
- `/joint_states` - Current joint positions and velocities
- `/naoqi_driver/audio` - Microphone array audio
- `/naoqi_driver/imu` - Inertial Measurement Unit data

**Subscribed Topics (Actuators):**
- `/pepper_dcm/joint_trajectory_controller/command` - Joint position commands
- `/cmd_vel` - Velocity commands for base movement

**Dependencies:**
- NAOqi SDK 2.5+
- Pepper robot powered on and connected to network
- Network interface correctly configured

**Notes:**
- Audio nodes wait 15 seconds before starting to ensure driver is ready
- Actuator stiffness is limited to 0.9 for safety
- `use_dcm=false` uses NAOqi API instead of DCM for compatibility

---

### 4. robotLocalization

**Purpose:** Estimate robot's global position and orientation in the environment

**Type:** C++ executable

**Package:** `cssr_system`

**Executable:** `robotLocalization`

**Namespace:** `robotLocalization`

**Wait Time:** 20 seconds (for sensors to stabilize)

**Launch Parameters:**
```xml
<param name="initial_robot_x"     value="0.0" />
<param name="initial_robot_y"     value="0.0" />
<param name="initial_robot_theta" value="0.0" />
```

**Subscribed Topics:**
- `/naoqi_driver/odom` - Wheel odometry
- `/joint_states` - Joint encoder data
- `/naoqi_driver/imu` - IMU orientation
- `/camera/color/image_raw` - Visual features for localization

**Published Topics:**
- `/robotLocalization/robot_pose` - Current robot pose (x, y, θ)
- `/robotLocalization/pose_covariance` - Pose uncertainty estimate
- `/tf` - Transform from map → base_link

**Algorithm:**
Extended Kalman Filter (EKF) fusing:
- Wheel odometry (fast, drifts over time)
- Visual odometry (camera-based, drift-free)
- IMU orientation (absolute heading)

**Dependencies:**
- `/naoqi_driver` (odometry, IMU, joint states)
- `/camera/color/image_raw` (optional for visual odometry)

**Notes:**
- Initializes pose to (0, 0, 0) or provided parameters
- Publishes TF transforms for RViz visualization
- Updates at ~30 Hz

---

### 5. robotNavigation

**Purpose:** Plan and execute collision-free navigation to goal positions

**Type:** C++ executable

**Package:** `cssr_system`

**Executable:** `robotNavigation`

**Namespace:** `robotNavigation`

**Wait Time:** 25 seconds (for robotLocalization to stabilize)

**Launch Parameters:**
```xml
<param name="robot_ip" value="172.29.111.230" />
```

**Subscribed Topics:**
- `/robotLocalization/robot_pose` - Current robot position
- `/naoqi_driver/laser` - Obstacle detection
- `/naoqi_driver/sonar` - Proximity sensing
- `/robotNavigation/goal` - Navigation goal commands

**Published Topics:**
- `/cmd_vel` - Velocity commands to robot base
- `/robotNavigation/path` - Planned path visualization
- `/robotNavigation/status` - Navigation status (active, reached, failed)

**Services:**
- `/robotNavigation/set_goal` - Set navigation goal (x, y, θ)
- `/robotNavigation/cancel_goal` - Cancel current navigation

**Algorithm:**
- **Path Planning:** A* algorithm on occupancy grid
- **Local Planning:** Dynamic Window Approach (DWA) for obstacle avoidance
- **Controller:** Pure pursuit with velocity smoothing

**Dependencies:**
- robotLocalization (current pose)
- naoqi_driver (laser, sonar, odometry)

**Performance:**
- Max velocity: 0.35 m/s (linear), 0.5 rad/s (angular)
- Planning frequency: 10 Hz
- Obstacle avoidance radius: 0.5m

**Notes:**
- Uses NAOqi API directly for motion control
- Pepper has non-holonomic constraints (cannot strafe sideways)

---

### 6. soundDetection

**Purpose:** Detect and localize sound sources (speech, claps, environmental sounds)

**Type:** Python application

**Package:** `cssr_system`

**Executable:** `sound_detection_application.py`

**Namespace:** `soundDetection`

**Virtual Environment:** `cssr4africa_sound_detection_env`

**Wait Time:** 20 seconds (for audio nodes to initialize)

**Launch Command:**
```bash
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_sound_detection_env/bin/activate
rosrun cssr_system sound_detection_application.py
```

**Subscribed Topics:**
- `/naoqi_driver/audio` - 4-channel microphone array audio (48kHz, 16-bit)

**Published Topics:**
- `/soundDetection/sound_detected` - Sound event with type and direction
- `/soundDetection/sound_direction` - Angle to sound source (radians)
- `/soundDetection/sound_energy` - Sound energy level (dB)

**ROS Parameters:**
- `/soundDetection/unit_test` - Enable test mode (default: false)

**Algorithm:**
- **Sound Detection:** Energy-based voice activity detection (VAD)
- **Sound Localization:** Cross-correlation between microphone pairs
- **Classification:** Basic sound type classification (speech, clap, noise)

**Dependencies:**
- naoqi_driver (audio stream)
- Python libraries: numpy, scipy, soundfile

**Performance:**
- Detection latency: ~100ms
- Localization accuracy: ±15° (frontal)
- Range: 0-5 meters (speech)

**Notes:**
- Pepper has 4 microphones arranged in a square on the head
- Works best in quiet environments (<60dB background noise)

---

### 7. speechEvent

**Purpose:** Perform speech recognition and extract semantic meaning from audio

**Type:** Python application

**Package:** `cssr_system`

**Executable:** `speech_event_application.py`

**Namespace:** `speechEvent`

**Virtual Environment:** `cssr4africa_speech_event_env`

**Wait Time:** 30 seconds (for soundDetection to start producing signals)

**Launch Command:**
```bash
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_speech_event_env/bin/activate
rosrun cssr_system speech_event_application.py
```

**Subscribed Topics:**
- `/soundDetection/sound_detected` - Sound event triggers
- `/naoqi_driver/audio` - Raw audio for speech recognition

**Published Topics:**
- `/speechEvent/speech_recognized` - Recognized speech text
- `/speechEvent/speech_intent` - Extracted user intent
- `/speechEvent/speech_confidence` - Recognition confidence (0.0-1.0)

**Algorithm:**
- **Speech Recognition:** Uses Google Speech API or offline Kaldi ASR
- **Intent Extraction:** Keyword spotting and simple NLU
- **Confidence Scoring:** Acoustic model confidence + language model

**Dependencies:**
- soundDetection (sound event triggers)
- naoqi_driver (audio stream)
- Python libraries: speech_recognition, nltk

**Supported Languages:**
- English (primary)
- French, Swahili (experimental)

**Performance:**
- Recognition latency: ~500ms-2s (online), ~1-3s (offline)
- Accuracy: 85-95% (clean speech), 60-80% (noisy)

**Notes:**
- Requires internet connection for Google Speech API
- Offline mode uses Kaldi (slower but privacy-preserving)

---

### 8. textToSpeech

**Purpose:** Convert text to speech and control robot's voice output

**Type:** Python application

**Package:** `cssr_system`

**Executable:** `text_to_speech_application.py`

**Namespace:** `textToSpeech`

**Virtual Environment:** `cssr4africa_text_to_speech_env`

**Wait Time:** 20 seconds (for robot actuators to initialize)

**Launch Command:**
```bash
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_text_to_speech_env/bin/activate
rosrun cssr_system text_to_speech_application.py
```

**Subscribed Topics:**
- `/textToSpeech/say` - Text string to speak

**Published Topics:**
- `/textToSpeech/speech_status` - Speaking status (idle, speaking, done)
- `/textToSpeech/speech_duration` - Estimated speech duration (seconds)

**Services:**
- `/textToSpeech/speak` - Service to speak text and wait for completion

**Algorithm:**
Uses NAOqi's ALTextToSpeech module with:
- Multiple voice options (male, female, child)
- Adjustable speed, pitch, volume
- Multi-language support

**Dependencies:**
- naoqi_driver (robot connection)
- Python libraries: naoqi SDK, pydub

**Supported Languages:**
- English (US, UK), French, Spanish, German, Italian, Japanese, Chinese

**Performance:**
- Synthesis latency: ~200-500ms
- Speech quality: High (neural TTS)

**Notes:**
- Can interrupt current speech with new text
- Supports SSML for advanced prosody control

---

### 9. overtAttention

**Purpose:** Determine what/who the robot should attend to (visual + auditory fusion)

**Type:** C++ executable

**Package:** `cssr_system`

**Executable:** `overtAttention`

**Namespace:** `overtAttention`

**Wait Time:** 35 seconds (for faceDetection, soundDetection, robotLocalization)

**Subscribed Topics:**
- `/faceDetection/face_detected` - Detected face positions
- `/soundDetection/sound_detected` - Sound event positions
- `/robotLocalization/robot_pose` - Robot's current pose

**Published Topics:**
- `/overtAttention/attention_target` - Primary attention target (person ID, 3D position)
- `/overtAttention/attention_state` - Current attention state (idle, person, sound, object)
- `/overtAttention/head_goal` - Head orientation target for tracking

**Algorithm:**
**Multi-modal Attention Selection:**
1. **Saliency Calculation:**
   - Visual saliency: Face size, proximity, centrality
   - Auditory saliency: Sound energy, direction
   - Temporal saliency: Novelty, recency
2. **Attention Arbitration:**
   - Prioritize faces over sounds
   - Prioritize frontal over peripheral
   - Prioritize novel over persistent
3. **Target Tracking:**
   - Kalman filter for smooth tracking
   - Predict target motion

**Dependencies:**
- faceDetection (visual targets)
- soundDetection (auditory targets)
- robotLocalization (robot reference frame)

**Parameters:**
- `face_priority_weight: 2.0` - Faces are 2x more salient than sounds
- `proximity_threshold: 2.0m` - Ignore targets beyond 2m
- `attention_timeout: 5.0s` - Drop targets after 5s of no detection

**Performance:**
- Update rate: 10 Hz
- Switching latency: ~300ms

**Notes:**
- Essential for natural interaction (robot looks at who's speaking)
- Image transport should use compressed for bandwidth efficiency

---

### 10. gestureExecution

**Purpose:** Execute gestures, pointing, and coordinated body movements

**Type:** C++ executable

**Package:** `cssr_system`

**Executable:** `gestureExecution`

**Namespace:** `gestureExecution`

**Wait Time:** 40 seconds (for overtAttention, robotLocalization)

**Subscribed Topics:**
- `/overtAttention/attention_target` - Target to gesture towards
- `/gestureExecution/gesture_command` - Gesture execution commands
- `/robotLocalization/robot_pose` - Robot pose for IK calculations

**Published Topics:**
- `/pepper_dcm/joint_trajectory_controller/command` - Joint trajectories
- `/gestureExecution/gesture_status` - Execution status
- `/gestureExecution/current_gesture` - Currently executing gesture

**Services:**
- `/gestureExecution/execute_gesture` - Execute named gesture
- `/gestureExecution/point_at` - Point at 3D position

**Gesture Library:**
- **Greetings:** wave, bow, handshake
- **Pointing:** point_left, point_right, point_forward
- **Expressiveness:** nod, shake_head, shrug
- **Cultural:** namaste, salaam, thumbs_up

**Algorithm:**
- **Inverse Kinematics:** Analytical IK for Pepper's 5-DOF arms
- **Motion Planning:** Quintic polynomial trajectories for smooth motion
- **Collision Avoidance:** Self-collision checking (arm vs. body)

**Dependencies:**
- overtAttention (gesture targets)
- robotLocalization (robot frame)
- naoqi_dcm_driver (joint control)

**Performance:**
- Gesture execution time: 1-5 seconds (gesture-dependent)
- IK solve time: <10ms
- Joint control rate: 50 Hz

**Notes:**
- Uses Pepper-specific kinematics utilities
- Gestures are culturally customizable

---

### 11. behaviorController

**Purpose:** Mission orchestrator - controls overall robot behavior and interaction flow

**Type:** C++ executable

**Package:** `cssr_system`

**Executable:** `behaviorController`

**Namespace:** `behaviorController`

**Wait Time:** 60 seconds (for ALL other nodes to be ready)

**Subscribed Topics:**
- `/faceDetection/face_detected`
- `/soundDetection/sound_detected`
- `/speechEvent/speech_recognized`
- `/overtAttention/attention_target`
- `/gestureExecution/gesture_status`
- `/robotNavigation/status`
- `/robotLocalization/robot_pose`

**Published Topics:**
- `/textToSpeech/say` - Speech output commands
- `/gestureExecution/gesture_command` - Gesture commands
- `/robotNavigation/goal` - Navigation goals
- `/behaviorController/mission_state` - Current mission state

**Services:**
- `/behaviorController/start_mission` - Start interaction mission
- `/behaviorController/stop_mission` - Stop mission gracefully

**Architecture:**
**Hierarchical Finite State Machine (HFSM):**
```
IDLE → APPROACH → GREET → INTERACT → FAREWELL → IDLE
         ↓          ↓         ↓           ↓
      Navigate   Wave+Say  Converse   Wave+Say
```

**States:**
1. **IDLE**: Wait for person detection
2. **APPROACH**: Navigate towards detected person
3. **GREET**: Culturally appropriate greeting
4. **INTERACT**: Main conversation and task execution
5. **FAREWELL**: End interaction and return to idle

**Knowledge Bases:**
- **Culture Knowledge Base:** Cultural norms, greetings, taboos
- **Environment Knowledge Base:** Locations, navigation goals

**Dependencies:**
- ALL other nodes (this is the top-level controller)

**Configuration Files:**
- `culture_database.yaml` - Cultural interaction rules
- `environment_map.yaml` - Environment semantic map

**Performance:**
- State transition latency: ~100-500ms
- Mission duration: 2-10 minutes (task-dependent)

**Notes:**
- **User prompt:** "Press 'Enter' to start the mission" (can be disabled)
- Uses multi-threaded architecture for responsiveness
- Implements timeout and error recovery for robust operation

---

## Node Dependencies

### Dependency Graph

```
                    ┌──────────────┐
                    │   roscore    │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼──────┐    ┌─────▼────────┐  ┌────▼─────────┐
    │ RealSense │    │ Robot Bringup│  │              │
    │  Camera   │    │ (Actuators + │  │              │
    └────┬──────┘    │   Sensors)   │  │              │
         │           └─────┬────────┘  │              │
         │                 │           │              │
    ┌────▼──────────┐      │           │              │
    │ faceDetection │      │           │              │
    └───────────────┘      │           │              │
                           │           │              │
              ┌────────────┼───────────┼──────────────┘
              │            │           │
         ┌────▼────┐  ┌────▼─────┐ ┌──▼──────────┐
         │robotLoc │  │soundDet  │ │textToSpeech │
         └────┬────┘  └────┬─────┘ └─────────────┘
              │            │
         ┌────▼────┐  ┌────▼──────┐
         │robotNav │  │speechEvent│
         └─────────┘  └───────────┘
              │            │
              └────────┬───┴───────┐
                       │           │
                  ┌────▼───────┐   │
                  │overtAttent │───┘
                  └────┬───────┘
                       │
                  ┌────▼──────────┐
                  │gestureExecut  │
                  └────┬──────────┘
                       │
                  ┌────▼─────────────┐
                  │behaviorController│
                  └──────────────────┘
```

### Critical Dependencies

| Node              | Critical Dependencies                          | Optional Dependencies |
|-------------------|------------------------------------------------|-----------------------|
| faceDetection     | realsense2_camera                              | -                     |
| robotLocalization | naoqi_driver (odom, joints, IMU)               | camera (visual odom)  |
| robotNavigation   | robotLocalization, naoqi_driver (laser, sonar) | -                     |
| soundDetection    | naoqi_driver (audio)                           | -                     |
| speechEvent       | soundDetection, naoqi_driver (audio)           | -                     |
| textToSpeech      | naoqi_driver                                   | -                     |
| overtAttention    | faceDetection, soundDetection, robotLocalization | -                   |
| gestureExecution  | overtAttention, robotLocalization, naoqi_dcm_driver | -                |
| behaviorController| ALL nodes                                      | -                     |

---

## Virtual Environments

### Why Virtual Environments?

Different CSSR nodes require **different Python versions and incompatible libraries**:
- **soundDetection**: Python 3.8, numpy 1.19, scipy 1.5
- **speechEvent**: Python 3.9, transformers 4.x, torch 1.12
- **textToSpeech**: Python 3.7, pyttsx3, pydub
- **faceDetection**: Python 3.8, face_recognition, dlib

Virtual environments isolate dependencies to prevent conflicts.

### Virtual Environment Locations

**Default Base Path:** `~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/`

| Node              | Virtual Environment Name                       |
|-------------------|------------------------------------------------|
| faceDetection     | `cssr4africa_face_person_detection_env`        |
| soundDetection    | `cssr4africa_sound_detection_env`              |
| speechEvent       | `cssr4africa_speech_event_env`                 |
| textToSpeech      | `cssr4africa_text_to_speech_env`               |

### How Virtual Environments are Activated

ROS launch files use the `launch-prefix` attribute:

```xml
<node pkg="cssr_system"
      type="sound_detection_application.py"
      name="soundDetection"
      launch-prefix="bash -c 'source ~/path/to/env/bin/activate; sleep 20; $0 $@'"/>
```

**Breakdown:**
1. `bash -c '...'` - Execute command in bash shell
2. `source .../activate` - Activate virtual environment
3. `sleep 20` - Wait for dependencies
4. `$0 $@` - Execute the node with arguments

---

## Network Configuration

### ROS Network Setup

All machines must be on the **same network** and able to communicate.

#### On Computer (ROS Master)

```bash
# ~/.bashrc or session setup
export ROS_MASTER_URI=http://172.29.111.237:11311
export ROS_IP=172.29.111.237
export ROS_HOSTNAME=172.29.111.237
```

#### On Jetson (ROS Slave)

```bash
# ~/.bashrc or session setup
export ROS_MASTER_URI=http://172.29.111.237:11311  # Computer's IP
export ROS_IP=172.29.111.240                       # Jetson's IP
export ROS_HOSTNAME=172.29.111.240
```

### Testing Network Connectivity

```bash
# Ping test
ping 172.29.111.230  # Pepper
ping 172.29.111.237  # Computer
ping 172.29.111.240  # Jetson

# ROS connectivity test
# On Computer:
rostopic list

# On Jetson (after setting ROS_MASTER_URI):
rostopic list  # Should show same topics as Computer
```

### Firewall Configuration

If nodes cannot communicate, disable firewall or open ports:

```bash
# Ubuntu - allow ROS ports
sudo ufw allow 11311/tcp  # ROS master
sudo ufw allow 33000:34000/tcp  # ROS dynamic ports
```

---

## Troubleshooting

### Common Issues

#### 1. "Unable to contact ROS master" on Jetson

**Cause:** ROS_MASTER_URI not set or incorrect

**Solution:**
```bash
# On Jetson, verify:
echo $ROS_MASTER_URI
# Should output: http://172.29.111.237:11311

# If not, set it:
export ROS_MASTER_URI=http://172.29.111.237:11311
export ROS_IP=172.29.111.240
```

#### 2. faceDetection crashes with "ImportError: No module named cv2"

**Cause:** Virtual environment not activated or missing dependencies

**Solution:**
```bash
# Manually activate and test:
source ~/workspace/pepper_rob_ws/src/cssr4africa_virtual_envs/cssr4africa_face_person_detection_env/bin/activate
python3 -c "import cv2; print(cv2.__version__)"

# If error persists, reinstall:
pip install opencv-python face_recognition dlib
```

#### 3. naoqi_driver cannot connect to robot

**Cause:** Wrong robot IP or robot not powered on

**Solution:**
```bash
# Test connection:
ping 172.29.111.230

# Test NAOqi:
python -c "import qi; session = qi.Session(); session.connect('tcp://172.29.111.230:9559'); print('Connected!')"
```

#### 4. Nodes launching in wrong order / Dependency failures

**Cause:** Launch wait times too short or dependencies not ready

**Solution:**
Increase wait times in launch files:
```xml
<!-- Increase from 20s to 30s -->
<node ... launch-prefix="bash -c 'sleep 30; $0 $@'" />
```

#### 5. overtAttention gets no face detections

**Cause:** Image transport bandwidth issue or topic mismatch

**Solution:**
```bash
# Check if faceDetection is publishing:
rostopic echo /faceDetection/face_detected

# If using compressed transport:
rosrun cssr_system overtAttention _image_transport:=compressed
```

#### 6. behaviorController not starting mission

**Cause:** Waiting for user input "Press 'Enter' to start"

**Solution:**
- **Option 1:** Press Enter in terminal when prompted
- **Option 2:** Use GUI launcher (auto-sends Enter)
- **Option 3:** Modify code to remove prompt (in `behaviorControllerImplementation.cpp`)

---

## Quick Reference

### Launch Commands

#### Start Everything (Unified Script)
```bash
cd ~/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts
./start_unified_system.sh
```

#### Start Everything (GUI)
```bash
cd ~/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts
python3 cssr_launcher_gui.py
```

#### Manual Launch (Jetson)
```bash
# On Jetson:
roslaunch cssr_system cssrSystemLaunchJetson.launch \
  ros_master_ip:=172.29.111.237 \
  jetson_ip:=172.29.111.240
```

#### Manual Launch (Computer)
```bash
# On Computer:
roscore  # Terminal 1

# Terminal 2:
roslaunch cssr_system cssrSystemLaunchComputer.launch \
  robot_ip:=172.29.111.230 \
  roscore_ip:=172.29.111.237 \
  launch_controller:=true
```

### Useful Commands

```bash
# List all running nodes
rosnode list

# Check node info
rosnode info /faceDetection

# Monitor a topic
rostopic echo /overtAttention/attention_target

# Visualize system
rosrun rqt_graph rqt_graph

# Check TF tree
rosrun rqt_tf_tree rqt_tf_tree
```

---

## Additional Resources

- **ROS Wiki:** http://wiki.ros.org/
- **Pepper Documentation:** http://doc.aldebaran.com/
- **RealSense SDK:** https://github.com/IntelRealSense/librealsense
- **Project Repository:** [Your GitHub URL]

---

**End of Documentation**
