# 🪟 Windows 10 VPN Server Setup — Step by Step

> This guide assumes you have **nothing installed** except IntelliJ IDEA and you've cloned this repo.
> Follow every step **in order**. Don't skip anything.

---

## Step 1: Install WSL2 (Windows Subsystem for Linux)

WSL2 lets you run Linux inside Windows. The VPN server runs on Linux.

1. **Right-click** the Windows Start button (bottom-left corner) → click **"Windows Terminal (Admin)"** or **"PowerShell (Admin)"**
   - If you see a popup asking "Do you want to allow this app to make changes?" → click **Yes**

2. **Copy-paste** this command and press **Enter**:
   ```
   wsl --install -d Ubuntu
   ```

3. **Wait** — it will download Ubuntu. This takes 5–15 minutes depending on your internet.

4. When it's done, it will ask you to **restart your computer**. Do it.

5. After restart, a black window (Ubuntu terminal) will open automatically. If it doesn't:
   - Click Start → search for **"Ubuntu"** → open it

6. It will ask you to create a **username and password**:
   - Type a simple username (e.g. `user`) and press Enter
   - Type a password and press Enter (⚠️ you won't see the characters — that's normal, just type and press Enter)
   - Retype the password and press Enter
   - **Remember this password!** You'll need it for `sudo` commands

✅ You now have Linux running inside Windows.

---

## Step 2: Open Ubuntu Terminal

From now on, every command goes into the **Ubuntu terminal**.

To open it: Click **Start** → type **Ubuntu** → click to open.

You should see something like:
```
user@DESKTOP-EIBSFEK:~$
```

---

## Step 3: Install Required Software

Copy-paste these commands **one at a time** into the Ubuntu terminal. Press **Enter** after each one.

When it asks for your password, type the password you created in Step 1.

```bash
sudo apt update
```

Wait for it to finish, then:

```bash
sudo apt install -y shadowsocks-libev curl openssl git
```

Wait for it to finish (1–3 minutes).

To verify it worked:
```bash
ss-server --help
```

You should see a bunch of text starting with `shadowsocks-libev`. If you see "command not found", run the install command again.

---

## Step 4: Go to the Project Folder

Your Windows files are accessible from Ubuntu at `/mnt/c/`. You need to find where IntelliJ cloned the repo.

If the project is in `C:\Users\YourName\IdeaProjects\VPN`, then run:

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/IdeaProjects/VPN
```

> ⚠️ Replace `YOUR_WINDOWS_USERNAME` with your actual Windows username.
> Not sure what it is? Run this to find it:
> ```bash
> ls /mnt/c/Users/
> ```
> Look for your name in the list (ignore "Default" and "Public").

To confirm you're in the right folder:
```bash
ls
```

You should see files like `README.md`, `vpn-setup/`, `app/`, etc.

---

## Step 5: Run the Setup Script

```bash
bash vpn-setup/setup-vpn-windows.sh
```

This will:
- ✅ Start the VPN server
- ✅ Generate a random port and password
- ✅ Print your connection info and an `ss://` link
- ✅ Print PowerShell commands you need to run (next step)

**IMPORTANT:** At the end, it will print something like this:

```
==========================================
  ✅ VPN SERVER IS READY!
==========================================

Public IP:  203.0.113.55
WSL IP:     172.28.123.45
Port:       42587
Password:   aBcDeFgH12345678
Cipher:     chacha20-ietf-poly1305

=== ACCESS KEY ===
ss://xxxxxxxxxxxx@203.0.113.55:42587#VPN-Home

==========================================
  ⚠️  WINDOWS FIREWALL — RUN IN POWERSHELL (AS ADMIN):
==========================================

  netsh interface portproxy add v4tov4 listenport=42587 ...
  netsh advfirewall firewall add rule name="Shadowsocks TCP" ...
  netsh advfirewall firewall add rule name="Shadowsocks UDP" ...
```

📸 **Take a screenshot** or **copy everything** — you'll need the `ss://` link later, and the PowerShell commands for the next step.

---

## Step 6: Open Windows Firewall

The VPN server is running inside WSL, but Windows blocks incoming connections by default. You need to open the port.

1. **Right-click** the Windows Start button → click **"Windows Terminal (Admin)"** or **"PowerShell (Admin)"**
   - Click **Yes** on the popup

