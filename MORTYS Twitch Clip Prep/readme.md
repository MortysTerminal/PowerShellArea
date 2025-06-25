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
│   ├── downloaded_clips.json   # WIRD ERSTELLT - Alle heruntergeladenen Clips
│   └── processed_clips.json    # WIRD ERSTELLT Alle erfolgreich verarbeiteten Clips
├── RAW/                        # Temporäre MP4-Dateien direkt nach dem Download
├── <CLIPNAME>/
│   ├── <CLIPNAME>.mp4
│   ├── <CLIPNAME>.srt
│   └── <CLIPNAME>.zip
├── clip_automator.ps1          # Hauptskript
└── README.md
```