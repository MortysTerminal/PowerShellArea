# Mortys Downloader - YouTube, Twitter, Instagram, Twitch and TikTok Video Downloader

This repository contains a PowerShell script that utilizes the [yt-dlp](https://github.com/yt-dlp/yt-dlp) GitHub project to download videos from YouTube, Twitter, Instagram, and TikTok. The script simplifies the process of downloading videos in formats such as mp3, mp4, or m4a by automatically fetching the necessary files without requiring user approval.

## Usage

1. Open the respective `.bat` file for the desired video format:
    - `start_mp3-and-mp4.bat` for MP3 AND MP4 download
    - `start_only_m4a.bat` for M4A download
    - `start_only_mp3.bat` for MP3 download
    - `start_only_mp4.bat` for MP4 download

2. The script will start automatically and initiate the video download.

Note: The script will check for the presence of `yt-dlp.exe` and `ffmpeg.exe`. If these executables are missing, they will be **automatically downloaded.**

## Notes

- For further customization and advanced functionality of the script, refer to the PowerShell file `core/mbo-yt-download-script.ps1`.

## License

This project is licensed under the **MIT License**.

## Credits

This project utilizes the [yt-dlp](https://github.com/yt-dlp/yt-dlp) project for video downloading.
*Please do not load this script onto your USB stick and eat it afterwards.*