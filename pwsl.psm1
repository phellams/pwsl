using module libs\phwriter\phwriter.psm1

# -----------------------------------------------------------------------------
# GLOBALS
# -----------------------------------------------------------------------------

$global:__pwsl = @{ rootpath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
# -----------------------------------------------------------------------------
# INTERNAL HELPER: ANSI Logging
# -----------------------------------------------------------------------------
$script:PwslSpinnerIdx = 0


$script:colorpallet = @{
    Reset  = "$([char]27)[0m"
    Red    = "$([char]27)[31m"
    Green  = "$([char]27)[32m"
    Yellow = "$([char]27)[33m"
    Cyan   = "$([char]27)[36m"
    Gray   = "$([char]27)[90m"
    underline = "$([char]27)[4m"
}

function New-Spinner {
    <#
    .SYNOPSIS
        Returns the next character in a spinner sequence.
        Maintains state automatically using a script-level variable.
    #>
    [CmdletBinding()]
    param(
        # The animation frames. Defaults to standard ASCII.
        [parameter(mandatory = $true)]
        [string[]]$Steps,
        [switch]$Reset
    )

    begin {
        if (!$steps) {
            $steps = @('-', '\', '|', '/')
        }
        if ($steps.count -lt 2) {
            return "String array <= 2 please expand the array length";
        }
        if ($reset) {
            $script:PwslSpinnerIdx = 0
            return
        }
    }

    process {

        # 1. Calculate current frame based on script-level index
        $currentIndex = $script:PwslSpinnerIdx % $Steps.Count
        $char = $Steps[$currentIndex]

        # 2. Increment global index for the next call
        $script:PwslSpinnerIdx++

        # 3. Return the raw string/char
        return $char
    }
}

function Write-PwslLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Error", "Warning")]
        [string]$Level = "Info"

    )

    # ANSI Escape Codes
    $Reset  = $script:colorpallet.Reset
    $Red    = $script:colorpallet.Red
    $Green  = $script:colorpallet.Green
    $Yellow = $script:colorpallet.Yellow
    $Cyan   = $script:colorpallet.Cyan
    $Gray   = $script:colorpallet.Gray

    $Timestamp = "$Gray[$(Get-Date -Format 'HH:mm:ss')]$Reset"
    
    switch ($Level) {
        "Info"    { [Console]::WriteLine("$Timestamp $Cyan[INFO]$Reset $Message") }
        "Success" { [Console]::WriteLine("$Timestamp $Green[OK]$Reset $Message") }
        "Warning" { [Console]::WriteLine("$Timestamp $Yellow[WARN]$Reset $Message") }
        "Error"   { [Console]::WriteLine("$Timestamp $Red[ERR]$Reset $Message") }
    }
}

function Enter-PwslDistro {
    <#
    .SYNOPSIS
        Enters the distro shell (Wrapper for wsl -d).
    .DESCRIPTION
        Enters the distro shell (Wrapper for wsl -d).
    .PARAMETER Name
        The name of the distro to enter.
    .PARAMETER User
        The user to enter the distro as.
    .PARAMETER help
        Show help
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, position=0, ParameterSetName='NormalOperation')]
        [string]$Name,

        [Parameter(Mandatory=$false, ParameterSetName='NormalOperation')]
        [string]$User,

        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help

    )
    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\enter-pwsldistro_phwriter_metadata.json"
        return;
    }

    if (-not [string]::IsNullOrWhiteSpace($User)) {
        wsl -d $Name -u $User
    } else {
        wsl -d $Name
    }
}
# -----------------------------------------------------------------------------

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


