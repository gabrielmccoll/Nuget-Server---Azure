Function Register-PSRepositoryFix {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,

        [Parameter(Mandatory=$true)]
        [Uri]
        $SourceLocation,

        [ValidateSet('Trusted', 'Untrusted')]
        $InstallationPolicy = 'Trusted'
    )

    $ErrorActionPreference = 'Stop'

    Try {
        Write-Verbose 'Trying to register via ​Register-PSRepository'
        ​Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy
        Write-Verbose 'Registered via Register-PSRepository'
    } Catch {
        Write-Verbose 'Register-PSRepository failed, registering via workaround'

        # Adding PSRepository directly to file
        Register-PSRepository -name $Name -SourceLocation $env:TEMP -InstallationPolicy $InstallationPolicy
        $PSRepositoriesXmlPath = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\PSRepositories.xml"
        $repos = Import-Clixml -Path $PSRepositoriesXmlPath
        $repos[$Name].SourceLocation = $SourceLocation.AbsoluteUri
        $repos[$Name].PublishLocation = $SourceLocation.AbsoluteUri
        $repos[$Name].ScriptSourceLocation = $SourceLocation.AbsoluteUri
        $repos[$Name].ScriptPublishLocation = $SourceLocation.AbsoluteUri
        $repos | Export-Clixml -Path $PSRepositoriesXmlPath

        # Reloading PSRepository list
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        Write-Verbose 'Registered via workaround'
    }
}