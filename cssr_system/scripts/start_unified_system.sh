#!/bin/bash

################################################################################
# CSSR System - Unified Startup Script
#
# This script launches the ENTIRE CSSR system from one command.
# It uses SSH to start nodes on both Jetson and Computer.
#
# Prerequisites:
# - SSH key-based authentication set up between machines (passwordless)
# - This script can be run from either Jetson or Computer
#
# Usage:
#   ./start_unified_system.sh [OPTIONS]
#
################################################################################

set -e

# ============================================================================
# Configuration
# ============================================================================

# Default IP addresses
DEFAULT_JETSON_IP="172.29.111.240"
DEFAULT_COMPUTER_IP="172.29.111.237"
DEFAULT_ROBOT_IP="172.29.111.230"
DEFAULT_LAUNCH_CONTROLLER="true"

# Initialize with defaults
JETSON_IP="$DEFAULT_JETSON_IP"
COMPUTER_IP="$DEFAULT_COMPUTER_IP"
ROBOT_IP="$DEFAULT_ROBOT_IP"
LAUNCH_CONTROLLER="$DEFAULT_LAUNCH_CONTROLLER"
CONTROL_FROM="computer"  # or "jetson"

# SSH usernames
JETSON_USER="${JETSON_USER:-roboticslab}"
COMPUTER_USER="${COMPUTER_USER:-cssr4africa1}"

# ============================================================================
# Workspace Paths - ADJUST THESE TO MATCH YOUR SETUP
# ============================================================================
#
# IMPORTANT: If your workspace paths are different, update these variables!
# This is the ONLY place you need to change workspace paths.
#
# Examples:
#   COMPUTER_WORKSPACE="$HOME/my_custom_workspace"
#   JETSON_WORKSPACE="/opt/ros_workspace"
#   VENV_RELATIVE_PATH="virtual_envs/cssr4africa"
#

# Computer workspace path
COMPUTER_WORKSPACE="${COMPUTER_WORKSPACE:-$HOME/workspace_auto_demo/pepper_rob_ws}"

# Jetson workspace path
JETSON_WORKSPACE="${JETSON_WORKSPACE:-$HOME/workspace/pepper_rob_ws}"

# Virtual environment base paths (relative to workspace)
VENV_RELATIVE_PATH="src/cssr4africa/virtual_envs"

# Full virtual environment paths (automatically constructed)
COMPUTER_VENV_BASE="$COMPUTER_WORKSPACE/$VENV_RELATIVE_PATH"
JETSON_VENV_BASE="$JETSON_WORKSPACE/$VENV_RELATIVE_PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Launch ENTIRE CSSR System on both Jetson and Computer from one command

OPTIONS:
    --jetson-ip=IP           IP address of Jetson (default: $DEFAULT_JETSON_IP)
    --computer-ip=IP         IP address of Computer (default: $DEFAULT_COMPUTER_IP)
    --robot-ip=IP            IP address of Pepper robot (default: $DEFAULT_ROBOT_IP)
    --launch-controller=BOOL Launch behavior controller (default: $DEFAULT_LAUNCH_CONTROLLER)
    --control-from=MACHINE   Run this script from (computer/jetson, default: computer)
    --jetson-user=USER       SSH username for Jetson (default: $JETSON_USER)
    --computer-user=USER     SSH username for Computer (default: $COMPUTER_USER)
    -h, --help               Show this help message

CONFIGURATION:
    Workspace paths are configured at the top of this script:
      Computer workspace: $COMPUTER_WORKSPACE
      Jetson workspace:   $JETSON_WORKSPACE

    To change these paths, edit the script or set environment variables:
      export COMPUTER_WORKSPACE="/path/to/computer/workspace"
      export JETSON_WORKSPACE="/path/to/jetson/workspace"

EXAMPLES:
    # Run from Computer, launch everything
    $0

    # Run from Jetson, launch everything
    $0 --control-from=jetson

    # Custom IPs
    $0 --jetson-ip=192.168.1.240 --computer-ip=192.168.1.237

PREREQUISITES:
    1. SSH key-based authentication must be set up (passwordless SSH)
       Run this on the controlling machine:

       ssh-keygen -t rsa -b 4096
       ssh-copy-id roboticslab@JETSON_IP    (if controlling from Computer)
       ssh-copy-id cssr4africa1@COMPUTER_IP (if controlling from Jetson)

    2. Test SSH access:
       ssh roboticslab@172.29.111.240 "echo 'SSH works!'"

