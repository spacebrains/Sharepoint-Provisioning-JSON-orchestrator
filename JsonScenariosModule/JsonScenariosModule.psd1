@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'JsonScenariosModule.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0'

    # ID used to uniquely identify this module
    GUID              = 'ac037cb4-5d8d-4f83-a66f-7c1844caa654'

    # Author of this module
    Author            = 'Siarhei Yezhgunovich'

    # Company or vendor of this module
    CompanyName       = 'WM Reply'

    # Copyright statement for this module
    Copyright         = '(c) Siarhei Yezhgunovich. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Module for processing JSON scenarios with SharePoint.'

    # Functions to export from this module
    FunctionsToExport = @('RunJsonScenariosOrchestrator')

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport   = '*'

    # List of all modules packaged with this module
    NestedModules     = @()

    # List of all files packaged with this module
    FileList          = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @('SharePoint', 'JSON', 'Scenario')

            # A URL to the license for this module.
            LicenseUri = 'URL-TO-YOUR-LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'URL-TO-YOUR-PROJECT'

            # A URL to an icon representing this module.
            IconUri    = 'URL-TO-YOUR-ICON'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

} # End of manifest hashtable
