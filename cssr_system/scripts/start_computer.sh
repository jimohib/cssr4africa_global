#!/bin/bash

################################################################################
# CSSR System - Computer Startup Script
#
# This script launches the CSSR system nodes on the main computer.
# It handles:
# - ROS environment setup
# - roscore startup
# - Network configuration for distributed ROS
# - Robot hardware interface launch
# - All cognitive system nodes launch (except face detection on Jetson)
#
# Usage:
#   ./start_computer.sh [COMPUTER_IP] [ROBOT_IP] [LAUNCH_CONTROLLER]
#
# Arguments:
#   COMPUTER_IP         - IP address of this computer (default: 172.29.111.237)
#   ROBOT_IP            - IP address of Pepper robot (default: 172.29.111.230)
#   LAUNCH_CONTROLLER   - Launch behavior controller (true/false, default: true)
#
# Prerequisites:
# - ROS Noetic installed
# - Workspace built and sourced
# - Virtual environments created for Python nodes
# - Pepper robot connected and accessible
# - Jetson nodes launched (camera + face detection)
#
################################################################################

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Default IP addresses (override with command line arguments)
COMPUTER_IP="${1:-172.29.111.237}"
ROBOT_IP="${2:-172.29.111.230}"
LAUNCH_CONTROLLER="${3:-true}"
ROBOT_PORT="9559"
NETWORK_INTERFACE="wlp0s20f3"

# ROS Workspace path - ADJUST THIS TO YOUR WORKSPACE
ROS_WORKSPACE="${ROS_WORKSPACE:-$HOME/workspace/pepper_rob_ws}"

# Launch file path
LAUNCH_FILE="$(rospack find cssr_system 2>/dev/null || echo "$ROS_WORKSPACE/src/cssr4africa_global/cssr_system")/launch/cssrSystemLaunchComputer.launch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_header "CSSR System - Computer Startup"

print_info "Computer IP (ROS Master): $COMPUTER_IP"
print_info "Robot IP: $ROBOT_IP"
print_info "Launch Behavior Controller: $LAUNCH_CONTROLLER"
print_info "ROS Workspace: $ROS_WORKSPACE"

# Check if ROS workspace exists
if [ ! -d "$ROS_WORKSPACE" ]; then
    print_error "ROS workspace not found at: $ROS_WORKSPACE"
    print_info "Please set the ROS_WORKSPACE environment variable or edit this script"
    exit 1
fi
print_success "ROS workspace found"

# ============================================================================
# ROS Environment Setup
# ============================================================================

print_header "Setting up ROS Environment"

# Source ROS Noetic
if [ -f "/opt/ros/noetic/setup.bash" ]; then
    source /opt/ros/noetic/setup.bash
    print_success "Sourced ROS Noetic"
else
    print_error "ROS Noetic not found. Is it installed?"
    exit 1
fi

# Source workspace
if [ -f "$ROS_WORKSPACE/devel/setup.bash" ]; then
    source "$ROS_WORKSPACE/devel/setup.bash"
    print_success "Sourced workspace: $ROS_WORKSPACE"
else
    print_error "Workspace not built. Please run 'catkin_make' in $ROS_WORKSPACE"
    exit 1
fi

# ============================================================================
# ROS Network Configuration
# ============================================================================

print_header "Configuring ROS Network"

# Set ROS Master URI to this computer
export ROS_MASTER_URI="http://$COMPUTER_IP:11311"
print_success "ROS_MASTER_URI set to: $ROS_MASTER_URI"

# Set ROS IP to this computer's IP
export ROS_IP="$COMPUTER_IP"
print_success "ROS_IP set to: $ROS_IP"

# Check if roscore is running
print_info "Checking for roscore..."
if pgrep -x "rosmaster" > /dev/null; then
    print_success "roscore is already running"
else
    print_warning "roscore is not running"
    print_info "Starting roscore in background..."

    # Start roscore in the background
    roscore &
    ROSCORE_PID=$!

    # Wait for roscore to start
    sleep 3

    if pgrep -x "rosmaster" > /dev/null; then
        print_success "roscore started successfully (PID: $ROSCORE_PID)"
    else
        print_error "Failed to start roscore"
        exit 1
    fi
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
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================================
# Check Jetson Connection
# ============================================================================

print_header "Checking Jetson Status"

print_info "Checking if face detection is available from Jetson..."
if timeout 5 rostopic list 2>/dev/null | grep -q "/faceDetection"; then
    print_success "Face detection node detected (Jetson is running)"
else
    print_warning "Face detection node not detected"
    print_info "Make sure you have:"
    print_info "  1. Started the Jetson nodes using start_jetson.sh"
    print_info "  2. Configured ROS networking properly"
    print_info "  3. Jetson can reach this computer's roscore"
    echo
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================================
# Check Virtual Environments
# ============================================================================

print_header "Checking Virtual Environments"

VENV_BASE="$ROS_WORKSPACE/src/cssr4africa_virtual_envs"

check_venv() {
    local venv_name=$1
    local venv_path="$VENV_BASE/$venv_name"

    if [ -d "$venv_path" ]; then
        if [ -f "$venv_path/bin/activate" ]; then
            print_success "Found: $venv_name"
            return 0
        fi
    fi
    print_warning "Missing: $venv_name at $venv_path"
    return 1
}

check_venv "cssr4africa_sound_detection_env"
check_venv "cssr4africa_speech_event_env"
check_venv "cssr4africa_text_to_speech_env"

echo
print_info "If any virtual environments are missing, Python nodes may fail to start"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# ============================================================================
# Launch CSSR System on Computer
# ============================================================================

print_header "Launching CSSR System Nodes on Computer"

print_info "Launch sequence:"
print_info "  0. Robot Hardware Interface (actuators + sensors)"
print_info "  1. Robot Localization"
print_info "  2. Robot Navigation"
print_info "  3. Sound Detection (with virtual env)"
print_info "  4. Speech Event (with virtual env)"
print_info "  5. Text to Speech (with virtual env)"
print_info "  6. Overt Attention"
print_info "  7. Gesture Execution"
if [ "$LAUNCH_CONTROLLER" = "true" ]; then
    print_info "  8. Behavior Controller (Mission Control)"
fi
echo

print_warning "This will take approximately 60 seconds for all nodes to start"
print_info "Nodes will start sequentially with delays to ensure dependencies are met"
echo

print_info "Press Ctrl+C to stop all nodes"
echo

# Launch the system with all parameters
roslaunch cssr_system cssrSystemLaunchComputer.launch \
    robot_ip:="$ROBOT_IP" \
    roscore_ip:="$COMPUTER_IP" \
    network_interface:="$NETWORK_INTERFACE" \
    launch_controller:="$LAUNCH_CONTROLLER" \
    launch_actuators:=true \
    launch_sensors:=true \
    launch_audio_nodes:=true

# This line is reached when roslaunch is terminated
print_header "Shutdown Complete"
print_info "All nodes have been stopped"
