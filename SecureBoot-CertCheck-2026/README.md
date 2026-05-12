# SecureBoot-CA2023-Check

Read-only PowerShell diagnostic for the Secure Boot certificate rollout that
replaces the **2011 CAs expiring in June 2026** with the new **2023 CA
generation**.

The script answers a single, narrow question for one local Windows device:

> *Has this machine actually received the new Secure Boot certificates yet —
> in Windows, in the firmware DB, and in the firmware KEK?*

No deployment is triggered. No registry value is written. The script is safe to
run on production devices.

---

## Background

Microsoft is rotating the Secure Boot trust chain ahead of the June 2026
expiration of the original 2011 CAs. Five things must end up on each device:

| Variable | Certificate / object                         |
|----------|----------------------------------------------|
| `db`     | Windows UEFI CA 2023                         |
| `db`     | Microsoft UEFI CA 2023 (3rd-party)           |
| `db`     | Microsoft Option ROM UEFI CA 2023            |
| `KEK`    | Microsoft Corporation KEK 2K CA 2023         |
| boot     | Boot Manager signed by Windows UEFI CA 2023  |

Windows tracks the rollout in the registry under
`HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing`, primarily via
`UEFICA2023Status` (target value: `Updated`). The firmware variables are the
authoritative source of truth — the registry can claim success while the
firmware silently rejects the handoff, which is exactly what the OEM-related
issues reported in the Microsoft Tech Community thread look like.

This script reads **both** layers and reconciles them.

