-- ============================================================================
-- RADIAL MENU v2.0
-- Modern pie chart rendering with animations, icons, and adaptive config UI
-- ============================================================================

script_name("Radial Menu")
script_author("OnlyDexterZ")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'
local inicfg = require 'inicfg'

local ease_loaded = false
local ease = nil
pcall(function()
    ease = require 'ease'
    ease_loaded = true
end)

local fa_loaded = false
local faicons = nil
pcall(function()
    faicons = require 'fAwesome6'
    fa_loaded = true
end)

local notif_loaded = false
local Notifications = nil
pcall(function()
    require 'notifications'
    Notifications = _G.Notifications
    notif_loaded = true
end)

-- ============================================================================
-- CONFIG FILES
-- ============================================================================
local iniFileName = "RadialMenuConfig.ini"
local profilesFileName = "RadialMenuProfiles.ini"

-- ============================================================================
-- PROFILES & SERVER DETECTION
-- ============================================================================
local profilesData = inicfg.load({
    Settings = {
        currentProfile = "default",
        autoDetectServer = true,
    },
    ServerMapping = {},
}, profilesFileName)

if not profilesData then

    inicfg.save({
        Settings = { currentProfile = "default", autoDetectServer = true },
        ServerMapping = {},
    }, profilesFileName)
    profilesData = { Settings = { currentProfile = "default", autoDetectServer = true }, ServerMapping = {} }
end

local currentProfile = profilesData.Settings.currentProfile or "default"
local autoDetectServer = profilesData.Settings.autoDetectServer or true

-- ============================================================================
-- DEFAULT STRUCTURE
-- ============================================================================
local defaultStructure = {
    ButtonSettings = { posX = 1100.0, posY = 140.0 },
    HamburgerButton = { enabled = true, posX = 50.0, posY = 300.0, size = 80.0, alpha = 0.8 },
    CtxVeh1 = { name = "ENGINE", onCmd = "/engine", offCmd = "/engine" },
    CtxVeh2 = { name = "LOCK", onCmd = "/lock", offCmd = "/unlock" },
    CtxVeh3 = { name = "LIGHT", onCmd = "/lights", offCmd = "/lights" },
    CtxVeh4 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh5 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh6 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh7 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh8 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh9 = { name = "-", onCmd = "", offCmd = "" },
    CtxVeh10 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot1 = { name = "LOCK", onCmd = "/lock", offCmd = "/unlock" },
    CtxFoot2 = { name = "TRUNK", onCmd = "/trunk", offCmd = "/trunk" },
    CtxFoot3 = { name = "HOOD", onCmd = "/hood", offCmd = "/hood" },
    CtxFoot4 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot5 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot6 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot7 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot8 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot9 = { name = "-", onCmd = "", offCmd = "" },
    CtxFoot10 = { name = "-", onCmd = "", offCmd = "" },
    Sector1 = { name = "VEHICLE", cmd = "" },
    Sector2 = { name = "MAP",       cmd = "" },
    Sector3 = { name = "ANIM",    cmd = "" },
    Sector4 = { name = "-",       cmd = "" },
    CatSector1 = { name = "" }, CatSector2 = { name = "" },
    CatSector3 = { name = "" }, CatSector4 = { name = "" },
    VehCatSector1 = { name = "" }, VehCatSector2 = { name = "" },
    VehCatSector3 = { name = "" }, VehCatSector4 = { name = "" },
}
for i = 1, 21 do
    defaultStructure["Anim"..i] = { label = "", cmd = "", category = "" }
    defaultStructure["Veh"..i]  = { label = "", cmd = "", category = "" }
end

local iniData = inicfg.load(defaultStructure, iniFileName)
if not iniData then
    inicfg.save(defaultStructure, iniFileName)
    iniData = defaultStructure
end
for k, v in pairs(defaultStructure) do
    if not iniData[k] then iniData[k] = v end
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================

local showRadialMenu   = imgui.new.bool(false)
local showConfigWindow = imgui.new.bool(false)
local showCatRadial    = imgui.new.bool(false)
local showAnimRadial   = imgui.new.bool(false)
local showVehCatRadial = imgui.new.bool(false)
local showVehRadial    = imgui.new.bool(false)
local showContextVehRadial = imgui.new.bool(false)
local showCtxSubRadial = imgui.new.bool(false)

-- Full Map State
local fullMapMode = false
local fullMapOffsetX = 0
local fullMapOffsetY = 0
local fullMapZoom = 1.0
local fullMapDragging = false
local fullMapLastX = 0
local fullMapLastY = 0
local fullMapOpenTime = 0
local fullMapFocusPlayer = false
local fullMapFocusBtnLastClick = 0

-- Full Map Textures
local mapTexture = nil
local arrowTexture = nil

-- Full Map Player cached data
local cachedPlayerX = 0
local cachedPlayerY = 0
local cachedPlayerZ = 0
local cachedHeading = 0

-- Click debounce to prevent rapid menu transitions
local lastClickTime = 0
local CLICK_COOLDOWN = 0.2  -- 200ms cooldown between clicks

-- Animation state
local menuOpenTime = 0
local menuScale = 0
local activeMenu = nil  -- track which menu is open for animation

-- Config Window Tab State
local configTab = 1

-- Profile Management
local profileNameInput = imgui.new.char[32](currentProfile)
local autoDetectCheckbox = imgui.new.bool(autoDetectServer)
local availableProfiles = {}
local currentServerIP = ""
local currentServerName = ""

-- New Server Detection Dialog
local showNewServerDialog = imgui.new.bool(false)
local newServerDetected = { ip = "", name = "", suggestedProfileName = "" }
local newProfileNameInput = imgui.new.char[64]("")

local currentCategory    = ""
local animRadialPage     = 1
local animRadialList     = {}
local currentVehCategory = ""
local vehRadialPage      = 1
local vehRadialList      = {}

-- Context-aware vehicle radial
local contextVehCommands = {}

-- Context sub-radial (ON/OFF selection)
local ctxSubRadialItem = { name = "", onCmd = "", offCmd = "" }

-- Toggle state tracking
local toggleState = {}

local btnSliderX = imgui.new.float(iniData.ButtonSettings.posX or 1100.0)
local btnSliderY = imgui.new.float(iniData.ButtonSettings.posY or 140.0)

-- Hamburger Button Variables
local hamburgerEnabled = imgui.new.bool(iniData.HamburgerButton and iniData.HamburgerButton.enabled or true)
local hamburgerX = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.posX or 50.0)
local hamburgerY = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.posY or 300.0)

local hamburgerSize = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.size or 80.0)
local hamburgerAlpha = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.alpha or 0.8)
local hamburgerPulse = 0

-- Config edit buffers
local editName = {}
local editCmd = {}
local editCatName = {}
local editVehCatName = {}
for i = 1, 4 do
    editName[i] = imgui.new.char[32](iniData["Sector"..i].name or "")
    editCmd[i] = imgui.new.char[64](iniData["Sector"..i].cmd or "")
    editCatName[i] = imgui.new.char[32](iniData["CatSector"..i].name or "")
    editVehCatName[i] = imgui.new.char[32](iniData["VehCatSector"..i].name or "")
end

local MAX_ANIM_SLOTS = 21
local animEditLabel, animEditCmd, animEditCategory = {}, {}, {}
for i = 1, MAX_ANIM_SLOTS do
    local s = iniData["Anim"..i] or { label="", cmd="", category="" }
    animEditLabel[i]    = imgui.new.char[64](s.label    or "")
    animEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    animEditCategory[i] = imgui.new.char[32](s.category or "")
end

local MAX_VEH_SLOTS = 21
local vehEditLabel, vehEditCmd, vehEditCategory = {}, {}, {}
for i = 1, MAX_VEH_SLOTS do
    local s = iniData["Veh"..i] or { label="", cmd="", category="" }
    vehEditLabel[i]    = imgui.new.char[64](s.label    or "")
    vehEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    vehEditCategory[i] = imgui.new.char[32](s.category or "")
end

-- Context Vehicle Command Buffers
local ctxVehName, ctxVehOn, ctxVehOff = {}, {}, {}
for i = 1, 10 do
    local s = iniData["CtxVeh"..i] or { name = "", onCmd = "", offCmd = "" }
    ctxVehName[i] = imgui.new.char[32](s.name or "")
    ctxVehOn[i] = imgui.new.char[64](s.onCmd or "")
    ctxVehOff[i] = imgui.new.char[64](s.offCmd or "")
end

-- Context Foot Command Buffers
local ctxFootName, ctxFootOn, ctxFootOff = {}, {}, {}
for i = 1, 10 do
    local s = iniData["CtxFoot"..i] or { name = "", onCmd = "", offCmd = "" }
    ctxFootName[i] = imgui.new.char[32](s.name or "")
    ctxFootOn[i] = imgui.new.char[64](s.onCmd or "")
    ctxFootOff[i] = imgui.new.char[64](s.offCmd or "")
end


-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function getEase(easeFunc, x)
    if ease_loaded and ease and ease[easeFunc] then
        return ease[easeFunc](x)
    end
    return x  -- Fallback: linear
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize-1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r+1] = string.char(c)
    end
    return table.concat(r)
end

function closeAllRadial()
    showRadialMenu[0]   = false
    showCatRadial[0]    = false
    showAnimRadial[0]   = false
    showVehCatRadial[0] = false
    showVehRadial[0]    = false
    showContextVehRadial[0] = false
    showCtxSubRadial[0] = false
    menuOpenTime = os.clock()
end

function executeCommand(cmd)
    if cmd and cmd ~= "" and type(cmd) == "string" then 
        sampProcessChatInput(cmd)
        return true
    end
    return false
end

-- ============================================================================
-- PROFILE MANAGEMENT FUNCTIONS
-- ============================================================================
function getProfileFileName(profileName)
    return "RadialMenu_" .. profileName:gsub("[^%w_-]", "_") .. ".ini"
end

function sanitizeProfileName(serverName)
    local name = serverName
    name = name:gsub("[^%w%s_-]", "")
    name = name:gsub("%s+", "_")
    name = name:gsub("^_+", ""):gsub("_+$", "")

    local words = {}
    for word in name:gmatch("[^_%s]+") do
        table.insert(words, word)
        if #words >= 2 then break end
    end
    if #words > 0 then name = table.concat(words, "_") end
    if #name > 32 then name = name:sub(1, 32) end
    if name == "" then name = "server_" .. os.time() end
    return name
end

function isServerMapped(serverIP)
    if not serverIP or serverIP == "" then return false end
    return profilesData.ServerMapping[serverIP] ~= nil and profilesData.ServerMapping[serverIP] ~= ""
end

function showNewServerDetectionDialog(serverIP, serverName)
    newServerDetected.ip = serverIP
    newServerDetected.name = serverName
    newServerDetected.suggestedProfileName = sanitizeProfileName(serverName)
    local suggested = newServerDetected.suggestedProfileName
    for i = 0, 63 do newProfileNameInput[i] = 0 end
    for i = 1, #suggested do newProfileNameInput[i-1] = string.byte(suggested, i) end
    showNewServerDialog[0] = true
end

function loadProfile(profileName)
    if not profileName or profileName == "" then profileName = "default" end
    local fileName = getProfileFileName(profileName)
    local data = inicfg.load(defaultStructure, fileName)
    if not data then
        inicfg.save(defaultStructure, fileName)
        data = defaultStructure
    end
    for k, v in pairs(defaultStructure) do
        if not data[k] then data[k] = v end
    end
    iniData = data
    currentProfile = profileName
    profilesData.Settings.currentProfile = profileName
    inicfg.save(profilesData, profilesFileName)
    reloadEditBuffers()
    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile loaded: {FFFF00}" .. profileName, -1)
    return true
end

function saveProfile(profileName)
    if not profileName or profileName == "" then profileName = currentProfile end
    local fileName = getProfileFileName(profileName)
    if inicfg.save(iniData, fileName) then
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile saved: {FFFF00}" .. profileName, -1)
        return true
    end
    return false
end


function listProfiles()
    local profiles = {"default"}
    for k, v in pairs(profilesData.ServerMapping or {}) do
        if v and v ~= "" and v ~= "default" then
            local found = false
            for _, p in ipairs(profiles) do
                if p == v then found = true; break end
            end
            if not found then table.insert(profiles, v) end
        end
    end
    return profiles
end

function getServerInfo()
    if not sampIsLocalPlayerSpawned() then return nil, nil end
    local ip, port = sampGetCurrentServerAddress()
    if ip and port then
        return ip .. ":" .. port, sampGetCurrentServerName()
    end
    return nil, nil
end

function autoLoadProfileForServer()
    if not autoDetectServer then return false end
    local serverIP, serverName = getServerInfo()
    if not serverIP then return false end
    local mappedProfile = profilesData.ServerMapping[serverIP]
    if mappedProfile and mappedProfile ~= "" and mappedProfile ~= currentProfile then
        sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Auto-detected server: {FFFF00}" .. (serverName or serverIP), -1)
        return loadProfile(mappedProfile)
    elseif not mappedProfile or mappedProfile == "" then
        sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}New server detected!", -1)
        showNewServerDetectionDialog(serverIP, serverName or serverIP)
        return true
    end
    return false
end

function mapServerToProfile(serverIP, profileName)
    if not serverIP or serverIP == "" then return false end
    if not profileName or profileName == "" then profileName = currentProfile end
    profilesData.ServerMapping[serverIP] = profileName
    inicfg.save(profilesData, profilesFileName)
    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Server {FFFF00}" .. serverIP .. "{FFFFFF} mapped to profile: {FFFF00}" .. profileName, -1)
    return true
end

function reloadEditBuffers()
    btnSliderX[0] = iniData.ButtonSettings.posX or 1100.0
    btnSliderY[0] = iniData.ButtonSettings.posY or 140.0
    if iniData.HamburgerButton then
        hamburgerEnabled[0] = iniData.HamburgerButton.enabled or true
        hamburgerX[0] = iniData.HamburgerButton.posX or 50.0
        hamburgerY[0] = iniData.HamburgerButton.posY or 300.0

        hamburgerSize[0] = iniData.HamburgerButton.size or 80.0
        hamburgerAlpha[0] = iniData.HamburgerButton.alpha or 0.8
    end
    for i = 1, 4 do
        local name = iniData["Sector"..i].name or ""
        local cmd = iniData["Sector"..i].cmd or ""
        for j = 0, 31 do editName[i][j] = 0 end
        for j = 0, 63 do editCmd[i][j] = 0 end
        for j = 1, #name do editName[i][j-1] = string.byte(name, j) end
        for j = 1, #cmd do editCmd[i][j-1] = string.byte(cmd, j) end
    end
    for i = 1, 4 do
        local catName = iniData["CatSector"..i].name or ""
        local vehCatName = iniData["VehCatSector"..i].name or ""
        for j = 0, 31 do editCatName[i][j] = 0; editVehCatName[i][j] = 0 end
        for j = 1, #catName do editCatName[i][j-1] = string.byte(catName, j) end
        for j = 1, #vehCatName do editVehCatName[i][j-1] = string.byte(vehCatName, j) end
    end
    for i = 1, MAX_ANIM_SLOTS do
        local s = iniData["Anim"..i] or { label="", cmd="", category="" }
        for j = 0, 63 do animEditLabel[i][j] = 0 end
        for j = 0, 127 do animEditCmd[i][j] = 0 end
        for j = 0, 31 do animEditCategory[i][j] = 0 end
        for j = 1, #(s.label or "") do animEditLabel[i][j-1] = string.byte(s.label, j) end
        for j = 1, #(s.cmd or "") do animEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do animEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    for i = 1, MAX_VEH_SLOTS do
        local s = iniData["Veh"..i] or { label="", cmd="", category="" }
        for j = 0, 63 do vehEditLabel[i][j] = 0 end
        for j = 0, 127 do vehEditCmd[i][j] = 0 end
        for j = 0, 31 do vehEditCategory[i][j] = 0 end
        for j = 1, #(s.label or "") do vehEditLabel[i][j-1] = string.byte(s.label, j) end
        for j = 1, #(s.cmd or "") do vehEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do vehEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    for i = 1, 10 do
        local s = iniData["CtxVeh"..i] or { name = "", onCmd = "", offCmd = "" }
        for j = 0, 31 do ctxVehName[i][j] = 0 end
        for j = 0, 63 do ctxVehOn[i][j] = 0; ctxVehOff[i][j] = 0 end
        for j = 1, #(s.name or "") do ctxVehName[i][j-1] = string.byte(s.name, j) end
        for j = 1, #(s.onCmd or "") do ctxVehOn[i][j-1] = string.byte(s.onCmd, j) end
        for j = 1, #(s.offCmd or "") do ctxVehOff[i][j-1] = string.byte(s.offCmd, j) end
    end
    for i = 1, 10 do
        local s = iniData["CtxFoot"..i] or { name = "", onCmd = "", offCmd = "" }
        for j = 0, 31 do ctxFootName[i][j] = 0 end
        for j = 0, 63 do ctxFootOn[i][j] = 0; ctxFootOff[i][j] = 0 end
        for j = 1, #(s.name or "") do ctxFootName[i][j-1] = string.byte(s.name, j) end
        for j = 1, #(s.onCmd or "") do ctxFootOn[i][j-1] = string.byte(s.onCmd, j) end
        for j = 1, #(s.offCmd or "") do ctxFootOff[i][j-1] = string.byte(s.offCmd, j) end
    end
    rebuildAnimList()
    rebuildVehList()
