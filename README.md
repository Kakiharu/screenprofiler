Screen Profiler
A simple set of scripts to save, load, list, and remove screen profiles using kscreen-console and xrandr.

Installation
1. Clone the repository:

   git clone https://github.com/yourusername/screenprofiler.git
   cd screenprofiler

2. Make the scripts executable:

   chmod +x screenprofiler.sh
   chmod +x save_profile.sh
   chmod +x load_profile.sh

Usage

Saving a Profile
  The save command captures the current screen configuration and saves it to a profile.
   ./screenprofiler.sh save filename

  Example:
     ./screenprofiler.sh save default
     
     This command will save the current screen configuration to a profile named default in the profiles directory.

Load a Profile
  The load command applies a previously saved screen configuration.
   ./screenprofiler.sh load filename

  Example:
   ./screenprofiler.sh load default

    This command will load and apply the screen configuration from the profile named default.

List Profiles
  The list command displays all available profiles.
   ./screenprofiler.sh list

Remove a Profile
  The remove command deletes a specified profile.
   ./screenprofiler.sh remove filename

Help
  The help command (or -help or --help) displays usage instructions.
   ./screenprofiler.sh help


Dependencies
  The following dependencies are required for the scripts to work correctly:
   - kscreen-console
   - xrandr
   - jq

Ensure these are installed on your system.

License
This project is licensed under the GNU GPLv3 License. See the LICENSE file for details.