Primary reference:
[Secure Boot playbook for certificates expiring in 2026](https://techcommunity.microsoft.com/blog/windows-itpro-blog/secure-boot-playbook-for-certificates-expiring-in-2026/4469235)
· [aka.ms/GetSecureBoot](https://aka.ms/GetSecureBoot)

---

## Requirements

- Windows 10 (22H2 or later) or Windows 11
- Windows PowerShell 5.1 **or** PowerShell 7.x
- An elevated session (Administrator). The script will still run without
  elevation but registry and event-log reads may be partial.

---

## Usage

Run a basic interactive check:

```powershell
.\Get-SecureBootCertStatus.ps1
```

Run a check and persist the result for later comparison:

```powershell
.\Get-SecureBootCertStatus.ps1 -ExportCsv .\status.csv -LogPath .\check.log
```

Pipeline-friendly usage (no console output, just the result object):

```powershell
$r = .\Get-SecureBootCertStatus.ps1 -Quiet
if ($r.OverallState -ne 'Updated') {
    Write-Warning "Device $($r.Hostname) is in state '$($r.OverallState)'."
}
```

### Parameters

| Parameter   | Purpose                                                              |
|-------------|----------------------------------------------------------------------|
| `-ExportCsv`| Append a single-row CSV snapshot of the result to the given path.    |
| `-LogPath`  | Append a timestamped human-readable summary to the given log file.   |
| `-Quiet`    | Suppress the formatted console summary. The result object still emits.|

---

## Output

The script emits a single `PSCustomObject` with the following fields:

| Field                              | Meaning                                                          |
|------------------------------------|------------------------------------------------------------------|
| `OverallState`                     | `Updated` · `InProgress` · `NotStarted` · `Error` · `SecureBootDisabled` · `Unknown` |
| `SecureBootEnabled`                | Result of `Confirm-SecureBootUEFI`                               |
| `UEFICA2023Status`                 | Registry — current rollout phase as Windows sees it              |
| `UEFICA2023Error`                  | Registry — should be absent; non-null indicates a failure        |
| `WindowsUEFICA2023Capable`         | Registry — firmware capability flag                              |
| `AvailableUpdates`                 | Registry — bitmask of pending updates, displayed as hex          |
| `HighConfidenceOptOut`             | Registry — `1` opts the device out of Microsoft's auto rollout    |
| `MicrosoftUpdateManagedOptIn`      | Registry — `1` opts the device into Controlled Feature Rollout    |
| `DB_WindowsUEFICA2023`             | Firmware — `True` if certificate is present in `db`              |
| `DB_MicrosoftUEFICA2023`           | Firmware — `True` if 3rd-party CA is present in `db`             |
| `DB_MicrosoftOptionROMCA2023`      | Firmware — `True` if Option ROM CA is present in `db`            |
| `KEK_MicrosoftCorpKEK2KCA2023`     | Firmware — `True` if the new KEK is present in `KEK`             |
| `Event1808_Count` / `Event1808_Last` | Success events                                                 |
| `Event1801_Count` / `Event1801_Last` | Error events                                                   |
| `Event1795_Count` / `Event1795_Last` | Firmware handoff errors                                        |
| `OEMManufacturer`, `OEMModel`, `FirmwareVersion`, `FirmwareReleaseDate` | Useful context if you need to contact the OEM |

### Decision matrix

| `OverallState`        | What it means                                                                          | Suggested next step |
|-----------------------|----------------------------------------------------------------------------------------|---------------------|
| `Updated`             | All four 2023 certificates are present in firmware **and** Windows confirms the state. | Done. Optionally re-check after the next monthly cumulative update to confirm the Boot Manager swap happened. |
| `InProgress`          | Windows is in the middle of the rollout. The scheduled task runs every 12 hours and one or more reboots are still pending. | Wait roughly 48 hours and one full reboot, then re-run. |
| `NotStarted`          | The rollout has not been initiated on this device.                                     | Either wait for Microsoft to include the device in a high-confidence rollout via Windows Update, or trigger it manually by setting `AvailableUpdates = 0x5944` (see Microsoft's deployment guidance — not done by this script). |
| `Error`               | `UEFICA2023Error` is populated. Most common cause is a firmware that refuses the handoff. | Check `Event1795_Last`, then look for a BIOS / UEFI update from your OEM. |
| `SecureBootDisabled`  | Secure Boot itself is off in the UEFI.                                                 | Out of scope for this script. Enable Secure Boot first if your device supports it. |
| `Unknown`             | The script could not derive a clear state from the available data.                     | Inspect the raw result object and the event log. |

---

## What this script deliberately does **not** do

- It does not write any registry values.
- It does not trigger the rollout (no `AvailableUpdates = 0x5944`).
- It does not opt the device into or out of Microsoft's Controlled Feature Rollout.
- It does not modify Group Policy, Intune, or WinCS settings.

Triggering deployment is intentionally a separate, manual decision documented
in the Microsoft playbook. Mixing deployment methods on the same device is
explicitly discouraged by Microsoft, which is one more reason this script
stays purely on the diagnostic side.

---

## Quick check (run without cloning)

For a one-shot diagnostic on a client PC, you can fetch and execute the
script directly from this repository without cloning:

```powershell
# Default check, no parameters
irm 'https://raw.githubusercontent.com/MortysTerminal/PowerShellArea/main/SecureBoot-CertCheck-2026/Get-SecureBootCertStatus.ps1' | iex
```

If you need to pass parameters (`-ExportCsv`, `-LogPath`, `-Quiet`), wrap
the downloaded content in a script block so PowerShell forwards them
properly:

```powershell
$src = irm 'https://raw.githubusercontent.com/MortysTerminal/PowerShellArea/main/SecureBoot-CertCheck-2026/Get-SecureBootCertStatus.ps1'
$sb  = [scriptblock]::Create($src)
& $sb -ExportCsv .\status.csv -LogPath .\check.log
```

On Windows PowerShell 5.1 on older systems you may need to force TLS 1.2
before the request:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

> **A note on trust.** Running a script straight off the internet means
> trusting whatever happens to be at that URL the moment you invoke it. The script in this repo is read-only and does not modify the system, but inspecting the source before piping it into `iex` is always a reasonable habit.

---

## License

MIT — feel free to adapt for your environment.

---

<sub>Part of the [MortysTerminal/PowerShellArea](https://github.com/MortysTerminal/PowerShellArea) collection.</sub>