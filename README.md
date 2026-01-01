<div align="center">
    <img src="https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/pwsl/dist/png/pwsl-128x128.png" alt="PWSL Logo">
    <h1><strong>PWSL</strong></h1>
     <small>Powershell Windows Subsystem for Linux</small>
    <hr>
    <p>A wrapper for <code>wsl.exe</code>. It parses WSL output into standard PowerShell objects, provides safety checks for destructive operations, and automates the migration of distributions between drives.</p>
    <small>Available on <strong>MacOS</strong>, <strong>Linux</strong>, and <strong>Windows</strong></small>
    <span>
        <h5>
            <a href="https://gitlab.com/phellams/pwsl">Website</a> |
            <a href="https://gitlab.com/phellams/pwsl#Core Features">Features</a> | 
            <a href="https://github.com/phellams/pwsl">GitHub</a> |
            <a href="https://www.powershellgallery.com/packages/PWSL">PSGallery</a> |
            <a href="https://chocolatey.org/packages/pwsl">Chocolatey</a>
        </h5>
    </span>
    <hr>
</div>


## **Installation**

1. Save the module code as `pwsl.psm1`.
2. Import the module in your session or profile:

```powershell
Import-Module .\pwsl.psm1
```
> **Note:** This module requires Windows 10/11 with WSL enabled.

## **Core Features**

### 1. Object-Oriented Output

Standard `wsl --list` returns raw text (often with encoding issues). `PWSL` returns PowerShell objects.

```powershell
$distros = Get-PwslList
$distros | Where-Object { $_.State -eq 'Running' }

```

### 2. Moving Distributions

`Move-PwslDistro` automates the manual Export -> Unregister -> Import workflow.

**Logic Handled:**

1. **Stops** the running distro.
2. **Exports** to a temporary location (with file size safety checks).
3. **Unregisters** (deletes) the original only if the backup is valid.
4. **Imports** to the new destination.
5. **Restores Default User:** Injects `/etc/wsl.conf` so you don't log in as `root` by default.

```powershell
# Move Ubuntu to D: drive and set as default
Move-PwslDistro -Name "Ubuntu-24.04" -NewLocation "D:\WSL\Ubuntu" -SetAsDefault

```

### ⚠️ Important: Moving & Users

When a distro is imported, WSL defaults the user to `root`. This script attempts to ask for your username and write it to `/etc/wsl.conf` automatically. If this fails, you will log in as root.

To fix manually inside the distro:

```bash
# Inside WSL
echo -e "[user]\ndefault=your_username" >> /etc/wsl.conf

```

### 3. Argument Completion

The module registers a tab-completer. You can press `[TAB]` to cycle through installed distro names for commands like `Stop-`, `Move-`, or `Enter-`.

## **Command Reference**

### General

| Command             | Description                                                      |
| ------------------- | ---------------------------------------------------------------- |
| `Get-PwslList`      | Returns object list of installed distros (Name, State, Version). |
| `Get-PwslRunning`   | Returns only running distros.                                    |
| `Get-PwslAvailable` | Lists distros available for download (`wsl --list --online`).    |
| `Enter-PwslDistro`  | Enters the shell of a specific distro (`wsl -d`).                |

### Lifecycle

| Command                 | Description                                           |
| ----------------------- | ----------------------------------------------------- |
| `Install-PwslDistro`    | Installs a new distro from the online list.           |
| `Stop-PwslDistro`       | Terminates a running instance immediately.            |
| `Register-PwslDistro`   | Alias for Import. Registers a custom rootfs.          |
| `Unregister-PwslDistro` | ⚠️ **Destructive**. Deletes the distro and virtual disk. |

### Migration / Backup

| Command             | Description                            |
| ------------------- | -------------------------------------- |
| `Move-PwslDistro`   | Safely moves a distro to a new path.   |
| `Export-PwslDistro` | Exports rootfs to a `.tar` file.       |
| `Import-PwslDistro` | Imports a `.tar` file as a new distro. |

## **Examples**

**Install and Setup**

```powershell
# Check what is available
Get-PwslAvailable

# Install
Install-PwslDistro -Name "Debian"

# install in a specific location
# Note: Move-Pwsldistro will be called to perform move steps and will take addtional time
# Note: Default user must be the same as the one you specify during intereactive installation
Install-PwslDistro -Name "Debian" -InstallLocation "C:\WSL\Debian"
```

**Backup and res**

```powershell
# Create a snapshot
Export-PwslDistro -Name "Debian" -Path "C:\Backups\debian-snap.tar"

# Restore as a separate instance for testing
Import-PwslDistro -Name "Debian-Test" -InstallLocation "C:\WSL\Test" -SourceTar "C:\Backups\debian-snap.tar"
```

**Relocation**

```powershell
# Move to a different drive
Get-PwslList

# Default temp location is C:\Users\gsnow\AppData\Local\Temp
Move-PwslDistro -Name "Debian" -NewLocation "G:\WSL\Debian" -defaultUser "username"

# custom temp location
Move-PwslDistro -Name "Debian" -NewLocation "G:\WSL\Debian" -TempLocation "G:\Backups" -defaultUser "username"
```

## **Roadmap**

## **Contribute**

## **Acknowledgments**

 - WSL2: [**@wsl**](https://learn.microsoft.com/en-us/windows/wsl/about) - Windows Subsystem for Linux (WSL) lets developers run a GNU/Linux environment inside a Windows environment.
 - Shields\.io: [**@shields.io**](https://shields.io/) - Shields.io provides a service to generate badges and other visual elements for your projects.

## License

This module is released under the [MIT License](https://github.com/gsnow/pwsl/blob/main/LICENSE).
