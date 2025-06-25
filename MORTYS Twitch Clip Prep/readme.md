# 🎬 Twitch Clip Pipeline – Automatisierter Clip-Downloader & Transcriber

Dieses PowerShell-Skript automatisiert den gesamten Workflow für Twitch-Clips:  
✔️ Clips herunterladen, ✔️ automatisch transkribieren, ✔️ organisieren, ✔️ zippen – alles in einem Schritt.

Ideal für Streamer wie **mortys_welt**, die ihre besten Momente als YouTube Shorts oder TikToks aufbereiten möchten.

---

## 🔧 Features

- ⬇️ **Automatischer Download** von Twitch-Clips über `yt-dlp`
- 🧼 **Normierte Dateinamen** (ASCII, max. 40 Zeichen, deutschfreundlich)
- 🗃️ **Verzeichnisstruktur pro Clip** (`MP4 + SRT + ZIP`)
- 🎙️ **Transkription mit Whisper** (`base`-Modell, Sprache wählbar)
- 💾 **JSON-Logfiles** zur Nachverfolgung aller Downloads und Verarbeitungen
- 🧪 **Debug-Modus** für schnelle Tests

---

## 📂 Projektstruktur

```
.
├── config/
│   ├  ─  ─ downloaded_clips.json   # WIRD ERSTELLT - Alle heruntergeladenen Clips
│   └  ─  ─ processed_clips.json    # WIRD ERSTELLT - Alle erfolgreich verarbeiteten Clips
├── clip_automator.ps1          # Hauptskript
└── README.md
```

Im Skript abgeänderte BaseDir - ergibt den Downloadpfad an und es entsteht dort folgende Struktur:

```
.
├── RAW/                        # Temporäre MP4-Dateien direkt nach dem Download
├── <CLIPNAME>/                 # Fertiges Verzeichnis pro Clip
│   ├── <CLIPNAME>.mp4          # .mp4 Video-Datei (x264)
│   ├── <CLIPNAME>.srt          # .srt Untertitel-Datei z.B. für Davinci Resolve
│   └── <CLIPNAME>.zip          # .zip -> beinhaltet .mp4 und .srt; lediglich für vereinfachten Download
```