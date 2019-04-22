#Astroneer Savegame Backup Installer
#Made by Xech on 04/2019
#Version 1.1
#Written for Astroneer 1.0.15.0 on 04/2019

#MAKE MANUAL BACKUPS PRIOR TO USE
#ONLY COMPATIBLE WITH STEAM VERSION
#PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED

#1.1 To-Do:
#X Replace "install" and "uninstall" with "enable" and "disable"
#X Remove Intro
#X Title the MainMenu
#X Add Readme and Credit pages to MainMenu
#X Check common install location before launching game to gather path
#X Copy instead of zip
#X Add configurable backup timeframe
#X Package .ps1 as .exe

#1.2 To-Do:
#Declare script authoring as functions
#Remove most or all sleeps
#Auto update

#Stop on error.
$ErrorActionPreference = "Stop"

# Self-elevate the script, if required.
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	If ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
	 $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
	 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
	 Exit
	}
}

#Declare variables.

#Disabled path declarations.
#$myPath = (Get-Item $MyInvocation.MyCommand.Path).DirectoryName

#Declare savegames location.
$bSource = "$env:LOCALAPPDATA\Astro\Saved\SaveGames\"

#Declare savegames backup location.
$bDest = "$env:LOCALAPPDATA\AstroneerBackup\"

#Declare backup scripts, paths, and combinations.
$bScriptNameStart = "AstroneerBackupSteamStart.ps1"
$bScriptNameStop = "AstroneerBackupSteamStop.ps1"
$bScriptNames = "$bScriptNameStart" + ", " + "$bScriptNameStop"
$bScriptDest = $bDest + "Config\"
$bScriptStart = $bScriptDest + $bScriptNameStart
$bScriptStop = $bScriptDest + $bScriptNameStop

#Declare backup lifetime config path. 
$bLifetimeConfig = "$bScriptDest" + "bLifetime.cfg"

#Declare task audit export, task names, and combinations.
#These prevent scripts from running unless the game is also running. You're welcome.
$bTaskAudit = "$env:TEMP\secpol.cfg"
$bTaskNameStart = "AstroneerBackupTaskStart"
$bTaskNameStop = "AstroneerBackupTaskStop"
$bTaskNames = "$bTaskNameStart" + ", " + "$bTaskNameStop"

#Define functions.

#Declare game location for task auditing.
Function Get-LaunchDir {
	$sLaunched = $False
	#Check the Steam library first.
	$SteamPath = (Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Valve\Steam -Name InstallPath).InstallPath
	If (Test-Path "$SteamPath\steamapps\common\Astroneer Early Access\Astro.exe") {
		$script:gLaunchDir = "$SteamPath\steamapps\common\Astroneer Early Access\Astro.exe"
	}
	Else {
	$script:gLaunchDir = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
	}
	#If game process isn't found, launch it to find it.
	If (![bool]$gLaunchDir) {
		explorer.exe steam://run/361420
		$sLaunched = $True
		Do {
			#Wait for game to launch, trying to get path.
			$script:gLaunchDir = (Get-Process -Name Astro -ErrorAction SilentlyContinue).Path
			Start-Sleep -Seconds 1
		}
		Until ([bool]$gLaunchDir)
	}
	#If script launched the game, close it. Otherwise, leave your game running.
	If ($sLaunched -And [bool](Get-Process -Name Astro -ErrorAction SilentlyContinue)){
		Stop-Process -Name Astro -ErrorAction SilentlyContinue
		Stop-Process -Name Astro-Win64-Shipping -ErrorAction SilentlyContinue
	}
}

#Declare variables that check for backup components.
Function Get-Done {
	$script:bSourceExists = $(Test-Path $bSource)
	$script:bDestExists = $(Test-Path $bDest)
	$script:bScriptDestExists = $(Test-Path $bScriptDest)
	$script:bScriptStartExists = $(Test-Path $bScriptStart)
	$script:bScriptStopExists = $(Test-Path $bScriptStop)
	$script:bScriptsExist = $($bScriptStartExists -And $bScriptStopExists)
	$script:bLifetimeConfigExists = $(Test-Path $bLifetimeConfig)
	$script:bTaskAuditExists = $(Test-Path($bTaskAudit)) -And $($null -ne (Select-String -Path "$bTaskAudit" -Pattern 'AuditProcessTracking = 1'))
	$script:bTaskStartExists = $($null -ne (Get-ScheduledTask | Where-Object {$_.TaskName -like $bTaskNameStart})) 
	$script:bTaskStopExists = $($null -ne (Get-ScheduledTask | Where-Object {$_.TaskName -like $bTaskNameStop})) 
	$script:bTasksExist = $($bTaskStartExists -And $bTaskStopExists)
	$script:AllDone = $($bDestExists -And $bScriptDestExists -And $bScriptsExist -And $bTaskAuditExists -And $bTasksExist)
	$script:AllUndone = $(!($bDestExists -Or $bScriptDestExists -Or $bScriptsExist -Or $bTaskAuditExists -Or $bTasksExist))
}

#Count the backups.
Function Get-BackupCount {
	If ($bDestExists) {
		$script:bCount = (Get-ChildItem $bDest -Filter *.savegame).Count
	}
	Else {
		$script:bCount = 0
	}
}

#Set backup lifetime config. Units are in days.
Function Set-Lifetime {
	Get-Done
		If ($bLifetimeConfigExists) {
			Clear-Content $bLifetimeConfig
		}
		Add-Content $bLifetimeConfig $bLifetime
		[Int]$script:bLifetime = (Get-Content $bLifetimeConfig)
}

#Get backup lifetime from config, or set default if missing. Units are in days.
Function Get-Lifetime {
	If ($bLifetimeConfigExists) {
		[Int]$script:bLifetime = (Get-Content $bLifetimeConfig)
	}
	Else {
		[Int]$script:bLifetime = 30
	}
}

#Export task audit policy for modification.
Function Export-Task {
	secedit /export /cfg "$env:TEMP\secpol.cfg" | Out-Null
}

#Write the specified count of blank lines.
Function Write-Blank($Count) {
	For ($i=0; $i -lt $Count; $i++) {
		Write-Host ""
	}
}

#Highlight boolean results respectively.
Function Write-Highlight($Exists) {
	If ($Exists) {Write-Host -F GREEN "$Exists"} Else {Write-Host -F RED "$Exists"}
}

#Highlight boolean results respectively, on the same line.
Function Write-HighlightNNL($Exists) {
	If ($Exists) {Write-Host -F GREEN "$Exists" -N} Else {Write-Host -F RED "$Exists" -N}
}

#Wait to receive any key from user.
Function Get-Prompt {
	cmd /c pause | Out-Null
	#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

#Assuming if Astroneer folder exists, Astroneer is installed.
Function Get-GameInstalled {
	While (!($bSourceExists)) {
		Clear-Host
		Write-Host -F RED "Astroneer savegame folder MISSING:" $bSource
		Write-Blank(1)
		Write-Host "INSTALL Astroneer from Steam and CREATE a savegame"
		Write-Blank(6)
		Do {
			Write-Host -N -F YELLOW "Would you like to CONTINUE Y/(N)?"
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
				Clear-Host
				Export-Task
				Get-Lifetime
				Get-BackupCount
				Get-Done
				Write-MainMenu
			}
			"N|^$" {
				Clear-Host
				Exit
			}
		}
	}
}

#Alt-tabs, since a PowerShell window flickers even when hidden... https://github.com/Microsoft/console/issues/249
#Function Get-AltTab {
#	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
#	[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
#}

