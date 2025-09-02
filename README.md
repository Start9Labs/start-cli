<div align="center">
  <img src="https://raw.githubusercontent.com/Start9Labs/start-os/refs/heads/master/web/projects/shared/assets/img/icon.png" alt="Project Logo" width="11%" />
  <h1 style="margin-top: 0;">Start CLI</h1>
</div>

**Start CLI (`start-cli`)** is the official command-line tool for **StartOS** - a sovereignty-first operating system empowering anyone to run and host their own services independently.

The CLI is **essential** for:  
- building and packaging services into the **`.s9pk`** (StartOS Service Package) format,  
- remotely managing a StartOS node (listing services, installing, updating, backups, monitoring),  
- integrating StartOS with CI/CD pipelines and developer tooling.  

This repository provides **prebuilt `start-cli` binaries** for:  
- macOS (Intel x86_64 & Apple Silicon ARM64),  
- Linux (Intel x86_64 & ARM64).  

Official StartOS source code is here: [start9labs/start-os](https://github.com/start9labs/start-os).  

---

## 🔧 Installation

### Automated Installation (Recommended)

The easiest way to install start-cli is using our automated installer script:
```
curl -fsSL https://start9labs.github.io/start-cli | sh
```
<details>
  <summary><b>Click to see installation demo</b><br><br></summary>
  <img src=".github/start-cli-installer-demo.webp" alt="Start CLI Installer demo animation"/>
  <br>
</details>

Or download and run the script manually:
```
curl -fsSL https://start9labs.github.io/start-cli -o start-cli-installer.sh
chmod +x start-cli-installer.sh
./start-cli-installer.sh
```

The installer will:
- → Detect your platform automatically (macOS/Linux, Intel/ARM64)
- → Download the correct binary from GitHub releases
- → Install to `~/.local/bin/start-cli`
- → Update your shell configuration for PATH
- → Verify the installation

### Manual Installation

If you prefer manual installation, download the appropriate binary from the [Releases](https://github.com/Start9Labs/start-cli/releases) page, then extract the archive, set executable permissions, and copy it to a directory in your PATH.

---

## 🔄 Release Workflow

Binaries are built and published automatically using **GitHub Actions** workflow:  

- Triggered on each new **tag** pushed (`vX.Y.Z`),  
- Builds for all supported platforms,  
- Generates SHA256 checksums for integrity verification,  
- Publishes a GitHub Release with `.tar.gz` archives ready for download.  