# -----------------------------------------------------------------------------
# CORE FUNCTIONS
# -----------------------------------------------------------------------------
function Get-PwslList {
    <#
    .SYNOPSIS
        Lists all installed distros using Regex parsing.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\get-pwsllist_phwriter_metadata.json"
        return;
    }

    Write-PwslLog "Fetching installed distribution list..." "Info"

    # 1. Force Console Encoding to Unicode (Fixes the "Chinese characters" or null byte issues)
    $origEnc = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $rawOutput = wsl --list --verbose
    [Console]::OutputEncoding = $origEnc

    $distros = @()

    foreach ($line in $rawOutput) {
        # 2. Skip Header or Empty lines immediately
        if ($line -match "NAME\s+STATE" -or [string]::IsNullOrWhiteSpace($line)) { continue }

        # 3. Strict Regex Pattern:
        # ^\s* = Start of line, ignore leading space
        # (\*?)     = Capture Group 1: Optional Asterisk (The Default Marker)
        # \s* = Ignore space
        # (\S+)     = Capture Group 2: Name (Non-whitespace characters)
        # \s+       = Ignore space
        # (\S+)     = Capture Group 3: State (Running/Stopped)
        # \s+       = Ignore space
        # (\d+)     = Capture Group 4: Version (1 or 2)
        if ($line -match "^\s*(\*?)\s*(\S+)\s+(\S+)\s+(\d+)\s*$") {
            $distros += [PSCustomObject]@{
                Name      = $matches[2]
                State     = $matches[3]
                Version   = $matches[4]
                IsDefault = ($matches[1] -eq "*")
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
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\get-pwslrunning_phwriter_metadata.json"
        return;
    }

    $all = Get-PwslList
    return $all | Where-Object { $_.State -eq 'Running' }
}

function Get-PwslAvailable {
    <#
    .SYNOPSIS
        Lists distros available for download online.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\get-pwslavailable_phwriter_metadata.json"
        return;
    }


    Write-PwslLog "Fetching online distribution list..." "Info"
    wsl --list --online
}

function Install-PwslDistro {
    <#
    .SYNOPSIS
        Installs a specific distribution.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,

        [parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=1)]
        [string]$DefaultUser,

        [parameter(Mandatory = $false, ParameterSetName = 'NormalOperation', Position=2)]
        [string]$InstallLocation,

        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )
    # scope script colors
    $green = $script:colorpallet.green
    $cyan = $script:colorpallet.cyan
    $gray = $script:colorpallet.gray
    $reset = $script:colorpallet.reset
    # --
    
    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\install-pwsldistro_phwriter_metadata.json"
        return;
    }

    if(!$InstallLocation){
        Write-PwslLog "Preparing to install $green$Name$reset..." "Info"
        do {
            Write-PwslLog "$(New-Spinner -steps '.  ', '.. ', '...', ' ..', '  .') Installing $green$Name$reset..."
        } while (ping -n 10 google.com.au) #(wsl --install -d $Name --no-launch)
        
        Write-PwslLog "Installation complete!" "Success"
        
    }else{
        Write-PwslLog "Installing $green$Name$reset to $cyan$InstallLocation$reset with user $cyan$DefaultUser$reset" "Info"
        Write-PwslLog "Note: $gray`Wsl doest support custom install location$reset" "warning"
        write-PwslLog "Note: $gray`Move-Pwsldistro will be called to perform move steps and will take addtional time$reset" "warning"
        write-PwslLog "Note: $gray`Default user must be the same as the one you specify during intereactive installation$reset" "warning"

        $Q_continue = Read-Host "Are you sure you want to continue with this operation? (y/n)"
        if($Q_continue -ne "y"){
            write-PwslLog "Canceling opersion." "info"
            return
        }else{
            write-PwslLog "Installing $Name to $InstallLocation with user $defaultUser"
            wsl --install --distribution $Name
            if($LASTEXITCODE -eq 0){
                write-PwslLog "Installation complete!" "Success"
            }else{
                write-PwslLog "Installation failed!" "Error"
                return
            }
            Move-PwslDistro -Name $Name -NewLocation $InstallLocation -DefaultUser $DefaultUser -SetAsDefault:$false 
        }
    }

}

function Stop-PwslDistro {
    <#
    .SYNOPSIS
        Terminates a running distribution.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation')]
        [string]$Name,
        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\stop-pwsldistro_phwriter_metadata.json"
        return;
    }

    Write-PwslLog "Terminating $Name..." "Info"
    wsl --terminate $Name
    if ($LASTEXITCODE -eq 0) {
        Write-PwslLog "${cyan}$Name$reset terminated." "Success"
    } else {
        Write-PwslLog "Failed to terminate ${cyan}$Name`.$reset" "Error"
    }
}

