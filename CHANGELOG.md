# 📋 Changelog

All notable changes to this project will be documented in this file.

---

## [v2.0.1] - 2026-06-06

### 🐛 Bug Fixes

#### Fixed Click Handling Issues
- **Fixed rapid click issue** causing unintended command execution
  - Added 200ms click cooldown (`CLICK_COOLDOWN`) to prevent rapid menu transitions
  - Prevents accidental double-clicks during menu animations
  - Each menu level now checks `(currentTime - lastClickTime) > CLICK_COOLDOWN` before processing clicks
  
- **Fixed Context Sub-Radial flow**
  - After executing ON/OFF command, menu now returns to Main Radial (not closing completely)
  - Flow: Main → Context Vehicle → Sub-Radial → Execute → **Back to Main**
  - User can immediately tap VEHICLE again to access context menu
  - Matches expected UX: quick access without full menu close/reopen

#### Technical Details
- Added `lastClickTime` tracking with `os.clock()`
- Applied cooldown check to all 5 menu levels:
  - Main Radial (Level 1)
  - Context Vehicle (Level 2)
  - Context Sub-Radial ON/OFF (Level 3)
  - Anim Category (Level 2)
  - Anim Items (Level 3)
- Cooldown timer resets on successful click to allow next interaction

---

## [v2.0.0] - 2026-06-06

### 🎉 MAJOR REDESIGN - PIE CHART RENDERING

Complete visual and technical overhaul with modern circular pie menu rendering, smooth animations, icon support, and adaptive config UI. This version merges proven rendering from PieMenuDemo.lua and modern config window from ConfigWindowRedesign.lua while preserving all existing functionality.

#### ✨ Added - New Rendering System
- **Pie Chart / Circular Sector Rendering** (from PieMenuDemo.lua)
  - True circular sectors rendered as filled arc segments (20 segments per sector)
  - Angle-based sector detection using `math.atan2()` for precise touch/click detection
  - 64-segment circles for smooth outer rings and backgrounds
  - Animated sector highlighting on hover (opacity changes based on hover state)
  - Sector divider lines with subtle transparency for visual separation
  - Full-screen dark overlay (40% opacity) with smooth fade in/out

- **Ease Animations** (optional ease.lua library)
  - `outCubic` easing for menu opening (accelerating start, smooth end)
  - `inCubic` easing for menu closing (smooth start, accelerating end)
  - 300ms animation duration for all transitions
  - Linear fallback if ease library not found (graceful degradation)
  - Animation scale clamping (skip render if scale < 0.01 for performance)

- **FontAwesome 6 Icons Support** (optional fAwesome6.lua)
  - XMARK icon (`faicons('XMARK')`) for center close button
  - Clean fallback to "X" text if fAwesome6 library not found
  - All icon rendering wrapped in pcall for safety
  - Ready for future sector-specific icon expansion

- **Modern Config Window Redesign** (from ConfigWindowRedesign.lua)
  - Adaptive window height per tab:
    - Tab 1 (MAIN): 250px - hamburger button settings
    - Tab 2 (ANIM): 380px - 8 visible animation rows
    - Tab 3 (VEH): 400px - IN-VEHICLE + ON-FOOT sections
    - Tab 4 (PROF): 280px - profile management
  - Clean modern styling with rounded corners (12px window, 6px frame)
  - Correct MonetLoader mimgui functions:
    - `PushStyleVarFloat()` - for single float style vars
    - `PushStyleVarVec2()` - for ImVec2 style vars
    - `PushStyleColor()` - applied ONCE before Begin, not per tab
  - Compact tab buttons with active indicator ("> TAB_NAME <")
  - Improved spacing (8px horizontal, 6px vertical)
  - Dark theme (0.08, 0.08, 0.1) with subtle accent colors
  - SAVE ALL button auto-closes window after saving

#### 🔧 Changed - Core Rendering
- **Replaced old radial menu rendering completely**
  - Old system: Square invisible button zones positioned on circle + DrawList decorations
  - New system: True circular pie chart with mathematical angle detection
  - Better touch accuracy on Android (no dead zones between sectors)
  - More intuitive visual feedback (sectors light up on hover)
  - Smoother animations (ease curves vs linear)

- **Menu overlay system**
  - Full-screen transparent overlay (0, 0) to (sw, sh)
  - Dark background (0, 0, 0, 0.4 * scale) fades with menu animation
  - Prevents game interaction while menu is open
  - Smooth fade in/out synchronized with menu scale

- **Hamburger button improvements**
  - Pulse animation using `math.sin(hamburgerPulse)` (continuous loop)
  - Outer glow effect with animated radius (15% size variation)
  - 3-line hamburger icon (80% width, 12% height lines, 25% spacing)
  - Clean white color (0xFFFFFFFF) for maximum visibility
  - Border and background with configurable opacity
  - Optimized rendering (16 segments for glow, 32 for main circle)

