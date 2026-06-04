# 🎮 SAMP Android Lua Scripts

Professional Lua scripts collection for **SA-MP (San Andreas Multiplayer) Android** using **MoonLoader**.

Created by **OnlyDexterZ**

---

## 📦 Available Scripts

### 🎯 **Radial Menu** - Advanced Quick Access Menu

A powerful, multi-level radial menu system with profile management and auto-detection features.

**Perfect for:** Roleplay servers, Quick commands, Vehicle spawning, Animation shortcuts

---

## ✨ Features

### **🎯 Multi-Level Radial Menu**
- **4-sector circular menu** with customizable labels
- **3-level navigation:** Main → Categories → Items
- **Pagination system** (4 items per page)
- **Smooth navigation** between levels
- **Toggle state management** (ON/OFF commands like engine, lights)

### **📁 Multiple Profiles System**
- **Unlimited profiles** for different servers
- **Quick switching** between configurations
- **Separate .ini file** per profile
- **Profile-specific** animations & vehicles
- **Import/Export ready** (just share .ini file)

### **🔍 Auto-detect Server**
- **Automatic detection** when connecting to server
- **IP-based mapping** to profiles
- **Smart dialog** for new servers
- **One-time setup** per server
- **Auto-load** on reconnect

### **💬 User-Friendly Dialog**
- **ImGui popup** for new server detection
- **Editable profile names** before creation
- **Clear action buttons** (Create or Skip)
- **Visual feedback** on all actions
- **Non-intrusive** design

### **⚙️ Full UI Configuration**
- **4-tab interface:** Main / Animations / Vehicles / Profiles
- **No commands needed** (all clickable)
- **Real-time preview** of button position
- **21 customizable slots** for animations
- **21 customizable slots** for vehicles
- **Category-based organization**

---

## 🎮 Usage

### **Basic Commands:**

| Command | Description |
|---------|-------------|
| `/rcmdf` | Open configuration panel |
| `/rcmdf 2` or `/rcmdf anim` | Open to Animations tab |
| `/rcmdf 3` or `/rcmdf veh` | Open to Vehicles tab |
| `/rcmdf 4` or `/rcmdf profile` | Open to Profiles tab |

### **Advanced Commands (Optional):**

| Command | Description |
|---------|-------------|
| `/rprofile list` | List all profiles |
| `/rprofile load <name>` | Load specific profile |
| `/rprofile create <name>` | Create new profile |
| `/rprofile map <name>` | Map server to profile |
| `/rprofile current` | Show current profile info |

---

## 📖 Quick Start Guide

### **1️⃣ First Time Setup**

1. Install the script to MoonLoader folder
2. Connect to your server
3. **Dialog appears:** "New Server Detected"
4. Edit profile name (or use suggested)
5. Click **CREATE & MAP**
6. Done! Profile created & mapped

### **2️⃣ Configure Your Menu**

1. Type `/rcmdf` in chat
2. **Tab 1 (MAIN):** Set button position, sector names, categories
3. **Tab 2 (ANIM):** Add your animations (21 slots)
4. **Tab 3 (VEHICLE):** Add your vehicles (21 slots)
5. Click **SAVE ALL**

### **3️⃣ Use the Radial Menu**

1. Click the **[MENU]** button on screen
2. Navigate through sectors
3. Click center to go back
4. Use pagination for more items

### **4️⃣ Multiple Servers**

1. Connect to different server
2. Dialog appears for new server
3. Create separate profile
4. Configure for that server
5. Next connect: **Auto-loads** the right profile!

---

## 🎯 Example Workflows

### **Scenario 1: Roleplay Server Setup**

