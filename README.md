<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>Screen Profiler</h1>
    <p>A program for helping switch between monitor layouts and resolutions in KDE. You can use the base scripts to simply set your resolution.
    There is also a python script that creates a system tray icon for easy gui interaction. You can save, load, list, and remove screen profiles.</p>

  <p>To get started, use the KDE display configuration to set up your screens exactly as you like them. Once everything looks perfect, run the script to save your configuration. Now, you can easily switch between any of your saved configurations whenever you need to.</p>
  <p>KDE integration is included and can be used to let you save and apply your Linux customizations like widgets and panels on certain screens; you must have it installed for this feature to work. If KDE is enabled on the profile creation, it will auto-load on the profile every time. Make sure to save before loading a different profile so you don't lose any saves.
      <br>For example, going from multi-monitor to single monitor and having its own panel.<br>

  <h2>Easy Installation</h2>
  <ol>
      <li>
          <p>Download the install.sh</p>
      </li>
      <li>
          <p>Just place the installer where you want to install it and run. It will automatically add itself to <code>~/.local/bin</code> as <code>screenprofilercmd</code> so you can easily run commands.</p>
      </li>
      <li>
          <p>Don't forget to give it execution rights.</p>
      </li>
  </ol>

  <h2>Manual Installation</h2>
  <ol>
      <li>
          <p>Clone the repository:</p>
          <pre><code>git clone https://github.com/kakiharu/screenprofiler.git
cd screenprofiler</code></pre>
        </li>
        <li>
            <p>Make the scripts executable:</p>
            <pre><code>chmod +x screenprofilercmd.sh
chmod +x save_profile.sh
chmod +x load_profile.sh
chmod +x screenprofiler.py</code></pre>
        </li>
    </ol>

  <h2>Usage</h2>
  <p>Save/Load/Remove Profile<br>
      Usage: <code>screenprofilercmd {save|load|remove} [profilename] [KDE enabled (0 or 1)]</code><br>
      Example: <code>screenprofilercmd save example 1</code> - This will save KDE settings<br>
      Example: <code>screenprofilercmd load example</code><br>
  List Profiles<br>
      Usage: <code>screenprofilercmd list</code></p>
  <p>Help<br>
  The help command (or <code>-help</code> or <code>--help</code>) displays usage instructions.<br>
  Usage: <code>screenprofilercmd help</code></p>
  <br><br>

  <h2>Dependencies</h2>
  <p>The following dependencies are required for the scripts to work correctly:</p>
  <ul>
      <li>kscreen</li>
      <li>xrandr</li>
      <li>jq</li>
      <br>
      <p>Python Dependencies</p>
      <li>PyQt5</li>
  </ul>
  <p>Ensure these are installed on your system.</p>

  <h2>License</h2>
  <p>This project is licensed under the GNU GPLv3 License. See the LICENSE file for details.</p>
</body>
</html>
