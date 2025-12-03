#!/usr/bin/python
import os
import subprocess
import sys
import webbrowser
import json
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QCheckBox,
    QPushButton, QDialog, QSystemTrayIcon, QMenu, QAction, QMessageBox
)
from PyQt5.QtGui import QIcon, QCursor

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Screen Profiler")

        #Always resolve paths relative to this file, not cwd
        self.base_dir = os.path.dirname(os.path.realpath(__file__))
        self.profiles_dir = os.path.join(self.base_dir, "profiles")
        self.screenprofilercmd_path = os.path.join(self.base_dir, "screenprofilercmd.sh")

        self._tray_icon = None
        self._profiles = []  # List of tuples (name, save_kde_flag, primary_monitor)
        self._create_profiles_directory()
        self.init_tray_icon()

    def _create_profiles_directory(self):
        if not os.path.exists(self.profiles_dir):
            try:
                os.makedirs(self.profiles_dir)
                print(f"Created profiles directory: {self.profiles_dir}")
            except OSError as e:
                print(f"Error creating profiles directory: {e}")
    # Initializes the system tray icon.
    def init_tray_icon(self):
        if self._tray_icon is None:
            icon_path = os.path.join(self.base_dir, "resources", "mainicon.png")
            self._tray_icon = QSystemTrayIcon(QIcon(icon_path))
            self._tray_icon.setToolTip("Screen Profiler")
            self.update_tray_icon_menu()
            self._tray_icon.show()
            self._tray_icon.activated.connect(self.on_tray_activated)


    # Handle left-click activation
    def on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.Trigger:  # left-click
            if self._tray_icon.contextMenu():
                self._tray_icon.contextMenu().popup(QCursor.pos())

    # Loads the list of available profile names and their metadata.
    def _load_available_profiles(self):
        if os.path.exists(self.profiles_dir):
            try:
                profile_dirs = [d for d in os.listdir(self.profiles_dir)
                                if os.path.isdir(os.path.join(self.profiles_dir, d))]
                self._profiles = []
                for d in profile_dirs:
                    meta_path = os.path.join(self.profiles_dir, d, "meta.json")
                    save_kde = True
                    primary_monitor = None
                    if os.path.exists(meta_path):
                        try:
                            with open(meta_path) as f:
                                meta = json.load(f)
                                save_kde = (meta.get("save_kde", 1) == 1)
                                primary_monitor = meta.get("primaryMonitor")
                        except Exception as e:
                            print(f"Error reading metadata for {d}: {e}")
                    self._profiles.append((d, save_kde, primary_monitor))
                #Sort alphabetically by profile name
                self._profiles.sort(key=lambda tup: tup[0].lower())
            except Exception as e:
                print(f"Error loading profiles: {e}")

    # Creates and adds profile-related actions to the given menu.
    def _create_profile_actions(self, menu, action_type):
        if not os.path.exists(self.profiles_dir):
            no_dir_action = QAction("Profiles directory not found", self)
            no_dir_action.setEnabled(False)
            menu.addAction(no_dir_action)
            return

        if not self._profiles:
            if action_type == "delete":
                no_profiles_action = QAction("No profiles available", self)
                no_profiles_action.setEnabled(False)
                menu.addAction(no_profiles_action)
            return

        for profile_name, save_kde, primary_monitor in self._profiles:
            action = QAction(profile_name, self)
            if primary_monitor:
                action.setToolTip(f"Primary monitor: {primary_monitor}")
            if action_type == "load":
                action.triggered.connect(lambda checked, name=profile_name:
                                         self.screenprofilercmd("load", name, None))
            elif action_type == "save_existing":
                action.triggered.connect(lambda checked, name=profile_name, flag=save_kde:
                                         self.screenprofilercmd("save", name, flag))
            elif action_type == "delete":
                action.triggered.connect(lambda checked, name=profile_name:
                                         self.screenprofilercmd("remove", name, None))
            menu.addAction(action)

    # Updates the context menu of the system tray icon.
    def update_tray_icon_menu(self):
        menu = QMenu()
        menu.aboutToShow.connect(lambda: self.update_tray_icon_menu())

        profiles_header_action = QAction("Available Profiles", self)
        profiles_header_action.setEnabled(False)
        menu.addAction(profiles_header_action)

        self._load_available_profiles()
        if not self._profiles:
            profiles_header_action.setText("No Profiles")
        else:
            profiles_header_action.setText("Available Profiles")
            self._create_profile_actions(menu, "load")
        menu.addSeparator()

        # Save menu
        save_menu = menu.addMenu("Save Profile")
        new_profile_action = QAction("New Profile...", self)
        new_profile_action.triggered.connect(self.open_new_profile_window)
        save_menu.addAction(new_profile_action)
        self._create_profile_actions(save_menu, "save_existing")

        # Delete menu
        delete_menu = menu.addMenu("Delete Profile")
        self._create_profile_actions(delete_menu, "delete")
        menu.addSeparator()

        # About menu
        about_action = QAction("About", self)
        about_action.triggered.connect(self.open_about_window)
        menu.addAction(about_action)

        # Donate menu
        donate_action = QAction("Donate", self)
        donate_action.triggered.connect(lambda: webbrowser.open("patreon.com/user?u=32768912"))
        menu.addAction(donate_action)
        menu.addSeparator()

        # Exit menu
        exit_action = QAction("Exit", self)
        exit_action.triggered.connect(QApplication.quit)
        menu.addAction(exit_action)

        self._tray_icon.setContextMenu(menu)

    # Executes the screenprofilercmd.sh script.
    def screenprofilercmd(self, command, profile_name, save_kde_flag):
        print(f"screenprofilercmd called with command: {command}, profile: {profile_name}, save_kde_flag: {save_kde_flag}")
        if os.name == 'posix':
            try:
                arguments = [self.screenprofilercmd_path, command, profile_name]
                if command == "save":
                    kde_state = "1" if save_kde_flag else "0"
                    arguments.append(kde_state)
                subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if command in ["remove", "save"]:
                    self.update_tray_icon_menu()
            except FileNotFoundError:
                QMessageBox.critical(self, "Error", f"Script not found: {self.screenprofilercmd_path}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Error executing script for command '{command}': {e}")
        else:
            QMessageBox.warning(self, "Warning", "Bash script execution is only supported on Linux.")

    # Handles the creation of a new profile by executing the save script.
    def handle_create_profile(self, profile_name, save_kde_flag, dialog):
        if profile_name:
            self.screenprofilercmd("save", profile_name, save_kde_flag)
            self.update_tray_icon_menu()
            dialog.hide()
        else:
            print("Profile name cannot be empty.")

    ###- Window Generation -###
    def open_new_profile_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("New Profile")
        layout = QVBoxLayout()

        name_label = QLabel("Enter Profile Name:")
        name_input = QLineEdit()
        kde_checkbox = QCheckBox("Save KDE desktop settings (panels, widgets, themes)")
        kde_checkbox.setChecked(True)

        create_button = QPushButton("Create")
        cancel_button = QPushButton("Cancel")

        layout.addWidget(name_label)
        layout.addWidget(name_input)
        layout.addWidget(kde_checkbox)
        layout.addWidget(create_button)
        layout.addWidget(cancel_button)

        create_button.clicked.connect(lambda: self.handle_create_profile(name_input.text(), kde_checkbox.isChecked(), dialog))
        cancel_button.clicked.connect(dialog.hide)

        dialog.setLayout(layout)
        dialog.exec_()

    # Reads version from common.sh
    def get_version(self):
        common_path = os.path.join(os.getcwd(), "common.sh")
        try:
            with open(common_path) as f:
                for line in f:
                    if line.startswith("SCREENPROFILER_VERSION="):
                        return line.split("=")[1].strip().strip('"')
        except Exception as e:
            print(f"Error reading version: {e}")
        return "unknown"

    def open_about_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("About")
        layout = QVBoxLayout()
        version = self.get_version()
        about_label = QLabel(f"Screen Profiler\n\nVersion {version}")
        close_button = QPushButton("Close")
        layout.addWidget(about_label)
        layout.addWidget(close_button)
        close_button.clicked.connect(dialog.hide)
        dialog.setLayout(layout)
        dialog.exec_()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    exit_code = app.exec_()
    sys.exit(exit_code)
