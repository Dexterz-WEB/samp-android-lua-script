# 📋 Changelog

All notable changes to this project will be documented in this file.

---

## [v2.0.0] - 2026-06-06

### 🎉 MAJOR REDESIGN - PIE CHART RENDERING

#### ✨ Added - New Rendering System
- **Pie Chart / Circular Sector Rendering** (from PieMenuDemo.lua)
  - Smooth circular sectors with gradient fills
  - Angle-based sector detection (no more invisible buttons)
  - 64-segment circles for smooth edges
  - 20-segment arc fills per sector
  - Animated sector highlighting on hover
  - Sector divider lines with transparency

- **Ease Animations** (optional ease.lua library)
  - `outCubic` easing for menu opening
  - `inCubic` easing for menu closing
  - Smooth scale transitions (0.3s duration)
  - Fallback to linear animation if ease library not found

- **FontAwesome 6 Icons Support** (optional fAwesome6.lua)
  - XMARK icon for close button in center
  - Fallback to "X" text if library not found
  - Ready for sector icon support in future updates

- **Modern Config Window Redesign** (from ConfigWindowRedesign.lua)
  - Adaptive window sizing per tab (250-400px height)
  - Clean modern styling with rounded corners
  - Correct MonetLoader mimgui functions:
    - `PushStyleVarFloat()` - for float style vars
    - `PushStyleVarVec2()` - for Vec2 style vars
    - `PushStyleColor()` - for colors (NO per-tab switching)
  - Compact tab buttons (4 tabs fit cleanly)
  - Improved spacing and visual hierarchy

#### 🔧 Changed - Core Rendering
- **Replaced old radial menu rendering**
  - Old: Square invisible button zones + DrawList decorations
  - New: True circular pie chart with angle detection
  - Better touch accuracy on Android
  - More intuitive visual feedback

- **Menu overlay system**
  - Full-screen dark overlay (40% opacity * scale)
  - Smooth fade in/out with animations
  - Better visual separation from game

- **Hamburger button improvements**
  - Pulse animation with sine wave
  - Outer glow effect (animated radius)
  - 3-line icon (white, clean design)
  - Better visibility on all backgrounds

#### ⚡ Performance Optimizations
- Cached commonly used values in rendering
- Reduced draw calls per frame
- Efficient sector detection algorithm
- Animation scale clamping (skip render if scale < 0.01)

#### 🐛 Fixed - MonetLoader Compatibility
- **CRITICAL FIX: Correct style functions**
  - Changed `PushStyleVar()` to `PushStyleVarFloat()` and `PushStyleVarVec2()`
  - Prevents crashes on MonetLoader Android
  - Removed per-tab color switching (crash issue)
  - Applied same styling to all tabs safely

- **Animation timing fixes**
  - Proper `os.clock()` usage for animations
  - Smooth transitions between menu levels
  - No animation glitches or stuttering

#### 📦 Dependencies (All Optional)
- `mimgui` - Required (base library)
- `inicfg` - Required (config storage)
- `ease` - Optional (smooth animations, fallback to linear)
- `fAwesome6` - Optional (icons, fallback to text)

#### 🔄 Preserved Features
- ✅ All existing logic from v1.2.0
- ✅ Profile system (unlimited profiles, server auto-detect)
- ✅ Context detection (in-vehicle vs on-foot)
- ✅ ON/OFF toggle system with state memory
- ✅ CtxVeh and CtxFoot commands
- ✅ Animation & vehicle management (21 slots each)
- ✅ Category-based organization
- ✅ Pagination support
- ✅ Auto-close on dialog active

#### 📝 Technical Notes
- Tested and confirmed working on MonetLoader Android
- PieMenuDemo.lua and ConfigWindowRedesign.lua remain in testing/ folder as reference
- Compatible with all existing config files (RadialMenuConfig.ini, RadialMenuProfiles.ini)

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
