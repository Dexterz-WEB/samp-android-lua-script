# 📋 Changelog

All notable changes to this project will be documented in this file.

---

## [v1.3.0] - 2026-06-06

### 🎨 Major Update - Modern UI & Visual Enhancements

#### ✨ Added
- **Ease Animations System**
  - Smooth open/close transitions for all radial menus
  - Uses cubic easing functions (outCubic for opening, inCubic for closing)
  - 250ms animation duration with proper scaling
  - Individual animation tracking per menu (main, category, animations, vehicles, context)
  - Graceful fallback when ease library is not available

- **FontAwesome Icons Support**
  - Icon display above menu labels for better visual recognition
  - Support for FontAwesome 6 icons (via fAwesome6 library)
  - Text-based fallback icons when library not available
  - Icons for main sectors (Vehicle, Anim, etc.)
  - Icons for context commands (Lock, Engine, Lights, Trunk, Hood)
  - Icon field added to configuration structure

- **Toast Notifications System**
  - Modern toast notifications for user feedback
  - Uses Notifications library with graceful fallback to chat
  - Notification types: OK (green), ERROR (red), INFO (blue), WARNING (orange)
  - Notifications for: command execution, profile operations, config save, server mapping
  - Configurable duration per notification

- **Modern UI Styling**
  - Rounded windows and buttons (8-10px window rounding, 4-5px frame rounding)
  - Custom color scheme with dark blue theme
  - Gradient title bars for windows and dialogs
  - Custom padding and spacing for better readability
  - Outer glow effect on radial menus
  - Subtle border highlights on menu circles

- **Pie Chart / Arc Rendering**
  - Filled arc segments for sector highlighting
  - Real-time hover detection on radial menu sectors
  - Colored sector highlights (Blue, Orange, Pink, Green)
  - Smooth quad-based triangulation for arc rendering
  - Interactive hover feedback with 27% opacity overlays

- **Safe Library Loading**
  - Protected loading with pcall for optional libraries
  - Prevents crashes when libraries are not installed
  - Libraries: ease, fAwesome6, notifications
  - Graceful degradation with fallback features

#### 🔧 Changed
- Radial menu rendering now supports hover effects
- `drawRadialMenu()` function now returns both pressed and hovered sector
- Profile loading/saving now uses notification system instead of direct chat
- Config save operations now show toast notifications
- Enhanced visual feedback for all user interactions

#### ⚡ Optimized
- Menu scale calculation with proper animation timing
- Hover state tracking per menu for smooth interactions
- Icon rendering with centered positioning
- Arc segment rendering with configurable segment count

#### 🎨 Visual Improvements
- Config window: dark theme with rounded corners and gradient title
- New Server Dialog: modern styling with 10px rounding
- Radial menus: outer glow, subtle borders, and sector highlights
- Buttons: rounded with hover states and active feedback
- Icons: displayed above labels with proper spacing

#### 📝 Technical Details
- Animation state: `menuOpenTime`, `menuScale`, `menuHovered` tracking
- Helper functions: `getEase()`, `clamp()`, `updateMenuAnimation()`
- Icon system: `getIcon()`, `drawLabelWithIcon()`
- Notification: `showNotification()` with type and duration support
- Arc rendering: `drawFilledArc()`, `drawSectorHighlight()`

---

## [v1.2.0] - 2026-06-04

### 🎉 Major Update - Profile System & Auto-detection

#### ✨ Added
- **Multiple Profiles System**
  - Unlimited profile support
  - Each profile stored in separate .ini file
  - Profile-specific configurations (animations, vehicles, settings)
  - Easy profile switching via UI

- **Auto-detect Server**
  - Automatic server detection by IP address
  - Server-to-profile mapping system
  - Auto-load profile when connecting to mapped server
  - Toggle auto-detect on/off

- **ImGui Dialog for New Servers**
  - Professional popup dialog when detecting new server
  - Shows server name and IP
  - Auto-suggests profile name (sanitized from server name)
  - Editable profile name before creation
  - Clear action buttons (CREATE & MAP or USE DEFAULT)
  - Non-intrusive design

- **Profile Management Tab (Tab 4)**
  - Current profile & server info display
  - Create new profile section
  - Map server to profile section (2 options)
  - List of available profiles with Load buttons
  - Visual indicators for active profile
  - Show mapped servers per profile
  - Tips and instructions

- **Profile Commands** (Optional, UI is primary)
  - `/rprofile list` - List all profiles
  - `/rprofile load <name>` - Load specific profile
  - `/rprofile create <name>` - Create new profile
  - `/rprofile map <name>` - Map current server to profile
  - `/rprofile current` - Show current profile info

#### 🔧 Changed
- Configuration window now has 4 tabs (added Profiles tab)
- Tab buttons width adjusted to fit 4 tabs
- Profile system replaces single global config
- Auto-load on server connect (if mapped)

#### 📁 Files Added
- `RadialMenuProfiles.ini` - Profile settings & server mappings
- `RadialMenu_<profilename>.ini` - Individual profile configs

---

## [v1.1.0] - 2026-06-04

### 🔄 Refactor & Optimization Update

#### ✨ Added
- Single unified command `/rcmdf` with tab system
- Optional parameters: `/rcmdf 2` (anim), `/rcmdf 3` (veh)
- Tab-based UI (3 tabs: Main, Animations, Vehicles)

#### 🔧 Changed
- **Merged 3 commands into 1**
  - Old: `/rcmdf`, `/rcmdanim`, `/rcmdveh`
  - New: `/rcmdf` with tabs
- Improved UI layout
  - Simple tab buttons
  - Clear section headers
  - Better spacing and organization

#### ⚡ Optimized
- **Smart save system**
  - Only rebuilds animation/vehicle lists if data changed
  - Prevents unnecessary processing
  - Faster save operations

- **Better error handling**
  - Added nil checks in `executeCommand()`
  - Type validation for commands
  - Returns success/failure boolean

- **Code cleanup**
  - Removed redundant `tostring()` calls
  - Fixed undefined variable references
  - Improved variable naming

#### 🐛 Fixed
- Crash on line 519 (undefined `lbls` variable)
- Crash from `PushID`/`PopID` (not supported in MoonLoader Android)
- Potential crashes from nil commands
- Empty sector name validation issues

---

## [v1.0.0] - Initial Release

### 🎉 Initial Features

#### ✨ Core Features
- **Multi-level Radial Menu**
  - 4-sector circular menu design
  - 3-level navigation (Main → Categories → Items)
  - Smooth transitions between levels
  - Center button for back navigation

- **Configuration System**
  - Main settings panel (`/rcmdf`)
  - Animation editor (`/rcmdanim`)
  - Vehicle editor (`/rcmdveh`)
  - INI-based configuration storage
  - Auto-save functionality

- **Animation Management**
  - 21 customizable animation slots
  - Category-based organization
  - Custom labels and commands
  - Pagination (4 items per page)

- **Vehicle Management**
  - 21 customizable vehicle slots
  - Category-based organization
  - Custom labels and commands
  - Pagination (4 items per page)

- **Toggle State System**
  - Smart ON/OFF detection
  - State memory per category
  - Auto-disable opposite action
  - Visual feedback (grayed out when disabled)

- **UI Features**
  - Draggable menu button
  - Position sliders (X, Y)
  - Sector name customization
  - Category name customization
  - Scrollable editors

#### 🎨 Design
- Circular radial menu (135px outer, 50px inner)
- Auto-centered labels with word wrap
- Color-coded sections
- Invisible button zones for clicking
- Modern minimalist design

#### ⚙️ Technical
- mimgui for UI rendering
- inicfg for configuration storage
- Background draw list for radial menu
- Sector-based invisible buttons
- Category filtering system

---

## 📝 Version Format

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)

---

## 🔗 Links

- **Repository:** [github.com/Dexterz-WEB/samp-android-lua-script](https://github.com/Dexterz-WEB/samp-android-lua-script)
- **Issues:** [Report bugs](https://github.com/Dexterz-WEB/samp-android-lua-script/issues)
- **Discussions:** [Feature requests](https://github.com/Dexterz-WEB/samp-android-lua-script/discussions)

---

**Made with ❤️ by OnlyDexterZ**
