# 🔐 Personal Shadowsocks VPN Server

A self-hosted [Shadowsocks](https://shadowsocks.org/) VPN server for bypassing internet censorship.
Uses `shadowsocks-libev` (`ss-server`) — runs natively on macOS, Linux, or Windows (WSL).

## Why Shadowsocks?

Countries like Iran, China, and Russia actively block standard VPN protocols (OpenVPN, WireGuard).
Shadowsocks disguises traffic as normal HTTPS, making it **extremely hard to detect and block**.

---

## 🖥️ Server Setup

### Prerequisites

| Platform | Install command |
|----------|----------------|
| **macOS** | `brew install shadowsocks-libev` |
| **Ubuntu / Debian** | `sudo apt update && sudo apt install -y shadowsocks-libev` |
| **Fedora / RHEL** | `sudo dnf install -y shadowsocks-libev` |
| **Arch** | `sudo pacman -S shadowsocks-libev` |
| **Windows** | Use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install), then follow the Ubuntu instructions |

### Quick Start (macOS)

```bash
bash vpn-setup/setup-vpn.sh
```

This will:
1. Generate a random port and password (or reuse existing config from `~/.shadowsocks-vpn/`)
2. Start `ss-server` natively
3. Print connection info and an `ss://` link to share with clients

### Quick Start (Linux)

```bash
# Generate a password and pick a port
SS_PORT=443
SS_PASS=$(openssl rand -base64 16 | tr -d '=+/' | head -c 16)

# Start ss-server
ss-server \
    -s 0.0.0.0 \
    -p "$SS_PORT" \
    -k "$SS_PASS" \
    -m chacha20-ietf-poly1305 \
    -d 8.8.8.8,8.8.4.4 \
    -u \
    --fast-open
```

### Quick Start (Windows via WSL)

1. Install WSL2: `wsl --install -d Ubuntu`
2. Inside WSL: `sudo apt install -y shadowsocks-libev`
3. Run the same Linux commands above
4. Forward the chosen port through Windows Firewall:
   ```powershell
   # Run in PowerShell as Administrator
   netsh advfirewall firewall add rule name="Shadowsocks" dir=in action=allow protocol=TCP localport=YOUR_PORT
   netsh advfirewall firewall add rule name="Shadowsocks UDP" dir=in action=allow protocol=UDP localport=YOUR_PORT
   ```

### Port Forwarding (All Platforms)

Forward the chosen port (TCP + UDP) on your router to your machine's local IP:

1. Find your local IP:
   - macOS: `ipconfig getifaddr en0`
   - Linux: `hostname -I | awk '{print $1}'`
   - Windows: `ipconfig` → look for IPv4 under your adapter
2. Log into your router admin panel and add a port forwarding rule

### Firewall

| Platform | Action |
|----------|--------|
| **macOS** | System Settings → Network → Firewall → turn off or add exception |
| **Linux** | `sudo ufw allow YOUR_PORT` (if using ufw) |
| **Windows** | See PowerShell commands above |

---

## 📱 Client Setup (Android / iOS / Desktop)

### Option A: v2rayNG (Android — recommended)

1. Install [v2rayNG](https://github.com/2dust/v2rayNG/releases) (or from Google Play)
2. Tap **➕** → **"Type manually [Shadowsocks]"**
3. Enter your server IP, port, password, and method `chacha20-ietf-poly1305`
4. Save → tap **▶** to connect

### Option B: Shadowrocket (iOS)

1. Install [Shadowrocket](https://apps.apple.com/us/app/shadowrocket/id932747118) from App Store
2. Add server with your connection details

### Option C: Import ss:// link

The setup script generates an `ss://` link. Paste it into any Shadowsocks-compatible client to auto-configure.

Format: `ss://BASE64(method:password)@host:port#name`

### Option D: Desktop clients

| Platform | Client |
|----------|--------|
| macOS | [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG/releases) |
| Windows | [Shadowsocks-windows](https://github.com/shadowsocks/shadowsocks-windows/releases) |
| Linux | `ss-local` (bundled with `shadowsocks-libev`) |

---

## 🧪 Testing

### End-to-end test (on the server machine)

```bash
bash vpn-setup/test-native.sh
```

Starts a local `ss-server` + `ss-local`, curls through the SOCKS5 proxy, and verifies connectivity.

### Manual test with ss-local

```bash
ss-local -s YOUR_SERVER_IP -p YOUR_PORT -l 1080 -k "YOUR_PASSWORD" -m "chacha20-ietf-poly1305"

# In another terminal:
curl -x socks5h://127.0.0.1:1080 http://ifconfig.me
# Should print your server's public IP
```

---

## 🔧 Managing the Server

```bash
bash vpn-setup/setup-vpn.sh     # Start / restart server
```

Server config is persisted at `~/.shadowsocks-vpn/`:

| File | Content |
|------|---------|
| `server.conf` | Port and password |
| `ss-server.pid` | Process ID |
| `ss-server.log` | Server logs |
| `connection-info.txt` | Generated connection details & ss:// links |

View logs:
```bash
tail -f ~/.shadowsocks-vpn/ss-server.log
```

---

## 🏗️ Project Structure

```
├── vpn-setup/                 # Shell scripts for server management
│   ├── setup-vpn.sh            # Setup for macOS / Linux
│   ├── setup-vpn-windows.sh    # Setup for Windows (WSL2)
│   ├── start-vpn.sh            # Start the server
│   ├── stop-vpn.sh             # Stop the server
│   ├── status-vpn.sh           # Check server status + connections
│   └── test-native.sh          # End-to-end connectivity test
├── app/                        # Kotlin/JVM module (future Android client)
├── utils/                      # Shared Kotlin utilities module
├── buildSrc/                   # Gradle convention plugins
├── ANDROID_APP_SPEC.md         # Spec for building an Android Shadowsocks client
└── gradle/libs.versions.toml   # Dependency version catalog
```

### Kotlin/Gradle Build

```bash
./gradlew build          # Build all modules
./gradlew :app:run       # Run the JVM app
./gradlew :utils:test    # Run utils tests
```

Requires **Java 23** (auto-downloaded via Foojay toolchain plugin).

---

## ⚠️ Security Notes

- **Never commit credentials** to version control
- Share server details only via encrypted messaging (Signal, Telegram, WhatsApp)
- Rotate your password by deleting `~/.shadowsocks-vpn/server.conf` and re-running setup
- Your public IP may change — check with `curl ifconfig.me`

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't connect | Check port forwarding (TCP + UDP) |
| Connection drops | Ensure server machine isn't sleeping |
| Server not running | Run `bash vpn-setup/setup-vpn.sh` |
| Slow speed | Normal — traffic routes through your server |
| `ss-server` not found | Install via your package manager (see Prerequisites) |
| Blocked by firewall | Open the port in your OS firewall and router |

---

## 📱 Android App (Planned)

See `ANDROID_APP_SPEC.md` for a full specification to build a custom Android VPN client using:
- **VpnService** + TUN interface
- **sslocal** (shadowsocks-rust) + **tun2socks**
- Jetpack Compose UI

## License

MIT
