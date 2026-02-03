<p align="center">
  <img src="icon.png" alt="StartTunnel" width="120">
</p>

<h1 align="center">Start CLI</h1>

**Start CLI (`start-cli`)** is the official command-line tool for **StartOS** - a sovereignty-first operating system empowering anyone to run and host their own services independently.

The CLI is **essential** for:

- building and packaging services into the **`.s9pk`** (StartOS Service Package) format,
- remotely managing a StartOS node (listing services, installing, updating, backups, monitoring),
- integrating StartOS with CI/CD pipelines and developer tooling.

Prebuilt binaries are available for:

- macOS (Intel x86_64 & Apple Silicon ARM64),
- Linux (Intel x86_64 & ARM64).

Official StartOS source code is here: [start9labs/start-os](https://github.com/start9labs/start-os).

---

## Installation

### Automated Installation (Recommended)

The easiest way to install start-cli is using our automated installer script:

```
curl -fsSL https://start9labs.github.io/start-cli/install.sh | sh
```

The installer will:

- Detect your platform automatically (macOS/Linux, Intel/ARM64)
- Download the correct binary from GitHub releases
- Install to `~/.local/bin/start-cli`
- Update your shell configuration for PATH
- Verify the installation

### Manual Installation

If you prefer manual installation, download the appropriate binary from the [start-os releases](https://github.com/Start9Labs/start-os/releases) page, then set executable permissions and copy it to a directory in your PATH.

---

## Source Code

This repo hosts the installer script via GitHub Pages. The start-cli source code and release binaries live in the [StartOS monorepo](https://github.com/Start9Labs/start-os).

## Learn More

- [StartOS Documentation](https://docs.start9.com)
- [Start9 Website](https://start9.com)