- **Center button (close/back)**
  - FontAwesome XMARK icon or text fallback
  - Hover effect (90% vs 60% opacity)
  - Color indicates function: red for CLOSE, cyan for BACK
  - 30px radius scaled with menu animation

#### ⚡ Performance Optimizations
- **Rendering optimizations**
  - Cached commonly used calculations (centerX, centerY, halfSize values)
  - Reduced redundant `imgui.CalcTextSize()` calls
  - Efficient sector detection (single angle calculation per frame)
  - Skip rendering when menuScale < 0.01
  - Hamburger glow uses 16 segments instead of 64 (sufficient for blur effect)

- **Animation efficiency**
  - Single `os.clock()` call per frame
  - Reuse menuScale across all menu levels
  - Clamp values to [0, 1] to prevent overshoot calculations

- **Draw call reduction**
  - Combined quad fills for arc segments (20 quads per sector)
  - Single AddCircleFilled for backgrounds
  - Minimized AddText calls (one per label)

#### 🐛 Fixed - MonetLoader Compatibility
- **CRITICAL FIX: Correct style functions**
  - Changed `imgui.PushStyleVar()` to `PushStyleVarFloat()` and `PushStyleVarVec2()`
  - Prevents crashes on MonetLoader Android (PushStyleVar not supported)
  - Removed per-tab `PushStyleColor()` switching (causes crash on rapid tab changes)
  - Applied styling ONCE before window Begin, Pop after End
  - All 5 color pushes and 4 var pushes properly balanced

- **Animation timing fixes**
  - Proper `os.clock()` usage instead of frame counting
  - Smooth transitions between menu levels (each transition resets menuOpenTime)
  - No animation glitches when rapidly opening/closing menus
  - Scale calculation handles both opening and closing states correctly

- **Config window stability**
  - SAVE ALL button now auto-closes window (prevents state confusion)
  - Tab switching no longer causes style stack imbalance
  - Adaptive window size prevents content overflow
  - All buffers properly sized (char[32], char[64], char[128])

#### 📦 Dependencies (Safe Loading with pcall)
- `mimgui` - Required (base UI library)
- `inicfg` - Required (config file storage)
- `ease` - Optional (smooth animations, fallback to linear if not found)
- `fAwesome6` - Optional (icons, fallback to text if not found)
- `notifications` - Optional (toast notifications, fallback to chat messages)

All optional libraries wrapped in `pcall()` with feature flags (`ease_loaded`, `fa_loaded`, `notif_loaded`)

#### 🔄 Preserved Features (100% Backward Compatible)
- ✅ All existing logic from v1.2.0 maintained
- ✅ Profile system (unlimited profiles, auto-save to separate .ini files)
- ✅ Server auto-detection (maps IP to profile, auto-loads on connect)
- ✅ Context detection (in-vehicle vs on-foot, different command sets)
- ✅ ON/OFF toggle system with state memory (lock/unlock, open/close, on/off)
- ✅ CtxVeh commands (4 slots for IN-VEHICLE context)
- ✅ CtxFoot commands (4 slots for ON-FOOT context)
- ✅ Animation management (21 slots, category-based, pagination)
- ✅ Vehicle management (21 slots, category-based, pagination)
- ✅ Category organization (4 anim categories, 4 vehicle categories)
- ✅ Pagination support (4 items per page, NEXT/PREV navigation)
- ✅ Auto-close on dialog active (prevents menu overlap with server dialogs)
- ✅ Chat commands (`/rcmdf`, `/rprofile list/load/save/create/map/current`)
- ✅ Config persistence (RadialMenuConfig.ini, RadialMenuProfiles.ini)

#### 🎨 Visual Improvements
- **Color-coded sectors** with configurable alpha (hover = 0.6, normal = 0.2)
- **Smooth transitions** between all menu levels (main → context → sub-radial)
- **Better label visibility** (0.9 opacity text on dark sectors)
- **Title indicators** show current context ([MAIN], [QUICK VEH], [ANIM], etc.)
- **Page indicators** for paginated menus ("Page 1/3")
- **Disabled state visualization** (grey = 0x55FFFFFF, enabled = 0xFFFFFFFF)
- **Hover feedback** (labels brighten, sectors lighten)

#### 📝 Technical Notes
- **Tested on MonetLoader Android** - All rendering and animation confirmed working
- **Reference files preserved** - PieMenuDemo.lua and ConfigWindowRedesign.lua remain in testing/ folder as documentation
- **Config file compatibility** - All existing .ini files work without migration
- **Safe library loading** - Script runs with or without optional libraries
- **No breaking changes** - Drop-in replacement for v1.2.0

#### 🔄 Migration Notes
- **No action required** - Simply replace RadialMenu.lua with v2.0
- **Optional libraries** - Install `ease.lua` and `fAwesome6.lua` for enhanced experience
- **Existing configs** - All settings, profiles, and server mappings preserved
- **Command changes** - None (all commands work identically)

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
