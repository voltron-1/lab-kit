@{
    RootModule        = 'AdminTools.psm1'
    ModuleVersion     = '1.2.0'
    GUID              = 'a1b2c3d4-1111-2222-3333-444455556666'
    Author            = 'IT Ops'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-DiskReport','Restart-AppPool')
    CmdletsToExport   = @()
    RequiredModules   = @('ActiveDirectory')
}
