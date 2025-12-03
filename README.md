<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <h1>Screen Profiler</h1>
  <p>
    Screen Profiler makes it easy to switch between different monitor setups on Linux with KDE. 
    You can save your current screen layout, then quickly load it later without having to reconfigure everything. 
    There’s also a simple tray app so you can manage profiles with a mouse click.
  </p>

  <h2>How it Works</h2>
  <p>
    1. Set up your monitors the way you like using KDE’s display settings.<br>
    2. Save that setup as a "profile".<br>
    3. Later, load the profile to instantly restore your layout.<br>
    You can create as many profiles as you want (for example: "TV", "Gaming", "Laptop Only").
  </p>

  <h2>Easy Installation</h2>
  <p>
    The installer places Screen Profiler in your home directory (<code>~/screenprofiler</code>) 
    and adds a shortcut command called <code>screenprofilercmd</code> into your PATH.
  </p>
  <p>
    Quick one‑liner install:
  </p>
  <pre><code>curl -s https://raw.githubusercontent.com/Kakiharu/screenprofiler/main/install.sh | bash</code></pre>

  <h2>Manual Installation</h2>
  <ol>
    <li>
      Clone the repository:
      <pre><code>git clone https://github.com/Kakiharu/screenprofiler.git ~/screenprofiler
cd ~/screenprofiler</code></pre>
    </li>
    <li>
      Make the scripts executable:
      <pre><code>chmod +x screenprofilercmd.sh
chmod +x save_profile.sh
chmod +x load_profile.sh
chmod +x screenprofiler.py</code></pre>
    </li>
    <li>
      Add a symlink so you can run it easily:<br>
      <pre><code>
# If you have root access:
sudo ln -sf ~/screenprofiler/screenprofilercmd.sh /usr/bin/screenprofilercmd

# Otherwise (user-only install):
ln -sf ~/screenprofiler/screenprofilercmd.sh ~/.local/bin/screenprofilercmd
      </code></pre>
    </li>
  </ol>

  <h2>Usage</h2>
  <p>
    <strong>Save a Profile</strong><br>
    Usage: <code>screenprofilercmd save &lt;name&gt; [0|1]</code><br>
    - Use <code>0</code> if you only want to save the monitor layout.<br>
    - Use <code>1</code> if you also want to save KDE desktop settings (like panels and widgets).<br>
    Example: <code>screenprofilercmd save worksetup 1</code>
  </p>

  <p>
    <strong>Load a Profile</strong><br>
    Usage: <code>screenprofilercmd load &lt;name&gt;</code><br>
    Example: <code>screenprofilercmd load worksetup</code>
  </p>

  <p>
    <strong>Remove a Profile</strong><br>
    Usage: <code>screenprofilercmd remove &lt;name&gt;</code>
  </p>

  <p>
    <strong>List Profiles</strong><br>
    Usage: <code>screenprofilercmd list</code><br>
    Shows all saved profiles in alphabetical order.
  </p>

  <p>
    <strong>Tray App</strong><br>
    Usage: <code>screenprofilercmd tray</code><br>
    Opens a system tray icon where you can save, load, and remove profiles with a click.
  </p>

  <p>
    <strong>Uninstall</strong><br>
    Usage: <code>screenprofilercmd uninstall</code><br>
    Runs the uninstall script to remove Screen Profiler from your system.
  </p>

  <h2>Dependencies</h2>
  <p>
    Since Screen Profiler is designed for KDE, you already have the core display tools. 
    You just need these extras:
  </p>
  <ul>
    <li>jq</li>
    <li>Python 3 + PyQt5 (for the tray app)</li>
  </ul>

  <h2>License</h2>
  <p>This project is licensed under the GNU GPLv3 License. See the LICENSE file for details.</p>
</body>
</html>
