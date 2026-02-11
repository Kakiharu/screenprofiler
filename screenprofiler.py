#!/usr/bin/python3
import os
import subprocess
import sys
import webbrowser
import json
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QCheckBox,
    QPushButton, QDialog, QSystemTrayIcon, QMenu, QAction, QMessageBox,
    QComboBox
)
from PyQt5.QtGui import QIcon, QCursor

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Screen Profiler")

        # Paths
        self.base_dir = os.path.dirname(os.path.realpath(__file__))
        self.profiles_dir = os.path.join(self.base_dir, "profiles")
        self.screenprofilercmd_path = os.path.join(self.base_dir, "screenprofilercmd.sh")
        self.resources_dir = os.path.join(self.base_dir, "resources")
        self.config_path = os.path.join(self.resources_dir, "mainicon.cfg")

        self._tray_icon = None
        self._profiles = []

        self._create_profiles_directory()
        self._load_config()
        self.init_tray_icon()

    def _create_profiles_directory(self):
        if not os.path.exists(self.profiles_dir):
            os.makedirs(self.profiles_dir)

    def _load_config(self):
        default_icon = os.path.join(self.resources_dir, "mainicon.png")

        if not os.path.exists(self.resources_dir):
            os.makedirs(self.resources_dir)

        if not os.path.exists(self.config_path):
            with open(self.config_path, "w", encoding="utf-8") as f:
                f.write(default_icon)

        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                self.icon_path = f.read().strip()
        except Exception:
            self.icon_path = default_icon

        if not os.path.exists(self.icon_path):
            self.icon_path = default_icon

    def init_tray_icon(self):
        if self._tray_icon is None:
            self._tray_icon = QSystemTrayIcon(QIcon(self.icon_path))
            self._tray_icon.setToolTip("Screen Profiler")
            self.update_tray_icon_menu()
            self._tray_icon.show()
            self._tray_icon.activated.connect(self.on_tray_activated)

    def on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.Trigger:
            if self._tray_icon.contextMenu():
                self._tray_icon.contextMenu().popup(QCursor.pos())

    def _load_available_profiles(self):
        if os.path.exists(self.profiles_dir):
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
                    except Exception:
                        pass
                self._profiles.append((d, save_kde, primary_monitor))
            self._profiles.sort(key=lambda tup: tup[0].lower())

    def _create_profile_actions(self, menu, action_type):
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

    def update_tray_icon_menu(self):
        menu = QMenu()
        menu.aboutToShow.connect(lambda: self.update_tray_icon_menu())

        self._load_available_profiles()
        profiles_header_action = QAction("Available Profiles", self)
        profiles_header_action.setEnabled(False)
        menu.addAction(profiles_header_action)

        if not self._profiles:
            profiles_header_action.setText("No Profiles")
        else:
            self._create_profile_actions(menu, "load")
        menu.addSeparator()

        save_menu = menu.addMenu("Save Profile")
        new_profile_action = QAction("New Profile...", self)
        new_profile_action.triggered.connect(self.open_new_profile_window)
        save_menu.addAction(new_profile_action)
        self._create_profile_actions(save_menu, "save_existing")

        delete_menu = menu.addMenu("Delete Profile")
        self._create_profile_actions(delete_menu, "delete")
        menu.addSeparator()

        settings_action = QAction("Settings", self)
        settings_action.triggered.connect(self.open_settings_window)
        menu.addAction(settings_action)
        menu.addSeparator()

        about_action = QAction("About", self)
        about_action.triggered.connect(self.open_about_window)
        menu.addAction(about_action)

        donate_action = QAction("Donate", self)
        donate_action.triggered.connect(lambda: webbrowser.open("https://linktr.ee/kakiharu"))
        menu.addAction(donate_action)
        menu.addSeparator()

        exit_action = QAction("Exit", self)
        exit_action.triggered.connect(QApplication.quit)
        menu.addAction(exit_action)

        self._tray_icon.setContextMenu(menu)

    def screenprofilercmd(self, command, profile_name, save_kde_flag):
        if os.name == 'posix':
            try:
                arguments = [self.screenprofilercmd_path, command, profile_name]
                if command == "save":
                    kde_state = "1" if save_kde_flag else "0"
                    arguments.append(kde_state)
                subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if command in ["remove", "save"]:
                    self.update_tray_icon_menu()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Error executing script: {e}")

    def handle_create_profile(self, profile_name, save_kde_flag, dialog):
        if profile_name:
            self.screenprofilercmd("save", profile_name, save_kde_flag)
            self.update_tray_icon_menu()
            dialog.hide()

    ###- Window Generation -###
    def open_new_profile_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("New Profile")
        layout = QVBoxLayout()

        name_label = QLabel("Enter Profile Name:")
        name_input = QLineEdit()
        kde_checkbox = QCheckBox("Save KDE desktop settings")
        kde_checkbox.setChecked(True)

        create_button = QPushButton("Create")
        cancel_button = QPushButton("Cancel")

        layout.addWidget(name_label)
        layout.addWidget(name_input)
        layout.addWidget(kde_checkbox)
        layout.addWidget(create_button)
        layout.addWidget(cancel_button)

        create_button.clicked.connect(lambda: self.handle_create_profile(
            name_input.text(),
            kde_checkbox.isChecked(),
            dialog
        ))
        cancel_button.clicked.connect(dialog.hide)

        dialog.setLayout(layout)
        dialog.exec_()

    def open_settings_window(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("Settings")
        layout = QVBoxLayout()

        icon_label = QLabel("Icon")
        icon_dropdown = QComboBox()

        if os.path.exists(self.resources_dir):
            for fname in os.listdir(self.resources_dir):
                # Restrict to raster formats only
                if fname.lower().endswith((".png", ".jpg", ".jpeg")):
                    icon_dropdown.addItem(fname)

        current_icon_file = os.path.basename(self.icon_path)
        idx = icon_dropdown.findText(current_icon_file)
        if idx >= 0:
            icon_dropdown.setCurrentIndex(idx)

        layout.addWidget(icon_label)
        layout.addWidget(icon_dropdown)

        save_button = QPushButton("Save")
        cancel_button = QPushButton("Cancel")
        layout.addWidget(save_button)
        layout.addWidget(cancel_button)

        save_button.clicked.connect(lambda: self.handle_save_settings(
            icon_dropdown.currentText(),
            dialog
        ))
        cancel_button.clicked.connect(dialog.hide)

        dialog.setLayout(layout)
        dialog.exec_()

    def handle_save_settings(self, selected_icon, dialog):
        new_icon_path = os.path.join(self.resources_dir, selected_icon)

        self._tray_icon.setIcon(QIcon(new_icon_path))
        self.icon_path = new_icon_path

        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                f.write(self.icon_path)
        except Exception as e:
            print(f"Error saving mainicon.cfg: {e}")

        dialog.hide()
    def get_version(self):
        common_path = os.path.join(self.base_dir, "common.sh")
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
