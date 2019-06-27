
# [Download Astroneer Backup Version 1.4.1](https://github.com/Xechorizo/Astroneer-Backup/blob/dev/AstroneerBackup.exe)
###### [EXE Clean Scan](https://www.virustotal.com/gui/file/d8faae1b9604b32c02849eee2f6b943de399562ac6b32d210c2c1a5e7d379472/detection)
###### SHA256: d8faae1b9604b32c02849eee2f6b943de399562ac6b32d210c2c1a5e7d379472

###### [PS1 Clean Scan](https://www.virustotal.com/gui/file/b007dbede94ec6de16821fba79e962ef5cce2345427eb7163a56d82e84d81e64/detection)
###### SHA256: b007dbede94ec6de16821fba79e962ef5cce2345427eb7163a56d82e84d81e64

![Screenshot](https://i.imgur.com/5gHwipx.png)

### Made by Xech
- Written for Astroneer 1.2.9.0 on Steam and Microsoft Store - Authored June 2019

## Readme
### What does it do?
- This tool backs up Astroneer saves while Astroneer is running.
- When Astroneer closes, it stops watching for changes.
- You can choose where and how long you want backups to be kept.
- The Astroneer install is not changed in any way by this tool.
- When saves are backed up, they're copied here by default: **%userprofile%\Saved Games\AstroneerBackup**

### How do I use it?
- Astroneer Backup is best run from the [.EXE](https://github.com/Xechorizo/Astroneer-Backup/blob/dev/AstroneerBackup.exe).
- You can examine the code using the included [.PS1](https://github.com/Xechorizo/Astroneer-Backup/blob/dev/AstroneerBackup.ps1).
- It must be run as **Administrator**. It will try to ensure this.
- To enable backup, type **1** and Enter at the Main Menu.
- To disable backup, type **2** and Enter at the Main Menu.
- To open the backup folder, type **3** and Enter at the Main Menu.
- Backups are kept for **14** days by default. **10** backups are always kept.
- Backup will only work if this appears in the Main Menu: **Backup ENABLED: True**

### How does it work?
- A backup folder and backup script are created.
- A scheduled task is created that invokes the script.
- The task is triggered when the Astroneer is launched.
- The backup script copies save files when changed.
- Backups older than the backup lifetime are deleted.

## Change Log
#### 1.4.1
- Added platform-specific subfolders to destination
- Improved cleanup

#### 1.4
- Added support for Microsoft Store version (Windows 10 1809+ UWP)
- Added shortcuts to savegame folders in backup destination
- Added configuration of backup destination
- Added support for all Steam libraries
- Added additional credits
- Improved save file filtering
- Improved null path testing
- Improved upgrade feature
- Improved menu title
- Improved Readme
- Reduced default backup lifetime (30 days now 14 days)

#### 1.3
- Added Astroneer Backup upgrade functionality
- Added support for legacy, future, and EXO Flight Test versions
- Added 10 backups per save, per version, per lifetime
- Added new icon
- Improved EXE packaging and security
- Improved loop logic and performance
- Improved launch directory logic
- Removed changelog and consolidated versioning within the script

#### 1.2
- Added support for Early Acces binary paths
- Consolidated tasks
- Imporoved backups to always keep 10 
- Improved task game detection
- Improved elevation checks
- Improved escapes for task script launch
- Improved Readme

#### 1.1
- Added .exe packaging
- Added configurable backup lifetime
- Added common install locations and game launch for unusual paths
- Improved file handling
- Improved the Main Menu
- Replaced "install"/"uninstall" with "enable"/"disable"
- Replaced Intro with Readme and Credits

#### 1.0
- Initial release

#### Future:
- Add backup throttle
- Add disk space check
- Add automatic updates
- Add savegame-named subfolders for UWP saves

## Disclosure
### *MAKE MANUAL BACKUPS PRIOR TO USE*
### *PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED*
