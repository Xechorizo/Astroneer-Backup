
# [Download Astroneer Backup Version 1.3](https://github.com/Xechorizo/Astroneer-Backup/blob/dev/AstroneerBackup.exe)
###### [EXE Clean Scan](https://www.virustotal.com/en/file/9cda24dbb8118d1a4c46b2d619c745b20d17eecfb407830da9740073bcacf23f/analysis/1556964473/)
###### [PS1 Clean Scan](https://www.virustotal.com/en/file/29816d6b05c2e8fc1c58936a4e88b4fe75daa0090f99c07128da0ba80fe31653/analysis/1556964461/)
#### Made by Xech

Written for Astroneer 1.0.15.0 on Steam - Authored May 2019

## What does this do?

-This tool backs up Astroneer saves while Astroneer is running.
-When Astroneer closes, it stops watching for changes.
-You can choose how long you want backups to be kept.
-The Astroneer install is not changed in any way by this tool.
-When saves are backed up, they're copied here: **%userprofile%\Saved Games\AstroneerBackup**

## How do I use it?

-Astroneer Backup is best run from the [.EXE](https://www.virustotal.com/en/file/660b07cad89b8201902c70f7738154b12c87a211c0173288b863d757e0f496b5/analysis/1556963295/).
-The [.PS1](https://www.virustotal.com/en/file/660b07cad89b8201902c70f7738154b12c87a211c0173288b863d757e0f496b5/analysis/1556963295/) is included if you'd like to examine the code.
-It must be run as **Administrator**. It will try to ensure this.
-To enable backup, type 1 and Enter at the Main Menu.
-To disable backup, type 2 and Enter at the Main Menu.
-To open the backup folder, type 3 and Enter at the Main Menu.
-Backups are kept for 30 days by default. 10 backups are always kept.
-Backup will only work if this appears in the Main Menu: **Backup ENABLED: True**

## How does it work?

-A backup folder and backup script are created.
-A scheduled task is created that invokes the script.
-The task is triggered when the Astro.exe is launched.
-The backup script copies .savegame files when changed.
-Backups older than the backup lifetime are deleted.

## Change Log
#### 1.1
- Replace "install" and "uninstall" with "enable" and "disable"
- Remove Intro
- Title the MainMenu
- Add Readme and Credit pages to MainMenu
- Check common install location before launching game to gather path
- Copy instead of zip
- Add configurable backup timeframe
- Package .ps1 as .exe

#### 1.2
- Consolidate tasks into one
- Check for Early Acces binary paths
- Correct escapes for task script launch
- Improve task game detection
- Improve elevation checks
- Improve Readme
- 10 backups are always kept

#### 1.3
- Added Astroneer Backup upgrade functionality
- Added support for legacy, future, and EXO Flight Test versions
- Added 10 backups per save, per version, per lifetime
- Added new icon
- Improved EXE packaging and security
- Improved loop logic and performance
- Improved launch directory logic
- Removed changelog and consolidated versioning within the script

#### Future To-Do:
- Automatically update
- Add support for Microsoft Store version
- Add backup throttle
- Add disk space check
- Move enable/disable operations to functions

## Disclosure
### *MAKE MANUAL BACKUPS PRIOR TO USE*
### *ONLY TESTED WITH STEAM VERSION*
### *PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED*