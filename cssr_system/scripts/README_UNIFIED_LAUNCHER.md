# CSSR System - Unified Launcher Guide

This guide covers two new ways to launch the CSSR system that are easier and more user-friendly.

## Table of Contents

1. [Option 1: Unified Script (Single Command)](#option-1-unified-script)
2. [Option 2: GUI Launcher (Point-and-Click)](#option-2-gui-launcher)
3. [Comparison](#comparison)
4. [Setup Instructions](#setup-instructions)

---

## Option 1: Unified Script

**What it is:** A single bash script that launches nodes on both Jetson and Computer.

**How it works:** Uses SSH to execute commands on the remote machine.

### Features

✅ Single command launches everything
✅ No need to SSH manually into each machine
✅ Supports named arguments
✅ Automatic pre-flight checks
✅ Can run from either Jetson or Computer

### Prerequisites

**You must set up passwordless SSH between machines:**

```bash
# On the controlling machine (where you'll run the script)
ssh-keygen -t rsa -b 4096

# Copy key to remote machine
# If running from Computer:
ssh-copy-id cssr4africa@172.29.111.240  # Jetson

# If running from Jetson:
ssh-copy-id cssr4africa1@172.29.111.237  # Computer

# Test SSH (should NOT ask for password)
ssh user@remote-ip "echo 'SSH works!'"
```

### Usage

```bash
# Navigate to scripts directory
cd ~/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts

# Make script executable (first time only)
chmod +x start_unified_system.sh

# Run with all defaults (from Computer)
./start_unified_system.sh

# Run with custom IPs
./start_unified_system.sh --jetson-ip=192.168.1.240 --computer-ip=192.168.1.237

# Run from Jetson instead
./start_unified_system.sh --control-from=jetson

# Without behavior controller
./start_unified_system.sh --launch-controller=false

# Show help
./start_unified_system.sh --help
```

### How It Works

**When running from Computer:**

1. Script executes on Computer
2. SSH into Jetson → Start roscore + camera + face detection
3. Wait 15 seconds for Jetson to initialize
4. Start Computer nodes locally

**When running from Jetson:**

1. Script executes on Jetson
2. Start roscore + camera + face detection locally
3. Wait 15 seconds
4. SSH into Computer → Start Computer nodes

### Stopping the System

Press `Ctrl+C` to stop all nodes. The script will clean up processes on both machines.

---

## Option 2: GUI Launcher

**What it is:** A graphical application with buttons and status indicators.

**Best for:** Non-technical users, demonstrations, or when you prefer a visual interface.

### Features

✅ **Big START button** - One click to launch everything
✅ **Real-time status indicators** - See which nodes are running
✅ **Live log window** - Monitor system output
✅ **IP configuration fields** - Easy to change settings
✅ **Pre-flight checks** - Automatic network testing
✅ **Stop button** - Cleanly shutdown system

### Installation

```bash
# Install required Python package (if not already installed)
pip3 install tk

# Navigate to scripts directory
cd ~/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts

# Make script executable
chmod +x cssr_launcher_gui.py
```

### Running the GUI

**Method 1: From Terminal**

```bash
cd ~/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts
python3 cssr_launcher_gui.py
```

**Method 2: Desktop Shortcut (Recommended)**

```bash
# Copy desktop launcher to Desktop
cp CSSR_Launcher.desktop ~/Desktop/

# Make it executable
chmod +x ~/Desktop/CSSR_Launcher.desktop

# Double-click the icon on your Desktop to launch!
```

**Method 3: Add to Applications Menu**

```bash
# Copy to applications folder
mkdir -p ~/.local/share/applications
cp CSSR_Launcher.desktop ~/.local/share/applications/

# Now you can launch from your system's application menu
```

### Using the GUI

#### Configuration Panel

Fill in the IP addresses:
- **Jetson IP**: IP address of Jetson (default: 172.29.111.240)
- **Computer IP**: IP address of Computer (default: 172.29.111.237)
- **Robot IP**: IP address of Pepper robot (default: 172.29.111.230)
- **Launch Behavior Controller**: Check/uncheck to enable/disable
- **Control from**: Select "computer" or "jetson"

#### Starting the System

1. **Check your configuration** in the Configuration Panel
2. **Click the green "START SYSTEM" button**
3. **Watch the status indicators** turn green as nodes start
4. **Monitor the log window** for detailed output

#### Status Indicators

The GUI shows real-time status for:
- 🟢 **ROS Master** - roscore running
- 🟢 **Camera** - RealSense camera active
- 🟢 **Face Detection** - Face detection node running
- 🟢 **Robot Interface** - Pepper connection active
- 🟢 **Navigation** - Navigation stack running
- 🟢 **Behavior Controller** - Mission control active

Colors:
- **Gray (●)** - Stopped/Not running
- **Orange (●)** - Starting
- **Green (●)** - Running
- **Red (●)** - Error

#### Stopping the System

Click the red **"STOP SYSTEM"** button to cleanly shutdown all nodes.

---

## Comparison

| Feature | Unified Script | GUI Launcher |
|---------|---------------|--------------|
| **Ease of Use** | Command-line | Point-and-click |
| **Visual Status** | Terminal output only | Color-coded indicators |
| **User Audience** | Developers, SSH users | Anyone (non-technical) |
| **Network Config** | Command-line args | GUI form fields |
| **Log Viewing** | Terminal scrollback | Dedicated log window |
| **Pre-flight Checks** | Yes | Yes (with visual feedback) |
| **Setup Complexity** | SSH keys required | Just install tkinter |
| **Remote Control** | Yes (via SSH) | No (local only) |
| **Best For** | Automation, scripts | Demos, end-users |

---

## Setup Instructions

### For Unified Script

1. **Set up SSH keys** (one-time setup):

   ```bash
   # On Computer
   ssh-keygen -t rsa -b 4096
   ssh-copy-id cssr4africa@172.29.111.240

   # Test
   ssh cssr4africa@172.29.111.240 "echo 'Success!'"
   ```

2. **Make script executable**:

   ```bash
   chmod +x start_unified_system.sh
   ```

3. **Run it**:

   ```bash
   ./start_unified_system.sh
   ```

### For GUI Launcher

1. **Install dependencies**:

   ```bash
   pip3 install tk
   ```

2. **Make script executable**:

   ```bash
   chmod +x cssr_launcher_gui.py
   ```

3. **Create desktop shortcut**:

   ```bash
   # Edit CSSR_Launcher.desktop and update the Exec path
   # Then:
   cp CSSR_Launcher.desktop ~/Desktop/
   chmod +x ~/Desktop/CSSR_Launcher.desktop
   ```

4. **Launch**:

   Double-click the desktop icon or run:
   ```bash
   python3 cssr_launcher_gui.py
   ```

---

## Troubleshooting

### Unified Script Issues

**Problem:** "Permission denied" when SSH'ing

**Solution:** Set up SSH keys properly:
```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id user@remote-ip
```

**Problem:** "Connection refused" to remote machine

**Solution:**
- Check if remote machine is on
- Verify IP addresses are correct
- Check network connectivity: `ping remote-ip`

### GUI Launcher Issues

**Problem:** "ModuleNotFoundError: No module named 'tkinter'"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install python3-tk

# Or use pip
pip3 install tk
```

**Problem:** GUI shows but START button doesn't work

**Solution:**
- Check the script paths in `cssr_launcher_gui.py` (line ~390)
- Ensure `start_computer_v2_remote.sh` exists and is executable
- Check log window for error messages

**Problem:** Desktop icon doesn't launch GUI

**Solution:**
- Edit `CSSR_Launcher.desktop`
- Update the `Exec=` line with the correct full path
- Make it executable: `chmod +x CSSR_Launcher.desktop`

---

## Advanced Usage

### Customizing Default IPs in GUI

Edit `cssr_launcher_gui.py` and change these lines (~29-31):

```python
self.config = {
    'jetson_ip': tk.StringVar(value="YOUR_JETSON_IP"),
    'computer_ip': tk.StringVar(value="YOUR_COMPUTER_IP"),
    'robot_ip': tk.StringVar(value="YOUR_ROBOT_IP"),
    ...
}
```

### Running GUI Remotely (X11 Forwarding)

```bash
# SSH with X11 forwarding
ssh -X user@remote-machine

# Launch GUI
python3 cssr_launcher_gui.py
```

### Auto-start on Boot

To automatically start the CSSR system when Computer boots:

1. **Create systemd service** (for unified script):

   ```bash
   sudo nano /etc/systemd/system/cssr-system.service
   ```

   ```ini
   [Unit]
   Description=CSSR Robot System
   After=network.target

   [Service]
   Type=simple
   User=cssr4africa1
   WorkingDirectory=/home/cssr4africa1/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts
   ExecStart=/home/cssr4africa1/workspace_auto_demo/pepper_rob_ws/src/cssr4africa/cssr_system/scripts/start_unified_system.sh
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

2. **Enable and start**:

   ```bash
   sudo systemctl enable cssr-system
   sudo systemctl start cssr-system

   # Check status
   sudo systemctl status cssr-system
   ```

---

## Screenshots (GUI)

### Main Window

```
┌──────────────────────────────────────────────────────┐
│  🤖 CSSR System Launcher                             │
├──────────────────────────────────────────────────────┤
│  Configuration                                       │
│  Jetson IP:    [172.29.111.240]  Computer IP: [...]  │
│  Robot IP:     [172.29.111.230]  ☑ Launch Controller │
│  Control from: [computer ▼]                          │
├──────────────────────────────────────────────────────┤
│  System Status                                       │
│  ROS Master: ● Camera: ● Face Detection: ●           │
│  Robot Interface: ● Navigation: ● Controller: ●      │
├──────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ ▶ START      │  │ ■ STOP       │                 │
│  │   SYSTEM     │  │   SYSTEM     │                 │
│  └──────────────┘  └──────────────┘                 │
├──────────────────────────────────────────────────────┤
│  System Log                                          │
│  ┌────────────────────────────────────────────────┐ │
│  │ [12:34:56] [INFO] CSSR System Launcher init... │ │
│  │ [12:35:01] [INFO] Checking Jetson connection.. │ │
│  │ [12:35:02] [SUCCESS] ✓ Jetson is reachable     │ │
│  │ [12:35:05] [INFO] Starting system...           │ │
│  └────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────┤
│  CSSR4Africa Robot System | Ready              ●    │
└──────────────────────────────────────────────────────┘
```

---

## Summary

**Choose Unified Script if:**
- You're comfortable with command line
- You want to automate launches (scripts, cron jobs)
- You need to control from either machine
- You want to integrate with other automation

**Choose GUI Launcher if:**
- You want point-and-click simplicity
- You're demonstrating to non-technical users
- You want visual status feedback
- You prefer a user-friendly interface

**Both options:**
- Run all necessary pre-flight checks
- Provide clear feedback about what's happening
- Support custom IP configuration
- Can be stopped cleanly with one action

Enjoy your simplified CSSR system launch! 🚀
