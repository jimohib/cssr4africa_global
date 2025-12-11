#!/bin/bash

################################################################################
# CSSR System - Jetson Startup Script (Version 2: Jetson as ROS Master)
#
# This script launches the CSSR system nodes on the Jetson Nano/Xavier.
# In Version 2, the Jetson acts as the ROS MASTER.
#
# It handles:
# - ROS environment setup
# - roscore startup (on this Jetson)
# - Network configuration for distributed ROS
# - RealSense camera launch
# - Face detection node launch (with virtual environment)
#
# Usage:
#   ./start_jetson_v2_master.sh [JETSON_IP]
#
# Arguments:
#   JETSON_IP    - IP address of this Jetson (default: 172.29.111.240)
#
# Prerequisites:
# - ROS Noetic installed
# - Workspace built and sourced
# - RealSense SDK installed
# - Virtual environment created for face detection
#
################################################################################

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Default IP address
DEFAULT_JETSON_IP="172.29.111.240"

# Initialize with default
JETSON_IP="$DEFAULT_JETSON_IP"
JETSON_HOSTNAME=$(hostname)

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Launch CSSR System nodes on Jetson (acts as ROS Master)

OPTIONS:
    --jetson-ip=IP     IP address of this Jetson (default: $DEFAULT_JETSON_IP)
    -h, --help         Show this help message

EXAMPLES:
    # Use default IP
    $0

    # Specify Jetson IP
    $0 --jetson-ip=192.168.1.240

    # Backward compatible positional argument (deprecated)
    $0 JETSON_IP

EOF
    exit 0
}

# ============================================================================
# Parse Arguments
# ============================================================================

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Check if using positional arguments (backward compatibility)
if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; then
    # Positional argument mode (deprecated but supported)
    JETSON_IP="${1:-$DEFAULT_JETSON_IP}"
else
    # Named arguments mode
    for arg in "$@"; do
        case $arg in
            --jetson-ip=*)
                JETSON_IP="${arg#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
fi

# ROS Workspace path - ADJUST THIS TO YOUR WORKSPACE
ROS_WORKSPACE="${ROS_WORKSPACE:-$HOME/workspace/pepper_rob_ws}"

# Launch file path
LAUNCH_FILE="$(rospack find cssr_system 2>/dev/null || echo "$ROS_WORKSPACE/src/cssr4africa_global/cssr_system")/launch/cssrSystemLaunchJetson_v2_master.launch"

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

print_header "CSSR System - Jetson Startup (Version 2: ROS Master)"

print_info "Jetson IP (ROS Master): $JETSON_IP"
print_info "Jetson Hostname: $JETSON_HOSTNAME"
print_info "ROS Workspace: $ROS_WORKSPACE"
echo
print_warning "NOTE: This Jetson will act as the ROS MASTER"
print_info "The Computer will connect to this Jetson's roscore"

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
# ROS Network Configuration (Jetson as Master)
# ============================================================================

print_header "Configuring ROS Network (Jetson as Master)"

# Set ROS Master URI to this Jetson
export ROS_MASTER_URI="http://$JETSON_IP:11311"
print_success "ROS_MASTER_URI set to: $ROS_MASTER_URI"

# Set ROS IP to this Jetson's IP
export ROS_IP="$JETSON_IP"
print_success "ROS_IP set to: $ROS_IP"

# ============================================================================
# Start roscore on Jetson
# ============================================================================

print_header "Starting roscore on Jetson"

# Check if roscore is already running
if pgrep -x "rosmaster" > /dev/null; then
    print_warning "roscore is already running"
    print_info "Using existing roscore instance"
else
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

# Verify roscore is accessible
print_info "Verifying roscore is accessible..."
if timeout 5 rostopic list &> /dev/null; then
    print_success "roscore is accessible"
else
    print_error "Cannot connect to roscore"
    exit 1
fi

# ============================================================================
# Check RealSense Camera
# ============================================================================

print_header "Checking RealSense Camera"

if lsusb | grep -q "Intel Corp"; then
    print_success "RealSense camera detected"
else
    print_warning "RealSense camera not detected. Make sure it's connected."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================================
# Display Connection Info for Computer
# ============================================================================

print_header "ROS Master Information"

print_info "This Jetson is now the ROS MASTER"
print_info "For the Computer to connect, set these environment variables:"
echo
echo -e "${GREEN}export ROS_MASTER_URI=http://$JETSON_IP:11311${NC}"
echo -e "${GREEN}export ROS_IP=[COMPUTER_IP]${NC}"
echo
print_info "Then run: ./start_computer_v2_remote.sh"
echo

# ============================================================================
# Launch CSSR System on Jetson
# ============================================================================

print_header "Launching CSSR System Nodes on Jetson"

print_info "Launching:"
print_info "  1. Intel RealSense Camera"
print_info "  2. Face Detection Node (with virtual environment)"
echo

print_info "Starting launch file: $LAUNCH_FILE"
echo
print_info "Press Ctrl+C to stop all nodes and roscore"
echo

# Launch the system
roslaunch cssr_system cssrSystemLaunchJetson_v2_master.launch \
    jetson_ip:="$JETSON_IP"

# This line is reached when roslaunch is terminated
print_header "Shutdown"
print_info "Nodes stopped. roscore is still running in background."
print_info "To stop roscore, run: pkill -f rosmaster"
