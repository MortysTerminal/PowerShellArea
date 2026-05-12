# PowerShellArea

Collection of PowerShell scripts for private and enterprise Windows environments.

Each project lives in its own folder with its own README and is intended to be
standalone — no shared dependencies between projects, so you can pick a single
folder, drop it onto a target machine, and run it without having to clone the
rest of the repo.

## Projects

| Folder | Purpose |
|--------|---------|
| [`SecureBoot-CertCheck-2026/`](./SecureBoot-CertCheck-2026) | Read-only diagnostic for the Secure Boot CA 2023 certificate rollout that replaces the 2011 CAs expiring in June 2026. |

## Conventions

- **Language.** All documentation, inline comments, and parameter help are
  written in English.
- **Compatibility.** Scripts are kept working on Windows PowerShell 5.1 unless
  a project explicitly requires PowerShell 7+. Compatibility notes live in
  each project's README.
- **Per-project READMEs** cover usage, parameters, expected output, and any
  caveats specific to that script.

## License

MIT — see [LICENSE](./LICENSE).

---

<sub>Maintained by [MortysTerminal](https://github.com/MortysTerminal).</sub>