```
Step 1: Connect to "Valiant Roleplay"
→ Dialog: Create profile?
→ Name: "ValiantRP"
→ Click: CREATE & MAP

Step 2: Configure
→ /rcmdf → Tab 2 (Animations)
→ Add: /anim dance, /anim sit, /anim wave, etc.
→ Tab 3 (Vehicles)
→ Add: /v Sultan, /v Infernus, etc.
→ SAVE ALL

Step 3: Use
→ Click [MENU] button
→ Navigate to ANIM → Dance → Select animation
→ Or: VEHICLE → Car → Spawn vehicle

Step 4: Next Time
→ Reconnect to server
→ Auto-loads "ValiantRP" profile
→ No setup needed!
```

### **Scenario 2: Multiple Servers**

```
Server A: Valiant RP
→ Profile: "ValiantRP" 
→ Mapped: 139.99.12.34:7777

Server B: DM Indo
→ Profile: "DMServer"
→ Mapped: 192.168.1.1:7777

Connect to Server A → Loads "ValiantRP" ✅
Connect to Server B → Loads "DMServer" ✅

Each server has its own:
- Animations
- Vehicles  
- Categories
- Settings
```

---

## 📁 File Structure

```
moonloader/
├── RadialMenu.lua                    # Main script
├── RadialMenuProfiles.ini            # Profile settings & mappings
├── RadialMenu_default.ini            # Default profile
├── RadialMenu_ValiantRP.ini          # Profile for Valiant RP
├── RadialMenu_DMServer.ini           # Profile for DM Server
└── RadialMenu_<profilename>.ini      # Other profiles
```

**RadialMenuProfiles.ini:**
```ini
[Settings]
currentProfile=ValiantRP
autoDetectServer=true

[ServerMapping]
139.99.12.34:7777=ValiantRP
192.168.1.1:7777=DMServer
```

---

## ⚙️ Configuration Panel

### **Tab 1: MAIN CONFIG**
- Button position (X, Y sliders)
- Main sector names (4 sectors)
- Animation categories (4 categories)
- Vehicle categories (4 categories)

### **Tab 2: ANIMATIONS**
- 21 animation slots
- Format: `Label | Command | Category`
- Example: `Dance | /anim dance | Dance`
- Scrollable list

### **Tab 3: VEHICLES**
- 21 vehicle slots
- Format: `Label | Command | Category`
- Example: `Sultan | /v Sultan | Car`
- Scrollable list

### **Tab 4: PROFILES**
- Current profile display
- Current server info & mapping
- Auto-detect toggle
- Create new profile
- Map server to profile
- Load existing profiles
- Profile list with mappings

---

## 🎨 Customization

### **Profile Names:**
- Use alphanumeric characters
- Underscores and dashes allowed
- Auto-sanitized from server names
- Example: `Valiant Roleplay` → `Valiant_Roleplay`

### **Categories:**
Organize animations/vehicles by category:
- **Animations:** Dance, Action, Gangs, Misc
- **Vehicles:** Car, Bike, Boat, Air

### **Toggle States:**
Special labels for ON/OFF commands:
- **ON labels:** `on`, `open`, `start`, `buka`
- **OFF labels:** `off`, `close`, `stop`, `tutup`

When clicked, the script remembers state and disables the opposite button.

Example:
- Engine ON (enabled) → Engine OFF (disabled)
- Click OFF → Engine OFF (enabled) → Engine ON (disabled)

---

## 🔧 Advanced Features

### **Auto-detect Logic:**
1. Player connects to server
2. Script gets IP address
3. Check if IP is mapped to profile
4. **Mapped:** Auto-load profile
5. **Not mapped:** Show dialog

### **Profile Sanitization:**
Server names auto-converted to valid filenames:
```
"Valiant Roleplay" → "Valiant_Roleplay"
"[ID] SAMP Mobile RP" → "ID_SAMP_Mobile_RP"
"DM #1 Server!!!" → "DM_1_Server"
```

### **Smart Save:**
- Only rebuilds lists if data changed
- Validates input before saving
- Shows success/error messages
- Prevents data corruption

---

## 📥 Installation

### **Requirements:**
- ✅ GTA SA Android (v2.00 recommended)
- ✅ **MoonLoader for Android**
- ✅ **mimgui** library (usually included)
- ✅ **inicfg** library (usually included)

