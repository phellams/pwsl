<div align="center">
    <img src="https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/pwsl/dist/png/pwsl-128x128.png" alt="PWSL Logo">
    <h1><strong>PWSL</strong></h1>
    <p><b>PowerShell Windows Subsystem for Linux</b></p>
    <hr>
    <p>A wrapper for <code>wsl.exe</code>. It parses WSL output into standard PowerShell objects, provides safety checks for destructive operations, and automates the migration of distributions between drives.</p>
    <p>🚨 <strong>Requirement:</strong> Windows 10/11 with WSL enabled.</p>
    <br>
    <span>
        <a href="https://gitlab.com/phellams/pwsl#Core Features"><strong>Core Features</strong></a> ♾️
        <a href="https://www.powershellgallery.com/packages/PWSL"><strong>PSGallery</strong></a> ♾️
        <a href="https://chocolatey.org/packages/pwsl"><strong>Chocolatey</strong></a> ♾️
        <a href="https://github.com/phellams/pwsl"><strong>GitHub</strong></a>
    </span>
    <br>
    <br>

   [![gitlab-license](https://img.shields.io/gitlab/license/phellams/pwsl?style=for-the-badge&logo=gitlab&labelColor=sienna4&color=%23ffaf5f&logoColor=%23ffd7af)](https://gitlab.com/phellams) [![gitlab-pipeline](https://img.shields.io/gitlab/pipeline-status/phellams/pwsl?style=for-the-badge&logo=gitlab&labelColor=sienna4&color=%23ffaf5f&logoColor=%23ffd7af)](https://gitlab.com/phellams) [![gitlab-issues](https://img.shields.io/gitlab/issues/open/phellams/pwsl?style=for-the-badge&logo=gitlab&labelColor=sienna4&color=%23ffaf5f&logoColor=%23ffd7af)](https://gitlab.com/phellams)

   <img src="https://raw.githubusercontent.com/phellams/phellams-general-resources/main/misc/hr/hr-style-pencel-gradient-blue.svg" alt="hr-style-pencel-gradient-blue.svg" ><br>


</div>


## **Installation**

Installing **pwsl** is available via the package repositories: ***PSGallery***, ***Chocolatey*** and ***GitLab***.

|▓▓▓▓▒▒▒▒░░░|▓▓▓▓▒▒▒▒░░░|▓▓▓▓▒▒▒▒░░░|
|-|-|-|
| 📦 PSGallery  | <a href="https://www.powershellgallery.com/packages/pwsl"> <img src="https://img.shields.io/powershellgallery/v/pwsl?label=version&style=flat-square&logoColor=blue&labelColor=23CD5C5C&color=%231E3D59" alt="powershellgallery"></a>       | <img src="https://img.shields.io/powershellgallery/dt/pwsl?style=flat-square&logoColor=blue&label=downloads&labelColor=23CD5C5C&color=%231E3D59" alt="powershellgallery-downloads">       |
| 📦 Chocolatey | <a href="https://community.chocolatey.org/packages/pwsl/"><img src="https://img.shields.io/chocolatey/v/pwsl?label=version&include_prereleases&style=flat-square&logoColor=blue&labelColor=23CD5C5C&color=%231E3D59" alt="chocolatey"/></a> | <img src="https://img.shields.io/chocolatey/dt/pwsl?style=flat-square&logoColor=blue&label=downloads&include_prereleases&labelColor=23CD5C5C&color=%231E3D59" alt="chocolatey-downloads"> |

***Additinonal Installation Options:***
 
|▓▓▓▓▒▒▒▒░░░|▓▓▓▓▒▒▒▒░░░|▓▓▓▓▒▒▒▒░░░|
|-|-|-|
| 💼 Releases/Tags | <a href="https://gitlab.com/phellams/pwsl/-/releases"> <img src="https://img.shields.io/gitlab/v/release/phellams%2Fpwsl?include_prereleases&style=flat-square&logoColor=%2300B2A9&labelColor=%23CD5C5C&color=%231E3D59" alt="gitlab-release"></a> | <a href="https://gitlab.com/phellams/pwsl/-/tags"> <img src="https://img.shields.io/gitlab/v/tag/phellams%2Fpwsl?include_prereleases&style=flat-square&logoColor=%&labelColor=%23CD5C5C&color=%231E3D59" alt="gitlab tags"></a> |

#### *GitLab Packages*

Using `nuget`: See the [**packages**](https://gitlab.com/phellams/pwsl/-/packages?orderBy=name&sort=asc&search[]=pwsl&type=NuGet) page for installation instructions.

> For instructions on adding `nuget sources` packages from **GitLab** see [**Releases**](https://github.com/sgkens/pwsl/releases) artifacts or via the [**Packages**](https://gitlab.com/phellams/pwsl/-/packages?orderBy=name&sort=asc&search[]=pwsl&type=NuGet) page.

#### *Generic Package Registry*

The latest release artifacts can be downloaded from the [**Generic Assets Artifacts**](https://gitlab.com/phellams/pwsl/-/packages?orderBy=type&sort=desc&type=Generic) page.

#### *Git*

```bash
# Clone the repository
git clone https://gitlab.com/phellams/pwsl.git
cd pwsl
import-module .\
```

## **Core Features**

### 🔸 Object-Oriented Output

Standard `wsl --list` returns raw text (often with encoding issues). `PWSL` returns PowerShell objects.

```powershell
$distros = Get-PwslList
$distros | Where-Object { $_.State -eq 'Running' }

```

### 🔸 Moving Distributions

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

### 🔸⚠️ Important: Moving & Users

When a distro is imported, WSL defaults the user to `root`. This script attempts to ask for your username and write it to `/etc/wsl.conf` automatically. If this fails, you will log in as root.

To fix manually inside the distro:

```bash
# Inside WSL
echo -e "[user]\ndefault=your_username" >> /etc/wsl.conf

```

### 🔸 Argument Completion

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

 - [ ] The ability to enable and disble wsl via powershell
 - [ ] The ability to list distro versions and perhaps install previous version if the need is there
 - [ ] complete phwriter help metadata for accurate help output

## Contributing

Contributions are welcome! Please fork the repository and submit a **Merge Request** (MR) targeting the `develop` branch.

1. **Fork the Project**
   Click the "Fork" button in the top right corner of the repository page.

2. **Clone your Fork**
   ```bash
   git clone [https://gitlab.com/YOUR_USERNAME/pwsl.git](https://gitlab.com/YOUR_USERNAME/pwsl.git)
   cd pwslmerge_requests/new)
   ```

3. Create a Feature Branch Ensure you base your work on the develop branch:
   ```bash
   git switch develop
   git switch -c feature/AmazingFeature
   ```

4. Commit your Changes
   ```bash
   git commit -m 'feat: Add some AmazingFeature'
   ```

5. Push to the Branch
   ```bash
   git push origin feature/AmazingFeature
   ```

6. Open a Merge Request

   <a href="https://gitlab.com/phellams/pwsl/-/merge_requests/new"><img src="https://img.shields.io/badge/Open_Merge_Request-GitLab-orange?style=flat-square&logo=gitlab"></a>
   > https://gitlab.com/phellams/pwsl/-/merge_requests/new


## **Acknowledgments**

 - [**@wsl**](https://learn.microsoft.com/en-us/windows/wsl/about) - Windows Subsystem for Linux (WSL) lets developers run a GNU/Linux environment inside a Windows environment.
 - [**@shields.io**](https://shields.io/) - Shields.io provides a service to generate badges and other visual elements for your projects.

## License

This module is released under the [MIT License](https://github.com/gsnow/pwsl/blob/main/LICENSE).
