#!/usr/bin/python
import os
import subprocess
import sys
import webbrowser
from PyQt5.QtWidgets import (QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QCheckBox, QPushButton, QDialog, QSystemTrayIcon, QMenu, QAction, QMessageBox)
from PyQt5.QtGui import QIcon

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Screen Profiler")
        self.profiles_dir = os.path.join(os.getcwd(), "profiles")
        self.screenprofilercmd_path = os.path.join(os.getcwd(), "screenprofilercmd.sh")
        self._tray_icon = None
        self._profiles =[]# List to store available profile names
        self._create_profiles_directory()
        self.init_tray_icon()
        
        # self.hide() # may not need

    #Creates the profiles directory if it doesn't exist.
    def _create_profiles_directory(self):
        if not os.path.exists(self.profiles_dir):
            try:
                os.makedirs(self.profiles_dir)
                print(f"Created profiles directory: {self.profiles_dir}")
            except OSError as e:
                print(f"Error creating profiles directory: {e}")
    
    #Initializes the system tray icon.
    def init_tray_icon(self):
        if self._tray_icon is None:
            self._tray_icon = QSystemTrayIcon(QIcon("resources/mainicon.png"))
            self._tray_icon.setToolTip("Screen Profiler")
            self.update_tray_icon_menu()
            self._tray_icon.show()
        
    #Loads the list of available profile names from the profiles directory.
    def _load_available_profiles(self):
        if os.path.exists(self.profiles_dir):
            try:
                profile_files = [f for f in os.listdir(self.profiles_dir) if os.path.isfile(os.path.join(self.profiles_dir, f))]
                self._profiles = sorted([os.path.splitext(f)[0] for f in profile_files])
            except Exception as e:
                print(f"Error loading profiles: {e}")

    #Creates and adds profile-related actions to the given menu.
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

        for profile_name in self._profiles:
            action = QAction(profile_name, self)
            if action_type == "load":
                action.triggered.connect(lambda checked, name=profile_name: self.screenprofilercmd("load", name, False))
            elif action_type == "save_existing":
                action.triggered.connect(lambda checked, name=profile_name: self.screenprofilercmd("save", name, False))
            elif action_type == "delete":
                action.triggered.connect(lambda checked, name=profile_name: self.screenprofilercmd("remove", name, False))
            menu.addAction(action)

    #Updates the context menu of the system tray icon.
    def update_tray_icon_menu(self):
        menu = QMenu()
        # Refresh list on every open
        menu.aboutToShow.connect(lambda: self.update_tray_icon_menu())
            
        # Top menu title
        profiles_header_action = QAction("Available Profiles", self)
        profiles_header_action.setEnabled(False)
        menu.addAction(profiles_header_action)
        if not self._profiles:
            profiles_header_action.setText("No Profiles")
        else:
            profiles_header_action.setText("Available Profiles")

        # Files in the profiles folder
        self._load_available_profiles() #get array of files
        self._create_profile_actions(menu, "load")
        menu.addSeparator()

        # Save menu
        save_menu = menu.addMenu("Save Profile")
        new_profile_action = QAction("New Profile...", self)
        new_profile_action.triggered.connect(self.open_new_profile_window) # Connect directly to open_new_profile_window
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

    #Executes the screenprofilercmd.sh script."""
    def screenprofilercmd(self, command, profile_name, enable_konsave):
        print(f"screenprofilercmd called with command: {command}, profile: {profile_name}, konsave: {enable_konsave}")
        if os.name == 'posix':
            try:
                konsave_state = "1" if enable_konsave else "0"
                arguments = [self.screenprofilercmd_path, command, profile_name, konsave_state]
                process = subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if command == "remove" or command == "save":
                    self.update_tray_icon_menu() # Update menu after saving or removing
            except FileNotFoundError:
                QMessageBox.critical(self, "Error", f"Script not found: {self.screenprofilercmd_path}")
                print(f"Error: Script not found at {self.screenprofilercmd_path}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Error executing script for command '{command}': {e}")
                print(f"Error executing script for command '{command}': {e}")
        else:
            QMessageBox.warning(self, "Warning", "Bash script execution is only supported on Linux.")
            print("Bash script execution is only supported on Linux.")


    #Handles the creation of a new profile by executing the save script.
    def handle_create_profile(self, profile_name, enable_konsave, dialog):
        print("handle_create_profile called")
        if profile_name:
            self.screenprofilercmd("save", profile_name, enable_konsave)
            print("screenprofilercmd for save completed")
            self.update_tray_icon_menu()
            dialog.hide() # Close the new profile dialog
            print(f"Profile created: {profile_name}, Konsave: {enable_konsave}")
        else:
            print("Profile name cannot be empty.")

###-    Window Generation   -###
    def open_new_profile_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("New Profile")
        layout = QVBoxLayout()

        # Create input fields and checkbox
        name_label = QLabel("Enter Profile Name:")
        name_input = QLineEdit()
        konsave_checkbox = QCheckBox("Enable Konsave Integration")
        konsave_checkbox.setChecked(True)
        # Create buttons
        create_button = QPushButton("Create")
        cancel_button = QPushButton("Cancel")
        # Add widgets to the layout
        layout.addWidget(name_label)
        layout.addWidget(name_input)
        layout.addWidget(konsave_checkbox)
        layout.addWidget(create_button)
        layout.addWidget(cancel_button)
        # Connect button signals to handlers
        create_button.clicked.connect(lambda: self.handle_create_profile(name_input.text(), konsave_checkbox.isChecked(), dialog))
        cancel_button.clicked.connect(dialog.hide)

        dialog.setLayout(layout)
        dialog.exec_()


    def open_about_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("About")
        layout = QVBoxLayout()
        about_label = QLabel("""



        Version 0.0.5""")
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