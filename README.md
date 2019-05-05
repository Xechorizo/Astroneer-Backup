
# [Download Astroneer Backup Version 1.3](AstroneerBackup.exe)
[EXE Clean Scan](https://www.virustotal.com/en/file/7d3032b8169bb5d41106db408d10317ed70199e2fa7702b8f94e2b31135961c0/analysis/1557043972/)
SHA256: 7D3032B8169BB5D41106DB408D10317ED70199E2FA7702B8F94E2B31135961C0

[PS1 Clean Scan](https://www.virustotal.com/en/file/56923c5ba052420a83563323ae00aa710d01ffc8e96937ac29f4753cc25ff3dd/analysis/1557043980/)
SHA256: 56923C5BA052420A83563323AE00AA710D01FFC8E96937AC29F4753CC25FF3DD

### Made by Xech
- Written for Astroneer 1.0.15.0 on Steam - Authored May 2019

## Readme
### What does this do?
- This tool backs up Astroneer saves while Astroneer is running.
- When Astroneer closes, it stops watching for changes.
- You can choose how long you want backups to be kept.
- The Astroneer install is not changed in any way by this tool.
- When saves are backed up, they're copied here: **%userprofile%\Saved Games\AstroneerBackup**

### How do I use it?
- Astroneer Backup is best run from the [.EXE](https://www.virustotal.com/en/file/660b07cad89b8201902c70f7738154b12c87a211c0173288b863d757e0f496b5/analysis/1556963295/).
- You can examine the code using the included [.PS1](https://www.virustotal.com/en/file/660b07cad89b8201902c70f7738154b12c87a211c0173288b863d757e0f496b5/analysis/1556963295/).
- It must be run as **Administrator**. It will try to ensure this.
- To enable backup, type 1 and Enter at the Main Menu.
- To disable backup, type 2 and Enter at the Main Menu.
- To open the backup folder, type 3 and Enter at the Main Menu.
- Backups are kept for 30 days by default. 10 backups are always kept.
- Backup will only work if this appears in the Main Menu: **Backup ENABLED: True**

### How does it work?
- A backup folder and backup script are created.
- A scheduled task is created that invokes the script.
- The task is triggered when the Astro.exe is launched.
- The backup script copies .savegame files when changed.
- Backups older than the backup lifetime are deleted.

## Change Log
#### 1.1
- Added .exe packaging
- Added configurable backup lifetime
- Added common install locations and game launch for unusual paths
- Improved file handling
- Improved the Main Menu
- Replaced "install"/"uninstall" with "enable"/"disable"
- Replaced Intro with Readme and Credits

#### 1.2
- Added support for Early Acces binary paths
- Consolidated tasks
- Imporoved backups to always keep 10 
- Improved task game detection
- Improved elevation checks
- Improved escapes for task script launch
- Improved Readme

#### 1.3
- Added Astroneer Backup upgrade functionality
- Added support for legacy, future, and EXO Flight Test versions
- Added 10 backups per save, per version, per lifetime
- Added new icon
- Improved EXE packaging and security
- Improved loop logic and performance
- Improved launch directory logic
- Removed changelog and consolidated versioning within the script

#### Future:
- Automatically update
- Add support for Microsoft Store version
- Add backup throttle
- Add disk space check
- Move enable/disable operations to functions

## Disclosure
### *MAKE MANUAL BACKUPS PRIOR TO USE*
### *ONLY TESTED WITH STEAM VERSION*
### *PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED*