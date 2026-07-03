# Security Policy

## Reporting a vulnerability

Use GitHub's private vulnerability reporting for this repository
(**Security → Report a vulnerability**) instead of opening a public issue.
Reports are handled on a best-effort basis.

## Scope

- `install.ps1` bootstrap flow (`irm | iex`)
- `setup.ps1` profile resolution and `sandbox.wsb` generation
- `scripts/autostart.ps1` — hardening, winget installs, Sysmon config download + SHA256 pinning

Note that Windows Sandbox itself is not a malware-grade isolation boundary (see the README);
weaknesses in Windows Sandbox belong upstream with Microsoft, not here.

## Supported versions

Only the latest release and `main` are supported.
