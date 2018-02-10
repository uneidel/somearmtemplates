function GenerateHeader()
{
param (
 $accountName,
 $accountKey,
 $shareName,
 $url,
 $method

)
    $resourceTz = [System.TimeZoneInfo]::FindSystemTimeZoneById(([System.TimeZoneInfo]::Local).Id)
    [string]$xmsDate = Get-Date ([System.TimeZoneInfo]::ConvertTimeToUtc((Get-Date).ToString(),$resourceTz)) -Format r
    $uri = New-Object System.Uri -ArgumentList $url
    $x_ms_date_h="x-ms-date:$xmsdate"
    $x_ms_version_h="x-ms-version:2015-02-21"
    $canonicalized_headers="$x_ms_date_h`n$x_ms_version_h`n"
    $canonicalized_resource ="/" + $accountName + $uri.AbsolutePath
    $string_to_sign = "$method$([char]10)$([char]10)$([char]10)$([char]10)$canonicalized_headers$canonicalized_resource";
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Convert]::FromBase64String($accountKey)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($string_to_sign.ToString()))
    $signature = [Convert]::ToBase64String($signature)
    $headers = @{}
    $headers.Add("x-ms-date", $xmsdate);
    $headers.Add("x-ms-version", "2015-02-21");
    $headers.Add("Authorization", "SharedKeyLite $accountName`:$signature")
    return $headers
}
function GetShareProperties(){
   param(
      $storageName, 
      $storageKey,
      $shareName
   )
   $bret = $false;
   $url = "https://$storageName.file.core.windows.net/$shareName" + "?restype=share";
   $headers = GenerateHeader -accountName $storageName -accountKey $storageKey -shareName $shareName -url $url -method "GET"
   try
   {
   Invoke-RestMethod -Uri $url -Method GET -Headers $headers 
   $bret=$true;
   }
   catch{
    
   }
   $bret;
}

function CreateShare(){
   param(
    $storageName, 
    $storageKey,
    $shareName
   ) 

   $url = "https://$storageName.file.core.windows.net/$shareName" + "?restype=share";
   Write-Verbose $url
   $headers = GenerateHeader -accountName $storageName -accountKey $storageKey -shareName $shareName -url $url -method "PUT"
   Invoke-RestMethod -Uri $url -Method Put -Headers $headers 
  
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
    $storageName = $storageName.ToLower();
    Write-Verbose "StorageName: $storageName"
    Write-Verbose "ShareName: $shareName"
	CreateShare -storageName $storageName -storageKey $storageKey -shareName $shareName
    
    
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
    
    Write-Verbose "Start Test-TargetResource"
    $storageName = $storageName.ToLower();
    Write-Verbose "StorageKey: $storageKey"
    [System.Boolean]$bret = $false;
    $bret= GetShareProperties -storageName $storageName -storageKey $storageKey -ShareName $shareName
    Write-Verbose "Result: $bret"
    return $bret;
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