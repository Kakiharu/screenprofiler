<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <h1>Screen Profiler</h1>
  <p>A simple set of scripts to save, load, list, and remove screen profiles using <code>kscreen-doctor</code>.</p>
  <p>To get started, use the KDE display configuration to set up your screens exactly as you like them. Once everything looks perfect, run the script to save your configuration. Now, you can easily switch between any of your saved configurations whenever you need to.</p>

  <h2>Installation</h2>
  <ol>
    <li>
      <p>Clone the repository:</p>
      <pre><code>git clone https://github.com/kakiharu/screenprofiler.git
cd screenprofiler</code></pre>
    </li>
    <li>
      <p>Make the scripts executable:</p>
      <pre><code>chmod +x screenprofiler.sh
chmod +x save_profile.sh
chmod +x load_profile.sh</code></pre>
    </li>
  </ol>

  <h2>Usage</h2>

  <h3>Saving a Profile</h3>
  <p>The save command captures the current screen configuration and saves it to a profile.</p>
  <pre><code>./screenprofiler.sh save [filename]</code></pre>
  <blockquote>
  <p>Example:</p>
  <p>This command will save the current screen configuration to a profile named <code>default</code> in the <code>profiles</code> directory.</p>
  <pre><code>./screenprofiler.sh save default</code></pre>
  </blockquote>
  <br>

  <h3>Loading a Profile</h3>
  <p>The load command applies a previously saved screen configuration.</p>
  <pre><code>./screenprofiler.sh load [filename]</code></pre>
  <blockquote>
  <p>Example:</p>
  <p>This command will load and apply the screen configuration from the profile named <code>default</code>.</p>
  <pre><code>./screenprofiler.sh load default</code></pre>
  </blockquote>
  <br>

  <h3>Listing Profiles</h3>
  <p>The list command displays all available profiles.</p>
  <pre><code>./screenprofiler.sh list</code></pre>
  <br>

  <h3>Remove a Profile</h3>
  <p>The remove command deletes a specified profile.</p>
  <pre><code>./screenprofiler.sh remove [filename]</code></pre>
  <br>

  <h3>Help</h3>
  <p>The help command (or <code>-help</code> or <code>--help</code>) displays usage instructions.</p>
  <pre><code>./screenprofiler.sh help</code></pre>
  <br>
  <br>

  <h2>Dependencies</h2>
  <p>The following dependencies are required for the scripts to work correctly:</p>
  <ul>
    <li>kscreen</li>
    <li>xrandr</li>
    <li>jq</li>
  </ul>
  <p>Ensure these are installed on your system.</p>

  <h2>License</h2>
  <p>This project is licensed under the GNU GPLv3 License. See the LICENSE file for details.</p>
</body>
</html>