function Export-PwslDistro {
    <#
    .SYNOPSIS
        Exports a distro to a .tar file.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=1)]
        [string]$Path,

        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\export-pwsldistro_phwriter_metadata.json"
        return;
    }

    if (-not (Test-Path $Path) -and -not (Test-Path (Split-Path $Path))) {
        Write-PwslLog "Destination directory does not exist." "Error"
        return
    }

    Write-PwslLog "Exporting ${cyan}$Name$reset to ${cyan}$Path$reset (This may take time)..." "Info"
    wsl --export $Name "$Path"
    
    if ($LASTEXITCODE -eq 0) {
        Write-PwslLog "☑️ Export complete." "Success"
    } else {
        Write-PwslLog "❌ Export failed." "Error"
    }
}

function Unregister-PwslDistro {
    <#
    .SYNOPSIS
        Unregisters (Deletes) a distribution and its disk image.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$false, ParameterSetName='NormalOperation')]
        [switch]$Force,
        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\unregister-pwsldistro_phwriter_metadata.json"
        return;
    }

    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to DELETE $Name and all its data? (y/n)"
        if ($confirm -ne 'y') { return }
    }

    Write-PwslLog "Unregistering $Name..." "Warning"
    wsl --unregister $Name
    Write-PwslLog "☑️ ${cyan}$Name$reset unregistered." "Success"
}

function Import-PwslDistro {
    <#
    .SYNOPSIS
        Imports a .tar file as a new distribution.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=1)]
        [string]$InstallLocation,

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=2)]
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
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=1)]
        [string]$InstallLocation,

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=2)]
        [string]$SourceTar,

        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )
    
    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\register-pwsldistro_phwriter_metadata.json"
        return;
    }

    Import-PwslDistro -Name $Name -InstallLocation $InstallLocation -SourceTar $SourceTar
}

function Move-PwslDistro {
    <#
    .SYNOPSIS
        Moves a WSL distro safely and restores the default user.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NormalOperation')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=0)]
        [string]$Name,

        [parameter(mandatory = $true, ParameterSetName = 'NormalOperation', Position = 1)]
        [string]$DefaultUser, # NEW: Allow user to specify username

        [Parameter(Mandatory=$true, ParameterSetName='NormalOperation', Position=2)]
        [string]$NewLocation,

        [Parameter(Mandatory=$false, ParameterSetName='NormalOperation', Position=3)]
        [string]$TempLocation,

        [Parameter(Mandatory=$false, ParameterSetName='NormalOperation', Position=4)]
        [switch]$SetAsDefault,

        [Parameter(Mandatory=$false, ParameterSetName='ShowHelp')]
        [switch]$help
    )

    # help context switch
    if ($PSCmdlet.ParameterSetName -eq 'ShowHelp') {
        New-PHWriter -JsonFile "$($global:__pwsl.rootpath)\libs\help_metadata\move-pwsldistro_phwriter_metadata.json"
        return;
    }

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

    if (!$TempLocation) {
        Write-PwslLog "Using default temp path: ${cyan}$env:TEMP$reset"
        $tempFile = Join-Path $env:TEMP "$Name-backup.tar"
    }else{
        Write-PwslLog "Using temp path: ${cyan}$TempLocation$reset"
        if(!(Test-Path $TempLocation)){
            Write-PwslLog "Creating temp path: ${cyan}$TempLocation$reset" "info"
            $null = New-Item -ItemType Directory -Force -Path $TempLocation
        }
       $tempFile = Join-Path $TempLocation "$Name-backup.tar"
    }

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

# =========================================|
# EXPORT MODULE MEMBERS ===================|
# =========================================|
$module_config = @{
    function = @(
        'Get-PwslList',
        'Get-PwslRunning',
        'Get-PwslAvailable',
        'Install-PwslDistro',
        'Move-PwslDistro',
        'Export-PwslDistro',
        'Import-PwslDistro',
        'Register-PwslDistro',
        'Unregister-PwslDistro',
        'Stop-PwslDistro',
        'Enter-PwslDistro'
    )
    alias = @()
}

# Exporting Functions
Export-ModuleMember @module_config