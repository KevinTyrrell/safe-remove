
## 🗂️ Table of Contents
- [About](#-about)
- [Usage](#-usage)
- [Installation](#-installation)
- [License](#-license)

## ℹ️ About

**safe-remove** or `sm` is a Shell script designed to emulate the `rm` (remove) command, but in a safer manner akin to the Recycle Bin from Windows. Files targeted by *safe-remove* are placed into your 'Recycle Bin' folder (by default, `~/.recycle` in `\$HOME`). Files are removed through `rm` once they exceed a certain threshold and become stale (by default, 30 days). Duplicate named files are renamed accordingly with suffixes `(1)`, `(2)`, etc.


#### The Recycle Bin is only cleaned during subsequent `sm` calls, if applicable. One can automate this process by including `sm --no-op &` in their `.bashrc` or `.bash_profile` or other CLI start-up files.

## 📑 Usage
|Command|Syntax|Description|
|:-|:-|:-|
|Help|--help, -h|Prints help and usage text for safe-remove|
|No-Op|--no-op, -n|Runs without performing operations on the parameters|
|Version|--version, -v|Displays the version number of the program|

## ⚙️ Configuration

The options below are set inside the installed script itself. To edit them, open `sm` in your editor of choice:

```shell
sudo vim /usr/local/bin/sm
```

|Option|Variable|Default|Description|
|:-|:-|:-|:-|
|Recycle Location|[`RECYCLE_DIR_PATH`](https://github.com/KevinTyrrell/safe-remove/blob/766d9643e7f8578f181cdf475531ba6ba997fe41/sm.sh#L24)|`$HOME/.recycle`|Directory where removed files are stored. Must already exist and be writable.|
|Stale File Threshold|[`STALE_THRESH_DAYS`](https://github.com/KevinTyrrell/safe-remove/blob/766d9643e7f8578f181cdf475531ba6ba997fe41/sm.sh#L27)|`30`|Number of days before a file is considered stale. Must be a positive integer.|
|Safe Mode Toggle|[`SAFE_MODE`](https://github.com/KevinTyrrell/safe-remove/blob/766d9643e7f8578f181cdf475531ba6ba997fe41/sm.sh#L29)|`1`|Set to `1` to prompt for approval before deleting stale files, or `0` to delete silently.|

## 📝 Installation

#### Linux

```shell
(cd /tmp && SM_URL=$(curl -fsSL https://api.github.com/repos/KevinTyrrell/safe-remove/releases/latest | grep "zipball_url" | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g') && curl -fsSL -o sm.zip "$SM_URL" && unzip -q sm.zip -d sm && sudo install -m 755 sm/*/sm.sh /usr/local/bin/sm && rm -rf sm.zip sm)
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
