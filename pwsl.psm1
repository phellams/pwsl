<#
.SYNOPSIS
    PWSL - A PowerShell wrapper for managing WSL distributions.
.DESCRIPTION
    Provides a PowerShell-native experience for listing, installing, moving, 
    and managing WSL distributions using standard WSL.exe commands.
#>

# -----------------------------------------------------------------------------
# INTERNAL HELPER: ANSI Logging
# -----------------------------------------------------------------------------
function Write-PwslLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Error", "Warning")]
        [string]$Level = "Info"
    )

    # ANSI Escape Codes
    $ESC = [char]27
    $Reset  = "$ESC[0m"
    $Red    = "$ESC[31m"
    $Green  = "$ESC[32m"
    $Yellow = "$ESC[33m"
    $Cyan   = "$ESC[36m"
    $Gray   = "$ESC[90m"

    $Timestamp = "$Gray[$(Get-Date -Format 'HH:mm:ss')]$Reset"
    
    switch ($Level) {
        "Info"    { [Console]::WriteLine("$Timestamp ${Cyan}[INFO]$Reset $Message") }
        "Success" { [Console]::WriteLine("$Timestamp ${Green}[OK]$Reset   $Message") }
        "Warning" { [Console]::WriteLine("$Timestamp ${Yellow}[WARN]$Reset $Message") }
        "Error"   { [Console]::WriteLine("$Timestamp ${Red}[ERR]$Reset  $Message") }
    }
}

function Enter-PwslDistro {
    <#
    .SYNOPSIS
        Enters the distro shell (Wrapper for wsl -d).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [string]$User
    )

    if (-not [string]::IsNullOrWhiteSpace($User)) {
        wsl -d $Name -u $User
    } else {
        wsl -d $Name
    }
}

# -----------------------------------------------------------------------------
# ARGUMENT COMPLETION
# -----------------------------------------------------------------------------
$distroCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $distros = Get-PwslList
    return $distros.Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName "Stop-PwslDistro", "Export-PwslDistro", "Unregister-PwslDistro", "Move-PwslDistro" -ParameterName "Name" -ScriptBlock $distroCompleter

# -----------------------------------------------------------------------------
# CORE FUNCTIONS
# -----------------------------------------------------------------------------

function Get-PwslList {
    <#
    .SYNOPSIS
        Lists all installed distros with their state and version.
    #>
    [CmdletBinding()]
    param()

    # wsl -l -v outputs UTF-16, we fix encoding for parsing
    $consoleEnc = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    $rawOutput = wsl --list --verbose
    [Console]::OutputEncoding = $consoleEnc

    $distros = @()
    
    # parsing logic: skip header, split by whitespace
    $rawOutput | Select-Object -Skip 1 | ForEach-Object {
        $line = $_.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            # Handle the asterisk for default distro
            $isDefault = $line -match "^\*"
            $cleanLine = $line -replace "^\*\s*", ""
            
            # Split by multiple spaces
            $parts = $cleanLine -split '\s+'
            
            if ($parts.Count -ge 3) {
                $distros += [PSCustomObject]@{
                    Name      = $parts[0]
                    State     = $parts[1]
                    Version   = $parts[2]
                    IsDefault = $isDefault
                }
            }
        }
    }
    return $distros
}

function Get-PwslRunning {
    <#
    .SYNOPSIS
        Lists only the currently running distributions.
    #>
    [CmdletBinding()]
    param()

    $all = Get-PwslList
    return $all | Where-Object { $_.State -eq 'Running' }
}

function Get-PwslAvailable {
    <#
    .SYNOPSIS
        Lists distros available for download online.
    #>
    [CmdletBinding()]
    param()

    Write-PwslLog "Fetching online distribution list..." "Info"
    wsl --list --online
}

function Install-PwslDistro {
    <#
    .SYNOPSIS
        Installs a specific distribution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-PwslLog "Installing $Name..." "Info"
    wsl --install -d $Name
}

function Stop-PwslDistro {
    <#
    .SYNOPSIS
        Terminates a running distribution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-PwslLog "Terminating $Name..." "Info"
    wsl --terminate $Name
    if ($LASTEXITCODE -eq 0) {
        Write-PwslLog "$Name terminated." "Success"
    } else {
        Write-PwslLog "Failed to terminate $Name." "Error"
    }
}

function Export-PwslDistro {
    <#
    .SYNOPSIS
        Exports a distro to a .tar file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-not (Test-Path $Path) -and -not (Test-Path (Split-Path $Path))) {
        Write-PwslLog "Destination directory does not exist." "Error"
        return
    }

    Write-PwslLog "Exporting $Name to $Path (This may take time)..." "Info"
    wsl --export $Name "$Path"
    
    if ($LASTEXITCODE -eq 0) {
        Write-PwslLog "Export complete." "Success"
    } else {
        Write-PwslLog "Export failed." "Error"
    }
}

