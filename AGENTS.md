# AGENTS.md

## Project Overview

Personal Shadowsocks VPN server (`ss-server` via `shadowsocks-libev`) with shell-based setup scripts and a Kotlin/Gradle scaffold for a future Android client. No Docker — runs natively on macOS/Linux and inside WSL2 on Windows.

## Architecture

- **`vpn-setup/`** — Bash scripts that manage the VPN server lifecycle. These are the core of the project:
  - `setup-vpn.sh` — macOS/Linux: generates config, starts `ss-server`, prints `ss://` link
  - `setup-vpn-windows.sh` — WSL2: same as above + prints PowerShell firewall commands
  - `start-vpn.sh` / `stop-vpn.sh` / `status-vpn.sh` — manage a running server
  - `test-native.sh` — end-to-end test (starts `ss-server` + `ss-local`, curls through SOCKS5)
- **`app/`** — Kotlin JVM module (placeholder `main()` using `utils`). Entry: `org.example.app.AppKt`
- **`utils/`** — Shared Kotlin utilities (`Printer` class using kotlinx-datetime, serialization, coroutines)
- **`buildSrc/`** — Gradle convention plugin (`kotlin-jvm.gradle.kts`): sets JVM toolchain to Java 23, configures JUnit 5

## Key Conventions

- **Shell scripts must use LF line endings** — `.gitattributes` enforces `eol=lf` for `*.sh`. This is critical for WSL2 compatibility; CRLF breaks bash.
- **Server state lives in `~/.shadowsocks-vpn/`** — `server.conf` (port + password), `ss-server.pid`, `ss-server.log`, `connection-info.txt`. Scripts are idempotent: re-running reuses existing config.
- **No credentials in the repo** — port, password, and `ss://` links are generated at runtime and stored in `~/.shadowsocks-vpn/` only.
- **Encryption method**: always `chacha20-ietf-poly1305` (hardcoded across all scripts).

## Build & Run

```bash
./gradlew build          # Build Kotlin modules
./gradlew :app:run       # Run JVM app
./gradlew :utils:test    # Run tests (JUnit 5)
```

Requires Java 23 (auto-provisioned via Foojay toolchain plugin in `settings.gradle.kts`).

## VPN Server Commands

```bash
bash vpn-setup/setup-vpn.sh           # macOS/Linux: full setup + start
bash vpn-setup/setup-vpn-windows.sh   # Windows WSL2: full setup + start + firewall instructions
bash vpn-setup/start-vpn.sh           # Start server (config must exist)
bash vpn-setup/stop-vpn.sh            # Stop server
bash vpn-setup/status-vpn.sh          # Check if running
bash vpn-setup/test-native.sh         # E2E connectivity test
```

## Dependencies

- **Runtime**: `shadowsocks-libev` (`ss-server`), `curl`, `openssl` — installed via OS package manager
- **Kotlin**: version catalog at `gradle/libs.versions.toml` — Kotlin 2.2.20, kotlinx-datetime, kotlinx-serialization-json, kotlinx-coroutines
- **Gradle**: convention plugin in `buildSrc/` applies to both `app` and `utils`

## Important Patterns

- When adding/editing shell scripts, always ensure LF line endings (the `.gitattributes` handles this in Git, but verify with `file script.sh`)
- The `setup-vpn*.sh` scripts are the source of truth for the VPN config format — any changes to port/password/cipher must be reflected in `start-vpn.sh` and `test-native.sh` too
- `ss://` links use the format `ss://BASE64(method:password)@host:port#name`
- Platform detection in scripts: WSL is detected via `grep -qi microsoft /proc/version`

