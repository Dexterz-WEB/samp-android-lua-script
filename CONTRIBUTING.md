# 🤝 Contributing to SAMP Android Lua Scripts

Thank you for considering contributing to this project! We welcome contributions from everyone.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)

---

## 📜 Code of Conduct

This project follows a simple code of conduct:
- **Be respectful** to all contributors
- **Be constructive** in feedback
- **Be patient** with responses
- **Be helpful** to newcomers

---

## 🎯 How Can I Contribute?

There are many ways to contribute:

### 1. **Report Bugs** 🐛
Found a bug? Please report it! See [Reporting Bugs](#reporting-bugs).

### 2. **Suggest Features** 💡
Have an idea? We'd love to hear it! See [Suggesting Features](#suggesting-features).

### 3. **Submit Code** 💻
Want to fix a bug or add a feature? See [Pull Requests](#pull-requests).

### 4. **Improve Documentation** 📝
Help us make the docs better! Fix typos, add examples, clarify instructions.

### 5. **Share Configurations** ⚙️
Create preset configs for specific servers or use cases.

### 6. **Test & Provide Feedback** 🧪
Test new features, report issues, suggest improvements.

---

## 🐛 Reporting Bugs

**Before reporting:**
1. Check if the bug is already reported in [Issues](https://github.com/Dexterz-WEB/samp-android-lua-script/issues)
2. Make sure you're using the latest version
3. Try to reproduce the bug

**When reporting, include:**
- **Script version** (check CHANGELOG.md)
- **MoonLoader version**
- **Android version** and device model
- **Server** you were connected to (if relevant)
- **Steps to reproduce** the bug
- **Error message** (from moonloader.log)
- **Screenshots** (if helpful)

**Example bug report:**
```markdown
**Bug:** Script crashes when clicking sector 2

**Environment:**
- Script: v1.2.0
- MoonLoader: Android v26.5
- Device: Samsung Galaxy S10, Android 11

**Steps to reproduce:**
1. Open radial menu
2. Click sector 2 (HEAL)
3. Game crashes

**Error message:**
```
RadialMenu.lua:123: attempt to index nil value
```

**Expected behavior:**
Should execute /heal command
```

---

## 💡 Suggesting Features

**Before suggesting:**
1. Check if feature is already requested
2. Check if it's already in development (ROADMAP in README)
3. Consider if it fits the project scope

**When suggesting, include:**
- **Clear description** of the feature
- **Use case** - why is it useful?
- **Example** of how it would work
- **Mockup/screenshot** (optional but helpful)

**Example feature request:**
```markdown
**Feature:** Export/Import Profile

**Description:**
Add ability to export profile to a shareable file and import from file.

**Use case:**
Players want to share their configurations with friends or backup configs.

**How it would work:**
1. Tab 4 → Export button
2. Creates .json file with profile data
3. User shares file
4. Other user: Import button → select file → profile created

**Benefits:**
- Easy config sharing
- Backup/restore capability
- Community preset configs
```

---

## 🔧 Pull Requests

### **Before You Start:**

1. **Open an issue first** (for major changes)
   - Discuss the change with maintainers
   - Get feedback on approach
   - Avoid wasted effort

2. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub
   ```

3. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/samp-android-lua-script.git
   cd samp-android-lua-script
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/my-awesome-feature
   # or
   git checkout -b fix/bug-description
   ```

### **Making Changes:**

1. **Follow coding guidelines** (see below)
2. **Test thoroughly** on actual device/emulator
3. **Update documentation** if needed
4. **Add yourself to credits** (optional)

### **Commit Messages:**

Use clear, descriptive commit messages:

```bash
# Good ✅
git commit -m "Add export profile feature"
git commit -m "Fix crash when clicking empty sector"
git commit -m "Update README with profile system docs"

# Bad ❌
git commit -m "fix"
git commit -m "update"
git commit -m "changes"
```

**Format:**
```
<type>: <short description>

<optional longer description>
<optional list of changes>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Testing changes
- `chore:` Maintenance tasks

### **Submitting PR:**

1. **Push to your fork**
   ```bash
   git push origin feature/my-awesome-feature
   ```

2. **Open Pull Request** on GitHub
   - Clear title describing the change
   - Reference related issues (#123)
   - Describe what changed and why
   - Include screenshots if UI changes

3. **Respond to feedback**
   - Be open to suggestions
   - Make requested changes
   - Update PR as needed

---

## 🛠️ Development Setup

### **Requirements:**
- Text editor (VS Code, Sublime, Notepad++, etc.)
- Android device with:
  - GTA SA installed
  - MoonLoader installed
  - USB debugging enabled (for file transfer)
- Basic Lua knowledge

### **Setup Steps:**

1. **Clone repository**
   ```bash
   git clone https://github.com/Dexterz-WEB/samp-android-lua-script.git
   ```

2. **Edit script**
   - Use your preferred editor
   - Make changes to `RadialMenu.lua`

3. **Test on device**
   - Copy to MoonLoader folder
   - Restart game or reload scripts
   - Test functionality

4. **Check logs**
   - If crash: check `moonloader.log`
   - Location: `/sdcard/Android/data/com.rockstargames.gtasa/`

---

## 📐 Coding Guidelines

### **General Principles:**

1. **Keep it simple**
   - Write clear, readable code
   - Avoid over-engineering
   - Comment complex logic

2. **Performance matters**
   - This runs on mobile devices
   - Optimize loops and checks
   - Avoid unnecessary processing

3. **Error handling**
   - Check for nil values
   - Validate user input
   - Fail gracefully

### **Lua Style Guide:**

```lua
-- Good ✅

-- Clear variable names
local currentProfile = "default"
local showConfigWindow = imgui.new.bool(false)

-- Functions with clear purpose
function loadProfile(profileName)
    if not profileName or profileName == "" then
        return false
    end
    -- ... rest of function
end

-- Comments for complex logic
-- Check if server IP is already mapped to a profile
local mappedProfile = profilesData.ServerMapping[serverIP]

-- Proper spacing
if condition then
    doSomething()
elseif otherCondition then
    doSomethingElse()
else
    doDefault()
end
```

```lua
-- Bad ❌

-- Unclear variable names
local x = "default"
local b = imgui.new.bool(false)

-- No error handling
function loadProfile(p)
    -- direct use without checking
    local data = inicfg.load(defaultStructure, p)
    iniData = data
end

-- No comments for complex logic
local m = profilesData.ServerMapping[s]

-- Poor spacing
if condition then doSomething() elseif other then doElse() end
```

### **Naming Conventions:**

```lua
-- Variables: camelCase
local playerHealth = 100
local currentServerIP = ""

-- Constants: UPPER_CASE
local MAX_ANIM_SLOTS = 21
local DEFAULT_PROFILE = "default"

-- Functions: camelCase
function saveProfile(profileName)
function isServerMapped(serverIP)

-- ImGui variables: camelCase
local showDialog = imgui.new.bool(false)
local profileInput = imgui.new.char[32]("")
```

---

## 🧪 Testing

### **Before Submitting PR:**

1. **Test basic functionality**
   - Does the script load without errors?
   - Can you open the menu?
   - Do buttons work?

2. **Test edge cases**
   - Empty inputs
   - Very long inputs
   - Special characters
   - Nil values

3. **Test on actual device**
   - Not just emulator
   - Test on different Android versions if possible
   - Test on different servers

4. **Check for crashes**
   - Review moonloader.log
   - No error messages
   - No memory leaks

### **Testing Checklist:**

```
[ ] Script loads without errors
[ ] Config window opens (/rcmdf)
[ ] All tabs accessible
[ ] Can create profile
[ ] Can load profile
[ ] Can map server
[ ] Radial menu opens
[ ] Buttons clickable
[ ] Commands execute
[ ] Auto-detect works
[ ] Dialog shows for new server
[ ] No crashes in moonloader.log
[ ] Performance is smooth
```

---

## 📞 Getting Help

**Need help contributing?**

- 💬 Open a [Discussion](https://github.com/Dexterz-WEB/samp-android-lua-script/discussions)
- 📧 Comment on existing Issues/PRs
- 📖 Read README.md and CHANGELOG.md

---

## 🎖️ Recognition

Contributors will be:
- Listed in README.md credits
- Mentioned in CHANGELOG.md
- Appreciated forever! ❤️

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing! 🙏**

**Made with ❤️ by the community**