2. **Copy-paste the 3 commands** that the setup script printed (from Step 5). They look like:

   ```powershell
   netsh interface portproxy add v4tov4 listenport=YOUR_PORT listenaddress=0.0.0.0 connectport=YOUR_PORT connectaddress=YOUR_WSL_IP
   ```
   ```powershell
   netsh advfirewall firewall add rule name="Shadowsocks TCP" dir=in action=allow protocol=TCP localport=YOUR_PORT
   ```
   ```powershell
   netsh advfirewall firewall add rule name="Shadowsocks UDP" dir=in action=allow protocol=UDP localport=YOUR_PORT
   ```

   > ⚠️ Use the **exact commands** the script printed — they have your actual port and IP filled in.

3. Each command should say `Ok.` — that means it worked.

---

## Step 7: Port Forwarding on Your Router

Your router blocks connections from the internet by default. You need to tell it to forward your VPN port to your computer.

1. Open a browser and go to your **router admin page**. Usually one of these:
   - `http://192.168.1.1`
   - `http://192.168.0.1`
   - `http://10.0.0.1`
   - Check the sticker on the bottom of your router for the address

2. Log in (default username/password is often `admin`/`admin` — check your router sticker)

3. Find **Port Forwarding** (might be under "Advanced", "NAT", or "Virtual Server")

4. Add a new rule:
   - **External Port**: your VPN port (from Step 5, e.g. `42587`)
   - **Internal IP**: your computer's local IP (find it: open PowerShell → type `ipconfig` → look for "IPv4 Address" under "Ethernet" or "Wi-Fi", e.g. `192.168.1.100`)
   - **Internal Port**: same as external port
   - **Protocol**: **Both** (TCP + UDP)

5. Save / Apply

---

## Step 8: Share the ss:// Link

Go back to the Ubuntu terminal. To see your connection info again:

```bash
cat ~/.shadowsocks-vpn/connection-info.txt
```

Copy the `ss://` link and send it via **WhatsApp, Telegram, or Signal** (not SMS) to whoever needs to connect.

---

## 📱 How the Other Person Connects (Android)

Tell them:

1. Download **v2rayNG** — https://github.com/2dust/v2rayNG/releases
   - Download the file ending in `.apk`
   - Open it → tap "Install" (they may need to allow "Install from unknown sources")
2. Open v2rayNG
3. Tap the **➕** button (top-right) → **"Import config from clipboard"**
   - Before this, they should **copy** the `ss://` link you sent them
4. Tap the **▶** play button at the bottom to connect
5. Open a browser → go to `whatismyip.com` → it should show **your** public IP

---

## 🔧 Daily Use — Start / Stop the Server

### Starting the server (after reboot or shutdown)

Every time you **restart your computer**, the VPN server stops. To start it again:

1. Open **Ubuntu** (Start → search "Ubuntu")
2. Run:
   ```bash
   cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/IdeaProjects/VPN
   bash vpn-setup/start-vpn.sh
   ```

### Stopping the server

```bash
bash vpn-setup/stop-vpn.sh
```

### Checking if it's running

```bash
bash vpn-setup/status-vpn.sh
```

---

## ⚠️ Important Things to Know

### Your computer must stay ON
- The VPN only works while your computer is **running** and **not sleeping**
- To prevent sleep: **Settings → System → Power & sleep → set Sleep to "Never"** (both on battery and plugged in)

### Your public IP might change
- If the person using your VPN says it stopped working, your IP probably changed
- Check your new IP:
  ```bash
  curl ifconfig.me
  ```
- Send them the new `ss://` link (re-run `bash vpn-setup/setup-vpn-windows.sh` to regenerate)

### WSL might get a new IP after reboot
- If VPN stops working after a reboot, the WSL IP might have changed
- Re-run the setup: `bash vpn-setup/setup-vpn-windows.sh`
- Then re-run the PowerShell firewall commands it prints

---

## 🆘 Troubleshooting

| Problem | What to do |
|---------|-----------|
| `wsl --install` says "not recognized" | Your Windows 10 needs updating. Go to Settings → Update & Security → Windows Update → install all updates |
| `ss-server: command not found` | Run `sudo apt install -y shadowsocks-libev` again |
| Script says "This script is meant for WSL2" | You're running it from PowerShell. Open **Ubuntu** terminal instead |
| Server starts but nobody can connect | Did you do Step 6 (firewall) and Step 7 (port forwarding)? |
| "curl: command not found" | Run `sudo apt install -y curl` |
| VPN works on local WiFi but not from outside | Port forwarding on your router isn't set up correctly (Step 7) |
| Everything was working, now it's not | Restart WSL: in PowerShell run `wsl --shutdown`, then open Ubuntu and run the start command again |
| The `ss://` link doesn't work in v2rayNG | Make sure you copied the **entire** link including `ss://` at the start |

