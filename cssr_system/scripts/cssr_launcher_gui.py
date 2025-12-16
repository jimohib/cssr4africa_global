#!/usr/bin/env python3
"""
CSSR System - Graphical Launcher Interface

A user-friendly GUI for launching the CSSR robot system.
Can be used by anyone without command-line knowledge.

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
        self.root.title("CSSR System Launcher")
        self.root.geometry("900x700")
        self.root.resizable(True, True)

        # Process tracking
        self.processes = []
        self.is_running = False

        # Configuration
        self.config = {
            'jetson_ip': tk.StringVar(value="172.29.111.240"),
            'computer_ip': tk.StringVar(value="172.29.111.237"),
            'robot_ip': tk.StringVar(value="172.29.111.230"),
            'launch_controller': tk.BooleanVar(value=True),
            'control_from': tk.StringVar(value="computer"),
        }

        self.create_widgets()
        self.log("CSSR System Launcher initialized")
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
            text="CSSR System Launcher",
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
            fg="#00ff00",
            insertbackground="white"
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)

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
        """Add message to log window"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] [{level}] {message}\n"

        self.log_text.insert(tk.END, formatted_message)
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
            script_path = os.path.join(
                os.path.dirname(__file__),
                "start_computer_v2_remote.sh"
            )

            if not os.path.exists(script_path):
                self.log(f"ERROR: Script not found: {script_path}", "ERROR")
                messagebox.showerror("Error", f"Launch script not found!\n{script_path}")
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

            # Launch process
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            self.processes.append(process)

            # Stream output to log
            for line in process.stdout:
                self.log(line.strip())

                # Update status based on log output
                if "roscore" in line.lower():
                    self.update_status('roscore', 'running')
                if "camera" in line.lower() or "realsense" in line.lower():
                    self.update_status('camera', 'running')
                if "facedetection" in line.lower():
                    self.update_status('face_detection', 'running')
                if "robot" in line.lower() and "interface" in line.lower():
                    self.update_status('robot_interface', 'running')
                if "navigation" in line.lower():
                    self.update_status('navigation', 'running')
                if "behaviorcontroller" in line.lower():
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