end

-- ============================================================================
-- ANIMATION & VEHICLE LIST FUNCTIONS
-- ============================================================================
local animList = {}
function rebuildAnimList()
    animList = {}
    for i = 1, MAX_ANIM_SLOTS do
        local e = iniData["Anim"..i]
        if e and e.label ~= "" and e.category ~= "" then
            animList[#animList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildAnimList()

function loadAnimForCategory(cat)
    animRadialList = {}
    for _, a in ipairs(animList) do
        if a.category:lower() == cat:lower() then animRadialList[#animRadialList+1] = a end
    end
    animRadialPage = 1
end

function getAnimPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = animRadialList[s+i] end
    return r
end

function totalAnimPages() return math.max(1, math.ceil(#animRadialList / 4)) end

local vehList = {}
function rebuildVehList()
    vehList = {}
    for i = 1, MAX_VEH_SLOTS do
        local e = iniData["Veh"..i]
        if e and e.label ~= "" and e.category ~= "" then
            vehList[#vehList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildVehList()

function loadVehForCategory(cat)
    vehRadialList = {}
    for _, v in ipairs(vehList) do
        if v.category:lower() == cat:lower() then vehRadialList[#vehRadialList+1] = v end
    end
    vehRadialPage = 1
end


function getVehPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = vehRadialList[s+i] end
    return r
end

function totalVehPages() return math.max(1, math.ceil(#vehRadialList / 4)) end

-- ============================================================================
-- CONTEXT DETECTION
-- ============================================================================
function getOnFootCommands()
    local cmds = {}
    for i = 1, 10 do
        local s = iniData["CtxFoot"..i] or { name = "-", onCmd = "", offCmd = "" }
        cmds[i] = { name = s.name or "-", onCmd = s.onCmd or "", offCmd = s.offCmd or "" }
    end
    return cmds
end

function getInVehicleCommands()
    local cmds = {}
    for i = 1, 10 do
        local s = iniData["CtxVeh"..i] or { name = "-", onCmd = "", offCmd = "" }
        cmds[i] = { name = s.name or "-", onCmd = s.onCmd or "", offCmd = s.offCmd or "" }
    end
    return cmds
end

-- ============================================================================
-- SAVE CONFIG
-- ============================================================================
function saveAllConfig()
    iniData.ButtonSettings.posX = btnSliderX[0]
    iniData.ButtonSettings.posY = btnSliderY[0]
    if not iniData.HamburgerButton then iniData.HamburgerButton = {} end
    iniData.HamburgerButton.enabled = hamburgerEnabled[0]
    iniData.HamburgerButton.posX = hamburgerX[0]
    iniData.HamburgerButton.posY = hamburgerY[0]
    iniData.HamburgerButton.size = hamburgerSize[0]
    iniData.HamburgerButton.alpha = hamburgerAlpha[0]
    for i = 1, 4 do
        iniData["Sector"..i].name       = readCharBuffer(editName[i], 32)
        iniData["Sector"..i].cmd        = readCharBuffer(editCmd[i], 64)
        iniData["CatSector"..i].name    = readCharBuffer(editCatName[i], 32)
        iniData["VehCatSector"..i].name = readCharBuffer(editVehCatName[i], 32)
    end
    local animChanged = false
    for i = 1, MAX_ANIM_SLOTS do
        if not iniData["Anim"..i] then iniData["Anim"..i] = {} end
        local newLabel = readCharBuffer(animEditLabel[i], 64)
        local newCmd = readCharBuffer(animEditCmd[i], 128)
        local newCat = readCharBuffer(animEditCategory[i], 32)
        if iniData["Anim"..i].label ~= newLabel or iniData["Anim"..i].cmd ~= newCmd or iniData["Anim"..i].category ~= newCat then animChanged = true end

        iniData["Anim"..i].label = newLabel
        iniData["Anim"..i].cmd = newCmd
        iniData["Anim"..i].category = newCat
    end
    local vehChanged = false
    for i = 1, MAX_VEH_SLOTS do
        if not iniData["Veh"..i] then iniData["Veh"..i] = {} end
        local newLabel = readCharBuffer(vehEditLabel[i], 64)
        local newCmd = readCharBuffer(vehEditCmd[i], 128)
        local newCat = readCharBuffer(vehEditCategory[i], 32)
        if iniData["Veh"..i].label ~= newLabel or iniData["Veh"..i].cmd ~= newCmd or iniData["Veh"..i].category ~= newCat then vehChanged = true end
        iniData["Veh"..i].label = newLabel
        iniData["Veh"..i].cmd = newCmd
        iniData["Veh"..i].category = newCat
    end
    for i = 1, 10 do
        if not iniData["CtxVeh"..i] then iniData["CtxVeh"..i] = {} end
        iniData["CtxVeh"..i].name = readCharBuffer(ctxVehName[i], 32)
        iniData["CtxVeh"..i].onCmd = readCharBuffer(ctxVehOn[i], 64)
        iniData["CtxVeh"..i].offCmd = readCharBuffer(ctxVehOff[i], 64)
    end
    for i = 1, 10 do
        if not iniData["CtxFoot"..i] then iniData["CtxFoot"..i] = {} end
        iniData["CtxFoot"..i].name = readCharBuffer(ctxFootName[i], 32)
        iniData["CtxFoot"..i].onCmd = readCharBuffer(ctxFootOn[i], 64)
        iniData["CtxFoot"..i].offCmd = readCharBuffer(ctxFootOff[i], 64)
    end
    if inicfg.save(iniData, iniFileName) then
        if animChanged then rebuildAnimList() end
        if vehChanged then rebuildVehList() end
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Configuration saved!", -1)
        showConfigWindow[0] = false
        return true
    else
        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Failed to save config!", -1)
        return false
    end
end

-- ============================================================================
-- FULL MAP TEXTURE LOADING
-- ============================================================================
imgui.OnInitialize(function()
    pcall(function()
        mapTexture = imgui.CreateTextureFromFile("testing/map.png")
    end)
    pcall(function()
        arrowTexture = imgui.CreateTextureFromFile("testing/arrow.png")
    end)
end)

-- ============================================================================
-- FULL MAP HELPER FUNCTIONS
-- ============================================================================
local function getPlayerData()
    local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
    if ok and x then
        cachedPlayerX = x
        cachedPlayerY = y
        cachedPlayerZ = z
    end
    local ok2, h = pcall(getCharHeading, PLAYER_PED)
    if ok2 and h then
        cachedHeading = h
    end
end

local function worldToUV(wx, wy)
    local uvx = (wx + 3000) / 6000
    local uvy = 1.0 - (wy + 3000) / 6000
    return uvx, uvy
end

local function drawRotatedImage(draw_list, texture, cx, cy, size, angle, color)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    local half = size / 2
    local p1 = imgui.ImVec2(cx + (-half * cos_a - (-half) * sin_a), cy + (-half * sin_a + (-half) * cos_a))
    local p2 = imgui.ImVec2(cx + (half * cos_a - (-half) * sin_a), cy + (half * sin_a + (-half) * cos_a))
    local p3 = imgui.ImVec2(cx + (half * cos_a - half * sin_a), cy + (half * sin_a + half * cos_a))
    local p4 = imgui.ImVec2(cx + (-half * cos_a - half * sin_a), cy + (-half * sin_a + half * cos_a))
    draw_list:AddImageQuad(texture, p1, p2, p3, p4,
        imgui.ImVec2(0, 0), imgui.ImVec2(1, 0), imgui.ImVec2(1, 1), imgui.ImVec2(0, 1), color)
end

-- ============================================================================
-- FULL MAP RENDERING
-- ============================================================================
local function drawFullMap(draw_list)
    if not mapTexture then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = getScreenResolution() end)
    if sw == 0 or sh == 0 then sw, sh = 1280, 720 end

    -- Fullscreen window to block GTA SA camera/touch input
    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    imgui.Begin('##FullMapOverlay', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoBackground)
    imgui.End()

    local io = imgui.GetIO()
    local mx = io.MousePos.x
    local my = io.MousePos.y

    -- Background overlay
    draw_list:AddRectFilled(
        imgui.ImVec2(0, 0),
        imgui.ImVec2(sw, sh),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 0.7))
    )

    -- Get player UV position
    getPlayerData()
    local playerUVX, playerUVY = worldToUV(cachedPlayerX, cachedPlayerY)

    -- Calculate map display area (at zoom 1.0, map fits screen)
    local baseSize = math.min(sw, sh) * 0.9
    local mapDisplaySize = baseSize * fullMapZoom

    local mapX, mapY

    if fullMapFocusPlayer then
        -- Focus mode: center map on player position
        local playerScreenX = sw / 2 - playerUVX * mapDisplaySize
        local playerScreenY = sh / 2 - playerUVY * mapDisplaySize
        mapX = playerScreenX + fullMapOffsetX
        mapY = playerScreenY + fullMapOffsetY
    else
        -- Default centered mode: center map on screen, then apply drag offset
        mapX = (sw - mapDisplaySize) / 2 + fullMapOffsetX
        mapY = (sh - mapDisplaySize) / 2 + fullMapOffsetY
    end

    -- Drag limits: map edges cannot go past screen edges
    if mapDisplaySize <= sw then
        mapX = (sw - mapDisplaySize) / 2
        if not fullMapFocusPlayer then
            fullMapOffsetX = 0
        end
    else
        if mapX > 0 then
            mapX = 0
            if fullMapFocusPlayer then
                fullMapOffsetX = mapX - (sw / 2 - playerUVX * mapDisplaySize)
            else
                fullMapOffsetX = mapX - (sw - mapDisplaySize) / 2
            end
        end
        if mapX + mapDisplaySize < sw then
            mapX = sw - mapDisplaySize
            if fullMapFocusPlayer then
                fullMapOffsetX = mapX - (sw / 2 - playerUVX * mapDisplaySize)
            else
                fullMapOffsetX = mapX - (sw - mapDisplaySize) / 2
            end
        end
    end

    if mapDisplaySize <= sh then
        mapY = (sh - mapDisplaySize) / 2
        if not fullMapFocusPlayer then
            fullMapOffsetY = 0
        end
    else
        if mapY > 0 then
            mapY = 0
            if fullMapFocusPlayer then
                fullMapOffsetY = mapY - (sh / 2 - playerUVY * mapDisplaySize)
            else
                fullMapOffsetY = mapY - (sh - mapDisplaySize) / 2
            end
        end
        if mapY + mapDisplaySize < sh then
            mapY = sh - mapDisplaySize
            if fullMapFocusPlayer then
                fullMapOffsetY = mapY - (sh / 2 - playerUVY * mapDisplaySize)
            else
                fullMapOffsetY = mapY - (sh - mapDisplaySize) / 2
            end
        end
    end

    -- Draw the full map
    local pMin = imgui.ImVec2(mapX, mapY)
    local pMax = imgui.ImVec2(mapX + mapDisplaySize, mapY + mapDisplaySize)
    local colorU32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.95))
    draw_list:AddImage(mapTexture, pMin, pMax, imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), colorU32)

    -- Draw player arrow on full map
    if arrowTexture then
        local playerMapX = mapX + playerUVX * mapDisplaySize
        local playerMapY = mapY + playerUVY * mapDisplaySize
        local headingRad = -math.rad(cachedHeading)
        local arrowSz = fullMapFocusPlayer and 40 or 28
        local arrowColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1))
        drawRotatedImage(draw_list, arrowTexture, playerMapX, playerMapY, arrowSz, headingRad, arrowColor)
    end

    -- Handle drag (touch hold and move)
    if imgui.IsMouseDown(0) then
        if not fullMapDragging then
            fullMapDragging = true
            fullMapLastX = mx
            fullMapLastY = my
        else
            local dx = mx - fullMapLastX
            local dy = my - fullMapLastY
            fullMapOffsetX = fullMapOffsetX + dx
            fullMapOffsetY = fullMapOffsetY + dy
            fullMapLastX = mx
            fullMapLastY = my
        end
    else
        fullMapDragging = false
        -- In focus mode, reset offset every frame so map snaps back to player
        if fullMapFocusPlayer then
            fullMapOffsetX = 0
            fullMapOffsetY = 0
        end
    end

    -- Zoom controls (draw +/- buttons)
    local btnSize = 50
    local zoomInPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 - btnSize - 10)
    local zoomOutPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 + 10)

    -- Zoom In button
    draw_list:AddRectFilled(zoomInPos, imgui.ImVec2(zoomInPos.x + btnSize, zoomInPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local plusSize = imgui.CalcTextSize("+")
    draw_list:AddText(imgui.ImVec2(zoomInPos.x + (btnSize - plusSize.x) / 2, zoomInPos.y + (btnSize - plusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "+")

    -- Zoom Out button
    draw_list:AddRectFilled(zoomOutPos, imgui.ImVec2(zoomOutPos.x + btnSize, zoomOutPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local minusSize = imgui.CalcTextSize("-")
    draw_list:AddText(imgui.ImVec2(zoomOutPos.x + (btnSize - minusSize.x) / 2, zoomOutPos.y + (btnSize - minusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "-")

    -- Close button (top-right)
    local closeBtnPos = imgui.ImVec2(sw - btnSize - 20, 20)
    draw_list:AddRectFilled(closeBtnPos, imgui.ImVec2(closeBtnPos.x + btnSize, closeBtnPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.1, 0.1, 0.9)), 8)
    local xSize = imgui.CalcTextSize("X")
    draw_list:AddText(imgui.ImVec2(closeBtnPos.x + (btnSize - xSize.x) / 2, closeBtnPos.y + (btnSize - xSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "X")

    -- Focus Player button (below zoom buttons, right side)
    local focusBtnPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 + btnSize + 30)
    local focusBtnColor
    if fullMapFocusPlayer then
        focusBtnColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.7, 0.2, 0.9))
    else
        focusBtnColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.3, 0.3, 0.9))
    end
    draw_list:AddRectFilled(focusBtnPos, imgui.ImVec2(focusBtnPos.x + btnSize, focusBtnPos.y + btnSize),
        focusBtnColor, 8)
    local focusText = "F"
    local fSize = imgui.CalcTextSize(focusText)
    draw_list:AddText(imgui.ImVec2(focusBtnPos.x + (btnSize - fSize.x) / 2, focusBtnPos.y + (btnSize - fSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), focusText)

    -- Handle tap for buttons (X button, zoom, and focus)
    local mapCooldown = (os.clock() - fullMapOpenTime) > 0.3
    if imgui.IsMouseClicked(0) and mapCooldown then
        -- Focus Player button
        local focusCooldown = (os.clock() - fullMapFocusBtnLastClick) > 0.5
        if mx >= focusBtnPos.x and mx <= focusBtnPos.x + btnSize and my >= focusBtnPos.y and my <= focusBtnPos.y + btnSize and focusCooldown then
            fullMapFocusBtnLastClick = os.clock()
            fullMapFocusPlayer = not fullMapFocusPlayer
            if fullMapFocusPlayer then
                -- Activate focus mode: zoom to 3.5 and reset offset
                fullMapZoom = 3.5
                fullMapOffsetX = 0
                fullMapOffsetY = 0
            else
                -- Deactivate focus mode: keep current zoom, reset offset for centered mode
                fullMapOffsetX = 0
                fullMapOffsetY = 0
            end
            return
        end
        -- Zoom In
        if mx >= zoomInPos.x and mx <= zoomInPos.x + btnSize and my >= zoomInPos.y and my <= zoomInPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom + 0.3, 0.5, 5.0)
            return
        end
        -- Zoom Out
        if mx >= zoomOutPos.x and mx <= zoomOutPos.x + btnSize and my >= zoomOutPos.y and my <= zoomOutPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom - 0.3, 0.5, 5.0)
            return
        end
        -- Close button (X only)
        if mx >= closeBtnPos.x and mx <= closeBtnPos.x + btnSize and my >= closeBtnPos.y and my <= closeBtnPos.y + btnSize then
            fullMapMode = false
            return
        end
    end
end

-- ============================================================================
-- PIE CHART RENDERING SYSTEM
-- ============================================================================
function drawPieMenuBackground(draw_list, centerX, centerY, radius, scale)
    local bgAlpha = 0.85 * scale
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        radius + 40,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.12, bgAlpha)),
        64
    )
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        radius + 42,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * scale)),
        64,
        2
    )
