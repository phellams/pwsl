# COMMON params
$source = "https://gitlab.com/phellams/pwsl/-/blob/main/readme.md"
$phwriter_metadata_array = @(
    @{
        commandinfo = @{
            cmdlet      = "Get-PwslList";
            synopsis    = "Get-PwslList";
            description = "Lists all installed WSL distributions, returning PowerShell objects with Name, State, Version, and Default status.";
            source      = ""
        }
        paramtable  = @()
        examples    = @(
            "Get-PwslList",
            "Get-PwslList | Where-Object { $_.State -eq 'Running' }"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Get-PwslRunning";
            synopsis    = "Get-PwslRunning";
            description = "Returns a list of only the currently running WSL distributions.";
            source      = ""
        }
        paramtable  = @()
        examples    = @(
            "Get-PwslRunning"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Get-PwslAvailable";
            synopsis    = "Get-PwslAvailable";
            description = "Lists the distributions available for download and installation from the online store.";
            source      = ""
        }
        paramtable  = @()
        examples    = @(
            "Get-PwslAvailable"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Install-PwslDistro";
            synopsis    = "Install-PwslDistro [-Name <String>]";
            description = "Installs a specific WSL distribution from the online list.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to install (e.g., 'Ubuntu-24.04')."
                inline      = $false
            }
        )
        examples    = @(
            "Install-PwslDistro -Name 'Ubuntu-24.04'",
            "Install-PwslDistro -Name 'Debian'"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Move-PwslDistro";
            synopsis    = "Move-PwslDistro [-Name <String>] [-NewLocation <String>] [-DefaultUser <String>] [-SetAsDefault]";
            description = "Safely moves a WSL distro to a new drive/folder. Handles stop, export, unregister, import, and user restoration automatically.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to move."
                inline      = $false
            },
            @{
                name        = "NewLocation"
                param       = "NewLocation"
                type        = "string"
                required    = $true
                description = "The target directory where the new disk image will be stored."
                inline      = $false
            },
            @{
                name        = "DefaultUser"
                param       = "DefaultUser"
                type        = "string"
                required    = $false
                description = "The username to set as default after import (prevents logging in as root)."
                inline      = $false
            },
            @{
                name        = "SetAsDefault"
                param       = "SetAsDefault"
                type        = "switch"
                required    = $false
                description = "If set, marks this distro as the default WSL instance."
                inline      = $false
            }
        )
        examples    = @(
            "Move-PwslDistro -Name 'Ubuntu' -NewLocation 'D:\WSL\Ubuntu'",
            "Move-PwslDistro -Name 'Debian' -NewLocation 'E:\VMs\Debian' -DefaultUser 'dev_user' -SetAsDefault"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Export-PwslDistro";
            synopsis    = "Export-PwslDistro [-Name <String>] [-Path <String>]";
            description = "Exports a distribution's filesystem to a .tar archive.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to export."
                inline      = $false
            },
            @{
                name        = "Path"
                param       = "Path"
                type        = "string"
                required    = $true
                description = "The full path for the output .tar file."
                inline      = $false
            }
        )
        examples    = @(
            "Export-PwslDistro -Name 'Ubuntu' -Path 'C:\Backups\ubuntu.tar'"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Import-PwslDistro";
            synopsis    = "Import-PwslDistro [-Name <String>] [-InstallLocation <String>] [-SourceTar <String>]";
            description = "Imports a .tar file as a new WSL distribution.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name to assign to the new distribution."
                inline      = $false
            },
            @{
                name        = "InstallLocation"
                param       = "InstallLocation"
                type        = "string"
                required    = $true
                description = "The directory where the ext4.vhdx disk image will be created."
                inline      = $false
            },
            @{
                name        = "SourceTar"
                param       = "SourceTar"
                type        = "string"
                required    = $true
                description = "The path to the source .tar file."
                inline      = $false
            }
        )
        examples    = @(
            "Import-PwslDistro -Name 'Ubuntu-Copy' -InstallLocation 'D:\WSL\UbuntuCopy' -SourceTar 'C:\Backups\ubuntu.tar'"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Unregister-PwslDistro";
            synopsis    = "Unregister-PwslDistro [-Name <String>] [-Force]";
            description = "Deletes a distribution and its hard drive image. This action is destructive.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to delete."
                inline      = $false
            },
            @{
                name        = "Force"
                param       = "Force"
                type        = "switch"
                required    = $false
                description = "Skips the confirmation prompt."
                inline      = $false
            }
        )
        examples    = @(
            "Unregister-PwslDistro -Name 'Ubuntu-Old'",
            "Unregister-PwslDistro -Name 'TestDistro' -Force"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Stop-PwslDistro";
            synopsis    = "Stop-PwslDistro [-Name <String>]";
            description = "Terminates a running distribution immediately.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to stop."
                inline      = $false
            }
        )
        examples    = @(
            "Stop-PwslDistro -Name 'Ubuntu-24.04'"
        )
    },
    @{
        commandinfo = @{
            cmdlet      = "Enter-PwslDistro";
            synopsis    = "Enter-PwslDistro [-Name <String>] [-User <String>]";
            description = "Enters the interactive shell of the specified distribution.";
            source      = ""
        }
        paramtable  = @(
            @{
                name        = "Name"
                param       = "Name"
                type        = "string"
                required    = $true
                description = "The name of the distribution to enter."
                inline      = $false
            },
            @{
                name        = "User"
                param       = "User"
                type        = "string"
                required    = $false
                description = "The user to log in as (e.g., 'root'). Defaults to the distro's default user."
                inline      = $false
            }
        )
        examples    = @(
            "Enter-PwslDistro -Name 'Ubuntu'",
            "Enter-PwslDistro -Name 'Debian' -User 'root'"
        )
    }
)