### **Installation Steps:**

1. **Download the script:**
   - Get `RadialMenu.lua` from this repository

2. **Copy to MoonLoader folder:**
   ```
   /sdcard/Android/data/com.rockstargames.gtasa/moonloader/
   ```

3. **Restart game or reload scripts**

4. **First run:**
   - Connect to your server
   - Dialog will appear for first-time setup
   - Follow the prompts

---

## 🐛 Troubleshooting

### **Script crashes on load:**
- ✅ Make sure MoonLoader is properly installed
- ✅ Check mimgui library is present
- ✅ Update MoonLoader to latest version

### **Dialog doesn't appear:**
- ✅ Check `autoDetectServer` is enabled (Tab 4)
- ✅ Make sure server IP is not already mapped
- ✅ Try `/rprofile current` to check status

### **Profile not auto-loading:**
- ✅ Verify server is mapped: `/rprofile list`
- ✅ Check auto-detect is ON (Tab 4)
- ✅ Reconnect to server

### **Button not visible:**
- ✅ Adjust position in Tab 1
- ✅ Check screen resolution compatibility
- ✅ Reset to default: X=1100, Y=140

---

## 🔄 Version History

### **v1.2** - Profile System (Current)
- ✅ Multiple profiles support
- ✅ Auto-detect server by IP
- ✅ ImGui dialog for new servers
- ✅ Full UI control (no commands needed)
- ✅ Profile management tab

### **v1.1** - Optimization
- ✅ Single command with tabs
- ✅ Code optimization
- ✅ Better error handling
- ✅ Smart save system

### **v1.0** - Initial Release
- ✅ Multi-level radial menu
- ✅ Animation & vehicle management
- ✅ Category system
- ✅ Toggle state management

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. **Report Bugs:** Open an issue with details
2. **Suggest Features:** Create a feature request
3. **Submit PR:** Fork, modify, and create pull request
4. **Share Configs:** Post your preset configurations

---

## 📄 License

**MIT License**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction.

See [LICENSE](LICENSE) file for details.

---

## 👤 Author

**OnlyDexterZ**

- GitHub: [@Dexterz-WEB](https://github.com/Dexterz-WEB)
- Repository: [samp-android-lua-script](https://github.com/Dexterz-WEB/samp-android-lua-script)

---

## ⚠️ Disclaimer

**Important Notice:**

- ✅ These scripts are for **educational and personal use**
- ✅ Use at your own risk on multiplayer servers
- ⚠️ Some servers may have **rules against client-side modifications**
- ⚠️ Check your server's rules before using
- ❌ Not responsible for bans or issues from server rules violations

---

## 🌟 Support This Project

If you find this script useful:

- ⭐ **Star this repository**
- 🍴 **Fork and contribute**
- 📢 **Share with friends**
- 💬 **Report bugs & suggest features**
- 📝 **Write a review or showcase**

---

## 📞 Contact & Support

**Need help?**
- 🐛 Bug reports: Open an [Issue](https://github.com/Dexterz-WEB/samp-android-lua-script/issues)
- 💡 Feature requests: Open a [Discussion](https://github.com/Dexterz-WEB/samp-android-lua-script/discussions)
- 📧 Direct contact: Via GitHub profile

---

## 🎯 Roadmap

**Planned Features:**
- [ ] Visual theme customization
- [ ] Sound effects on actions
- [ ] Keyboard shortcuts support
- [ ] Preset configuration packs
- [ ] Video/GIF demo
- [ ] Community config database

**Want a feature?** Open an issue or discussion!

---

## 🙏 Credits & Thanks

**Special thanks to:**
- MoonLoader developers
- mimgui library creators
- SAMP Mobile community
- All contributors and testers

---

**Made with ❤️ for the SAMP Mobile community**

**Enjoy your enhanced SAMP Android experience!** 🎮✨