end


function drawPieSector(draw_list, centerX, centerY, angle1, angle2, innerR, outerR, color, alpha, scale)
    local arcSegments = 20
    for seg = 0, arcSegments - 1 do
        local a1 = angle1 + (angle2 - angle1) * seg / arcSegments
        local a2 = angle1 + (angle2 - angle1) * (seg + 1) / arcSegments
        local p1 = imgui.ImVec2(centerX + math.cos(a1) * innerR, centerY + math.sin(a1) * innerR)
        local p2 = imgui.ImVec2(centerX + math.cos(a1) * outerR, centerY + math.sin(a1) * outerR)
        local p3 = imgui.ImVec2(centerX + math.cos(a2) * outerR, centerY + math.sin(a2) * outerR)
        local p4 = imgui.ImVec2(centerX + math.cos(a2) * innerR, centerY + math.sin(a2) * innerR)
        local fillColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color[1], color[2], color[3], alpha * scale))
        draw_list:AddQuadFilled(p1, p2, p3, p4, fillColor)
    end
end

function drawSectorDivider(draw_list, centerX, centerY, angle, innerR, outerR, scale)
    local lineStart = imgui.ImVec2(centerX + math.cos(angle) * innerR, centerY + math.sin(angle) * innerR)
    local lineEnd = imgui.ImVec2(centerX + math.cos(angle) * outerR, centerY + math.sin(angle) * outerR)
    draw_list:AddLine(lineStart, lineEnd,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * scale)),
        1.5
    )
