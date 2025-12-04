#!/bin/bash

################################################################################
# CSSR System - Jetson Startup Script
#
# This script launches the CSSR system nodes on the Jetson Nano/Xavier.
# It handles:
# - ROS environment setup
# - Network configuration for distributed ROS
# - RealSense camera launch
# - Face detection node launch (with virtual environment)
#
# Usage:
#   ./start_jetson.sh [COMPUTER_IP] [JETSON_IP]
#
# Arguments:
#   COMPUTER_IP  - IP address of computer running roscore (default: 172.29.111.237)
#   JETSON_IP    - IP address of this Jetson (default: 172.29.111.240)
#
# Prerequisites:
# - ROS Noetic installed
# - Workspace built and sourced
# - RealSense SDK installed
# - Virtual environment created for face detection
# - roscore running on the computer
#
################################################################################

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Default IP addresses (override with command line arguments)
COMPUTER_IP="${1:-172.29.111.237}"
JETSON_IP="${2:-172.29.111.240}"
JETSON_HOSTNAME=$(hostname)

# ROS Workspace path - ADJUST THIS TO YOUR WORKSPACE
ROS_WORKSPACE="${ROS_WORKSPACE:-$HOME/workspace/pepper_rob_ws}"

# Launch file path
LAUNCH_FILE="$(rospack find cssr_system)/launch/cssrSystemLaunchJetson.launch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
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

print_header "CSSR System - Jetson Startup"

print_info "Computer IP (ROS Master): $COMPUTER_IP"
print_info "Jetson IP: $JETSON_IP"
print_info "Jetson Hostname: $JETSON_HOSTNAME"
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

# Set ROS Master URI to point to the computer
export ROS_MASTER_URI="http://$COMPUTER_IP:11311"
print_success "ROS_MASTER_URI set to: $ROS_MASTER_URI"

# Set ROS IP to this Jetson's IP
export ROS_IP="$JETSON_IP"
print_success "ROS_IP set to: $ROS_IP"

# Verify roscore is accessible
print_info "Checking connection to roscore..."
if timeout 5 rostopic list &> /dev/null; then
    print_success "Connected to roscore on $COMPUTER_IP"
else
    print_error "Cannot connect to roscore on $COMPUTER_IP"
    print_info "Make sure:"
    print_info "  1. roscore is running on the computer"
    print_info "  2. Computer IP ($COMPUTER_IP) is correct"
    print_info "  3. Network connection is working"
    print_info "  4. Firewall allows ROS communication (port 11311)"
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
# Launch CSSR System on Jetson
# ============================================================================

print_header "Launching CSSR System Nodes on Jetson"

print_info "Launching:"
print_info "  1. Intel RealSense Camera"
print_info "  2. Face Detection Node (with virtual environment)"
echo

# Launch the system
print_info "Starting launch file: $LAUNCH_FILE"
echo
print_info "Press Ctrl+C to stop all nodes"
echo

# Pass IP addresses as launch arguments
roslaunch cssr_system cssrSystemLaunchJetson.launch \
    ros_master_ip:="$COMPUTER_IP" \
    jetson_ip:="$JETSON_IP"

# This line is reached when roslaunch is terminated
print_info "\nShutdown complete"