EOF
    exit 0
}

# ============================================================================
# Parse Arguments
# ============================================================================

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

for arg in "$@"; do
    case $arg in
        --jetson-ip=*)
            JETSON_IP="${arg#*=}"
            shift
            ;;
        --computer-ip=*)
            COMPUTER_IP="${arg#*=}"
            shift
            ;;
        --robot-ip=*)
            ROBOT_IP="${arg#*=}"
            shift
            ;;
        --launch-controller=*)
            LAUNCH_CONTROLLER="${arg#*=}"
            shift
            ;;
        --control-from=*)
            CONTROL_FROM="${arg#*=}"
            shift
            ;;
        --jetson-user=*)
            JETSON_USER="${arg#*=}"
            shift
            ;;
        --computer-user=*)
            COMPUTER_USER="${arg#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_header "CSSR System - Unified Launcher"

print_info "Configuration:"
print_info "  Jetson IP: $JETSON_IP"
print_info "  Computer IP: $COMPUTER_IP"
print_info "  Robot IP: $ROBOT_IP"
print_info "  Control from: $CONTROL_FROM"
print_info "  Launch controller: $LAUNCH_CONTROLLER"
echo

# Test SSH connections
print_header "Testing SSH Connections"

if [ "$CONTROL_FROM" = "computer" ]; then
    # Running from Computer, need to SSH to Jetson
    print_info "Testing SSH to Jetson ($JETSON_USER@$JETSON_IP)..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$JETSON_USER@$JETSON_IP" "echo 'SSH OK'" &>/dev/null; then
        print_success "SSH to Jetson working"
    else
        print_error "Cannot SSH to Jetson. Please set up SSH keys:"
        echo "  On Computer, run:"
        echo "  ssh-keygen -t rsa -b 4096"
        echo "  ssh-copy-id $JETSON_USER@$JETSON_IP"
        exit 1
    fi
else
    # Running from Jetson, need to SSH to Computer
    print_info "Testing SSH to Computer ($COMPUTER_USER@$COMPUTER_IP)..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$COMPUTER_USER@$COMPUTER_IP" "echo 'SSH OK'" &>/dev/null; then
        print_success "SSH to Computer working"
    else
        print_error "Cannot SSH to Computer. Please set up SSH keys:"
        echo "  On Jetson, run:"
        echo "  ssh-keygen -t rsa -b 4096"
        echo "  ssh-copy-id $COMPUTER_USER@$COMPUTER_IP"
        exit 1
    fi
fi

# ============================================================================
# Check ROS Installation and Workspace
# ============================================================================

print_header "Checking ROS Environment"

# Determine which workspace is local vs remote based on control machine
if [ "$CONTROL_FROM" = "computer" ]; then
    LOCAL_WORKSPACE="$COMPUTER_WORKSPACE"
    REMOTE_WORKSPACE="$JETSON_WORKSPACE"
    REMOTE_USER="$JETSON_USER"
    REMOTE_IP="$JETSON_IP"
    REMOTE_MACHINE="Jetson"
else
    LOCAL_WORKSPACE="$JETSON_WORKSPACE"
    REMOTE_WORKSPACE="$COMPUTER_WORKSPACE"
    REMOTE_USER="$COMPUTER_USER"
    REMOTE_IP="$COMPUTER_IP"
    REMOTE_MACHINE="Computer"
fi

# Check local ROS Noetic installation
if [ -f "/opt/ros/noetic/setup.bash" ]; then
    print_success "ROS Noetic found on local machine"
else
    print_error "ROS Noetic not found on local machine"
    print_info "Please install ROS Noetic: http://wiki.ros.org/noetic/Installation"
    exit 1
fi

# Check local workspace exists
if [ ! -d "$LOCAL_WORKSPACE" ]; then
    print_error "ROS workspace not found at: $LOCAL_WORKSPACE"
    print_info "Please set ROS_WORKSPACE environment variable or adjust the script"
    exit 1
fi
print_success "Local workspace found: $LOCAL_WORKSPACE"

# Check local workspace is built
if [ ! -f "$LOCAL_WORKSPACE/devel/setup.bash" ]; then
    print_error "Workspace not built at: $LOCAL_WORKSPACE"
    print_info "Please run: cd $LOCAL_WORKSPACE && catkin_make"
    exit 1