end

function drawCenterButton(draw_list, centerX, centerY, centerR, centerHovered, scale, labelText, labelColor)
    local centerAlpha = centerHovered and (0.9 * scale) or (0.6 * scale)
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.22, centerAlpha)),
        32
    )
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.8, 0.5 * scale)),
        32,
        1.5
    )
    local closeIcon = fa_loaded and faicons('XMARK') or labelText
    local closeSize = imgui.CalcTextSize(closeIcon)
    draw_list:AddText(
        imgui.ImVec2(centerX - closeSize.x / 2, centerY - closeSize.y / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(labelColor[1], labelColor[2], labelColor[3], scale)),
        closeIcon
    )
end

function detectHoveredSector(mousePos, centerX, centerY, baseRadius, itemCount, startAngle, scale)

    local dx = mousePos.x - centerX
    local dy = mousePos.y - centerY
    local dist = math.sqrt(dx * dx + dy * dy)
    local sectorAngle = (2 * math.pi) / itemCount
    if dist > 30 * scale and dist < (baseRadius + 50) * scale then
        local mouseAngle = math.atan2(dy, dx)
        local normAngle = mouseAngle - startAngle
        if normAngle < 0 then normAngle = normAngle + 2 * math.pi end
        local sector = math.floor(normAngle / sectorAngle) + 1
        if sector > itemCount then sector = 1 end
        return sector, dist < 30 * scale
    end
    return -1, dist < 30 * scale
end