#MainMenu
Function Write-MainMenu {
	Clear-Host
	Write-Host -F GREEN "= = = = = = = = = = = = = = Astroneer Backup Script = = = = = = = = = = = = = ="
	Write-Host -F GREEN "                                  Version 1.1"
	Write-Blank(1)
	Write-Host -F WHITE "Backup LOCATION: " -N; Write-Host -F YELLOW "$bDest"
	Write-Host -F WHITE "Backup LIFETIME: " -N; Write-Host -F YELLOW "$bLifetime" -N; Write-Host -F WHITE " Days"
	Write-Host -F WHITE "Backup ENABLED: " -N; Write-Highlight($AllDone)
	Write-Host -F WHITE "Backup COUNT: " -N; If ([bool]$bCount) {Write-Host -F GREEN $bCount} Else {Write-Host -F RED $bCount}
	Write-Blank(1)
	While ($True) {
		Do {
			Write-Host -F YELLOW "Choose an option:"
			Write-Host -N -F YELLOW "ENABLE (1), DISABLE (2), BROWSE BACKUPS (3), README (4), CREDITS (5), EXIT (6):"
			$Choice = Read-Host
			$Ok = $Choice -match '^[123456]$'
				If (-not $Ok) {
					Write-Blank(1)
					Write-Host -F RED "Invalid choice..."
					Write-Blank(1)
				}
			}
		Until ($Ok)
		Clear-Host
		Switch -Regex ($Choice) {
			"1" {
				Clear-Host
				If ($AllDone) {
					Write-Host "Nothing left to enable..."
					Write-Blank(8)
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Clear-Host
					Write-MainMenu
				}
				If (!($AllDone)) {
					Clear-Host
					Enable
				}
			}
			"2" {
				If ($AllUndone) {
					Clear-Host
					Write-Host "Nothing left to disable..."
					Write-Blank(8)
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Clear-Host
					Write-MainMenu
				}
				If (!($AllUndone)) {
					Clear-Host
					Disable
				}
			}
			"3" {
				If ($bDestExists) {
					Invoke-Item $bDest -ErrorAction SilentlyContinue
					Write-MainMenu
				}
			}
			"4" {
				Write-Host -F GREEN "Written for Astroneer 1.0.15.0 on Steam"
				Write-Host -F GREEN "Authored April 2019"
				Write-Blank(1)
				Write-Host -F WHITE "This script creates two backup scripts."
				Write-Host -F WHITE "Each script corresponds to a scheduled task."
				Write-Host -F WHITE "Tasks are triggered only when the game is running."
				Write-Host -F WHITE "Backups are triggered by auditing save change events."
				Write-Host -F WHITE "Backups are deleted when older than the backup lifetime."
				Write-Blank(1)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
			"5" {
				Clear-Host
				Write-Host -F GREEN "= = = = = = = = = = = = = = Astroneer Backup Script = = = = = = = = = = = = = ="
				Write-Host -F GREEN "                                Made by " -N; Write-Host -F RED "Xech"
				Write-Blank(1)
				Write-Host -F GREEN "                             Special thanks to:"
				Write-Host -F WHITE "    Yksi, Afish, somejerk, sinuhe, Mitranium, System Era, and Paul Pepera " -N; Write-Host -F MAGENTA "<3"
				Write-Blank(1)
				Write-Host -F YELLOW "                      Contributors/Forks: " -N; Write-Host -F RED "None yet :)"
				Write-Blank(1)   
				Write-Host -F YELLOW "                              "-N; Write-Zebra "HAIL LORD ZEBRA"
				Write-Blank(2)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
			"6" {
				Exit
				Clear-Host
				}
		}
	}
}

#Write scheduled tasks to detect the game, call the backup script, and stop itself when the game exits.
Function Write-TaskStart {
	Get-LaunchDir
	#Start task
	$Path = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
	$Arguments = 'powershell.exe -WindowStyle Hidden -NoExit -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command ". ' + "$bScriptDest" + 'AstroneerBackupSteamStart.ps1"'
	$Service = New-Object -ComObject ("Schedule.Service")
	$Service.Connect()
	$RootFolder = $Service.GetFolder("\")
	$TaskDefinition = $Service.NewTask(0) # TaskDefinition object https://msdn.microsoft.com/en-us/library/windows/desktop/aa382542(v=vs.85).aspx
	$TaskDefinition.Principal.RunLevel = 1
	$TaskDefinition.RegistrationInfo.Description = "$bTaskNameStart"
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
	$Trigger.Subscription = "<QueryList><Query Id=`"0`" Path=`"Security`"><Select Path=`"Security`"> *[System[Provider[@Name=`'Microsoft-Windows-Security-Auditing`'] and Task = 13312 and (EventID=4688)]] and *[EventData[Data[@Name=`'NewProcessName`'] and (Data=`'" + "$gLaunchDir" + "`')]]</Select></Query></QueryList>"
	$Action = $TaskDefinition.Actions.Create(0)
	$Action.Path = $Path
	$Action.Arguments = $Arguments
	#Get-SID
	$RootFolder.RegisterTaskDefinition($bTaskNameStart, $TaskDefinition, 6, "$env:USERNAME", $null, 3) | Out-Null
}

Function Write-TaskStop {
	#Stop task
	$Path = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
	$Arguments = 'powershell.exe -WindowStyle Hidden -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command ". ' + "$bScriptDest" + 'AstroneerBackupSteamStop.ps1"'
	$Service = New-Object -ComObject ("Schedule.Service")
	$Service.Connect()
	$RootFolder = $Service.GetFolder("\")
	$TaskDefinition = $Service.NewTask(0) # TaskDefinition object https://msdn.microsoft.com/en-us/library/windows/desktop/aa382542(v=vs.85).aspx
	$TaskDefinition.Principal.RunLevel = 1
	$TaskDefinition.RegistrationInfo.Description = "$bTaskNameStop"
	$TaskDefinition.Settings.Enabled = $True
	$TaskDefinition.Settings.AllowDemandStart = $True
	$TaskDefinition.Settings.DisallowStartIfOnBatteries = $False
	$TaskDefinition.Settings.StopIfGoingOnBatteries = $False
	$TaskDefinition.Settings.RunOnlyIfIdle = $False
	$TaskDefinition.Settings.IdleSettings.StopOnIdleEnd = $False
	$Triggers = $TaskDefinition.Triggers
	$Trigger = $Triggers.Create(0) # 0 is an event trigger https://msdn.microsoft.com/en-us/library/windows/desktop/aa383898(v=vs.85).aspx
	$Trigger.Enabled = $True
	$Trigger.Id = '4689' # 4688 is for process create and 4689 is for process exit
	$Trigger.Subscription = "<QueryList><Query Id=`"0`" Path=`"Security`"><Select Path=`"Security`"> *[System[Provider[@Name=`'Microsoft-Windows-Security-Auditing`'] and Task = 13313 and (EventID=4689)]] and *[EventData[Data[@Name=`'ProcessName`'] and (Data=`'" + "$gLaunchDir" + "`')]]</Select></Query></QueryList>"
	$Action = $TaskDefinition.Actions.Create(0)
	$Action.Path = $Path
	$Action.Arguments = $Arguments
	#Get-SID
	$RootFolder.RegisterTaskDefinition($bTaskNameStop, $TaskDefinition, 6, "$env:USERNAME", $null, 3) | Out-Null
}

#Check for critical backup components, installing anything missing.
Function Enable {

	#Check for backup folder.
	Get-Done
	While (!($bDestExists)) {
		Write-Host -F WHITE "Astroneer backup folder MISSING:" $bDest
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CREATE it (Y)/N?"
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
			Clear-Host
			Write-Host -F YELLOW "CREATING Astroneer backup folder..."
			New-Item -ItemType Directory -Force -Path $bDest | Out-Null
			$bDestExists = $(Test-Path $bDest)
			If($bDestExists) {
				Write-Blank(1)
				Write-Host -F GREEN "CREATED Astroneer backup folder:" $bDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
			}
			Else {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup folder..."
				Write-Blank(1)
				Write-Host -F RED "ERROR creating Astroneer backup folder:" $bDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			}
			"N" {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup folder..."
				Write-Blank(1)
				Write-Host -F RED "DECLINED creating Astroneer backup folder:" $bDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
		}
	}
		
	#Check for backup script folder.
	Get-Done
	While (!($bScriptDestExists)) {
		Write-Host -F WHITE "Astroneer backup script folder MISSING:" $bScriptDest
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CREATE it (Y)/N?"
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
			Clear-Host
			Write-Host -F YELLOW "CREATING Astroneer backup script folder..."
			New-Item -ItemType Directory -Force -Path $bScriptDest | Out-Null
			$bScriptDestExists = $(Test-Path $bScriptDest)
			If ($bScriptDestExists) {
				Write-Blank(1)
				Write-Host -F GREEN "CREATED Astroneer backup script folder:" $bScriptDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				}
			Else {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup script folder..."
				Write-Blank(1)
				Write-Host -F RED "ERROR creating Astroneer backup folder:" $bScriptDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			}
			"N" {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup script folder..."
				Write-Blank(1)
				Write-Host -F RED "DECLINED creating Astroneer backup script folder:" $bScriptDest
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
		}
	}

	#Set backup lifetime.
	Get-Done
	Get-Lifetime
	While (!($bLifetimeConfigExists)) {
		Write-Host -F WHITE "Astroneer backup LIFETIME: " -N; Write-Host -F YELLOW "$bLifetime" -N; Write-Host -F WHITE " Days"
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CHANGE it Y/(N)?"
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
				Do {
					Clear-Host
					Write-Host -F WHITE "ENTER the amount of days from 1 to 365 (default 30): " -N
					$Choice = Read-Host
					$Ok = $Choice -match '^([1-9]\d?|[12]\d\d|3[0-5]\d|36[0-5])$|^$'
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
						Clear-Host
					}
					"^$" {
						Set-Lifetime
						Get-Done
						Clear-Host
					}
				}
			}
			"N|^$" {
				Set-Lifetime
				Get-Done
				Clear-Host
			}
		}
	}

	#Check for backup scripts.
	Get-Done
	While (!($bScriptsExist)) {
		Write-Host -F WHITE "Astroneer backup scripts MISSING:" $bScriptNames
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CREATE them (Y)/N?"
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
			Clear-Host
			Write-Host -F YELLOW "CREATING Astroneer backup scripts..."
			If (!$bScriptStartExists) {
				Add-Content $bScriptStart {
					#Start script
					
					$bSource = "$env:LOCALAPPDATA\Astro\Saved\SaveGames\"
					$bScriptDest = $bDest + "Config\"
					$bLifetimeConfig = "$bScriptDest" + "bLifetime.cfg"
					[Int]$script:bLifetime = (Get-Content $bLifetimeConfig)
					$bDest = "$env:LOCALAPPDATA\AstroneerBackup\"
					$bFilter = "*.savegame"
					$sWatcher = New-Object IO.FileSystemWatcher $bSource, $bFilter -Property @{ 
						EnableRaisingEvents = $true
						IncludeSubdirectories = $false
						NotifyFilter = [System.IO.NotifyFilters]::LastWrite
					}
					
					$bAction = {
						$cDate = Get-Date
						$dDate = $cDate.AddDays(-$bLifetime)
						$sGame = $Event.SourceEventArgs.Name
						$bFull = $bDest + "$sGame"
						$bFullExists = $(Test-Path ($bFull))
						If (!$bFullExists) {
							Copy-Item "$bSource\$sGame" -Destination $bFull
							Write-Host $bFull
							Write-Host $sGame
							Get-ChildItem $bDest | Where-Object { $_.LastWriteTime -lt $dDate } | Remove-Item
						}
					}
					
					Register-ObjectEvent -InputObject $sWatcher -EventName Changed -SourceIdentifier AstroFSWChange -Action $bAction

					#Start script End
				}
			}
			If (!$bScriptStopExists) {
				Add-Content $bScriptStop {
					#Stop script
					
					Stop-ScheduledTask -TaskName "AstroneerBackupTaskStart"
					Stop-ScheduledTask -TaskName "AstroneerBackupTaskStop"
					#Stop-Process -Name "Powershell" -Force -Confirm:$False
					
					#Stop script End
				}
			}
			Get-Done
			If ($bScriptsExist) {
				Write-Blank(1)
				Write-Host -F GREEN "CREATED Astroneer backup scripts:" $bScriptNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				}
			Else {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup scripts..."
				Write-Blank(1)
				Write-Host -F RED "ERROR creating Astroneer backup scripts:" $bScriptNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			}
			"N" {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup scripts..."			
				Write-Blank(1)
				Write-Host -F RED "DECLINED creating Astroneer backup scripts:" $bScriptNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
		}
	}

	#Check for exported security policy for task auditing.
	Get-Done
	While (!($bTaskAuditExists)) {
		Clear-Host
		Write-Host -F WHITE "Astroneer backup task audit MISSING:" $bTaskAudit
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CREATE it (Y)/N?"
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
			Clear-Host
			Write-Host -F YELLOW "CREATING Astroneer backup task audit..."
			secedit /export /cfg $bTaskAudit | Out-Null
			While (!(Test-Path($bTaskAudit))) {
				Do {
					Start-Sleep -Seconds 1
				}
				Until (Test-Path($bTaskAudit))
			}
			(Get-Content $bTaskAudit).replace('AuditProcessTracking = 0','AuditProcessTracking = 1') | Out-File $bTaskAudit
			secedit /configure /db c:\windows\security\local.sdb /cfg $bTaskAudit /areas SECURITYPOLICY | Out-Null
			Export-Task
			Get-Done
			If ($bTaskAuditExists) {
				Write-Blank(1)
				Write-Host -F GREEN "CREATED Astroneer backup task audit:" $bTaskAudit
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				}
			Else {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup task audit..."
				Write-Blank(1)
				Write-Host -F RED "ERROR creating Astroneer backup task audit:" $bTaskAudit
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			}
			"N" {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup task audit..."
				Write-Blank(1)
				Write-Host -F RED "DECLINED creating Astroneer backup task audit:" $bTaskAudit
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
		}
	}

	#Check for scheduled tasks.
	Get-Done
	While (!($bTasksExist)) {
		Clear-Host
		Write-Host -F WHITE "Astroneer backup scheduled tasks MISSING:" $bTaskNames
		Write-Blank(8)
		Do {
			Write-Host -N -F YELLOW "Would you like to CREATE them (Y)/N?"
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
			Clear-Host
			Write-Host -F YELLOW "CREATING Astroneer backup scheduled tasks..."
			Write-TaskStart
			Write-TaskStop
			Get-Done
			If ($bTasksExist) {
				#I know, this next line sucks.
				#The stop script executes after task creation, which kills this script.
				#Disabling task or looping to stop the task doesn't work. Suggestions welcome.
				Start-Sleep -Seconds 5
				(Get-Content $bScriptStop) | ForEach-Object {$_ -Replace '#Stop', 'Stop'} | Set-Content $bScriptStop
				Write-Blank(1)
				Write-Host -F GREEN "CREATED Astroneer backup scheduled tasks:" $bTaskNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			Else {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup scheduled tasks..."
				Write-Blank(1)
				Write-Host -F RED "ERROR creating Astroneer backup scheduled tasks:" $bTaskNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
				}
			}
			"N" {
				Clear-Host
				Write-Host -F YELLOW "CREATING Astroneer backup scheduled task..."
				Write-Blank(1)
				Write-Host -F RED "DECLINED creating Astroneer backup scheduled tasks:" $bTaskNames
				Write-Blank(6)
				Write-Host -N -F YELLOW "Press any key to CONTINUE..."
				Get-Prompt
				Clear-Host
				Write-MainMenu
			}
		}
	}
	Write-MainMenu
}

#Check for backup components and removes them. Tries to keep silly users from deleting their backups.
Function Disable {
	Clear-Host
	Get-Done
	Write-Host -F YELLOW "Deleting Astroneer backup config:" $bScriptDest
	If ($bScriptDestExists) {
		Remove-Item -Path $bScriptDest -Recurse -Force -Confirm:$False | Out-Null
	}
	Get-Done
	If ($bScriptDestExists) {
		Write-Host -F RED "ERROR deleting Astroneer backup config:" $bScriptDest
	}
	If (!($bScriptDestExists)) {
		Write-Host -F GREEN "DELETED Astroneer backup config:" $bScriptDest
	}
	Write-Blank(1)
	Get-Done
	Write-Host -F YELLOW "Deleting Astroneer backup task audit:" $bTaskAudit
	Export-Task
	If ($bTaskAuditExists) {
		(Get-Content $bTaskAudit).replace('AuditProcessTracking = 1','AuditProcessTracking = 0') | Out-File "$bTaskAudit"
		secedit /configure /db c:\windows\security\local.sdb /cfg $bTaskAudit /areas SECURITYPOLICY | Out-Null
	}
	Export-Task
	Get-Done
		If ($bTaskAuditExists) {
		Write-Host -F RED "ERROR deleting Astroneer backup task audit:" $bTaskAudit
	}
	If (!($bTaskAuditExists)) {
		Write-Host -F GREEN "DELETED Astroneer backup task audit:" $bTaskAudit
	}
	Write-Blank(1)
	Get-Done
	Write-Host -F YELLOW "Deleting Astroneer backup tasks:" $bTaskNameStart
	If ($bTasksExist) {
		Unregister-ScheduledTask -TaskName "$bTaskNameStart" -Confirm:$False | Out-Null
		Unregister-ScheduledTask -TaskName "$bTaskNameStop" -Confirm:$False | Out-Null
	}
	Get-Done
	If ($bTasksExist) {
		Write-Host -F RED "ERROR deleting Astroneer backup tasks:" $bTaskNameStart
	}
	If (!($bTasksExist)) {
		Write-Host -F GREEN "DELETED Astroneer backup tasks:" $bTaskNameStart
	}
	Write-Blank(1)
	Write-Host -N -F YELLOW "Press any key to CONTINUE..."
	Get-Prompt
	Clear-Host
	Get-Done
	Write-Host -F YELLOW "Checking for Astroneer backups: $bDest*.savegame"
	If ($bDestExists) {
		While ($(Get-ChildItem $bDest -Filter *.savegame).Count -gt 0) {
			Do {
				Write-Blank(1)
				Write-Host -F RED "WARNING - ASTRONEER BACKUPS EXIST:" $bDest
				Write-Blank(6)
				Write-Host -N -F RED "THIS CANNOT BE UNDONE: Would you like to DELETE them Y/(N)?"
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
					Clear-Host
					Write-Host -F RED "ASTRONEER BACKUP FOLDER DELETED:" $bDest
					Write-Blank(7)
					Remove-Item -Path $bDest -Recurse -Force -Confirm:$False
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Write-MainMenu
				}
				"N|^$" {
					Clear-Host
					Write-Host -F GREEN "ASTRONEER BACKUP FOLDER PRESERVED:" $bDest
					Write-Blank(8)
					Write-Host -N -F YELLOW "Press any key to CONTINUE..."
					Get-Prompt
					Write-MainMenu
				}
			}
		}
	}
	Get-Done
	If ($bDestExists -And ($(Get-ChildItem $bDest -Filter *.savegame).Count -eq 0)) {
		Write-Blank(1)
		Write-Host -F YELLOW "No Astroneer backups found: $bDest*.savegame"
		Write-Blank(1)
		Write-Host -F YELLOW "Deleting empty Astroneer backup folder:" $bDest
		Remove-Item -Path $bDest -Force -Recurse -Confirm:$False | Out-Null
		Write-Blank (1)
	}
	Get-Done
	If ($bDestExists) {
		Write-Host -F RED "ERROR deleting empty Astroneer backup folder:" $bDest
	}
	If (!($bDestExists)) {
		Write-Host -F GREEN "DELETED empty Astroneer backup folder:" $bDest
	}
	Write-Blank(3)
	Write-Host -N -F YELLOW "Press any key to CONTINUE..."
	Get-Prompt
	Write-MainMenu 
}

#HAIL LORD ZEBRA
Function Write-Zebra([char[]]$Text) {
    For ($i = 0; $i -lt $Text.Length; $i++) {
		If ($i % 2) {
			Write-Host $Text[$i] -F Black -B White -N
		}
		Else {
			Write-Host $Text[$i] -B Black -F White -N
		}
	}
}

#Begin the script.
Clear-Host
Export-Task
Get-Lifetime
Get-BackupCount
Get-Done
Get-GameInstalled
Write-MainMenu