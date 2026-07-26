# Security policy

## Supported versions

Security fixes are applied to the latest source on `main`. Tagged releases will
list their support status here once distribution begins.

## Reporting a vulnerability

Please do not publish an exploit or sensitive local data in a public issue.
Open a private GitHub security advisory for this repository with:

- the affected commit or version;
- reproduction steps;
- expected impact;
- any suggested mitigation.

Reports involving arbitrary file access, writes to the Codex database,
Accessibility misuse, URL handling, or release-signing integrity are especially
important.

## Security model

Codex Layouts intentionally:

- has no network client;
- opens Codex history read-only;
- keeps Accessibility operations scoped to the Codex process;
- uses no private framework or private Codex API;
- has no third-party runtime package dependencies.

Accessibility permission is powerful. A modified build can change its scope;
review source and release provenance before granting permission.
