function MapDrive(){
    param(
      $storageKey,
      $storageName, 
      $shareName,
      $driveLetter
    )
    $unc = "\\$storageName.file.core.windows.net\$shareName"
    $secureString = ConvertTo-SecureString $storageKey -AsPlainText -Force
    $credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $storageName,$secureString
    if ($driveLetter.Contains(":"))
    {
        $driveLetter = $driveLetter.Substring(0,1).ToUpper();
    }
    Write-Verbose "unc: $unc, DriveLetter: $driveLetter;StorageName: $storageName"
    #New-PSDrive -Name $driveLetter -PSProvider FileSystem -root $unc -Credential $credentials -Persist
}
function MapDriveNetUse(){
    param(
      $storageKey,
      $storageName, 
      $shareName,
      $driveLetter
    )
    $unc = "\\$storageName.file.core.windows.net\$shareName"
    $networkObject = New-Object -ComObject WScript.Network
    $networkObject.MapNetworkDrive($driveLetter,$unc,$true,$storageName,$storageKey)
}

function Get-TargetResource
{
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $shareName,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageName,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageKey,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter
    )

    Write-Verbose "Start Get-TargetResource"
     #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        ShareName = $shareName
        StorageName = $storageName
        StorageKey = $storageKey
		DriveLetter = $DriveLetter
    }
    
    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $shareName,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageName,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageKey,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter

    )
    Write-Verbose "Start Set-TargetResource"
	MapDriveNetUse -storageKey $storageKey -storageName $storageName -shareName $shareName -driveLetter $DriveLetter
    
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $shareName,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageName,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $storageKey,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter
    )
    #
    
    Return $false;
}








function DoesCommandExist
{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try 
    {
        if(Get-Command $command)
        {
            return $true
        }
    }
    Catch 
    {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
} 


##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Object]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor

    )

    #Override default Write-Host...
    Write-Verbose $Object
}

Export-ModuleMember -Function *-TargetResource