function drawPieMenu(draw_list, centerX, centerY, items, scale, titleText, titleColor)
    local baseRadius = 120 * scale
    local itemCount = #items
    local sectorAngle = (2 * math.pi) / itemCount
    local startAngle = -math.pi * 3/4
    local mousePos = imgui.GetIO().MousePos
    local hoveredSector, centerHovered = detectHoveredSector(mousePos, centerX, centerY, baseRadius, itemCount, startAngle, scale)
    
    drawPieMenuBackground(draw_list, centerX, centerY, baseRadius, scale)
    
    for i = 1, itemCount do
        if items[i] then
            local angle1 = startAngle + (i - 1) * sectorAngle
            local angle2 = startAngle + i * sectorAngle
            local midAngle = (angle1 + angle2) / 2
            local isHovered = (hoveredSector == i)
            local sectorAlpha = isHovered and 0.6 or 0.2
            local col = items[i].color or { 0.4, 0.4, 0.6 }
            local innerR = 35 * scale
            local outerR = (baseRadius + 35) * scale
            
            drawPieSector(draw_list, centerX, centerY, angle1, angle2, innerR, outerR, col, sectorAlpha, scale)
            drawSectorDivider(draw_list, centerX, centerY, angle1, innerR, outerR, scale)
            
            local iconDist = (innerR + outerR) / 2
            local iconX = centerX + math.cos(midAngle) * iconDist
            local iconY = centerY + math.sin(midAngle) * iconDist
            local labelText = items[i].label or "---"
            local labelSize = imgui.CalcTextSize(labelText)
            local labelAlpha = isHovered and scale or (0.7 * scale)
            local labelCol = items[i].labelColor or imgui.ImVec4(0.9, 0.9, 0.9, labelAlpha)
            if type(labelCol) == "number" then
                draw_list:AddText(
                    imgui.ImVec2(iconX - labelSize.x / 2, iconY - labelSize.y / 2),
                    labelCol,
                    labelText
                )
            else
                draw_list:AddText(
                    imgui.ImVec2(iconX - labelSize.x / 2, iconY - labelSize.y / 2),
                    imgui.ColorConvertFloat4ToU32(labelCol),
                    labelText
                )
            end
        end
    end

    
    local centerR = 30 * scale
    drawCenterButton(draw_list, centerX, centerY, centerR, centerHovered, scale, "X", titleColor or {1, 0.4, 0.4})
    
    if titleText and titleText ~= "" then
        local titleSize = imgui.CalcTextSize(titleText)
        draw_list:AddText(
            imgui.ImVec2(centerX - titleSize.x / 2, centerY - baseRadius - 50),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.8, 1.0, 0.8 * scale)),
            titleText
        )
    end
    
    return hoveredSector, centerHovered
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rcmdf{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. currentProfile, -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    sampRegisterChatCommand("rcmdf", function(param)
        showConfigWindow[0] = not showConfigWindow[0]
        if param == "anim" or param == "2" then
            configTab = 2
        elseif param == "veh" or param == "vehicle" or param == "3" then
            configTab = 3
        elseif param == "profile" or param == "4" then
            configTab = 4
        else
            configTab = 1
        end
    end)
    
    -- DEBUG COMMAND: Check animation config
    sampRegisterChatCommand("animdebug", function()
        sampAddChatMessage("{00FFFF}=== ANIMATION DEBUG ==={FFFFFF}", -1)
        sampAddChatMessage("{FFFF00}Categories:{FFFFFF}", -1)
        for i = 1, 4 do
            local catName = iniData["CatSector"..i].name or ""
            sampAddChatMessage(string.format("  Cat%d: '%s'", i, catName), -1)
        end
        sampAddChatMessage("{FFFF00}Animation Slots:{FFFFFF}", -1)
        local count = 0
        for i = 1, MAX_ANIM_SLOTS do
            local e = iniData["Anim"..i]
            if e and e.label ~= "" and e.category ~= "" then
                count = count + 1
                sampAddChatMessage(string.format("  Anim%d: Cat='%s' Lbl='%s' Cmd='%s'", i, e.category, e.label, e.cmd), -1)
            end
        end
        sampAddChatMessage(string.format("{00FF00}Total valid anims: %d{FFFFFF}", count), -1)
        sampAddChatMessage(string.format("{00FF00}animList size: %d{FFFFFF}", #animList), -1)
    end)
    
    sampRegisterChatCommand("rprofile", function(param)
        local args = {}
        for word in param:gmatch("%S+") do table.insert(args, word) end
        if #args == 0 or args[1] == "list" then
            local profiles = listProfiles()
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Available profiles:", -1)
            for _, p in ipairs(profiles) do
                local marker = (p == currentProfile) and "{00FF00}[ACTIVE]" or ""
                sampAddChatMessage("{FFFF00}" .. p .. " {FFFFFF}" .. marker, -1)
            end
        elseif args[1] == "load" and args[2] then
            loadProfile(args[2])
        elseif args[1] == "save" and args[2] then
            saveProfile(args[2])

        elseif args[1] == "create" and args[2] then
            loadProfile(args[2])
        elseif args[1] == "map" and args[2] then
            local serverIP, serverName = getServerInfo()
            if serverIP then
                mapServerToProfile(serverIP, args[2])
            else
                sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Not connected to server!", -1)
            end
        elseif args[1] == "current" then
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. currentProfile, -1)
            local serverIP, serverName = getServerInfo()
            if serverIP then
                sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Server: {FFFF00}" .. (serverName or serverIP), -1)
            end
        else
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Profile Commands:", -1)
            sampAddChatMessage("{FFFF00}/rprofile list {FFFFFF}- List all profiles", -1)
            sampAddChatMessage("{FFFF00}/rprofile load <name> {FFFFFF}- Load profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile save <name> {FFFFFF}- Save to profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile create <name> {FFFFFF}- Create new profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile map <name> {FFFFFF}- Map current server to profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile current {FFFFFF}- Show current profile", -1)
        end
    end)
    
    lua_thread.create(function()
        local lastCheckedIP = ""
        while true do
            wait(1000)
            if sampIsLocalPlayerSpawned() then
                local serverIP, serverName = getServerInfo()
                if serverIP and serverIP ~= lastCheckedIP then
                    lastCheckedIP = serverIP
                    currentServerIP = serverIP
                    currentServerName = serverName or serverIP
                    if autoDetectServer then
                        autoLoadProfileForServer()
                    end
                end
            end
        end
    end)

    imgui.OnFrame(function() return true end, function()
        local sw, sh = getScreenResolution()
        local draw_list = imgui.GetBackgroundDrawList()
        local cx, cy = sw / 2, sh / 2

        local dialogActive = false
        pcall(function() dialogActive = sampIsDialogActive() end)
        if dialogActive then
            if showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showVehCatRadial[0] or showVehRadial[0] or showContextVehRadial[0] or showCtxSubRadial[0] then
                closeAllRadial()
            end
        end

        -- FULL MAP RENDERING
        if fullMapMode then
            drawFullMap(draw_list)
            return
        end


        -- NEW SERVER DETECTION DIALOG
        if showNewServerDialog[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - 250, sh/2 - 150), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(500, 300))
            imgui.Begin("New Server Detected", showNewServerDialog, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
            imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "NEW SERVER DETECTED!")
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.Text("Server:"); imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), newServerDetected.name)
            imgui.Text("IP:"); imgui.SameLine()
            imgui.TextDisabled(newServerDetected.ip)
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "Create profile for this server?")
            imgui.Spacing()
            imgui.Text("Profile name:")
            imgui.SetNextItemWidth(-1)
            imgui.InputText("##newprofilename", newProfileNameInput, 64)
            imgui.TextDisabled("(You can edit the name before creating)")
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            if imgui.Button("CREATE & MAP", imgui.ImVec2(230, 40)) then
                local profileName = readCharBuffer(newProfileNameInput, 64)
                if profileName ~= "" then
                    loadProfile(profileName)
                    mapServerToProfile(newServerDetected.ip, profileName)
                    saveProfile(profileName)
                    showNewServerDialog[0] = false
                    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile created & mapped: {FFFF00}" .. profileName, -1)
                end
            end
            imgui.SameLine()
            if imgui.Button("USE DEFAULT", imgui.ImVec2(230, 40)) then
                showNewServerDialog[0] = false
                sampAddChatMessage("{FFFF00}[Radial Menu] {FFFFFF}Using current profile: {FFFF00}" .. currentProfile, -1)
            end
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "INFO:")
            imgui.TextDisabled("Creating a profile will auto-load it next time")
            imgui.TextDisabled("you connect to this server.")
            imgui.End()
        end


        -- CONFIG WINDOW
        if showConfigWindow[0] then
            local winW = 500
            local winH = 350
            if configTab == 2 then winH = 520 end
            if configTab == 3 then winH = 500 end
            if configTab == 4 then winH = 350 end
            
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
            imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
            
            imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))
            imgui.Begin("Radial Menu Config v2", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
            
            local tabW = (winW - 30) / 4
            local tabH = 30
            local tabLabels = {"1.MAIN", "2.ANIM", "3.VEH", "4.PROF"}
            for t = 1, 4 do
                local label = tabLabels[t]
                if configTab == t then label = "> " .. label .. " <" end
                if imgui.Button(label, imgui.ImVec2(tabW, tabH)) then configTab = t end
                if t < 4 then imgui.SameLine() end
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            
            if configTab == 1 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "HAMBURGER BUTTON")
                imgui.Spacing()
                imgui.Text("Position X:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##posX", hamburgerX, 0, sw - 100, "%.0f")
                imgui.Text("Position Y:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##posY", hamburgerY, 0, sh - 100, "%.0f")
                imgui.Spacing()
                imgui.Text("Size:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##size", hamburgerSize, 50, 150, "%.0f")
                imgui.Text("Opacity:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##opacity", hamburgerAlpha, 0.3, 1.0, "%.2f")
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.2, 1), "MAIN SECTORS")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Sector "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(120); imgui.InputText("Name##n"..i, editName[i], 32); imgui.SameLine()
                    if i == 1 or i == 3 then 
                        imgui.TextDisabled(i == 1 and "(vehicle menu)" or "(anim menu)")
                    else 
                        imgui.SetNextItemWidth(-1); imgui.InputText("Cmd##c"..i, editCmd[i], 64) 
                    end
                end
                


            elseif configTab == 2 then
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIM CATEGORIES")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(80); imgui.InputText("##ca"..i, editCatName[i], 32)
                    if i < 4 then imgui.SameLine() end
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIMATION COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##animscroll", imgui.ImVec2(-1, -50), true)
                for i = 1, MAX_ANIM_SLOTS do
                    imgui.PushItemWidth(100); imgui.InputText("##animcat"..i, animEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##animlbl"..i, animEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##animcmd"..i, animEditCmd[i], 128); imgui.PopItemWidth()
                end
                imgui.EndChild()
            elseif configTab == 3 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "IN-VEHICLE COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 10 do
                    imgui.PushItemWidth(100); imgui.InputText("##vn"..i, ctxVehName[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(150); imgui.InputText("##vo"..i, ctxVehOn[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(310)
                    imgui.PushItemWidth(-1); imgui.InputText("##vf"..i, ctxVehOff[i], 64); imgui.PopItemWidth()
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "ON-FOOT COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 10 do
                    imgui.PushItemWidth(100); imgui.InputText("##fn"..i, ctxFootName[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(150); imgui.InputText("##fo"..i, ctxFootOn[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(310)
                    imgui.PushItemWidth(-1); imgui.InputText("##ff"..i, ctxFootOff[i], 64); imgui.PopItemWidth()
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.2, 0.8, 0.4, 1), "VEHICLE COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##vehscroll", imgui.ImVec2(-1, -50), true)
                for i = 1, MAX_VEH_SLOTS do
                    imgui.PushItemWidth(100); imgui.InputText("##vc"..i, vehEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##vl"..i, vehEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##vcmd"..i, vehEditCmd[i], 128); imgui.PopItemWidth()
                end
                imgui.EndChild()

            elseif configTab == 4 then
                imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.8, 1), "PROFILE MANAGEMENT")
                imgui.Spacing()
                imgui.Text("Current Profile:"); imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), currentProfile)
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                if currentServerIP ~= "" then
                    imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "Current Server:")
                    imgui.Text(currentServerName)
                    imgui.TextDisabled(currentServerIP)
                    local mappedProfile = profilesData.ServerMapping[currentServerIP] or "none"
                    imgui.Text("Mapped to: " .. mappedProfile)
                else
                    imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "Not connected to server")
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                if imgui.Checkbox("Auto-detect server and load profile", autoDetectCheckbox) then
                    autoDetectServer = autoDetectCheckbox[0]
                    profilesData.Settings.autoDetectServer = autoDetectServer
                    inicfg.save(profilesData, profilesFileName)
                end
                imgui.TextDisabled("Automatically load profile when connecting")
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "CREATE NEW PROFILE:")
                imgui.SetNextItemWidth(300)
                imgui.InputText("##profilename", profileNameInput, 32)
                imgui.SameLine()
                if imgui.Button("Create", imgui.ImVec2(80, 25)) then
                    local pName = readCharBuffer(profileNameInput, 32)
                    if pName ~= "" then
                        loadProfile(pName)
                        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile created: " .. pName, -1)
                    end
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "LOAD PROFILE:")
                availableProfiles = listProfiles()
                imgui.SetNextItemWidth(300)
                if imgui.BeginCombo("##loadprofile", currentProfile) then
                    for _, pName in ipairs(availableProfiles) do
                        local isSelected = (pName == currentProfile)
                        if imgui.Selectable(pName, isSelected) then
                            loadProfile(pName)
                        end
                        if isSelected then imgui.SetItemDefaultFocus() end
                    end
                    imgui.EndCombo()
                end
                imgui.SameLine()
                if imgui.Button("Load", imgui.ImVec2(80, 25)) then
                    -- Already loaded via combo selection
                    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile active: {FFFF00}" .. currentProfile, -1)
                end
            end
            
            imgui.Spacing()
            if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 40)) then
                saveAllConfig()
            end
            
            imgui.End()
            imgui.PopStyleColor(5)
            imgui.PopStyleVar(4)
        end
        
        -- HAMBURGER BUTTON
        if not showConfigWindow[0] then
            local hbx = hamburgerX[0]
            local hby = hamburgerY[0]
            local hbs = hamburgerSize[0]
            local hba = hamburgerAlpha[0]
            local hbsHalf = hbs / 2
            local hCenterX = hbx + hbsHalf
            local hCenterY = hby + hbsHalf
            local hCenter = imgui.ImVec2(hCenterX, hCenterY)
            
            hamburgerPulse = (hamburgerPulse + 0.05) % (math.pi * 2)
            local hPulse = math.sin(hamburgerPulse) * 0.15 + 1.0
            local hGlowAlpha = math.floor(hba * 100 * (1.0 - (hPulse - 1.0) * 3))
            local hGlowColor = hGlowAlpha * 0x01000000 + 0x0044AAFF
            draw_list:AddCircleFilled(hCenter, hbsHalf * hPulse, hGlowColor, 16)
            
            local hBgAlpha = math.floor(hba * 220)
            draw_list:AddCircleFilled(hCenter, hbsHalf, hBgAlpha * 0x01000000 + 0x00222222, 32)
            
            local hBorderAlpha = math.floor(hba * 255)
            draw_list:AddCircle(hCenter, hbsHalf, hBorderAlpha * 0x01000000 + 0x0088DDFF, 32, 3.0)
            
            local hIconSize = hbs * 0.4
            local hIconAlpha = math.floor(hba * 255)
            local hIconColor = hIconAlpha * 0x01000000 + 0x00FFFFFF
            local hLineW = hIconSize * 0.8
            local hLineH = hIconSize * 0.12
            local hLineS = hIconSize * 0.25
            local hLineWHalf = hLineW / 2
            local hLineHHalf = hLineH / 2
            
            draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineWHalf, hCenterY - hLineS - hLineHHalf), imgui.ImVec2(hCenterX + hLineWHalf, hCenterY - hLineS + hLineHHalf), hIconColor, hLineHHalf)
            draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineWHalf, hCenterY - hLineHHalf), imgui.ImVec2(hCenterX + hLineWHalf, hCenterY + hLineHHalf), hIconColor, hLineHHalf)
            draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineWHalf, hCenterY + hLineS - hLineHHalf), imgui.ImVec2(hCenterX + hLineWHalf, hCenterY + hLineS + hLineHHalf), hIconColor, hLineHHalf)

            
            imgui.SetNextWindowPos(imgui.ImVec2(hbx, hby), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(hbs, hbs))
            imgui.Begin("RadialBtn", nil,
                imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollbar)
                if imgui.InvisibleButton("##hamburger_main", imgui.ImVec2(hbs - 10, hbs - 10)) then
                    local anyRadialOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showVehCatRadial[0] or showVehRadial[0] or showContextVehRadial[0] or showCtxSubRadial[0]
                    if anyRadialOpen then
                        closeAllRadial()
                    else
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    end
                end
            imgui.End()
        end
        
        -- ANIMATION CALCULATION
        local anyMenuOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showVehCatRadial[0] or showVehRadial[0] or showContextVehRadial[0] or showCtxSubRadial[0]
        if anyMenuOpen then
            local elapsed = os.clock() - menuOpenTime
            local animDuration = 0.3
            local t = clamp(elapsed / animDuration, 0, 1.0)
            menuScale = getEase('outCubic', t)
        else
            if menuScale > 0 then
                local elapsed = os.clock() - menuOpenTime
                local animDuration = 0.3
                local t = clamp(elapsed / animDuration, 0, 1.0)
                menuScale = 1.0 - getEase('inCubic', t)
            end
        end
        menuScale = clamp(menuScale, 0, 1.0)
        
        if menuScale > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
            
            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlay', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            
            -- LEVEL 1: MAIN RADIAL
            if showRadialMenu[0] then
                local inVehicle = false
                pcall(function() inVehicle = isCharInAnyCar(PLAYER_PED) end)
                
                local menuItems = {
                    { label = iniData.Sector1.name or "VEHICLE", color = {0.26, 0.71, 0.81}, labelColor = 0xFFFFFFFF },
                    { label = iniData.Sector2.name or "-", color = {0.91, 0.30, 0.40}, labelColor = 0xFFFFFFFF },
                    { label = iniData.Sector3.name or "ANIM", color = {0.54, 0.36, 0.76}, labelColor = inVehicle and 0x55FFFFFF or 0xFFFFFFFF },
                    { label = iniData.Sector4.name or "-", color = {0.26, 0.81, 0.46}, labelColor = 0xFFFFFFFF },
                }
                
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[MAIN]", {1, 1, 0})
                
                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        closeAllRadial()
                    elseif hoveredSector == 1 then
                        if inVehicle then
                            contextVehCommands = getInVehicleCommands()
                        else
                            contextVehCommands = getOnFootCommands()
                        end
                        showRadialMenu[0] = false
                        showContextVehRadial[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector == 2 then
                        closeAllRadial()
                        fullMapMode = true
                        fullMapOpenTime = os.clock()
                        fullMapOffsetX = 0
                        fullMapOffsetY = 0
                        fullMapZoom = 1.0
                        fullMapDragging = false
                        fullMapFocusPlayer = false
                    elseif hoveredSector == 3 then
                        if not inVehicle then
                            showRadialMenu[0] = false
                            showCatRadial[0] = true
                            menuOpenTime = os.clock()
                        end
                    elseif hoveredSector == 4 then
                        local cmd = iniData.Sector4.cmd or ""
                        if executeCommand(cmd) then closeAllRadial() end
                    end
                end
            end

            
            -- LEVEL 2: CONTEXT VEHICLE
            if showContextVehRadial[0] then
                local menuItems = {}
                for i = 1, 4 do
                    local cmd = contextVehCommands[i]
                    menuItems[i] = { 
                        label = cmd and cmd.name or "---", 
                        color = {0.26, 0.71, 0.81},
                        labelColor = (cmd and cmd.name and cmd.name ~= "-") and 0xFFFFFFFF or 0x55FFFFFF
                    }
                end
                
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[QUICK VEH]", {0.53, 0.86, 1.0})
                
                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        showContextVehRadial[0] = false
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 then
                        local slot = contextVehCommands[hoveredSector]
                        if slot and slot.name and slot.name ~= "-" and slot.name ~= "" then
                            if (slot.onCmd and slot.onCmd ~= "") or (slot.offCmd and slot.offCmd ~= "") then
                                ctxSubRadialItem = { name = slot.name, onCmd = slot.onCmd or "", offCmd = slot.offCmd or "" }
                                showContextVehRadial[0] = false
                                showCtxSubRadial[0] = true
                                menuOpenTime = os.clock()
                            end
                        end
                    end
                end
            end
            
            -- LEVEL 3: CONTEXT SUB-RADIAL (ON/OFF)
            if showCtxSubRadial[0] then
                local item = ctxSubRadialItem
                local cat = (item.name or ""):lower()
                local isOn = toggleState[cat]
                
                local onLabel, offLabel = "ON", "OFF"
                if cat == "lock" then
                    onLabel, offLabel = "LOCK", "UNLOCK"
                elseif cat == "trunk" or cat == "hood" then
                    onLabel, offLabel = "OPEN", "CLOSE"
                elseif cat == "engine" or cat == "light" or cat == "lights" then
                    onLabel, offLabel = "ON", "OFF"
                end
                
                local onColor = isOn and 0x55FFFFFF or 0xFF44FF44
                local offColor = isOn and 0xFFFF4444 or 0x55FFFFFF
                
                local menuItems = {
                    { label = onLabel, color = {0.26, 0.81, 0.46}, labelColor = onColor },
                    { label = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF },
                    { label = offLabel, color = {0.91, 0.30, 0.40}, labelColor = offColor },
                    { label = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF },
                }
                
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[" .. item.name .. "]", {0, 1, 1})

                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        showCtxSubRadial[0] = false
                        showContextVehRadial[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector == 1 and not isOn then
                        executeCommand(item.onCmd)
                        toggleState[cat] = true
                        closeAllRadial()
                    elseif hoveredSector == 3 and isOn then
                        executeCommand(item.offCmd)
                        toggleState[cat] = false
                        closeAllRadial()
                    end
                end
            end
            
            -- LEVEL 2: ANIM CATEGORY
            if showCatRadial[0] then
                local menuItems = {}
                for i = 1, 4 do
                    local catName = iniData["CatSector"..i].name or ""
                    menuItems[i] = { 
                        label = catName ~= "" and catName or "-", 
                        color = {0.54, 0.36, 0.76},
                        labelColor = catName ~= "" and 0xFFFFFFFF or 0x55FFFFFF
                    }
                end
                
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[ANIM]", {0, 1, 1})
                
                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        showCatRadial[0] = false
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 then
                        local sectorName = iniData["CatSector"..hoveredSector].name or ""
                        if sectorName ~= "" and sectorName ~= "-" then
                            loadAnimForCategory(sectorName)
                            if #animRadialList > 0 then
                                currentCategory = sectorName
                                showCatRadial[0] = false
                                showAnimRadial[0] = true
                                menuOpenTime = os.clock()
                            else
                                sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No animations found. Use /rcmdf to configure: "..sectorName, -1)
                            end
                        end
                    end
                end
            end

            
            -- LEVEL 3: ANIM ITEMS
            if showAnimRadial[0] then
                local tp = totalAnimPages()
                local pga = getAnimPage(animRadialPage)
                local menuItems = {}
                for i = 1, 4 do
                    if pga[i] then
                        menuItems[i] = { label = pga[i].label, color = {0.54, 0.36, 0.76}, labelColor = 0xFFFFFFFF }
                    else
                        menuItems[i] = { label = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }
                    end
                end
                
                local titleText = "[" .. currentCategory .. "]"
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, titleText, {0, 1, 1})
                
                -- PREV/NEXT Buttons (only if multiple pages)
                if tp > 1 then
                    local btnSize = 60
                    local btnOffset = 200  -- Distance from center
                    local btnAlpha = 0.8
                    
                    -- PREV Button (Left side, near Sector 4)
                    local prevX = cx - btnOffset
                    local prevY = cy
                    local prevEnabled = animRadialPage > 1
                    local prevBgAlpha = prevEnabled and (btnAlpha * 220) or (btnAlpha * 100)
                    local prevIconAlpha = prevEnabled and (btnAlpha * 255) or (btnAlpha * 80)
                    
                    -- PREV Background
                    draw_list:AddCircleFilled(
                        imgui.ImVec2(prevX, prevY),
                        btnSize / 2,
                        math.floor(prevBgAlpha) * 0x01000000 + 0x00222222,
                        32
                    )
                    draw_list:AddCircle(
                        imgui.ImVec2(prevX, prevY),
                        btnSize / 2,
                        math.floor(prevIconAlpha) * 0x01000000 + 0x0088DDFF,
                        32,
                        2.5
                    )
                    
                    -- PREV Arrow Icon (←)
                    local arrowSize = btnSize * 0.3
                    local prevIconColor = math.floor(prevIconAlpha) * 0x01000000 + 0x00FFFFFF
                    -- Draw left arrow
                    draw_list:AddTriangleFilled(
                        imgui.ImVec2(prevX - arrowSize/2, prevY),
                        imgui.ImVec2(prevX + arrowSize/2, prevY - arrowSize/2),
                        imgui.ImVec2(prevX + arrowSize/2, prevY + arrowSize/2),
                        prevIconColor
                    )
                    
                    -- NEXT Button (Right side, near Sector 2)
                    local nextX = cx + btnOffset
                    local nextY = cy
                    local nextEnabled = animRadialPage < tp
                    local nextBgAlpha = nextEnabled and (btnAlpha * 220) or (btnAlpha * 100)
                    local nextIconAlpha = nextEnabled and (btnAlpha * 255) or (btnAlpha * 80)
                    
                    -- NEXT Background
                    draw_list:AddCircleFilled(
                        imgui.ImVec2(nextX, nextY),
                        btnSize / 2,
                        math.floor(nextBgAlpha) * 0x01000000 + 0x00222222,
                        32
                    )
                    draw_list:AddCircle(
                        imgui.ImVec2(nextX, nextY),
                        btnSize / 2,
                        math.floor(nextIconAlpha) * 0x01000000 + 0x0088DDFF,
                        32,
                        2.5
                    )
                    
                    -- NEXT Arrow Icon (→)
                    local nextIconColor = math.floor(nextIconAlpha) * 0x01000000 + 0x00FFFFFF
                    -- Draw right arrow
                    draw_list:AddTriangleFilled(
                        imgui.ImVec2(nextX + arrowSize/2, nextY),
                        imgui.ImVec2(nextX - arrowSize/2, nextY - arrowSize/2),
                        imgui.ImVec2(nextX - arrowSize/2, nextY + arrowSize/2),
                        nextIconColor
                    )
                    
                    -- Page Indicator (below radial)
                    local pageText = "Page " .. animRadialPage .. "/" .. tp
                    local pageTextSize = imgui.CalcTextSize(pageText)
                    draw_list:AddText(
                        imgui.ImVec2(cx - pageTextSize.x/2, cy + 170),
                        0xFFFFFFFF,
                        pageText
                    )
                end
                
                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        -- Center button = CLOSE ALL
                        closeAllRadial()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 and pga[hoveredSector] then
                        executeCommand(pga[hoveredSector].cmd)
                        closeAllRadial()
                    else
                        -- Check PREV/NEXT button clicks
                        if tp > 1 then
                            local mouseX, mouseY = imgui.GetMousePos().x, imgui.GetMousePos().y
                            local btnSize = 60
                            local btnOffset = 200
                            local prevX = cx - btnOffset
                            local prevY = cy
                            local nextX = cx + btnOffset
                            local nextY = cy
                            
                            -- Check PREV click
                            local distPrev = math.sqrt((mouseX - prevX)^2 + (mouseY - prevY)^2)
                            if distPrev < btnSize/2 and animRadialPage > 1 then
                                animRadialPage = animRadialPage - 1
                            end
                            
                            -- Check NEXT click
                            local distNext = math.sqrt((mouseX - nextX)^2 + (mouseY - nextY)^2)
                            if distNext < btnSize/2 and animRadialPage < tp then
                                animRadialPage = animRadialPage + 1
                            end
                        end
                    end
                end
            end
            
            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end
    end)

    while true do wait(100) end
end
