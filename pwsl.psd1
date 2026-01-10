@{
    RootModule         = 'pwsl.psm1'
    ModuleVersion      = '0.2.5'
    GUID               = '019b7754-6848-7a25-a4b3-2d847a419841'
    Author             = 'Garvey k. Snow'
    CompanyName        = 'Phellams'
    Copyright          = '(c) 2026 Garvey k. Snow. All rights reserved.'
    Description        = 'A wrapper for `wsl.exe`. It parses WSL output into standard PowerShell objects, provides safety checks for destructive operations, and automates the migration of distributions between drives.'
    FunctionsToExport  = @(
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
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData = @{
            Tags                     = @('PSModule','wsl', 'linux', 'distro', 'virtualization', 'windows', 'subsystem', 'subsystem for linux', 'wsl2')
            ReleaseNotes             = @{ 
                # '1.2.1' = 'Initial release with New-PHWriter cmdlet for custom help formatting and enhanced layout.'
            }
            RequireLicenseAcceptance = $false
            LicenseUri               = 'https://choosealicense.com/licenses/mit'
            ProjectUri               = 'https://gitlab.com/phellams/pwsl.git'
            IconUri                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/pwsl/dist/png/pwsl-logo-128x128.png'
            # CHOCOLATE ---------------------
            ChocoDescription         = 'A wrapper for `wsl.exe`. It parses WSL output into standard PowerShell objects, provides safety checks for destructive operations, and automates the migration of distributions between drives.'
            LicenseUrl               = 'https://choosealicense.com/licenses/mit'
            ProjectUrl               = 'https://github.com/phellams/pwsl'
            IconUrl                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/pwsl/pwsl-logo-128x128.png'
            Docsurl                  = 'https://pages.gitlab.io/sgkens/ptoml'
            MailingListUrl           = 'https://github.com/phellams/pwsl/issues'
            projectSourceUrl         = 'https://github.com/phellams/pwsl'
            bugTrackerUrl            = 'https://github.com/phellams/pwsl/issues'
            Summary                  = 'A wrapper for `wsl.exe`. It parses WSL output into standard PowerShell objects, provides safety checks for destructive operations, and automates the migration of distributions between drives.'
            # CHOCOLATE ---------------------
            Prerelease               = ''

        }        
    }
    RequiredModules    = @()
    RequiredAssemblies = @()
    FormatsToProcess   = @()
    TypesToProcess     = @()
    NestedModules      = @()
    ScriptsToProcess   = @()
}
