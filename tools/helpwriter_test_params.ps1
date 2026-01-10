import-module .\

$params = @{
    name        = 'modulename'
    version     = '1.0.0'
    indent      = 1
    padding     = 2
    commandinfo = @{
        cmdlet      = "New-PHWriter";
        synopsis    = "New-PHWriter [-HelpTable <Hashtable[]>] [-Padding <Int>] [-Indent <Int>]";
        description = "This cmdlet generates formatted help text for PowerShell cmdlets with custom layouts and coloring, mimicking the style of the 'help' command. It supports custom layouts, coloring, and inline/newline descriptions. "; 
        source      = "https://gitlab.com/phellams/phwriter/blob/main/README.md"        
    }
    paramtable  = @(
        @{
            Name        = "SourcePath"
            Param       = "s|Source"
            Type        = "string"
            required    = $true
            Description = "Specifies the source path for the operation. Wildcards are supported."
            Inline      = $false # Description on a new line
        },
        @{
            Name = "DestinationPath"
            Param = "d|Destination"
            Type = "string"
            required = $true
            Description = "Specifies the destination path where files will be copied."
            Inline = $false  # Description on the same line
        },
        @{
            Name        = "Recurse"
            Param       = "r|Recurse"
            Type        = "switch"
            required    = $false
            Description = "Indicates that the operation should process subdirectories recursively."
            Inline      = $false
        },
        @{
            Name        = "Confirmation"
            Param       = "c|Confirm"
            Type        = "switch"
            required    = $false
            Description = "Prompts you for confirmation before running the cmdlet. (CommonParameter)"
            Inline      = $false
        } 
    )
    examples = @(
        "New-PHWriter -SourcePath 'C:\Source' -DestinationPath 'C:\Destination' -Recurse",
        "New-PHWriter -SourcePath 'C:\Source\*' -DestinationPath 'C:\Destination' -Confirm",
        "New-PHWriter -SourcePath 'C:\Source' -DestinationPath 'C:\Destination' -Recurse -Confirm",
        "New-PHWriter -SourcePath 'C:\Source\*' -DestinationPath 'C:\Destination' -Recurse -Confirm"
    )
}

New-PHWriter @params

#New-PHWriter -help