# Mortys Downloader - YouTube, Twitter, Instagram, and TikTok Video Downloader

This repository contains a PowerShell script that utilizes the [yt-dlp](https://github.com/yt-dlp/yt-dlp) GitHub project to download videos from YouTube, Twitter, Instagram, and TikTok. The script simplifies the process of downloading videos in formats such as mp3, mp4, or m4a by automatically fetching the necessary files without requiring user approval.

## Usage

1. Open the respective `.bat` file for the desired video format:
   - `download_mp3.bat` for MP3 downloads
   - `download_mp4.bat` for MP4 downloads
   - `download_m4a.bat` for M4A downloads

2. The script will start automatically and initiate the video download.

Note: The script will check for the presence of `yt-dlp.exe` and `ffmpeg.exe`. If these executables are missing, they will be automatically downloaded.

## Notes

- For further customization and advanced functionality of the script, refer to the PowerShell file `download_videos.ps1`.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

This project utilizes the [yt-dlp](https://github.com/yt-dlp/yt-dlp) project for video downloading.
