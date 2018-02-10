#
# HelixDSC.ps1
#
Configuration Helix
{   

	param ($MachineName,$pfUserName,$pfPassword,$storageAccountName,$storageAccountKey)
    Import-DSCResource -Module xSystemSecurity
   Import-DSCResource -ModuleName pwcchoco
   Import-DSCResource -ModuleName xAzureFileStorage
   
   Node $MachineName
   {   
	    xIEEsc DisableIEEsc
        {
            IsEnabled = $false
            UserRole = "Administrators"
        }
		Registry  DisableServerManager {
			Ensure = "Present"
			Key="HKEY_LOCAL_MACHINE\Software\Microsoft\ServerManager"
			ValueName="DoNotOpenServerManagerAtLogon"
			ValueData="1"
			ValueType="Dword"
		}
		File CreateFile {
            DestinationPath = 'C:\Temp\Test.txt'
            Ensure = "Present"
            Contents = 'Let Me Create Some Content'
        }
		xUAC NeverNotifyAndDisableAll 
        { 
            Setting = "NeverNotifyAndDisableAll" 
        } 
	    xAzureStorageInstaller CreateShare
		{
            shareName="TeamShare"
			storageName=$storageAccountName
	        storageKey=$storageAccountKey
	        
		}
		XDriveMapper MapDrive
		{
			shareName="TeamShare"
			storageName=$storageAccountName
	        storageKey=$storageAccountKey
	        DriveLetter="z:"
			DependsOn = "[xAzureStorageInstaller]CreateShare"
		}
		cChocoInstaller installChoco
		{
			InstallDir = "c:\choco"
		}
	    cChocoPackageInstaller installFireFox
		{
			Name = "firefox"
			DependsOn = "[cChocoInstaller]installChoco"
		}
		cChocoPackageInstaller installHelixDesktop
		{
			Name="helixdesktop"
			Username=$pfUserName
			Password=$pfPassword
			Source="https://uneidel.pkgs.visualstudio.com/DefaultCollection/_packaging/pwc/nuget/v2"
			DependsOn = "[cChocoInstaller]installChoco"
		}
		
    }

}