fi
print_success "Local workspace is built"

# Check remote workspace via SSH
print_info "Checking $REMOTE_MACHINE workspace..."
if ssh "$REMOTE_USER@$REMOTE_IP" "[ -d $REMOTE_WORKSPACE ] && [ -f $REMOTE_WORKSPACE/devel/setup.bash ]"; then
    print_success "$REMOTE_MACHINE workspace is ready"
else
    print_error "$REMOTE_MACHINE workspace not found or not built at: $REMOTE_WORKSPACE"
    print_info "On $REMOTE_MACHINE, run: cd $REMOTE_WORKSPACE && catkin_make"
    exit 1
fi

# ============================================================================
# Check Robot Connection
# ============================================================================

print_header "Checking Pepper Robot Connection"

print_info "Attempting to ping robot at $ROBOT_IP..."
if ping -c 2 -W 2 "$ROBOT_IP" &> /dev/null; then
    print_success "Robot is reachable at $ROBOT_IP"
else
    print_warning "Cannot ping robot at $ROBOT_IP"
    print_info "Robot may be offline or on a different network"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================================
# Check Virtual Environments (Computer only)
# ============================================================================

print_header "Checking Virtual Environments"

# Function to check virtual environments
check_venv_remote() {
    local machine=$1
    local user=$2
    local ip=$3
    local venv_base=$4
    local venv_name=$5

    if ssh "$user@$ip" "[ -d $venv_base/$venv_name ] && [ -f $venv_base/$venv_name/bin/activate ]"; then
        print_success "[$machine] Found: $venv_name"
        return 0
    else
        print_warning "[$machine] Missing: $venv_name"
        return 1
    fi
}

check_venv_local() {
    local venv_base=$1
    local venv_name=$2

    if [ -d "$venv_base/$venv_name" ] && [ -f "$venv_base/$venv_name/bin/activate" ]; then
        print_success "Found: $venv_name"
        return 0
    else
        print_warning "Missing: $venv_name at $venv_base/$venv_name"
        return 1
    fi
}

# Check virtual environments based on where we're running from
if [ "$CONTROL_FROM" = "computer" ]; then
    # Running from Computer - check Computer's virtual envs locally
    print_info "Checking Computer virtual environments (local)..."
    check_venv_local "$COMPUTER_VENV_BASE" "sound_detection_env"
    check_venv_local "$COMPUTER_VENV_BASE" "speech_event_env"
    check_venv_local "$COMPUTER_VENV_BASE" "text_to_speech_env"

    # Check Jetson's face detection venv via SSH
    print_info "Checking Jetson virtual environments (remote)..."
    check_venv_remote "Jetson" "$JETSON_USER" "$JETSON_IP" "$JETSON_VENV_BASE" "face_detection_env"
else
    # Running from Jetson - check Jetson's venv locally, Computer's via SSH
    print_info "Checking Jetson virtual environments (local)..."
    check_venv_local "$JETSON_VENV_BASE" "face_detection_env"

    # Check Computer's venvs via SSH
    print_info "Checking Computer virtual environments (remote)..."
    check_venv_remote "Computer" "$COMPUTER_USER" "$COMPUTER_IP" "$COMPUTER_VENV_BASE" "sound_detection_env"
    check_venv_remote "Computer" "$COMPUTER_USER" "$COMPUTER_IP" "$COMPUTER_VENV_BASE" "speech_event_env"
    check_venv_remote "Computer" "$COMPUTER_USER" "$COMPUTER_IP" "$COMPUTER_VENV_BASE" "text_to_speech_env"
fi

echo
print_info "If any virtual environments are missing, Python nodes may fail to start"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# ============================================================================
# Launch Nodes
# ============================================================================

print_header "Starting CSSR System"

if [ "$CONTROL_FROM" = "computer" ]; then
    # Computer controls, Jetson is remote

    print_info "Step 1/2: Starting Jetson nodes (roscore + camera + face detection)..."
    ssh "$JETSON_USER@$JETSON_IP" "bash -s" << EOF &
        cd $JETSON_WORKSPACE
        source /opt/ros/noetic/setup.bash
        source devel/setup.bash
        export ROS_MASTER_URI="http://$JETSON_IP:11311"
        export ROS_IP="$JETSON_IP"

        echo "Starting roscore on Jetson..."
        roscore &
        sleep 5

        echo "Launching Jetson nodes..."
        roslaunch cssr_system cssrSystemLaunchJetson_v2_master.launch \
            jetson_ip:="$JETSON_IP" \
            camera_type:=realsense
