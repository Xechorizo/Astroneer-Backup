
# [Download Astroneer Backup Version 1.2](https://github.com/Xechorizo/Astroneer-Backup/blob/master/AstroneerBackup.exe)

#### Made by Xech

Written for Astroneer 1.0.15.0 on Steam - Authored April 2019

## What does this do?

- This tool backs up Astroneer saves while Astroneer is running.
- When Astroneer closes, it stops watching for changes.
- You can choose how long you want backups to be kept.
- The Astroneer install is not changed in any way by this tool.
- When saves are backed up, they're copied here: **%userprofile%\Saved Games\AstroneerBackup**

## How do I use it?

- To enable backup, type 1 and Enter at the Main Menu.
- To disable backup, type 2 and Enter at the Main Menu.
- To open the backup folder, type 3 and Enter at the Main Menu.
- Backups are kept for 30 days by default.
- Backup will only work if this appears in the Main Menu: **Backup ENABLED: True**

## How does it work?

- A backup folder and backup script are created.
- A scheduled task is created that invokes the script.
- The task is triggered when the Astro.exe is launched.
- The backup script copies .savegame files when changed.
- Backups older than the backup lifetime are deleted.

### *MAKE MANUAL BACKUPS PRIOR TO USE*
### *ONLY TESTED WITH STEAM VERSION*
### *PROVIDED AS-IS WITH NO GUARANTEE EXPRESS OR IMPLIED*
