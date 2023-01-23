## About this script

This is a script, which will give you the opportunity to download all clips + chat from your channel from twitch. It uses native elements of PowerShell (which is pre-installed on every Windows Computer (7+ and newer))
It works completly automatic, after you entered the correct settings into the "config.motm" file. *You can open this with the any Editor*

**Every Output is only in german right now! I'm working on a translation, but I translated a lot of commentaries inside the code already in english**

I use the "TwitchDownloader" for my project, which is a Program from @lay295 from GitHub. (https://github.com/lay295/TwitchDownloader) - to create the Chat-MP4 and JSON Files. The TwitchDownloader needs ffmpeg to convert the json to an MP4-Format (https://ffmpeg.org/). **Everything that is needed is already in the zip-Folder!**

## What do you need before you start?

- Windows 7 SP1 or never, with PowerShell installed (since Windows 10 it's natively installed)


## How to get started

*I'm working on a Tutorial YouTube Video at the moment, but for now here is little step-for-step tutorial in my terrific english. Why? Because I need to learn it.*

1. Download the latest .zip File from this repository
2. Unzip the folder to any **local** desired location
3. Start the script once by starting the file "start.bat"
	1. The script will create the config file for you. You need to edit that file for your needs.
	2. You need to edit the file like:

> DOWNLOADPATH=YOU LOCAL DOWNLOAD PATH (C:\\Download)
> CHANNELNAME=YOUR CHANNELNAME FROM TWITCH (mortys_welt)
> APPID=YOUR APPID (You need to generate this through Twitch-Developer)
> APPSECRET=YOU APPSECRET (You need to generate this through Twitch-Developer)
> CHATDOWNLOAD=YES or NO

4. After you edited the *config.motm* file, you can start the script "start.bat" again.
5. It will start to connect to twitch and verfiy your data. If anything is wrong, then the script will tell you what exactly is wrong.
6. The script will automaticly read all your Clips from your Channel and start downloading the Clips in the desired folder. *(+ Chat, if you configured "YES" in the config-file)

## Changelog
=======
Version 1.2:
- Added the possibility to have a task created automatically. ** WINDOWS ONLY**
	- After creating a task, the trigger and the login must be adjusted! (Task scheduling in Windows)
	
Version 1.1:
- Added a free space check for the hard-drive before downloading the clip
- Bug-Fixes:
	- Fixed a Bug where the filename wasnt renamed correctly for the chat-rendered mp4-files