EOF
    JETSON_PID=$!
    print_success "Jetson nodes starting (PID: $JETSON_PID)"

    print_info "Waiting 15 seconds for Jetson nodes to initialize..."
    sleep 15

    # Verify Jetson nodes are running
    print_header "Verifying Jetson Nodes"

    # Set ROS environment for checking
    export ROS_MASTER_URI="http://$JETSON_IP:11311"
    export ROS_IP="$COMPUTER_IP"

    # Check roscore is accessible
    print_info "Checking connection to Jetson's roscore..."
    if timeout 5 rostopic list &> /dev/null; then
        print_success "Connected to roscore on Jetson"
    else
        print_error "Cannot connect to roscore on Jetson ($JETSON_IP)"
        print_info "Make sure:"
        print_info "  1. Jetson nodes started successfully"
        print_info "  2. Jetson IP ($JETSON_IP) is correct"
        print_info "  3. Firewall allows ROS communication (port 11311)"
        exit 1
    fi

    # Check face detection is available
    print_info "Checking if face detection is available..."
    if timeout 5 rostopic list 2>/dev/null | grep -q "/faceDetection"; then
        print_success "Face detection node is running on Jetson"
    else
        print_warning "Face detection topics not detected"
        print_info "This may be normal if the nodes are still starting up"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_info "Step 2/2: Starting Computer nodes..."
    cd $COMPUTER_WORKSPACE
    source /opt/ros/noetic/setup.bash
    source devel/setup.bash
    export ROS_MASTER_URI="http://$JETSON_IP:11311"
    export ROS_IP="$COMPUTER_IP"

    roslaunch cssr_system cssrSystemLaunchComputer_v2_remote.launch \
        jetson_ip:="$JETSON_IP" \
        computer_ip:="$COMPUTER_IP" \
        robot_ip:="$ROBOT_IP" \
        launch_controller:="$LAUNCH_CONTROLLER"

else
    # Jetson controls, Computer is remote

    print_info "Step 1/2: Starting Jetson nodes (roscore + camera + face detection)..."
    cd $JETSON_WORKSPACE
    source /opt/ros/noetic/setup.bash
    source devel/setup.bash
    export ROS_MASTER_URI="http://$JETSON_IP:11311"
    export ROS_IP="$JETSON_IP"

    roscore &
    sleep 5

    roslaunch cssr_system cssrSystemLaunchJetson_v2_master.launch \
        jetson_ip:="$JETSON_IP" \
        camera_type:=realsense &
    JETSON_LAUNCH_PID=$!

    print_success "Jetson nodes started"

    print_info "Waiting 15 seconds for Jetson nodes to initialize..."
    sleep 15

    # Verify Jetson nodes are running
    print_header "Verifying Jetson Nodes"

    # Check roscore is accessible (local)
    print_info "Checking roscore..."
    if timeout 5 rostopic list &> /dev/null; then
        print_success "roscore is running"
    else
        print_error "Cannot connect to roscore"
        print_info "roscore may have failed to start"
        exit 1
    fi

    # Check face detection is available
    print_info "Checking if face detection is available..."
    if timeout 5 rostopic list 2>/dev/null | grep -q "/faceDetection"; then
        print_success "Face detection node is running"
    else
        print_warning "Face detection topics not detected"
        print_info "This may be normal if the nodes are still starting up"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_info "Step 2/2: Starting Computer nodes via SSH..."
    ssh "$COMPUTER_USER@$COMPUTER_IP" "bash -s" << EOF
        cd $COMPUTER_WORKSPACE
        source /opt/ros/noetic/setup.bash
        source devel/setup.bash
        export ROS_MASTER_URI="http://$JETSON_IP:11311"
        export ROS_IP="$COMPUTER_IP"

        roslaunch cssr_system cssrSystemLaunchComputer_v2_remote.launch \
            jetson_ip:="$JETSON_IP" \
            computer_ip:="$COMPUTER_IP" \
            robot_ip:="$ROBOT_IP" \
            launch_controller:="$LAUNCH_CONTROLLER"
EOF
fi

print_header "System Shutdown"
print_info "All nodes stopped"
