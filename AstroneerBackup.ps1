#Astroneer Backup
#Made by Xech

#MAKE MANUAL BACKUPS PRIOR TO USE
#ONLY TESTED WITH STEAM VERSION
#PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED

#Check here for non-standard Steam libraries.
	#$((Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam -Name InstallPath).InstallPath + "\steamapps\libraryfolders.vdf")

#Use this for selecting backup folder

#Astroneer Backup Version
$bVersion = "1.4"

#Stop on error.
$ErrorActionPreference = "Stop"

#Wait to receive any key from user.
Function Get-Prompt {
	cmd /c pause | Out-Null
	#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

#Write the specified count of blank lines.
Function Write-Blank($Count) {
	For ($i=0; $i -lt $Count; $i++) {
		Write-Host ""
	}
}

#Self-elevate the script, if required.
# If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
# 	If ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
# 	 $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
# 	 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
# 	 Exit
# 	}
# }

#Advise if elevation is needed.
$cPrinc = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
If (!$cPrinc.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Clear-Host
	Write-Host -F RED "Administrator privileges are REQUIRED."
	Write-Blank(1)
	Write-Host -F RED "Right-click the executable and choose `"Run as administrator`"."
	Get-Prompt
	Exit
}

#Declare variables.

#Disabled path declarations.
#$myPath = (Get-Item $MyInvocation.MyCommand.Path).DirectoryName

#Declare savegame locations.
$bSourceSteam = "$env:LOCALAPPDATA\Astro\Saved\SaveGames\"
If (Test-Path ((Get-ChildItem $env:LOCALAPPDATA\Packages\SystemEraSoftworks*\SystemAppData\wgs\ -Recurse -Filter container.*).FullName | Where-Object { Format-Hex $_ | Select-String S.A.V.E. } | Split-Path)) {
	$bSourceUWP = (Get-ChildItem $env:LOCALAPPDATA\Packages\SystemEraSoftworks*\SystemAppData\wgs\ -Recurse -Filter container.*).FullName | Where-Object { Format-Hex $_ | Select-String S.A.V.E. } | Split-Path
}

#Declare default savegames backup location.
#$bDest = "$env:USERPROFILE\Saved Games\AstroneerBackup\"

#Declare backup script name, path, and full path.
$bScriptName = "AstroneerBackup.ps1"
$bConfig = "C:\ProgramData\AstroneerBackup\"
$bScript = $bConfig + $bScriptName

#Declare backup lifetime config path. 
$bLifetimeConfig = "$bConfig" + "bLifetime.cfg"
$bDestConfig = "$bConfig" + "bDest.cfg"

#Declare task audit export and task names, so backup only runs when the game runs.
$bTaskAudit = "$bConfig" + "secpol.cfg"
$bTaskNameSteam = "AstroneerBackupSteam"
$bTaskNameUWP = "AstroneerBackupUWP"

#Declare game location for task auditing.
Function Get-LaunchDirs {
	$sLaunched = $False
	#Check the default Steam library first.
	If ($(Test-Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam)) {
		$script:SteamPath = (Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam -Name InstallPath).InstallPath
	}
	If (Test-Path ("$SteamPath" + "\steamapps\common\ASTRONEER\Astro.exe")) {
		$script:gLaunchDirSteam = "$SteamPath" + "\steamapps\common\ASTRONEER\Astro.exe"
	}
	If (Test-Path ("$SteamPath" + "\steamapps\common\ASTRONEER Early Access\Astro.exe")) {
		$script:gLaunchDirSteam = "$SteamPath" + "\steamapps\common\ASTRONEER Early Access\Astro.exe"
	}
	If ([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue).Path) {
		$script:gLaunchDirSteam = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
	}
	#Check the Microsoft Store packages next.
	If (Test-Path $(Get-AppxPackage SystemEraSoftworks*).InstallLocation) {
		$script:gLaunchDirUWP = $(Get-AppxPackage SystemEraSoftworks*).InstallLocation + "\Astro\Binaries\UWP64\Astro-UWP64-Shipping.exe"
	}
	#If game process is not found, launch it to find it.
	If ($script:gInstalledSteam -And (![bool]$script:gLaunchDirSteam))  {
		Write-Host -F WHITE "Steam game not found in default location. Launching briefly to get path..."
		explorer.exe steam://run/361420
		$sLaunched = $True
		Do {
			#Wait for game to launch, trying to get path.
			For ($i=0; $i -le 10; $i++) {
				$script:gLaunchDirSteam = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
				Start-Sleep -Seconds 1
			}
		}
		Until ([bool]$gLaunchDirSteam)
	}
	If ($script:gInstalledUWP -And (![bool]$script:gLaunchDirUWP))  {
		Write-Host -F WHITE "Steam game not found in default location. Launching briefly to get path..."
		Start-Process ("Shell:AppsFolder\" + $(Get-AppxPackage SystemEraSoftworks*).PackageFamilyName + "!ASTRONEER")
		$sLaunched = $True
		Do {
			#Wait for game to launch, trying to get path.
			For ($i=0; $i -le 10; $i++) {
				$script:gLaunchDirUWP = (Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue).Path
				Start-Sleep -Seconds 1
			}
		}
		Until ([bool]$gLaunchDirSteam)
	}
	#If script launched the game, close it. Otherwise, leave your game running.
	If ($sLaunched -And ([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue) -Or [bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue))) {
		Stop-Process -Name Astro -ErrorAction SilentlyContinue
		Stop-Process -Name Astro-Win64-Shipping -ErrorAction SilentlyContinue
		Stop-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue
	}
}

# Declare game version.
Function Get-GameVersions {
	If ([bool]$gLaunchDirSteam) {
		If (Test-Path ((Split-Path $gLaunchDirSteam -ErrorAction SilentlyContinue) + "\build.version")) {
			$script:gVersionSteam = ((Get-Content ((Split-Path $gLaunchDirSteam) + "\build.version") -Delimiter " ")[0] -replace " ","")
		}
	}
	If ([bool]$(Get-AppxPackage SystemEraSoftworks*).Version) {
		$script:gVersionUWP = $(Get-AppxPackage SystemEraSoftworks*).Version
	}
}

#Declare variables that check for backup components.
Function Get-Done {
	If ($Null -ne $script:bSourceSteam) {
		$script:bSourceSteamExists = $(Test-Path $bSourceSteam)
		}
		Else {
			$script:bSourceSteamExists = $False
	}
	If ($Null -ne $script:bSourceUWP) {
		$script:bSourceUWPExists = $(Test-Path $bSourceUWP)
		}
		Else { 
			$script:bSourceUWPExists = $False
	}
	If ($Null -ne $script:bDest) {
		$script:bDestExists = $(Test-Path $bDest)
		}
		Else {
			$script:bDestExists = $False
	}
	If ($bDestExists) {
		$script:bCount = (Get-ChildItem $bDest -File -Recurse | Where-Object -Property FullName -match "^.*sav(egame)?$|^[A-Z0-9]{32}$").Count
		}
		Else {
		$script:bCount = 0
	}
	If ($Null -ne $bConfig) {
		$script:bConfigExists = $(Test-Path $bConfig)
		}
		Else {
			$script:bConfigExists = $False
	}
	If ($Null -ne $bScript) {
		$script:bScriptExists = $(Test-Path $bScript)
		}
		Else {
			$script:bScriptExists = $False
	}
	If ($Null -ne $bDestConfig) {
		$script:bDestConfigExists = $(Test-Path $bDestConfig)
		}
		Else {
			$script:bConfigExists = $False
	}
	If ($bDestConfigExists) {
		$script:bDest = (Get-Content $bDestConfig)
		}
		Else {
			$script:bDest = "$env:USERPROFILE\Saved Games\AstroneerBackup\"
	}
	If ($Null -ne $bLifetimeConfig) {
		$script:bLifetimeConfigExists = $(Test-Path $bLifetimeConfig)
	}
	If ($bLifetimeConfigExists) {
		[Int]$script:bLifetime = (Get-Content $bLifetimeConfig)
		}
		Else {
			[Int]$script:bLifetime = 14
	}
	Export-Task
	If ($Null -ne $bTaskAudit) {
		$script:bTaskAuditExists = $(Test-Path $bTaskAudit) -And $([bool](Select-String -Path "$bTaskAudit" -Pattern 'AuditProcessTracking = 1'))
	}
	$script:bTaskExists = $([bool](Get-ScheduledTask | Where-Object {($_.TaskName -Like $bTaskNameSteam) -Or ($_.TaskName -Like $bTaskNameUWP)}))
	$script:AllDone = $($bDestExists -And $bConfigExists -And $bScriptExists -And $bTaskAuditExists -And $bTaskExists)
	$script:AllUndone = $(!($bDestExists -Or $bConfigExists -Or $bScriptExists -Or $bTaskAuditExists -Or $bTaskExists))
}

#Declare backup destination.
Function Set-Destination {
	Get-Done
	If ($bDest -notmatch "^.*\\$") {
		$bDest = $bDest + "\"
	}
	If ($bDestConfigExists) {
		Clear-Content $bDestConfig
	}
	Add-Content $bDestConfig $bDest
	$script:bDest = (Get-Content $bDestConfig)
	If (!$bDestExists) {
		New-Item -ItemType Directory -Force -Path $bDest | Out-Null
	}
	Get-Done
}

#Declare backup lifetime config in days.
Function Set-Lifetime {
	Get-Done
		If ($bLifetimeConfigExists) {
			Clear-Content $bLifetimeConfig
		}
		Add-Content $bLifetimeConfig $bLifetime
		[Int]$script:bLifetime = (Get-Content $bLifetimeConfig)
}

#Export task audit policy for modification.
Function Export-Task {
	secedit /export /cfg "$bConfig\secpol.cfg" | Out-Null
}

#Highlight boolean results respectively.
Function Write-Highlight($Exists) {
	If ($Exists) {Write-Host -F GREEN "$Exists"} Else {Write-Host -F RED "$Exists"}
}

#Highlight boolean results respectively, on the same line.
Function Write-HighlightNNL($Exists) {
	If ($Exists) {Write-Host -F GREEN "$Exists" -N} Else {Write-Host -F RED "$Exists" -N}
}

#Assumes if Astroneer save folder exists, Astroneer is installed.
Function Get-GameInstalled {
	If ($bSourceSteamExists) {
		$script:gInstalledSteam = $True
	}
	If ($bSourceUWPExists) {
	$script:gInstalledUWP = $True
	}
	While (!($bSourceSteamExists) -And !($bSourceUWPExists)) {
		Clear-Host
		Write-Host -F RED "Astroneer savegame folder MISSING:" $bSource
		Write-Blank(1)
		Write-Host -F RED "Astroneer savegame folder MISSING:" $env:LOCALAPPDATA\Packages\SystemEraSoftworks*\SystemAppData\wgs\
		Write-Blank(1)
		Write-Host "INSTALL Astroneer from Steam or Microsoft Store and CREATE a savegame"
		Write-Blank(4)
		Do {
			Write-Host -N -F YELLOW "Would you like to CONTINUE anyway Y/(N)? "
			$Choice = Read-Host
			$Ok = $Choice -match '^[yn]+$|^$'
				If (-not $Ok) {
					Write-Blank(1)
					Write-Host -F RED "Invalid choice..."
					Write-Blank(1)
				}
			}
			Until ($Ok)
		Switch -Regex ($Choice) {
			"Y" {
				$script:gInstalled = $False
				Clear-Host
				Export-Task
				Get-Done
			}
			"N|^$" {
				Clear-Host
				Exit
			}
		}
	}
}
Function Get-GameVersions {
	If ([bool]$gLaunchDirSteam) {
		If (Test-Path ((Split-Path $gLaunchDirSteam -ErrorAction SilentlyContinue) + "\build.version")) {
			$script:gVersionSteam = ((Get-Content ((Split-Path $gLaunchDirSteam) + "\build.version") -Delimiter " ")[0] -replace " ","")
		}
	}
	If ([bool]$(Get-AppxPackage SystemEraSoftworks*).Version) {
		$script:gVersionUWP = $(Get-AppxPackage SystemEraSoftworks*).Version
	}
}

#Alt-tabs, since a PowerShell window can steal focus... https://github.com/Microsoft/console/issues/249
Function Get-AltTab {
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
	[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
}

#Disable old versions of Astroneer Backup
Function Get-UpgradeNeeded {
	Get-Done
	While ([bool]($bSciptExists) -And (!(Get-Content $bScript)[0].Contains($bVersion))) {
		Write-Host -N -F RED "WARNING - ASTRONEER BACKUP MISMATCH: "; Write-Host -F YELLOW "Latest: $bVersion"
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "You must first DISABLE this version (Y)/N? "
			$Choice = Read-Host
			$Ok = $Choice -match '^[yn]+$|^$'
			If (-not $Ok) {
				Write-Blank(1)
				Write-Host -F RED "Invalid choice..."
				Write-Blank(1)
			}
		}
		Until ($Ok)
		Switch -Regex ($Choice) {
			"Y|^$" {
				Disable-Backup
			}
			"N" {
				Clear-Host
				Exit
			}
		}
	}
}

#Main Menu
Function Write-MainMenu {
	While ($True) {
		Clear-Host
		Get-Done
		Write-Host -F GREEN "= = = = = = = = = = = = = = = = Astroneer Backup $bVersion = = = = = = = = = = = = = = = ="
		Write-Host -F WHITE "Backup ENABLED: " -N; Write-Highlight($AllDone)
		Write-Host -F WHITE "Steam Version: " -N; If ($gInstalledSteam) {Write-Host -F GREEN "$gVersionSteam"} Else {Write-Host -F RED "N/A"}
		Write-Host -F WHITE "Microsoft Store Version: " -N; If ($gInstalledUWP) {Write-Host -F GREEN "$gVersionUWP"} Else {Write-Host -F RED "N/A"}
		Write-Host -F WHITE "Backup CONFIGURATION: " -N; If ($bConfigExists) {Write-Host -F GREEN "$bConfig"} Else {Write-Host -F RED "$bConfig"}
		Write-Host -F WHITE "Backup DESTINATION: " -N; If ($bDestExists) {Write-Host -F GREEN "$bDest"} Else {Write-Host -F RED "$bDest"}
		Write-Host -F WHITE "Backup LIFETIME: " -N; If ($bLifetimeConfigExists) {Write-Host -F GREEN "$bLifetime" -N} Else {Write-Host -F RED "$bLifetime" -N}; Write-Host -F WHITE " Days"
		Write-Host -F WHITE "Backup COUNT: " -N; If ([bool]$bCount) {Write-Host -F GREEN $bCount} Else {Write-Host -F YELLOW $bCount}
		Write-Host -F YELLOW "Choose an option:"
		Write-Host -N -F YELLOW "ENABLE (1), DISABLE (2), BROWSE BACKUPS (3), README (4), CREDITS (5), EXIT (6): "
		Do {
			$Choice = Read-Host
			$Ok = $Choice -match '^[123456]$'
				If (-not $Ok) {
					Write-Blank(1)
					Write-Host -F RED "Invalid choice..."
					Write-Blank(1)
					Write-Host -F YELLOW "Choose an option:"
					Write-Host -N -F YELLOW "ENABLE (1), DISABLE (2), BROWSE BACKUPS (3), README (4), CREDITS (5), EXIT (6): "
				}
			}
		Until ($Ok)
		Clear-Host
		Switch -Regex ($Choice) {
			"1" {
				Get-Done
				If ($AllDone) {
					Clear-Host
					Write-Host "Nothing left to enable..."
					Write-Blank(8)
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Clear-Host
				}
				Else {
					Clear-Host
					Enable-Backup
				}
			}
			"2" {
				Get-Done
				If ($AllUndone) {
					Clear-Host
					Write-Host "Nothing left to disable..."
					Write-Blank(8)
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Clear-Host
				}
				If (!($AllUndone)) {
					Clear-Host
					Disable-Backup
				}
			}
			"3" {
				If ($bDestExists) {
					Invoke-Item $bDest -ErrorAction SilentlyContinue
				}
			}
			"4" {
				Write-Host -F GREEN "= = = = = = = = = = = = = = = = Astroneer Backup $bVersion = = = = = = = = = = = = = = = ="
				Write-Host -F YELLOW "(1/3) What does this do?"
				Write-Blank(1)
				Write-Host -F WHITE "This tool backs up Astroneer saves while Astroneer is running."
				Write-Host -F WHITE "When Astroneer closes, it stops watching for changes."
				Write-Host -F WHITE "You can choose how long you want backups to be kept."
				Write-Host -F WHITE "The Astroneer install is not changed in any way by this tool."
				Write-Host -F WHITE "When saves are backed up, they're copied here: " -N; Write-Host -F YELLOW "$bDest"
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-Host -F GREEN "= = = = = = = = = = = = = = = = Astroneer Backup $bVersion = = = = = = = = = = = = = = = ="
				Write-Host -F YELLOW "(2/3) How do I use it?"
				Write-Blank(1)
				Write-Host -F WHITE "To enable backup, type 1 and Enter at the Main Menu."
				Write-Host -F WHITE "To disable backup, type 2 and Enter at the Main Menu."
				Write-Host -F WHITE "To open the backup folder, type 3 and Enter at the Main Menu."
				Write-Host -F WHITE "Backups are kept for 14 days by default. 10 backups are always kept."
				Write-Host -F YELLOW "Backup will only work if this appears in the Main Menu: " -N; Write-Host -F WHITE "Backup ENABLED: " -N; Write-Host -F GREEN "True"
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-Host -F GREEN "= = = = = = = = = = = = = = = = Astroneer Backup $bVersion = = = = = = = = = = = = = = = ="
				Write-Host -F YELLOW "(3/3) How does it work?"
				Write-Blank(1)
				Write-Host -F WHITE "A backup folder and backup script are created."
				Write-Host -F WHITE "A scheduled task is created that invokes the script."
				Write-Host -F WHITE "The task is triggered when the Astro.exe is launched."
				Write-Host -F WHITE "The backup script copies .savegame files when changed."
				Write-Host -F WHITE "Backups older than the backup lifetime are deleted."
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
			}
			"5" {
				Clear-Host
				Write-Host -F GREEN "= = = = = = = = = = = = = = = = Astroneer Backup $bVersion = = = = = = = = = = = = = = = ="
				Write-Host -F GREEN "                                   Made by " -N; Write-Host -F RED "Xech"
				Write-Blank(1)
				Write-Host -F GREEN "                                Special thanks to:"
				Write-Host -F WHITE "  Yksi, Mitranium, mallaig, sinuhe, Afish, somejerk, System Era, and Paul Pepera " -N; Write-Host -F MAGENTA "<3"
				Write-Blank(1)
				Write-Host -F YELLOW "                          Contributors/Forks: " -N; Write-Host -F RED "None yet :)"
				Write-Blank(1)   
				Write-Host -F YELLOW "                                 "-N; Write-Zebra "HAIL LORD ZEBRA"
				Write-Blank(2)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
			}
			"6" {
				Clear-Host
				Exit
			}
		}
	}
}

#Write scheduled tasks to detect the game, call the backup script, and stop itself when the game exits.
Function Write-Task {
	If ($gInstalledSteam) {
		Get-LaunchDirs
		Get-GameVersions
		$Path = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
		$Arguments = '-WindowStyle Hidden -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "' + "$bConfig" + 'AstroneerBackup.ps1"'
		$Service = New-Object -ComObject ("Schedule.Service")
		$Service.Connect()
		$RootFolder = $Service.GetFolder("\")
		
		$TaskDefinition = $Service.NewTask(0) # TaskDefinition object https://msdn.microsoft.com/en-us/library/windows/desktop/aa382542(v=vs.85).aspx
		$TaskDefinition.Principal.RunLevel = 1
		$TaskDefinition.RegistrationInfo.Description = "$bTaskNameSteam"
		$TaskDefinition.Settings.Enabled = $True
		$TaskDefinition.Settings.AllowDemandStart = $True
		$TaskDefinition.Settings.DisallowStartIfOnBatteries = $False
		$TaskDefinition.Settings.StopIfGoingOnBatteries = $False
		$TaskDefinition.Settings.RunOnlyIfIdle = $False
		$TaskDefinition.Settings.IdleSettings.StopOnIdleEnd = $False
		
		$Triggers = $TaskDefinition.Triggers
		$Trigger = $Triggers.Create(0) # 0 is an event trigger https://msdn.microsoft.com/en-us/library/windows/desktop/aa383898(v=vs.85).aspx
		$Trigger.Enabled = $True
		$Trigger.Id = '4688' # 4688 is for process create and 4689 is for process exit
		$Trigger.Subscription = "<QueryList><Query Id=`"0`" Path=`"Security`"><Select Path=`"Security`"> *[System[Provider[@Name=`'Microsoft-Windows-Security-Auditing`'] and Task = 13312 and (EventID=4688)]] and *[EventData[Data[@Name=`'NewProcessName`'] and (Data=`'" + "$gLaunchDirSteam" + "`')]]</Select></Query></QueryList>"
		
		$Action = $TaskDefinition.Actions.Create(0)
		$Action.Path = $Path
		$Action.Arguments = $Arguments
		
		#Needs password? https://powershell.org/forums/topic/securing-password-for-use-with-registertaskdefinition/
		$RootFolder.RegisterTaskDefinition($bTaskNameSteam, $TaskDefinition, 6, $env:USERNAME, $null, 3) | Out-Null
	}
	If ($gInstalledUWP) {
		Get-LaunchDirs
		Get-GameVersions
		$Path = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
		$Arguments = '-WindowStyle Hidden -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "' + "$bConfig" + 'AstroneerBackup.ps1"'
		$Service = New-Object -ComObject ("Schedule.Service")
		$Service.Connect()
		$RootFolder = $Service.GetFolder("\")
		
		$TaskDefinition = $Service.NewTask(0) # TaskDefinition object https://msdn.microsoft.com/en-us/library/windows/desktop/aa382542(v=vs.85).aspx
		$TaskDefinition.Principal.RunLevel = 1
		$TaskDefinition.RegistrationInfo.Description = "$bTaskNameUWP"
		$TaskDefinition.Settings.Enabled = $True
		$TaskDefinition.Settings.AllowDemandStart = $True
		$TaskDefinition.Settings.DisallowStartIfOnBatteries = $False
		$TaskDefinition.Settings.StopIfGoingOnBatteries = $False
		$TaskDefinition.Settings.RunOnlyIfIdle = $False
		$TaskDefinition.Settings.IdleSettings.StopOnIdleEnd = $False
		
		$Triggers = $TaskDefinition.Triggers
		$Trigger = $Triggers.Create(0) # 0 is an event trigger https://msdn.microsoft.com/en-us/library/windows/desktop/aa383898(v=vs.85).aspx
		$Trigger.Enabled = $True
		$Trigger.Id = '4688' # 4688 is for process create and 4689 is for process exit
		$Trigger.Subscription = "<QueryList><Query Id=`"0`" Path=`"Security`"><Select Path=`"Security`"> *[System[Provider[@Name=`'Microsoft-Windows-Security-Auditing`'] and Task = 13312 and (EventID=4688)]] and *[EventData[Data[@Name=`'NewProcessName`'] and (Data=`'" + "$gLaunchDirUWP" + "`')]]</Select></Query></QueryList>"
		
		$Action = $TaskDefinition.Actions.Create(0)
		$Action.Path = $Path
		$Action.Arguments = $Arguments
		
		#Needs password? https://powershell.org/forums/topic/securing-password-for-use-with-registertaskdefinition/
		$RootFolder.RegisterTaskDefinition($bTaskNameUWP, $TaskDefinition, 6, $env:USERNAME, $null, 3) | Out-Null
	}
}

#Check for critical backup components, installing anything missing.
Function Enable-Backup {

	#Set config folder.
	Get-Done
	While (!($bConfigExists)) {
		Write-Host -F YELLOW "CREATING Astroneer backup config folder..."
		New-Item -ItemType Directory -Force -Path $bConfig | Out-Null
		Get-Done
		If ($Null -ne $bConfig) {
			$bConfigExists = $(Test-Path $bConfig)
		}
		Get-Done
		If ($bConfigExists) {
			Write-Host -F GREEN "CREATED Astroneer backup config folder:" $bConfig
		}
		Else {
			Write-Host -F RED "ERROR creating Astroneer backup config folder:" $bConfig
		}
		Write-Blank(1)
		Write-Host -N -F YELLOW "Press any key to CONTINUE..."
		Get-Prompt
		Get-Done
	}

	#Set backup folder.
	Get-Done
	While (!($bDestConfigExists) -Or !($bDestExists)) {
		Clear-Host
		Write-Host -F WHITE "Astroneer backup DESTINATION: " -N; Write-Host -F YELLOW "$bDest"
		Do {
			Write-Host -N -F YELLOW "Would you like to CHANGE it Y/(N)? "
			$Choice = Read-Host
			$Ok = $Choice -match '^[yn]+$|^$'
			If (-not $Ok) {
				Write-Blank(1)
				Write-Host -F RED "Invalid choice..."
				Write-Blank(1)
			}
		}
		Until ($Ok)
		Switch -Regex ($Choice) {
			"Y" {
				Write-Blank(1)
				Do {
					Write-Host -F WHITE "TYPE or PASTE the Astroneer backup destination ($bdest): " -N
					$Choice = Read-Host
					$Ok = $Choice -match '^([A-Za-z]\:\\.+)$|^$'
					If (-not $Ok) {
						Write-Blank(1)
						Write-Host -F RED "Invalid choice..."
						Write-Blank(1)
					}
				}
				Until ($Ok)
				Switch -Regex ($Choice) {
					"^([A-Za-z]\:\\.+)$" {
						$bDest = $Choice
						Set-Destination
						Get-Done
						If ($bDestExists) {
							Write-Host -F GREEN "CREATED Astroneer backup destination:" $bDest
							}
							Else {
								Write-Host -F RED "ERROR creating Astroneer backup destination:" $bDest
						}
						Write-Blank(1)
						Write-Host -N -F YELLOW "Press any key to CONTINUE..."
						Get-Prompt
					}
					"^$" {
						Set-Destination
						Get-Done
						Write-Blank(1)
						If ($bDestExists) {
							Write-Host -F GREEN "CREATED DEFAULT Astroneer backup destination:" $bDest
							}
							Else {
								Write-Host -F RED "ERROR creating Astroneer backup destination:" $bDest
						}
						Write-Blank(1)
						Write-Host -N -F YELLOW "Press any key to CONTINUE..."
						Get-Prompt
						Get-Done
						Clear-Host
					}
				}
			}
			"N|^$" {
				Set-Destination
				Get-Done
				Write-Blank(1)
				If ($bDestExists) {
					Write-Host -F GREEN "CREATED DEFAULT Astroneer backup destination: " $bDest
					}
					Else {
						Write-Host -F RED "ERROR creating Astroneer backup destination: " $bDest
				}
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
			}
		}
	}

	#Set backup lifetime.
	Get-Done
	While (!($bLifetimeConfigExists)) {
		Clear-Host
		Write-Host -F WHITE "Astroneer backup LIFETIME: " -N; Write-Host -F YELLOW "$bLifetime" -N; Write-Host -F WHITE " Days"
		Do {
			Write-Host -N -F YELLOW "Would you like to CHANGE it Y/(N)? "
			$Choice = Read-Host
			$Ok = $Choice -match '^[yn]+$|^$'
			If (-not $Ok) {
				Write-Blank(1)
				Write-Host -F RED "Invalid choice..."
			}
		}
		Until ($Ok)
		Switch -Regex ($Choice) {
			"Y" {
				Write-Blank(1)
				Do {
					Write-Host -F WHITE "ENTER the amount of days from 1 to 365 (default 14): " -N
					$Choice = Read-Host
					$Ok = $Choice -match "^([1-9]\d?|[12]\d\d|3[0-5]\d|36[0-5])$|^$"
					If (-not $Ok) {
						Write-Blank(1)
						Write-Host -F RED "Invalid choice..."
						Write-Blank(1)
					}
				}
				Until ($Ok)
				Switch -Regex ($Choice) {
					"([1-9]\d?|[12]\d\d|3[0-5]\d|36[0-5])" {
						$bLifetime = $Choice
						Set-Lifetime
						Get-Done
						If ($bLifetimeConfigExists) {
							Write-Host -F GREEN "CREATED Astroneer backup lifetime config of " -N; Write-Host -F YELLOW $bLifetime -N; Write-Host -F GREEN " Days:" $bLifetimeConfig
							}
							Else {
								Write-Host -F RED "ERROR creating Astroneer backup lifetime config:" $bLifetimeConfig
						}
						Write-Blank(1)
						Write-Host -N -F YELLOW "Press any key to CONTINUE..."
						Get-Prompt
						Clear-Host
					}
					"^$" {
						Set-Lifetime
						Get-Done
						Write-Blank(1)
						If ($bLifetimeConfigExists) {
							Write-Host -F GREEN "CREATED DEFAULT Astroneer backup lifetime config of " -N; Write-Host -F YELLOW $bLifetime -N; Write-Host -F GREEN " Days:" $bLifetimeConfig
							}
							Else {
								Write-Host -F RED "ERROR creating Astroneer backup lifetime config:" $bLifetimeConfig
						}
						Write-Blank(1)
						Write-Host -N -F YELLOW "Press any key to CONTINUE..."
						Get-Prompt
						Clear-Host
					}
				}
			}
			"N|^$" {
				Set-Lifetime
				Get-Done
				Write-Blank(1)
				If ($bLifetimeConfigExists) {
					Write-Host -F GREEN "CREATED DEFAULT Astroneer backup lifetime config of " -N; Write-Host -F YELLOW $bLifetime -N; Write-Host -F GREEN " Days:" $bLifetimeConfig
					}
					Else {
						Write-Host -F RED "ERROR creating Astroneer backup lifetime config:" $bLifetimeConfig
				}
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
			}
		}
	}

	#Check for exported security policy for task auditing.
	Get-Done
	While (!($bTaskAuditExists)) {
		Write-Host -F YELLOW "CREATING Astroneer backup task audit..."
		Export-Task
		(Get-Content $bTaskAudit).replace('AuditProcessTracking = 0','AuditProcessTracking = 1') | Out-File $bTaskAudit
		secedit /configure /db c:\windows\security\local.sdb /cfg $bTaskAudit /areas SECURITYPOLICY | Out-Null
		Export-Task
		$bTaskAuditExists = $(Test-Path($bTaskAudit)) -And $($null -ne (Select-String -Path "$bTaskAudit" -Pattern 'AuditProcessTracking = 1'))
		If ($bTaskAuditExists) {
			Write-Host -F GREEN "CREATED Astroneer backup task audit:" $bTaskAudit
			Write-Blank(1)
		}
		Else {
			Write-Host -F RED "ERROR creating Astroneer backup task audit:" $bTaskAudit
			Write-Blank(1)
		}
	}

	#Check for backup scripts.
	Get-Done
	If (!($bScriptExists)) {
		Write-Host -F YELLOW "CREATING Astroneer backup script..."

		#Declare backup script.
		$bScriptContent =

'#Astroneer Backup ' + $bVersion + '
#Task audit event 4688 for Astro.exe or Astro-UWP64-Shipping.exe invokes backup actions.

#Declare paths and backup lifetime.
$bSourceSteam = "$env:LOCALAPPDATA\Astro\Saved\SaveGames\"
Write-Host "bSourceSteam =" $bSourceSteam
If (Test-Path ((Get-ChildItem $env:LOCALAPPDATA\Packages\SystemEraSoftworks*\SystemAppData\wgs\ -Recurse -Filter container.*).FullName | Where-Object { Format-Hex $_ | Select-String S.A.V.E. } | Split-Path)) {
	$bSourceUWP = (Get-ChildItem $env:LOCALAPPDATA\Packages\SystemEraSoftworks*\SystemAppData\wgs\ -Recurse -Filter container.*).FullName | Where-Object { Format-Hex $_ | Select-String S.A.V.E. } | Split-Path
	Write-Host "bSourceUWP" = $bSourceUWP
}
$bConfig = "C:\ProgramData\AstroneerBackup\Config\"
Write-Host "bConfig =" $bConfig
$bDestConfig = "$bConfig" + "bDest.cfg"
Write-Host "bDestConfig =" $bDestConfig
$bLifetimeConfig = "$bConfig" + "bLifetime.cfg"
Write-Host "bLifetimeConfig =" $bLifetimeConfig
$bDest = (Get-Content $bDestConfig)
Write-Host "bDest =" $bDest
$bLifetime = (Get-Content $bLifetimeConfig)
Write-Host "bLifetime =" $bLifetime
$bFilter = "*.sav*"
Write-Host "bFilter =" $bFilter

#Declare game launch directory function for task auditing.
Function Get-LaunchDirs {
	$sLaunched = $False
	#Check the Steam library first.
	If ($(Test-Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam)) {
		$script:SteamPath = (Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam -Name InstallPath).InstallPath
		Write-Host "SteamPath =" $SteamPath
	}
	If (Test-Path ("$SteamPath" + "\steamapps\common\ASTRONEER\Astro.exe")) {
		$script:gLaunchDirSteam = "$SteamPath" + "\steamapps\common\ASTRONEER\Astro.exe"
		Write-Host "SteamPath =" $SteamPath
	}
	If (Test-Path ("$SteamPath" + "\steamapps\common\ASTRONEER Early Access\Astro.exe")) {
		$script:gLaunchDirSteam = "$SteamPath" + "\steamapps\common\ASTRONEER Early Access\Astro.exe"
		Write-Host "SteamPath =" $SteamPath
	}
	If ([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue).Path) {
		$script:gLaunchDirSteam = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
		Write-Host "gLaunchDirSteam =" $gLaunchDirSteam
	}
	#Check the Microsoft Store packages next.
	If (Test-Path $(Get-AppxPackage SystemEraSoftworks*).InstallLocation) {
		$script:gLaunchDirUWP = $(Get-AppxPackage SystemEraSoftworks*).InstallLocation + "\Astro\Binaries\UWP64\Astro-UWP64-Shipping.exe"
		Write-Host "gLaunchDirUWP =" $gLaunchDirUWP
	}
	#If game process is not found, launch it to find it.
	If ($script:gInstalledSteam -And (![bool]$script:gLaunchDirSteam))  {
		Write-Host -F WHITE "Steam game not found in default location. Launching briefly to get path..."
		explorer.exe steam://run/361420
		$sLaunched = $True
		Do {
			#Wait for game to launch, trying to get path.
			For ($i=0; $i -le 10; $i++) {
				$script:gLaunchDirSteam = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
				Start-Sleep -Seconds 1
			}
		}
		Until ([bool]$gLaunchDirSteam)
	}
	If ($script:gInstalledUWP -And (![bool]$script:gLaunchDirUWP))  {
		Write-Host -F WHITE "Steam game not found in default location. Launching briefly to get path..."
		Start-Process ("Shell:AppsFolder\" + $(Get-AppxPackage SystemEraSoftworks*).PackageFamilyName + "!ASTRONEER")
		$sLaunched = $True
		Do {
			#Wait for game to launch, trying to get path.
			For ($i=0; $i -le 10; $i++) {
				$script:gLaunchDirUWP = (Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue).Path
				Start-Sleep -Seconds 1
			}
		}
		Until ([bool]$gLaunchDirSteam)
	}
	#If script launched the game, close it. Otherwise, leave your game running.
	If ($sLaunched -And ([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue) -Or [bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue))) {
		Stop-Process -Name Astro -ErrorAction SilentlyContinue
		Stop-Process -Name Astro-Win64-Shipping -ErrorAction SilentlyContinue
		Stop-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue
	}
}

#Declare game version function.
Function Get-GameVersions {
	If ([bool]$gLaunchDirSteam) {
		If (Test-Path ((Split-Path $gLaunchDirSteam -ErrorAction SilentlyContinue) + "\build.version")) {
			$script:gVersionSteam = ((Get-Content ((Split-Path $gLaunchDirSteam) + "\build.version") -Delimiter " ")[0] -replace " ","")
			Write-Host "gVersionSteam =" $gVersionSteam
		}
	}
	If ([bool]$(Get-AppxPackage SystemEraSoftworks*).Version) {
		$script:gVersionUWP = $(Get-AppxPackage SystemEraSoftworks*).Version
		Write-Host "gVersionUWP =" $gVersionUWP
	}
}

#If non-versioned saves exist, assume they were backed up by a pre-1.3 version of Astroneer Backup for Astroneer 1.0.15.0
If ([bool](Get-ChildItem $bDest -File)) {
	If (!(Test-Path ($bDest + "1.0.15.0" + "\"))) {
		New-Item ($bDest + "1.0.15.0") -ItemType Directory
		Write-Host "Made 1.0.15.0 folder"
	}
	Get-ChildItem $bDest -File | Select-Object -ExpandProperty FullName | ForEach-Object {
	Move-Item $_ ($bDest + "1.0.15.0" + "\") -Force
	Write-Host "Copied a file to 1.0.15.0 folder"
	}
}

#Begin Steam watcher.
$sWatcherSteam = New-Object IO.FileSystemWatcher $bSourceSteam, $bFilter -Property @{ 
	EnableRaisingEvents = $true
	IncludeSubdirectories = $false
	NotifyFilter = [System.IO.NotifyFilters]::LastWrite
}
Write-Host "sWatcherSteam declared"

#Begin UWP watchers.
$sWatcherUWP = New-Object IO.FileSystemWatcher $bSourceUWP, * -Property @{ 
	EnableRaisingEvents = $true
	IncludeSubdirectories = $false
	NotifyFilter = [System.IO.NotifyFilters]::FileName,[System.IO.NotifyFilters]::LastWrite,[System.IO.NotifyFilters]::LastAccess,[System.IO.NotifyFilters]::CreationTime,[System.IO.NotifyFilters]::DirectoryName
}

#Declare event handler actions.
$bAction = {
	Get-LaunchDirs
	Get-GameVersions
	$cDate = Get-Date
	Write-Host "cDate =" $cDate
	$dDate = $cDate.AddDays(-$bLifetime)
	Write-Host "dDate =" $dDate
	$sGame = $Event.SourceEventArgs.Name
	Write-Host "sGame =" $sGame
	If ([bool](Get-Process Astro -ErrorAction SilentlyContinue)) {
		$bFull = $bDest + $gVersionSteam + "\" + $sGame
		Write-Host "bFull =" $bFull
	}
	If ([bool](Get-Process Astro-UWP64-Shipping -ErrorAction SilentlyContinue)) {
		$bFull = $bDest + $gVersionUWP + "\" + $sGame
		Write-Host "bFull =" $bFull
	}
	$bFullExists = $(Test-Path ($bFull))
	Write-Host "bFullExists =" $bFullExists
	#Check for version folder and write one if missing.
	If (([bool](Get-Process Astro -ErrorAction SilentlyContinue)) -And !(Test-Path ($bDest + $gVersionSteam + "\"))) {
		New-Item ($bDest + $gVersionSteam) -ItemType Directory
		Write-Host "Created =" $bDest + $gVersionSteam
	}
	If (([bool](Get-Process Astro-UWP64-Shipping -ErrorAction SilentlyContinue)) -And !(Test-Path ($bDest + $gVersionUWP + "\"))) {
		New-Item ($bDest + $gVersionUWP) -ItemType Directory
		Write-Host "Created =" $bDest + $gVersionUWP
	}
	#Check for backup file and write one if missing.
	If (!$bFullExists -And [bool](Get-Process -Name Astro -ErrorAction SilentlyContinue).Path) {
		Copy-Item "$bSourceSteam\$sGame" -Destination $bFull -Force
		Write-Host "Copied Steam save from" $bSourceSteam\$sGame
	}
	If (!$bFullExists -And [bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue).Path -And $sGame -notmatch "\.") {
		Copy-Item "$bSourceUWP\$sGame" -Destination $bFull -Force
		Write-Host "Copied UWP save from" $bSourceUWP\$sGame
	}
	#Keep 10 backups per game, per game version, within the backup lifetime.
	(Get-ChildItem $bDest -Recurse -File).Name -Replace ("\$.*","") | Select-Object -Unique | ForEach-Object {
		Get-ChildItem $bDest -Recurse -File | Where-Object { $_.LastWriteTime -lt $dDate } | Sort-Object LastWriteTime -Desc | Select-Object -Skip 10 | Remove-Item -Force
		Write-Host "Backups cleaned"
	}
}

#Register the event handler.
$Handler = . {
	Register-ObjectEvent -InputObject $sWatcherSteam -EventName Changed -SourceIdentifier AstroFSWChangeSteam -Action $bAction
	Register-ObjectEvent -InputObject $sWatcherUWP -EventName Changed -SourceIdentifier AstroFSWChangeUWPChanged -Action $bAction
	Register-ObjectEvent -InputObject $sWatcherUWP -EventName Created -SourceIdentifier AstroFSWChangeUWPCreated -Action $bAction
	Register-ObjectEvent -InputObject $sWatcherUWP -EventName Renamed -SourceIdentifier AstroFSWChangeUWPRenamed -Action $bAction
}
Write-Host "Handler =" $Handler

#Wait for the game to stop.
Try {
	([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue))
	([bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue))
	Do {
		Wait-Event -Timeout 1
	}
	Until (![bool](Get-Process -Name Astro -ErrorAction SilentlyContinue) -And ![bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue))
	Write-Host "Game has closed"
}

#Unregister and dispose of active handlers and jobs.
Finally
{
	Unregister-Event -SourceIdentifier AstroFSWChangeSteam
	Write-Host "Event AstroFSWChangeSteam unregistered"
	Unregister-Event -SourceIdentifier AstroFSWChangeUWPChanged
	Write-Host "Event AstroFSWChangeUWPChanged unregistered"
	Unregister-Event -SourceIdentifier AstroFSWChangeUWPCreated
	Write-Host "Event AstroFSWChangeUWPCreated unregistered"
	Unregister-Event -SourceIdentifier AstroFSWChangeUWPRenamed
	Write-Host "Event AstroFSWChangeUWPRenamed unregistered"
	$Handler | Remove-Job
	Write-Host "Jobs removed"
	$sWatcherSteam.EnableRaisingEvents = $false
	$sWatcherSteam.Dispose()
	Write-Host "sWatcherSteam disposed"
	$sWatcherUWP.EnableRaisingEvents = $false
	$sWatcherUWP.Dispose()
	Write-Host "sWatcherUWPChanged disposed"
}'

		#Set backup script.
		Add-Content $bScript $bScriptContent
		$bScriptExists = $(Test-Path $bScript)
		If ($bScriptExists) {
			Write-Host -F GREEN "CREATED Astroneer backup script:" $bScript
			Write-Blank(1)
		}
		Else {
			Write-Host -F RED "ERROR creating Astroneer backup script:" $bScript
			Write-Blank(1)
		}
	}

	#Check for scheduled tasks.
	Get-Done
	If (!($bTaskExists)) {
		Write-Host -F YELLOW "CREATING Astroneer backup scheduled tasks..."
		Write-Task
		Get-Done
		If ($bTaskExists) {
			Write-Host -F GREEN "CREATED Astroneer backup scheduled tasks:" $bTaskNameSteam $bTaskNameUWP
			If ([bool](Get-Process -Name Astro -ErrorAction SilentlyContinue)) {
				Start-ScheduledTask $bTaskNameSteam | Out-Null
				Get-AltTab
			}
			If ([bool](Get-Process -Name Astro-UWP64-Shipping -ErrorAction SilentlyContinue)) {
				Start-ScheduledTask $bTaskNameUWP | Out-Null
				Get-AltTab
			}
			Write-Blank(1)
		}
		Else {
			Write-Host -F RED "ERROR creating Astroneer backup scheduled tasks:" $bTaskNameSteam $bTaskNameUWP
			Write-Blank(1)
		}
		Write-Host -N -F YELLOW "Press any key to CONTINUE..."
		Get-Prompt
	}

	#Clean up non-versioned saves.
	Get-Done
	If ($bDestExists -And [bool](Get-ChildItem $bDest -File -Recurse | Where-Object -Property FullName -match "^.*sav(egame)?$|^[A-Z0-9]{32}$").FullName) {
		If (!(Test-Path ($bDest + "1.0.15.0" + "\"))) {
			New-Item ($bDest + "1.0.15.0") -ItemType Directory
		}
		(Get-ChildItem $bDest -File | Where-Object -Property FullName -match "^.*sav(egame)?$|^[A-Z0-9]{32}$").FullName | ForEach-Object {
			Move-Item ($bDest + "1.0.15.0" + "\") -Force
		}
	}
}

#Disable Astroneer backup. Avoid deleting backups.
Function Disable-Backup {
	Clear-Host
	Get-Done
	If ($bTaskExists) {
		Write-Host -F YELLOW "DELETING Astroneer backup scheduled tasks:" $bTaskNameSteam $bTaskNameUWP
		Unregister-ScheduledTask -TaskName "$bTaskNameSteam" -Confirm:$False | Out-Null
		Unregister-ScheduledTask -TaskName "$bTaskNameUWP" -Confirm:$False | Out-Null
		Get-Done
		If ($bTaskExists) {
			Write-Host -F RED "ERROR deleting Astroneer backup scheduled tasks:" $bTaskNameSteam $bTaskNameUWP
			}
			Else {
				Write-Host -F GREEN "DELETED Astroneer backup scheduled tasks:" $bTaskNameSteam $bTaskNameUWP
		}
		Write-Blank(1)
	}

	If ($bTaskAuditExists) {
		Write-Host -F YELLOW "DELETING Astroneer backup task audit:" $bTaskAudit
		Export-Task
		(Get-Content $bTaskAudit).replace('AuditProcessTracking = 1','AuditProcessTracking = 0') | Out-File $bTaskAudit
		secedit /configure /db c:\windows\security\local.sdb /cfg $bTaskAudit /areas SECURITYPOLICY | Out-Null
		Export-Task
		Get-Done
		If ($bTaskAuditExists) {
			Write-Host -F RED "ERROR deleting Astroneer backup task audit:" $bTaskAudit
			}
			Else {
				Write-Host -F GREEN "DELETED Astroneer backup task audit:" $bTaskAudit
		}
		Write-Blank(1)
	}

	If ($bScriptExists) {
		Write-Host -F YELLOW "DELETING Astroneer backup script:" $bScript
		Remove-Item $bScript -Force
		Get-Done
		If ($bScriptExists) {
			Write-Host -F RED "ERROR deleting Astroneer backup script:" $bScript
			}
			Else {
				Write-Host -F GREEN "DELETED Astroneer backup script:" $bScript
		}
		Write-Blank(1)
		Write-Host -N -F YELLOW "Press any key to CONTINUE..."
		Get-Prompt
	}

	If ($bDestExists) {
		Clear-Host
		Get-Done
		$bChecked = $False
		Write-Host -F YELLOW "CHECKING for Astroneer backups: $bDest"
		While ($bCount -gt 0 -And !$bChecked -And $bDestExists) {
			Do {
				Write-Blank(1)
				Write-Host -F RED "WARNING - ASTRONEER BACKUPS EXIST: $bDest"
				Write-Host -N -F RED "THIS CANNOT BE UNDONE: "; Write-Host -N -F YELLOW "Would you like to DELETE BACKUPS Y/(N)? "
				$Choice = Read-Host
				$Ok = $Choice -match '^[yn]+$|^$'
				If (-not $Ok) {
					Write-Blank(1)
					Write-Host -F RED "Invalid choice..."
					Write-Blank(1)
				}
			}
			Until ($Ok)
			Switch -Regex ($Choice) {
				"Y" {
					$bChecked = $True
					Get-Done
					(Get-ChildItem $bDest -File -Recurse | Where-Object -Property FullName -match "^.*sav(egame)?$|^[A-Z0-9]{32}$").FullName | Remove-Item -Force
					Get-Done
					Write-Blank(1)
					Write-Host -F RED "ASTRONEER BACKUPS DELETED:" $bDest
				}
				"N|^$" {
					$bChecked = $True
					Write-Blank(1)
					Write-Host -F GREEN "ASTRONEER BACKUPS PRESERVED:" $bDest
				}
			}
			Write-Blank(1)
			Write-Host -N -F YELLOW "Press any key to CONTINUE..."
			Get-Prompt
			Clear-Host
		}
		If ($bCount -eq 0) {
			Write-Host -F GREEN "NO backups found in backup destination:" $bDest
			Write-Blank(1)
			Write-Host -F YELLOW "DELETING backup destination:" $bDest
			If ((Get-ChildItem $bDest -File -Recurse).Count -eq 0) {
				Remove-Item -Path $bDest -Force -Recurse -Confirm:$False | Out-Null
				Get-Done
				Write-Host -F GREEN "DELETED backup destination:" $bDest
				}
				Else {
					$bForeign = $True
					Write-Host -F RED "ERROR deleting backup destination due to FOREIGN files:" (Get-ChildItem $bDest -File -Recurse).FullName | Select-Object -First 1
			}
			If ($bDestExists -And !$bForeign) {
				Write-Host -F RED "ERROR deleting backup destination:" $bDest
			}
			Get-Done
			Write-Blank(1)
			Write-Host -N -F YELLOW "Press any key to CONTINUE..."
			Get-Prompt
		}
	}

	If ($bConfigExists) {
		Clear-Host
		Write-Host -F YELLOW "DELETING Astroneer backup config:" $bConfig
		Remove-Item -Path $bConfig -Recurse -Force -Confirm:$False -ErrorAction SilentlyContinue | Out-Null
		Get-Done
		If ($bConfigExists) {
			Write-Host -F RED "ERROR deleting Astroneer backup config:" $bConfig
		}
		If (!($bConfigExists)) {
			Write-Host -F GREEN "DELETED Astroneer backup config:" $bConfig
		}
		Write-Blank(1)
		Write-Host -N -F YELLOW "Press any key to CONTINUE..."
		Get-Prompt
	}
}

#HAIL LORD ZEBRA!
Function Write-Zebra([char[]]$Text) {
    For ($i = 0; $i -lt $Text.Length; $i++) {
		If ($i % 2) {
			Write-Host $Text[$i] -F BLACK -B WHITE -N
		}
		Else {
			Write-Host $Text[$i] -B BLACK -F WHITE -N
		}
	}
}

#Begin the script.
Clear-Host
Export-Task
Get-Done
Get-GameInstalled
Get-LaunchDirs
Get-GameVersions
Get-UpgradeNeeded
Write-MainMenu
Set-BackupFolder