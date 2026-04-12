# Screen Profiler

Screen Profiler makes it easy to switch between different monitor setups on Linux with KDE. You can save your current screen layout, then quickly load it later without having to reconfigure everything. There’s also a simple tray app so you can manage profiles with a mouse click. 

## How it Works

1. Set up your monitors the way you like using KDE’s display settings.  
2. Save that setup as a "profile".  
3. Later, load the profile to instantly restore your layout.  
You can create as many profiles as you want (for example: "TV", "Gaming", "Laptop Only"). 

## Easy Installation

The installer places Screen Profiler in your home directory (`~/screenprofiler`) and adds a shortcut command called `screenprofilercmd` into your PATH. 

Quick one‑liner install: 

```
`curl -s https://raw.githubusercontent.com/Kakiharu/screenprofiler/main/install.sh | sed 's/\r//' | bash`
```

## Manual Installation

1. Clone the repository: 

```
`git clone https://github.com/Kakiharu/screenprofiler.git ~/screenprofiler`

`cd ~/screenprofiler`
```

2. Make the scripts executable: 

```
`chmod +x screenprofilercmd.sh`

`chmod +x save\_profile.sh`

`chmod +x load\_profile.sh`

`chmod +x screenprofiler.py`
```

3. Add a symlink so you can run it easily:


`\# If you have root access:`

`sudo ln -sf ~/screenprofiler/screenprofilercmd.sh /usr/bin/screenprofilercmd`
```

# Otherwise (user-only install):

ln -sf ~/screenprofiler/screenprofilercmd.sh ~/.local/bin/screenprofilercmd 


## Usage

**Save a Profile**  
Usage: `screenprofilercmd save \<name\> \[0|1\]`  
- Use `0` if you only want to save the monitor layout.  
- Use `1` if you also want to save KDE desktop settings (like panels and widgets).  
Example: `screenprofilercmd save worksetup 1` 

**Load a Profile**  
Usage: `screenprofilercmd load \<name\>`  
Example: `screenprofilercmd load worksetup` 

**Remove a Profile**  
Usage: `screenprofilercmd remove \<name\>` 

**List Profiles**  
Usage: `screenprofilercmd list`  
Shows all saved profiles in alphabetical order. 

**Tray App**  
Usage: `screenprofilercmd tray`  
Opens a system tray icon where you can save, load, and remove profiles with a click. 

**Uninstall**  
Usage: `screenprofilercmd uninstall`  
Runs the uninstall script to remove Screen Profiler from your system.

**Update**  
Usage: `screenprofilercmd update`  
Runs the install script to updateScreen Profiler.

## Dependencies

Since Screen Profiler is designed for KDE, you already have the core display tools. You just need these extras: 

- jq 

## License

This project is licensed under the GNU GPLv3 License. See the LICENSE file for details.
