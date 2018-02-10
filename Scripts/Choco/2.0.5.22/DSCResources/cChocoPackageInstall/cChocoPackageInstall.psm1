function Get-TargetResource
{
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Username,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Password
    )

    Write-Verbose "Start Get-TargetResource"

    CheckChocoInstalled

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
        Params = $Params
        Version = $Version
		Source = $Source
        UserName = $Username
        Password = $Password
    }
    Write-Output $configuration;
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
        $Name,   
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,   
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Username,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Password

    )
    Write-Verbose "Start Set-TargetResource"
	
    CheckChocoInstalled

    InstallPackage -pName $Name -pParams $Params -pSource $Source -pVersion $Version -pUserName $Username -pPassword $Password 
    
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
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Username,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Password
    )

    Write-Verbose "Start Test-TargetResource"

    CheckChocoInstalled

	if	( `
			(-not $Version) -and -not (IsPackageInstalled $Name) `
			-or `
			($Version) -and -not (IsPackageInstalled -pName $Name -pVersion $Version) `
	)
    {
        Return $false
    }

    Return $true
}


function CheckChocoInstalled
{
    if (-not (DoesCommandExist choco))
    {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }
}

function InstallPackage
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName,
            [Parameter(Position=1,Mandatory=0)][string]$pParams,
            [Parameter(Position=2,Mandatory=0)][string]$pVersion,
            [Parameter(Position=3,Mandatory=0)][string]$pSource,
            [Parameter(Position=4,Mandatory=0)][string]$pUserName,
            [Parameter(Position=5,Mandatory=0)][string]$pPassword

    ) 

    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    
    #Todo: Refactor
    if ((-not ($pParams)) -and (-not $pVersion) -and (-not $pSource))
    {
        Write-Verbose "Installing Package Standard"
        $packageInstallOuput = choco install $pName -y
    }
    elseif ($pParams -and $pVersion)
    {
        Write-Verbose "Installing Package with Params $pParams and Version $pVersion"
        $packageInstallOuput = choco install $pName --params="$pParams" --version=$pVersion -y        
    }
    elseif ($pUserName -and $pPassword -and $pSource){
        Write-output "Installing Package with with UserName $pUsername and Password $password"
        $packageInstallOuput = choco install $pName -s $pSource -u $pUserName -password $pPassword -y     
    }
    elseif ($pUserName -and $pPassword -and $pVersion -and $pSource)
    {
        $packageInstallOuput = choco install $pName -s $pSource -u $pUserName -password $pPassword --version=$pVersion -y  
    }
    elseif ($pParams)
    {
        Write-Verbose "Installing Package with params $pParams"
        $packageInstallOuput = choco install $pName --params="$pParams" -y            
    }
    elseif ($pVersion)
    {
        Write-Verbose "Installing Package with version $pVersion"
        $packageInstallOuput = choco install $pName --version=$pVersion -y        
    }
    
    
    Write-Verbose "Package output $packageInstallOuput "

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}


function IsPackageInstalled
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName,
            [Parameter(Position=1,Mandatory=0)][string]$pVersion
        ) 
    Write-Verbose "Start IsPackageInstalled $pName"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

	if ($pVersion) {
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) -and $_.ToLower().Contains($pVersion.ToLower()) }
	} else {
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) }
	}
	
    if ($installedPackages.Count -gt 0)
    {
        return $true
    }

    return $false
    
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