function Unregister-PwslDistro {
    <#
    .SYNOPSIS
        Unregisters (Deletes) a distribution and its disk image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [switch]$Force
    )

    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to DELETE $Name and all its data? (y/n)"
        if ($confirm -ne 'y') { return }
    }

    Write-PwslLog "Unregistering $Name..." "Warning"
    wsl --unregister $Name
    Write-PwslLog "$Name unregistered." "Success"
}

function Import-PwslDistro {
    <#
    .SYNOPSIS
        Imports a .tar file as a new distribution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$InstallLocation,

        [Parameter(Mandatory=$true)]
        [string]$SourceTar
    )

    if (-not (Test-Path $SourceTar)) {
        Write-PwslLog "Source file not found: $SourceTar" "Error"
        return
    }

    # Ensure install directory exists
    if (-not (Test-Path $InstallLocation)) {
        Write-PwslLog "Creating directory: $InstallLocation" "Info"
        New-Item -ItemType Directory -Force -Path $InstallLocation | Out-Null
    }

    Write-PwslLog "Importing $Name from $SourceTar to $InstallLocation..." "Info"
    wsl --import $Name "$InstallLocation" "$SourceTar"

    if ($LASTEXITCODE -eq 0) {
        Write-PwslLog "Import successful." "Success"
    } else {
        Write-PwslLog "Import failed." "Error"
    }
}

function Register-PwslDistro {
    <#
    .SYNOPSIS
        Alias for Import-PwslDistro.
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$InstallLocation,
        [string]$SourceTar
    )
    Import-PwslDistro -Name $Name -InstallLocation $InstallLocation -SourceTar $SourceTar
}

function Move-PwslDistro {
    <#
    .SYNOPSIS
        Moves a WSL distro safely and restores the default user.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$NewLocation,
        
        [string]$DefaultUser, # NEW: Allow user to specify username

        [switch]$SetAsDefault
    )

    # 1. Validation
    $installed = Get-PwslList
    if ($Name -notin $installed.Name) {
        Write-PwslLog "Distro '$Name' not found." "Error"
        return
    }

    # If user didn't provide a username, try to guess it from the current running process or ask
    if ([string]::IsNullOrWhiteSpace($DefaultUser)) {
        Write-PwslLog "Note: Moving a distro resets the user to root." "Warning"
        $DefaultUser = Read-Host "Enter the default username for this distro (leave blank to default to root)"
    }

    $tempFile = Join-Path $env:TEMP "$Name-backup.tar"

    # 2. Stop
    Stop-PwslDistro -Name $Name
    Start-Sleep -Seconds 2 # Give file handles a moment to release

    # 3. Export
    Write-PwslLog "Step 1/4: Backing up distro to temp storage..." "Info"
    Export-PwslDistro -Name $Name -Path $tempFile
    
    # SAFETY CHECK: Ensure file exists AND has data (>1KB)
    if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -lt 1024) {
        Write-PwslLog "Backup failed or file is empty. Aborting move to prevent data loss." "Error"
        if (Test-Path $tempFile) { Remove-Item $tempFile }
        return
    }

    # 4. Unregister
    Write-PwslLog "Step 2/4: Removing old instance..." "Warning"
    wsl --unregister $Name

    # 5. Import
    Write-PwslLog "Step 3/4: Restoring to new location ($NewLocation)..." "Info"
    Import-PwslDistro -Name $Name -InstallLocation $NewLocation -SourceTar $tempFile

    # 6. Restore User (The Logic Fix)
    if (-not [string]::IsNullOrWhiteSpace($DefaultUser)) {
        Write-PwslLog "Step 4/4: Setting default user to '$DefaultUser'..." "Info"
        try {
            # Write wsl.conf inside the distro to set the user
            wsl -d $Name -u root sh -c "echo '[user]`ndefault=$DefaultUser' > /etc/wsl.conf"
            Write-PwslLog "User permissions restored." "Success"
        } catch {
            Write-PwslLog "Could not set default user automatically. You may log in as root." "Warning"
        }
    }

    # 7. Cleanup
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }

    # 8. Set Default
    if ($SetAsDefault) {
        wsl --set-default $Name
        Write-PwslLog "$Name is now the default distro." "Success"
    }

    Write-PwslLog "Move complete!" "Success"
}

# Exporting Functions
Export-ModuleMember -Function Get-PwslList, Get-PwslRunning, Get-PwslAvailable, Install-PwslDistro, Move-PwslDistro, Export-PwslDistro, Import-PwslDistro, Register-PwslDistro, Unregister-PwslDistro, Stop-PwslDistro