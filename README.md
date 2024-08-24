
## 🗂️ Table of Contents
- [About](#-about)
- [Usage](#-usage)
- [Installation](#-installation)
- [License](#-license)

## ℹ️ About

**safe-remove** or `sm` is a Shell script designed to emulate the `rm` (remove) command, but in a safer manner akin to the Recycle Bin from Windows. Files targeted by *safe-remove* are placed into your 'Recycle Bin' folder (by default, `~/recycle` in `\$HOME`). Files are removed through `rm` once they exceed a certain threshold and become stale (by default, 30 days). Duplicate named files are renamed accordingly with suffixes `(1)`, `(2)`, etc.


#### The Recycle Bin is only cleaned during subsequent `sm` calls, if applicable. One can automate this process by including `sm --no-op &` in their `.bashrc` or `.bash_profile` or other CLI start-up files.

## 📑 Usage
|Command|Syntax|Description|
|:-|:-|:-|
|Help|--help, -h|Prints help and usage text for safe-remove|
|No-OP|--no-op, -n|Runs without performing operations on the parameters|
|Version|--version, -v|Displays the version number of the program|

* ----- **Stale File Threshold:**

By default, files are deleted after 30 days when placed into `/recycle`. To modify this threshold, locate [[EXPIRATION_WINDOW_DAYS in sm.sh]](https://github.com/KevinTyrrell/safe-remove/blob/7af52e503544b2c43981104a16d523cda54fcc8b/sm.sh#L25). Set to a different value, in days.

* ----- **Safe Mode:**

By default, files are deleted from `/recycle` without user approval. To modify this behavior, locate [[SAFE_MODE in sm.sh]](https://github.com/KevinTyrrell/safe-remove/blob/7af52e503544b2c43981104a16d523cda54fcc8b/sm.sh#L27). Set to value `1` to require approval per-file, or `0` for silent deletion.

## 📝 Installation

#### Linux

```shell
cd /usr/local/bin

LOCATION=$(curl -s https://api.github.com/repos/KevinTyrrell/safe-remove/releases/latest \
| grep "zipball_url" \
| awk '{ print $2 }' \
| sed 's/,$//'       \
| sed 's/"//g' )     \
; curl -L -o sm $LOCATION

chmod +x sm
```

#### POSIX-compatible (Windows)

```shell
mkdir -p ~/bin && cd ~/bin

# Add ~/bin to your environmental variable PATH

LOCATION=$(curl -s https://api.github.com/repos/KevinTyrrell/safe-remove/releases/latest \
| grep "zipball_url" \
| awk '{ print $2 }' \
| sed 's/,$//'       \
| sed 's/"//g' )     \
; curl -L -o sm $LOCATION

chmod +x sm
```

## 📃 License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

[[See: LICENSE]](https://github.com/KevinTyrrell/safe-remove/blob/master/LICENSE) for more information.

[Back to top](#top)
