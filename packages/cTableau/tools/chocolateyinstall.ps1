$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName= 'cTableau' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://uneidelpwcstorage.blob.core.windows.net/packages/commonfiles_install_TableauDesktop-64bit-9-3-0.exe' # download url
$url64      = 'https://uneidelpwcstorage.blob.core.windows.net/packages/commonfiles_install_TableauDesktop-64bit-9-3-0.exe' # 64bit URL here or remove - if installer is both, use $url
$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE' #only one of these: exe, msi, msu
  url           = $url
  url64bit      = $url64
  #MSI
  silentArgs    = "/c" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)
  softwareName  = 'cTableau*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
}

Install-ChocolateyPackage @packageArgs
