#!/usr/bin/env python3
"""
CSSR4Africa System - Graphical Launcher Interface

A user-friendly GUI for launching the CSSR4Africa robot system.

Author: Ibrahim Jimoh
Email: ioj@andrew.cmu.edu
Date: 2025-12-12

Requirements:
    pip install tkinter paramiko
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import subprocess
import threading
import os
import socket
from datetime import datetime
import sys

class CSSRLauncherGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("CSSR4Africa System Launcher")
        self.root.geometry("900x700")
        self.root.resizable(True, True)

        # Process tracking
        self.processes = []
        self.is_running = False

        # Configuration
        self.config = {
            'jetson_ip': tk.StringVar(value="172.29.111.248"),
            'computer_ip': tk.StringVar(value="172.29.111.245"),
            'robot_ip': tk.StringVar(value="172.29.111.230"),
            'launch_controller': tk.BooleanVar(value=True),
            'control_from': tk.StringVar(value="computer"),
        }

        self.create_widgets()
        self.log("CSSR4Africa System Launcher initialized")
        self.log(f"Current user: {os.getenv('USER', 'unknown')}")
        self.log(f"Current host: {socket.gethostname()}")

    def create_widgets(self):
        """Create the GUI layout"""

        # ===== HEADER =====
        header_frame = tk.Frame(self.root, bg="#2c3e50", height=80)
        header_frame.pack(fill=tk.X)
        header_frame.pack_propagate(False)

        title_label = tk.Label(
            header_frame,
            text="CSSR4Africa System Launcher",
            font=("TkDefaultFont", 18, "bold"),
            bg="#2c3e50",
            fg="white"
        )
        title_label.pack(pady=20)

        # ===== CONFIGURATION PANEL =====
        config_frame = ttk.LabelFrame(self.root, text="Configuration", padding=10)
        config_frame.pack(fill=tk.X, padx=10, pady=10)

        # IP Configuration
        row = 0
        ttk.Label(config_frame, text="Jetson IP:").grid(row=row, column=0, sticky=tk.W, padx=5, pady=5)
        ttk.Entry(config_frame, textvariable=self.config['jetson_ip'], width=20).grid(row=row, column=1, padx=5, pady=5)

        ttk.Label(config_frame, text="Computer IP:").grid(row=row, column=2, sticky=tk.W, padx=5, pady=5)
        ttk.Entry(config_frame, textvariable=self.config['computer_ip'], width=20).grid(row=row, column=3, padx=5, pady=5)

        row += 1
        ttk.Label(config_frame, text="Robot IP:").grid(row=row, column=0, sticky=tk.W, padx=5, pady=5)
        ttk.Entry(config_frame, textvariable=self.config['robot_ip'], width=20).grid(row=row, column=1, padx=5, pady=5)

        ttk.Checkbutton(
            config_frame,
            text="Launch Behavior Controller",
            variable=self.config['launch_controller']
        ).grid(row=row, column=2, columnspan=2, sticky=tk.W, padx=5, pady=5)

        row += 1
        ttk.Label(config_frame, text="Control from:").grid(row=row, column=0, sticky=tk.W, padx=5, pady=5)
        control_combo = ttk.Combobox(
            config_frame,
            textvariable=self.config['control_from'],
            values=["computer", "jetson"],
            state="readonly",
            width=17
        )
        control_combo.grid(row=row, column=1, padx=5, pady=5)

        # ===== STATUS PANEL =====
        status_frame = ttk.LabelFrame(self.root, text="System Status", padding=10)
        status_frame.pack(fill=tk.X, padx=10, pady=5)

        # Status indicators
        self.status_labels = {}
        status_items = [
            ("ROS Master", "roscore"),
            ("Camera", "camera"),
            ("Face Detection", "face_detection"),
            ("Robot Interface", "robot_interface"),
            ("Navigation", "navigation"),
            ("Behavior Controller", "behavior_controller")
        ]

        for idx, (label, key) in enumerate(status_items):
            row_idx = idx // 3
            col_idx = (idx % 3) * 2

            ttk.Label(status_frame, text=f"{label}:").grid(
                row=row_idx, column=col_idx, sticky=tk.W, padx=5, pady=3
            )

            status_label = tk.Label(
                status_frame,
                text="●",
                font=("TkDefaultFont", 12),
                fg="gray"
            )
            status_label.grid(row=row_idx, column=col_idx+1, padx=5, pady=3)
            self.status_labels[key] = status_label

        # ===== CONTROL BUTTONS =====
        button_frame = tk.Frame(self.root, bg="#ecf0f1", height=80)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        button_frame.pack_propagate(False)

        button_container = tk.Frame(button_frame, bg="#ecf0f1")
        button_container.place(relx=0.5, rely=0.5, anchor=tk.CENTER)

        self.start_button = tk.Button(
            button_container,
            text="START SYSTEM",
            command=self.start_system,
            bg="#27ae60",
            fg="white",
            font=("TkDefaultFont", 14, "bold"),
            width=20,
            height=2,
            relief=tk.RAISED,
            bd=3,
            cursor="hand2"
        )
        self.start_button.pack(side=tk.LEFT, padx=10)

        self.stop_button = tk.Button(
            button_container,
            text="STOP SYSTEM",
            command=self.stop_system,
            bg="#e74c3c",
            fg="white",
            font=("TkDefaultFont", 14, "bold"),
            width=20,
            height=2,
            relief=tk.RAISED,
            bd=3,
            cursor="hand2",
            state=tk.DISABLED
        )
        self.stop_button.pack(side=tk.LEFT, padx=10)

        # ===== LOG PANEL =====
        log_frame = ttk.LabelFrame(self.root, text="System Log", padding=10)
        log_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            height=15,
            font=("TkFixedFont", 9),
            bg="#1e1e1e",
            fg="#cccccc",
            insertbackground="white",
            wrap=tk.WORD
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)

        # Configure text tags for different log levels with colors
        self.log_text.tag_config("INFO", foreground="#00bfff")      # Light blue
        self.log_text.tag_config("SUCCESS", foreground="#00ff00")   # Green
        self.log_text.tag_config("WARN", foreground="#ffa500")      # Orange
        self.log_text.tag_config("WARNING", foreground="#ffa500")   # Orange
        self.log_text.tag_config("ERROR", foreground="#ff4444")     # Red
        self.log_text.tag_config("DEBUG", foreground="#888888")     # Dark gray

        # Clear log button
        clear_log_btn = ttk.Button(log_frame, text="Clear Log", command=self.clear_log)
        clear_log_btn.pack(anchor=tk.E, pady=5)

        # ===== FOOTER =====
        footer_frame = tk.Frame(self.root, bg="#34495e", height=30)
        footer_frame.pack(fill=tk.X, side=tk.BOTTOM)
        footer_frame.pack_propagate(False)

        footer_label = tk.Label(
            footer_frame,
            text="CSSR4Africa Robot System | Ready",
            bg="#34495e",
            fg="white"
        )
        footer_label.pack(side=tk.LEFT, padx=10)

        self.footer_status = tk.Label(
            footer_frame,
            text="●",
            bg="#34495e",
            fg="gray",
            font=("TkDefaultFont", 10)
        )
        self.footer_status.pack(side=tk.RIGHT, padx=10)

    def log(self, message, level="INFO"):
        """Add message to log window with appropriate color based on level"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] [{level}] {message}\n"

        # Insert with tag for color coding
        self.log_text.insert(tk.END, formatted_message, level)
        self.log_text.see(tk.END)
        self.log_text.update()

    def clear_log(self):
        """Clear the log window"""
        self.log_text.delete(1.0, tk.END)

    def update_status(self, component, status):
        """Update status indicator

        Args:
            component: Component key (e.g., 'roscore', 'camera')
            status: 'running', 'stopped', 'error'
        """
        if component not in self.status_labels:
            return

        colors = {
            'running': '#27ae60',  # Green
            'stopped': 'gray',
            'error': '#e74c3c',    # Red
            'starting': '#f39c12'  # Orange
        }

        self.status_labels[component].config(fg=colors.get(status, 'gray'))

    def run_preflight_checks(self):
        """Run pre-flight checks before launching"""
        self.log("Running pre-flight checks...")

        # Check 1: Ping Jetson
        jetson_ip = self.config['jetson_ip'].get()
        self.log(f"Checking connection to Jetson ({jetson_ip})...")

        result = subprocess.run(
            ['ping', '-c', '2', '-W', '2', jetson_ip],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            self.log(f"WARNING: Cannot ping Jetson at {jetson_ip}", "WARN")
            if not messagebox.askyesno("Warning", f"Cannot reach Jetson at {jetson_ip}\nContinue anyway?"):
                return False
        else:
            self.log("✓ Jetson is reachable", "SUCCESS")

        # Check 2: Ping Robot
        robot_ip = self.config['robot_ip'].get()
        self.log(f"Checking connection to Robot ({robot_ip})...")

        result = subprocess.run(
            ['ping', '-c', '2', '-W', '2', robot_ip],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            self.log(f"WARNING: Cannot ping Robot at {robot_ip}", "WARN")
            if not messagebox.askyesno("Warning", f"Cannot reach Robot at {robot_ip}\nContinue anyway?"):
                return False
        else:
            self.log("✓ Robot is reachable", "SUCCESS")

        # Check 3: ROS environment
        self.log("Checking ROS environment...")
        if not os.path.exists("/opt/ros/noetic/setup.bash"):
            self.log("ERROR: ROS Noetic not found", "ERROR")
            messagebox.showerror("Error", "ROS Noetic is not installed!")
            return False
        else:
            self.log("✓ ROS Noetic found", "SUCCESS")

        self.log("✓ All pre-flight checks passed", "SUCCESS")
        return True

    def start_system(self):
        """Start the CSSR system"""
        if self.is_running:
            messagebox.showwarning("Warning", "System is already running!")
            return

        # Run pre-flight checks
        if not self.run_preflight_checks():
            return

        self.log("=" * 60)
        self.log("STARTING CSSR SYSTEM", "INFO")
        self.log("=" * 60)

        # Update UI
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        self.footer_status.config(fg="#f39c12")  # Orange
        self.is_running = True

        # Start in background thread
        thread = threading.Thread(target=self._start_system_thread)
        thread.daemon = True
        thread.start()

    def _start_system_thread(self):
        """Background thread for starting system"""
        try:
            jetson_ip = self.config['jetson_ip'].get()
            computer_ip = self.config['computer_ip'].get()
            robot_ip = self.config['robot_ip'].get()
            launch_controller = str(self.config['launch_controller'].get()).lower()

            # Build launch command
            script_dir = os.path.dirname(os.path.abspath(__file__))
            script_path = os.path.join(script_dir, "start_cssr_demo.sh")

            # Debug logging
            self.log(f"Script directory: {script_dir}")
            self.log(f"Looking for script at: {script_path}")
            self.log(f"Script exists: {os.path.exists(script_path)}")

            if os.path.exists(script_path):
                # Check if script is executable
                if not os.access(script_path, os.X_OK):
                    self.log(f"WARNING: Script is not executable: {script_path}", "WARN")
                    self.log("Attempting to make it executable...", "INFO")
                    try:
                        os.chmod(script_path, 0o755)
                        self.log("✓ Script made executable", "SUCCESS")
                    except Exception as e:
                        self.log(f"ERROR: Failed to make script executable: {e}", "ERROR")
                        messagebox.showerror("Error", f"Script is not executable and cannot be fixed!\n{script_path}\n\nRun: chmod +x {script_path}")
                        self.is_running = False
                        self.start_button.config(state=tk.NORMAL)
                        self.stop_button.config(state=tk.DISABLED)
                        return
            else:
                self.log(f"ERROR: Script not found: {script_path}", "ERROR")
                self.log(f"Files in {script_dir}:", "INFO")
                try:
                    for f in os.listdir(script_dir):
                        self.log(f"  - {f}", "INFO")
                except Exception as e:
                    self.log(f"Cannot list directory: {e}", "ERROR")
                messagebox.showerror("Error", f"Launch script not found!\n{script_path}\n\nMake sure start_cssr_demo.sh is in the same folder as cssr_launcher_gui.py")
                self.is_running = False
                self.start_button.config(state=tk.NORMAL)
                self.stop_button.config(state=tk.DISABLED)
                return

            cmd = [
                script_path,
                f"--jetson-ip={jetson_ip}",
                f"--computer-ip={computer_ip}",
                f"--robot-ip={robot_ip}",
                f"--launch-controller={launch_controller}"
            ]

            self.log(f"Launching: {' '.join(cmd)}")

            # Update status indicators
            self.update_status('roscore', 'starting')
            self.update_status('camera', 'starting')

            # Launch process with stdin enabled for auto-starting mission
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                stdin=subprocess.PIPE,  # Enable stdin to send Enter key
                text=True,
                bufsize=1
            )

            self.processes.append(process)

            # Stream output to log
            for line in process.stdout:
                self.log(line.strip())

                # Auto-send Enter when behaviorController prompts for mission start
                # Detects patterns like: "Press Enter to start", "Press 'Enter' to start", etc.
                line_lower = line.lower()
                if "press" in line_lower and "enter" in line_lower and "start" in line_lower:
                    self.log("=" * 60, "INFO")
                    self.log("Detected mission start prompt", "INFO")
                    self.log("Auto-starting mission...", "INFO")
                    try:
                        process.stdin.write("\n")
                        process.stdin.flush()
                        self.log("✓ Mission started automatically", "SUCCESS")
                    except Exception as e:
                        self.log(f"Failed to auto-start mission: {e}", "ERROR")
                    self.log("=" * 60, "INFO")

                # Handle mission restart prompt - ask user if they want to continue
                if ("run" in line_lower and "mission" in line_lower and "again" in line_lower) or \
                   ("continue" in line_lower and "y/n" in line_lower):
                    self.log("=" * 60, "INFO")
                    self.log("Mission completed - Restart prompt detected", "INFO")

                    # Ask user if they want to restart
                    restart = messagebox.askyesno(
                        "Mission Complete",
                        "The mission has completed.\n\nDo you want to run the mission again?",
                        parent=self.root
                    )

                    try:
                        if restart:
                            process.stdin.write("y\n")
                            process.stdin.flush()
                            self.log("✓ Mission restarting...", "SUCCESS")
                        else:
                            process.stdin.write("n\n")
                            process.stdin.flush()
                            self.log("Mission ended by user", "INFO")
                    except Exception as e:
                        self.log(f"Failed to send restart response: {e}", "ERROR")
                    self.log("=" * 60, "INFO")

                # Update status indicators - look for specific SUCCESS messages
                # These indicate nodes are actually running, not just starting

                # roscore - look for connection confirmation
                if ("connected to roscore" in line_lower or
                    "roscore already running" in line_lower or
                    "roscore is running" in line_lower):
                    self.update_status('roscore', 'running')

                # Camera - look for successful initialization
                if ("realsense" in line_lower and ("started" in line_lower or "running" in line_lower)) or \
                   ("camera node" in line_lower and "started" in line_lower):
                    self.update_status('camera', 'running')

                # Face detection - look for confirmation it's actually publishing
                if ("face detection node is running" in line_lower or
                    ("facedetection" in line_lower and "started" in line_lower) or
                    "/facedetection" in line_lower):
                    self.update_status('face_detection', 'running')

                # Robot interface - look for naoqi driver confirmation
                if (("naoqi_driver" in line_lower or "naoqi_dcm_driver" in line_lower) and "started" in line_lower) or \
                   ("robot driver" in line_lower and "running" in line_lower) or \
                   "naoqi" in line_lower and "successfully" in line_lower:
                    self.update_status('robot_interface', 'running')

                # Navigation - look for robotLocalization or robotNavigation
                if ("robotlocalization" in line_lower or "robotnavigation" in line_lower) and \
                   ("started" in line_lower or "running" in line_lower):
                    self.update_status('navigation', 'running')

                # Behavior controller - look for actual start confirmation
                if "behaviorcontroller" in line_lower and ("started" in line_lower or "running" in line_lower):
                    self.update_status('behavior_controller', 'running')

            process.wait()

            if process.returncode == 0:
                self.log("System stopped normally", "INFO")
            else:
                self.log(f"System stopped with error code {process.returncode}", "ERROR")

            self.footer_status.config(fg="gray")

        except Exception as e:
            self.log(f"ERROR: {str(e)}", "ERROR")
            messagebox.showerror("Error", f"Failed to start system:\n{str(e)}")

        finally:
            self.is_running = False
            self.start_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)

            # Reset all status indicators
            for status_label in self.status_labels.values():
                status_label.config(fg="gray")

    def stop_system(self):
        """Stop the CSSR system"""
        if not self.is_running:
            return

        if not messagebox.askyesno("Confirm", "Are you sure you want to stop the system?"):
            return

        self.log("=" * 60)
        self.log("STOPPING CSSR SYSTEM", "INFO")
        self.log("=" * 60)

        # Terminate all processes
        for process in self.processes:
            try:
                process.terminate()
                self.log(f"Sent termination signal to process {process.pid}")
            except Exception as e:
                self.log(f"Error terminating process: {e}", "ERROR")

        # Kill any remaining ROS nodes
        try:
            subprocess.run(['killall', 'roslaunch'], check=False)
            subprocess.run(['killall', 'roscore'], check=False)
            self.log("Killed all ROS processes")
        except Exception as e:
            self.log(f"Error killing ROS processes: {e}", "ERROR")

        self.processes.clear()
        self.is_running = False

        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.footer_status.config(fg="gray")

        # Reset all status indicators
        for status_label in self.status_labels.values():
            status_label.config(fg="gray")

        self.log("System stopped", "INFO")


def main():
    root = tk.Tk()
    app = CSSRLauncherGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
