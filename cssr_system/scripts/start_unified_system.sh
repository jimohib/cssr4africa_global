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
# Launch Nodes
# ============================================================================

print_header "Starting CSSR System"

if [ "$CONTROL_FROM" = "computer" ]; then
    # Computer controls, Jetson is remote

    print_info "Step 1/2: Starting Jetson nodes (roscore + camera + face detection)..."
    ssh "$JETSON_USER@$JETSON_IP" "bash -s" << EOF &
        cd ~/workspace/pepper_rob_ws
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

    print_info "Step 2/2: Starting Computer nodes..."
    cd ~/workspace_auto_demo/pepper_rob_ws
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
    cd ~/workspace/pepper_rob_ws
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

    print_info "Step 2/2: Starting Computer nodes via SSH..."
    ssh "$COMPUTER_USER@$COMPUTER_IP" "bash -s" << EOF
        cd ~/workspace_auto_demo/pepper_rob_ws
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
