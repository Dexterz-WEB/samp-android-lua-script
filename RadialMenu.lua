-- ============================================================================
-- RADIAL MENU v3.0
-- Configurable type system (MENU/COMMAND/TOGGLE) with pie chart rendering
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
-- DEFAULT STRUCTURE (v3.0 - Type System)
-- ============================================================================
local defaultStructure = {
    ButtonSettings = { posX = 1100.0, posY = 140.0 },
    HamburgerButton = { enabled = true, posX = 50.0, posY = 300.0, size = 80.0, alpha = 0.8 },
    Sector1 = { name = "VEHICLE", type = "MENU", target = "VehicleContext", cmd = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    Sector2 = { name = "-", type = "COMMAND", target = "", cmd = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    Sector3 = { name = "ANIM", type = "MENU", target = "AnimCategory", cmd = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    Sector4 = { name = "-", type = "COMMAND", target = "", cmd = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CtxVeh1 = { name = "ENGINE", type = "TOGGLE", cmd = "", target = "", category = "engine", labelOn = "START", labelOff = "STOP", cmdOn = "/engine on", cmdOff = "/engine off" },
    CtxVeh2 = { name = "LOCK", type = "TOGGLE", cmd = "", target = "", category = "lock", labelOn = "LOCK", labelOff = "UNLOCK", cmdOn = "/lock", cmdOff = "/unlock" },
    CtxVeh3 = { name = "LIGHTS", type = "COMMAND", cmd = "/lights", target = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CtxVeh4 = { name = "-", type = "COMMAND", cmd = "", target = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CtxFoot1 = { name = "LOCK", type = "TOGGLE", cmd = "", target = "", category = "lock", labelOn = "LOCK", labelOff = "UNLOCK", cmdOn = "/lock", cmdOff = "/unlock" },
    CtxFoot2 = { name = "TRUNK", type = "COMMAND", cmd = "/trunk", target = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CtxFoot3 = { name = "HOOD", type = "COMMAND", cmd = "/hood", target = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CtxFoot4 = { name = "-", type = "COMMAND", cmd = "", target = "", category = "", labelOn = "", labelOff = "", cmdOn = "", cmdOff = "" },
    CatSector1 = { name = "DANCE", type = "MENU", cmd = "", target = "" },
    CatSector2 = { name = "SIT", type = "COMMAND", cmd = "/anim sit1", target = "" },
    CatSector3 = { name = "LAY", type = "MENU", cmd = "", target = "" },
    CatSector4 = { name = "STOP", type = "COMMAND", cmd = "/stopanim", target = "" },
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
-- CONFIG MIGRATION (v2 -> v3)
-- ============================================================================
local function migrateConfig()
    for i = 1, 4 do
        local sec = iniData["Sector"..i]
        if not sec.type or sec.type == "" then
            if sec.name == "VEHICLE" or sec.name == "ANIM" then
                sec.type = "MENU"
                if sec.name == "VEHICLE" then sec.target = "VehicleContext"
                elseif sec.name == "ANIM" then sec.target = "AnimCategory" end
            else
                sec.type = "COMMAND"
            end
            if not sec.category then sec.category = "" end
            if not sec.labelOn then sec.labelOn = "" end
            if not sec.labelOff then sec.labelOff = "" end
            if not sec.cmdOn then sec.cmdOn = "" end
            if not sec.cmdOff then sec.cmdOff = "" end
            if not sec.target then sec.target = "" end
        end
    end
    for i = 1, 4 do
        local ctx = iniData["CtxVeh"..i]
        if not ctx.type or ctx.type == "" then
            if ctx.onCmd and ctx.onCmd ~= "" and ctx.offCmd and ctx.offCmd ~= "" and ctx.onCmd ~= ctx.offCmd then
                ctx.type = "TOGGLE"
                ctx.category = (ctx.name or ""):lower()
                ctx.labelOn = "ON"
                ctx.labelOff = "OFF"
                ctx.cmdOn = ctx.onCmd or ""
                ctx.cmdOff = ctx.offCmd or ""
            elseif ctx.onCmd and ctx.onCmd ~= "" then
                ctx.type = "COMMAND"
                ctx.cmd = ctx.onCmd or ""
            else
                ctx.type = "COMMAND"
                ctx.cmd = ""
            end
            if not ctx.cmd then ctx.cmd = "" end
            if not ctx.target then ctx.target = "" end
            if not ctx.category then ctx.category = "" end
            if not ctx.labelOn then ctx.labelOn = "" end
            if not ctx.labelOff then ctx.labelOff = "" end
            if not ctx.cmdOn then ctx.cmdOn = "" end
            if not ctx.cmdOff then ctx.cmdOff = "" end
        end
    end
    for i = 1, 4 do
        local ctx = iniData["CtxFoot"..i]
        if not ctx.type or ctx.type == "" then
            if ctx.onCmd and ctx.onCmd ~= "" and ctx.offCmd and ctx.offCmd ~= "" and ctx.onCmd ~= ctx.offCmd then
                ctx.type = "TOGGLE"
                ctx.category = (ctx.name or ""):lower()
                ctx.labelOn = "ON"
                ctx.labelOff = "OFF"
                ctx.cmdOn = ctx.onCmd or ""
                ctx.cmdOff = ctx.offCmd or ""
            elseif ctx.onCmd and ctx.onCmd ~= "" then
                ctx.type = "COMMAND"
                ctx.cmd = ctx.onCmd or ""
            else
                ctx.type = "COMMAND"
                ctx.cmd = ""
            end
            if not ctx.cmd then ctx.cmd = "" end
            if not ctx.target then ctx.target = "" end
            if not ctx.category then ctx.category = "" end
            if not ctx.labelOn then ctx.labelOn = "" end
            if not ctx.labelOff then ctx.labelOff = "" end
            if not ctx.cmdOn then ctx.cmdOn = "" end
            if not ctx.cmdOff then ctx.cmdOff = "" end
        end
    end
    for i = 1, 4 do
        local cat = iniData["CatSector"..i]
        if not cat.type or cat.type == "" then
            if cat.name and cat.name ~= "" and cat.name ~= "-" then
                cat.type = "MENU"
            else
                cat.type = "COMMAND"
            end
            if not cat.cmd then cat.cmd = "" end
            if not cat.target then cat.target = "" end
        end
    end
end
migrateConfig()

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================

local showRadialMenu   = imgui.new.bool(false)
local showConfigWindow = imgui.new.bool(false)
local showCatRadial    = imgui.new.bool(false)
local showAnimRadial   = imgui.new.bool(false)
local showContextVehRadial = imgui.new.bool(false)

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

-- Context-aware vehicle radial
local contextVehCommands = {}
local contextIsVehicle = false

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

-- Config edit buffers - Main sectors
local editName = {}
local editCmd = {}
local editSectorType = {}
local editSectorTarget = {}
local editSectorCategory = {}
local editSectorLabelOn = {}
local editSectorLabelOff = {}
local editSectorCmdOn = {}
local editSectorCmdOff = {}
for i = 1, 4 do
    editName[i] = imgui.new.char[32](iniData["Sector"..i].name or "")
    editCmd[i] = imgui.new.char[64](iniData["Sector"..i].cmd or "")
    editSectorType[i] = iniData["Sector"..i].type or "COMMAND"
    editSectorTarget[i] = iniData["Sector"..i].target or ""
    editSectorCategory[i] = imgui.new.char[32](iniData["Sector"..i].category or "")
    editSectorLabelOn[i] = imgui.new.char[32](iniData["Sector"..i].labelOn or "")
    editSectorLabelOff[i] = imgui.new.char[32](iniData["Sector"..i].labelOff or "")
    editSectorCmdOn[i] = imgui.new.char[128](iniData["Sector"..i].cmdOn or "")
    editSectorCmdOff[i] = imgui.new.char[128](iniData["Sector"..i].cmdOff or "")
end

-- Config edit buffers - Anim categories
local editCatName = {}
local editCatType = {}
local editCatCmd = {}
for i = 1, 4 do
    editCatName[i] = imgui.new.char[32](iniData["CatSector"..i].name or "")
    editCatType[i] = iniData["CatSector"..i].type or "MENU"
    editCatCmd[i] = imgui.new.char[128](iniData["CatSector"..i].cmd or "")
end

-- Config edit buffers - Anim slots
local MAX_ANIM_SLOTS = 21
local animEditLabel, animEditCmd, animEditCategory = {}, {}, {}
for i = 1, MAX_ANIM_SLOTS do
    local s = iniData["Anim"..i] or { label="", cmd="", category="" }
    animEditLabel[i]    = imgui.new.char[64](s.label    or "")
    animEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    animEditCategory[i] = imgui.new.char[32](s.category or "")
end

-- Config edit buffers - Context Vehicle
local ctxVehName, ctxVehCmd, ctxVehType = {}, {}, {}
local ctxVehCategory, ctxVehLabelOn, ctxVehLabelOff, ctxVehCmdOn, ctxVehCmdOff = {}, {}, {}, {}, {}
for i = 1, 4 do
    local s = iniData["CtxVeh"..i] or defaultStructure["CtxVeh"..i]
    ctxVehName[i] = imgui.new.char[32](s.name or "")
    ctxVehCmd[i] = imgui.new.char[128](s.cmd or "")
    ctxVehType[i] = s.type or "COMMAND"
    ctxVehCategory[i] = imgui.new.char[32](s.category or "")
    ctxVehLabelOn[i] = imgui.new.char[32](s.labelOn or "")
    ctxVehLabelOff[i] = imgui.new.char[32](s.labelOff or "")
    ctxVehCmdOn[i] = imgui.new.char[128](s.cmdOn or "")
    ctxVehCmdOff[i] = imgui.new.char[128](s.cmdOff or "")
end

-- Config edit buffers - Context Foot
local ctxFootName, ctxFootCmd, ctxFootType = {}, {}, {}
local ctxFootCategory, ctxFootLabelOn, ctxFootLabelOff, ctxFootCmdOn, ctxFootCmdOff = {}, {}, {}, {}, {}
for i = 1, 4 do
    local s = iniData["CtxFoot"..i] or defaultStructure["CtxFoot"..i]
    ctxFootName[i] = imgui.new.char[32](s.name or "")
    ctxFootCmd[i] = imgui.new.char[128](s.cmd or "")
    ctxFootType[i] = s.type or "COMMAND"
    ctxFootCategory[i] = imgui.new.char[32](s.category or "")
    ctxFootLabelOn[i] = imgui.new.char[32](s.labelOn or "")
    ctxFootLabelOff[i] = imgui.new.char[32](s.labelOff or "")
    ctxFootCmdOn[i] = imgui.new.char[128](s.cmdOn or "")
    ctxFootCmdOff[i] = imgui.new.char[128](s.cmdOff or "")
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

local function setCharBuffer(buf, str, maxSize)
    for j = 0, maxSize-1 do buf[j] = 0 end
    if str then
        for j = 1, math.min(#str, maxSize-1) do buf[j-1] = string.byte(str, j) end
    end
end

function closeAllRadial()
    showRadialMenu[0]   = false
    showCatRadial[0]    = false
    showAnimRadial[0]   = false
    showContextVehRadial[0] = false
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
    migrateConfig()
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
        setCharBuffer(editName[i], iniData["Sector"..i].name or "", 32)
        setCharBuffer(editCmd[i], iniData["Sector"..i].cmd or "", 64)
        editSectorType[i] = iniData["Sector"..i].type or "COMMAND"
        editSectorTarget[i] = iniData["Sector"..i].target or ""
        setCharBuffer(editSectorCategory[i], iniData["Sector"..i].category or "", 32)
        setCharBuffer(editSectorLabelOn[i], iniData["Sector"..i].labelOn or "", 32)
        setCharBuffer(editSectorLabelOff[i], iniData["Sector"..i].labelOff or "", 32)
        setCharBuffer(editSectorCmdOn[i], iniData["Sector"..i].cmdOn or "", 128)
        setCharBuffer(editSectorCmdOff[i], iniData["Sector"..i].cmdOff or "", 128)
    end
    for i = 1, 4 do
        setCharBuffer(editCatName[i], iniData["CatSector"..i].name or "", 32)
        editCatType[i] = iniData["CatSector"..i].type or "MENU"
        setCharBuffer(editCatCmd[i], iniData["CatSector"..i].cmd or "", 128)
    end
    for i = 1, MAX_ANIM_SLOTS do
        local s = iniData["Anim"..i] or { label="", cmd="", category="" }
        setCharBuffer(animEditLabel[i], s.label or "", 64)
        setCharBuffer(animEditCmd[i], s.cmd or "", 128)
        setCharBuffer(animEditCategory[i], s.category or "", 32)
    end
    for i = 1, 4 do
        local s = iniData["CtxVeh"..i] or defaultStructure["CtxVeh"..i]
        setCharBuffer(ctxVehName[i], s.name or "", 32)
        setCharBuffer(ctxVehCmd[i], s.cmd or "", 128)
        ctxVehType[i] = s.type or "COMMAND"
        setCharBuffer(ctxVehCategory[i], s.category or "", 32)
        setCharBuffer(ctxVehLabelOn[i], s.labelOn or "", 32)
        setCharBuffer(ctxVehLabelOff[i], s.labelOff or "", 32)
        setCharBuffer(ctxVehCmdOn[i], s.cmdOn or "", 128)
        setCharBuffer(ctxVehCmdOff[i], s.cmdOff or "", 128)
    end
    for i = 1, 4 do
        local s = iniData["CtxFoot"..i] or defaultStructure["CtxFoot"..i]
        setCharBuffer(ctxFootName[i], s.name or "", 32)
        setCharBuffer(ctxFootCmd[i], s.cmd or "", 128)
        ctxFootType[i] = s.type or "COMMAND"
        setCharBuffer(ctxFootCategory[i], s.category or "", 32)
        setCharBuffer(ctxFootLabelOn[i], s.labelOn or "", 32)
        setCharBuffer(ctxFootLabelOff[i], s.labelOff or "", 32)
        setCharBuffer(ctxFootCmdOn[i], s.cmdOn or "", 128)
        setCharBuffer(ctxFootCmdOff[i], s.cmdOff or "", 128)
    end
    rebuildAnimList()
end

-- ============================================================================
-- ANIMATION LIST FUNCTIONS
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
        iniData["Sector"..i].name = readCharBuffer(editName[i], 32)
        iniData["Sector"..i].cmd = readCharBuffer(editCmd[i], 64)
        iniData["Sector"..i].type = editSectorType[i]
        iniData["Sector"..i].target = editSectorTarget[i] or ""
        iniData["Sector"..i].category = readCharBuffer(editSectorCategory[i], 32)
        iniData["Sector"..i].labelOn = readCharBuffer(editSectorLabelOn[i], 32)
        iniData["Sector"..i].labelOff = readCharBuffer(editSectorLabelOff[i], 32)
        iniData["Sector"..i].cmdOn = readCharBuffer(editSectorCmdOn[i], 128)
        iniData["Sector"..i].cmdOff = readCharBuffer(editSectorCmdOff[i], 128)
    end
    for i = 1, 4 do
        iniData["CatSector"..i].name = readCharBuffer(editCatName[i], 32)
        iniData["CatSector"..i].type = editCatType[i]
        iniData["CatSector"..i].cmd = readCharBuffer(editCatCmd[i], 128)
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
    for i = 1, 4 do
        if not iniData["CtxVeh"..i] then iniData["CtxVeh"..i] = {} end
        iniData["CtxVeh"..i].name = readCharBuffer(ctxVehName[i], 32)
        iniData["CtxVeh"..i].cmd = readCharBuffer(ctxVehCmd[i], 128)
        iniData["CtxVeh"..i].type = ctxVehType[i]
        iniData["CtxVeh"..i].category = readCharBuffer(ctxVehCategory[i], 32)
        iniData["CtxVeh"..i].labelOn = readCharBuffer(ctxVehLabelOn[i], 32)
        iniData["CtxVeh"..i].labelOff = readCharBuffer(ctxVehLabelOff[i], 32)
        iniData["CtxVeh"..i].cmdOn = readCharBuffer(ctxVehCmdOn[i], 128)
        iniData["CtxVeh"..i].cmdOff = readCharBuffer(ctxVehCmdOff[i], 128)
    end
    for i = 1, 4 do
        if not iniData["CtxFoot"..i] then iniData["CtxFoot"..i] = {} end
        iniData["CtxFoot"..i].name = readCharBuffer(ctxFootName[i], 32)
        iniData["CtxFoot"..i].cmd = readCharBuffer(ctxFootCmd[i], 128)
        iniData["CtxFoot"..i].type = ctxFootType[i]
        iniData["CtxFoot"..i].category = readCharBuffer(ctxFootCategory[i], 32)
        iniData["CtxFoot"..i].labelOn = readCharBuffer(ctxFootLabelOn[i], 32)
        iniData["CtxFoot"..i].labelOff = readCharBuffer(ctxFootLabelOff[i], 32)
        iniData["CtxFoot"..i].cmdOn = readCharBuffer(ctxFootCmdOn[i], 128)
        iniData["CtxFoot"..i].cmdOff = readCharBuffer(ctxFootCmdOff[i], 128)
    end
    if inicfg.save(iniData, iniFileName) then
        if animChanged then rebuildAnimList() end
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Configuration saved!", -1)
        showConfigWindow[0] = false
        return true
    else
        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Failed to save config!", -1)
        return false
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
    if itemCount == 0 then return -1, false end
    local sectorAngle = (2 * math.pi) / itemCount
    local startAngle = -math.pi / 2
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
            local labelText2 = items[i].label or "---"
            local labelSize = imgui.CalcTextSize(labelText2)
            local labelAlpha = isHovered and scale or (0.7 * scale)
            local labelCol = items[i].labelColor or imgui.ImVec4(0.9, 0.9, 0.9, labelAlpha)
            if type(labelCol) == "number" then
                draw_list:AddText(
                    imgui.ImVec2(iconX - labelSize.x / 2, iconY - labelSize.y / 2),
                    labelCol,
                    labelText2
                )
            else
                draw_list:AddText(
                    imgui.ImVec2(iconX - labelSize.x / 2, iconY - labelSize.y / 2),
                    imgui.ColorConvertFloat4ToU32(labelCol),
                    labelText2
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
-- DYNAMIC MENU ITEM BUILDER (skip empty sectors)
-- ============================================================================
local function buildDynamicItems(rawItems)
    -- rawItems: list of {name, ...} tables. Filter out empty/dash entries.
    local active = {}
    local indexMap = {} -- maps active index back to original index
    for i, item in ipairs(rawItems) do
        if item.name and item.name ~= "" and item.name ~= "-" then
            active[#active+1] = item
            indexMap[#active] = i
        end
    end
    return active, indexMap
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}v3.0 loaded successfully!", -1)
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
            if showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showContextVehRadial[0] then
                closeAllRadial()
            end
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
            local winH = 400
            if configTab == 2 then winH = 500 end
            if configTab == 3 then winH = 550 end
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
            imgui.Begin("Radial Menu Config v3", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

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

            -- TAB 1: MAIN
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
                imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.2, 1), "MAIN SECTORS (4)")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1), "--- Sector " .. i .. " ---")
                    imgui.Text("Name:"); imgui.SameLine()
                    imgui.SetNextItemWidth(150); imgui.InputText("##sn"..i, editName[i], 32)
                    imgui.SameLine()
                    imgui.Text("Type:"); imgui.SameLine()
                    if imgui.Button(editSectorType[i] .. "##st"..i, imgui.ImVec2(90, 20)) then
                        if editSectorType[i] == "COMMAND" then editSectorType[i] = "MENU"
                        elseif editSectorType[i] == "MENU" then editSectorType[i] = "TOGGLE"
                        else editSectorType[i] = "COMMAND" end
                    end
                    if editSectorType[i] == "MENU" then
                        imgui.TextDisabled("  Target: " .. (editSectorTarget[i] ~= "" and editSectorTarget[i] or "(auto)"))
                    elseif editSectorType[i] == "COMMAND" then
                        imgui.Text("  Cmd:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##sc"..i, editCmd[i], 64)
                    elseif editSectorType[i] == "TOGGLE" then
                        imgui.Text("  Category:"); imgui.SameLine()
                        imgui.SetNextItemWidth(100); imgui.InputText("##scat"..i, editSectorCategory[i], 32)
                        imgui.Text("  LabelOn:"); imgui.SameLine()
                        imgui.SetNextItemWidth(80); imgui.InputText("##slon"..i, editSectorLabelOn[i], 32)
                        imgui.SameLine(); imgui.Text("LabelOff:"); imgui.SameLine()
                        imgui.SetNextItemWidth(80); imgui.InputText("##slof"..i, editSectorLabelOff[i], 32)
                        imgui.Text("  CmdOn:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##scon"..i, editSectorCmdOn[i], 128)
                        imgui.Text("  CmdOff:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##scof"..i, editSectorCmdOff[i], 128)
                    end
                end

            -- TAB 2: ANIM
            elseif configTab == 2 then
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIM CATEGORIES (4)")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Cat " .. i .. ":"); imgui.SameLine()
                    imgui.SetNextItemWidth(100); imgui.InputText("##cn"..i, editCatName[i], 32)
                    imgui.SameLine(); imgui.Text("Type:"); imgui.SameLine()
                    if imgui.Button(editCatType[i] .. "##ct"..i, imgui.ImVec2(90, 20)) then
                        if editCatType[i] == "COMMAND" then editCatType[i] = "MENU"
                        else editCatType[i] = "COMMAND" end
                    end
                    if editCatType[i] == "COMMAND" then
                        imgui.Text("    Cmd:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##ccmd"..i, editCatCmd[i], 128)
                    end
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIMATION SLOTS (21)")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##animscroll", imgui.ImVec2(-1, -50), true)
                for i = 1, MAX_ANIM_SLOTS do
                    imgui.Text(string.format("%2d|", i)); imgui.SameLine()
                    imgui.PushItemWidth(100); imgui.InputText("##ac"..i, animEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##al"..i, animEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##acmd"..i, animEditCmd[i], 128); imgui.PopItemWidth()
                end
                imgui.EndChild()

            -- TAB 3: VEH
            elseif configTab == 3 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "IN-VEHICLE (4)")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Item " .. i .. ":"); imgui.SameLine()
                    imgui.SetNextItemWidth(80); imgui.InputText("##vn"..i, ctxVehName[i], 32)
                    imgui.SameLine(); imgui.Text("Type:"); imgui.SameLine()
                    if imgui.Button(ctxVehType[i] .. "##vt"..i, imgui.ImVec2(90, 20)) then
                        if ctxVehType[i] == "COMMAND" then ctxVehType[i] = "MENU"
                        elseif ctxVehType[i] == "MENU" then ctxVehType[i] = "TOGGLE"
                        else ctxVehType[i] = "COMMAND" end
                    end
                    if ctxVehType[i] == "COMMAND" then
                        imgui.Text("    Cmd:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##vcmd"..i, ctxVehCmd[i], 128)
                    elseif ctxVehType[i] == "TOGGLE" then
                        imgui.Text("    Cat:"); imgui.SameLine()
                        imgui.SetNextItemWidth(80); imgui.InputText("##vcat"..i, ctxVehCategory[i], 32)
                        imgui.SameLine(); imgui.Text("On:"); imgui.SameLine()
                        imgui.SetNextItemWidth(60); imgui.InputText("##vlon"..i, ctxVehLabelOn[i], 32)
                        imgui.SameLine(); imgui.Text("Off:"); imgui.SameLine()
                        imgui.SetNextItemWidth(60); imgui.InputText("##vlof"..i, ctxVehLabelOff[i], 32)
                        imgui.Text("    CmdOn:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##vcon"..i, ctxVehCmdOn[i], 128)
                        imgui.Text("    CmdOff:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##vcof"..i, ctxVehCmdOff[i], 128)
                    elseif ctxVehType[i] == "MENU" then
                        imgui.TextDisabled("    (Opens sub-menu)")
                    end
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "ON-FOOT (4)")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Item " .. i .. ":"); imgui.SameLine()
                    imgui.SetNextItemWidth(80); imgui.InputText("##fn"..i, ctxFootName[i], 32)
                    imgui.SameLine(); imgui.Text("Type:"); imgui.SameLine()
                    if imgui.Button(ctxFootType[i] .. "##ft"..i, imgui.ImVec2(90, 20)) then
                        if ctxFootType[i] == "COMMAND" then ctxFootType[i] = "MENU"
                        elseif ctxFootType[i] == "MENU" then ctxFootType[i] = "TOGGLE"
                        else ctxFootType[i] = "COMMAND" end
                    end
                    if ctxFootType[i] == "COMMAND" then
                        imgui.Text("    Cmd:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##fcmd"..i, ctxFootCmd[i], 128)
                    elseif ctxFootType[i] == "TOGGLE" then
                        imgui.Text("    Cat:"); imgui.SameLine()
                        imgui.SetNextItemWidth(80); imgui.InputText("##fcat"..i, ctxFootCategory[i], 32)
                        imgui.SameLine(); imgui.Text("On:"); imgui.SameLine()
                        imgui.SetNextItemWidth(60); imgui.InputText("##flon"..i, ctxFootLabelOn[i], 32)
                        imgui.SameLine(); imgui.Text("Off:"); imgui.SameLine()
                        imgui.SetNextItemWidth(60); imgui.InputText("##flof"..i, ctxFootLabelOff[i], 32)
                        imgui.Text("    CmdOn:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##fcon"..i, ctxFootCmdOn[i], 128)
                        imgui.Text("    CmdOff:"); imgui.SameLine()
                        imgui.SetNextItemWidth(-1); imgui.InputText("##fcof"..i, ctxFootCmdOff[i], 128)
                    elseif ctxFootType[i] == "MENU" then
                        imgui.TextDisabled("    (Opens sub-menu)")
                    end
                end

            -- TAB 4: PROFILE
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
                    local anyRadialOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showContextVehRadial[0]
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
        local anyMenuOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showContextVehRadial[0]
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

            -- LEVEL 1: MAIN RADIAL (dynamic sectors)
            if showRadialMenu[0] then
                local inVehicle = false
                pcall(function() inVehicle = isCharInAnyCar(PLAYER_PED) end)

                -- Build raw sector data
                local rawSectors = {}
                for i = 1, 4 do
                    rawSectors[i] = {
                        name = iniData["Sector"..i].name or "",
                        type = iniData["Sector"..i].type or "COMMAND",
                        target = iniData["Sector"..i].target or "",
                        cmd = iniData["Sector"..i].cmd or "",
                        category = iniData["Sector"..i].category or "",
                        labelOn = iniData["Sector"..i].labelOn or "",
                        labelOff = iniData["Sector"..i].labelOff or "",
                        cmdOn = iniData["Sector"..i].cmdOn or "",
                        cmdOff = iniData["Sector"..i].cmdOff or "",
                        idx = i
                    }
                end

                -- Dynamic: filter out empty sectors
                local activeItems, indexMap = buildDynamicItems(rawSectors)
                local menuItems = {}
                for ai, item in ipairs(activeItems) do
                    local label = item.name
                    local labelColor = 0xFFFFFFFF
                    if item.type == "TOGGLE" then
                        local cat = item.category
                        if cat and cat ~= "" then
                            local isOn = toggleState[cat]
                            if isOn then
                                label = item.labelOff ~= "" and item.labelOff or item.name
                                labelColor = 0xFFFF4444  -- RED
                            else
                                label = item.labelOn ~= "" and item.labelOn or item.name
                                labelColor = 0xFF44FF44  -- GREEN
                            end
                        end
                    end
                    if item.type == "MENU" and item.target == "AnimCategory" and inVehicle then
                        labelColor = 0x55FFFFFF  -- dim if in vehicle
                    end
                    menuItems[ai] = {
                        label = label,
                        color = {0.26, 0.71, 0.81},
                        labelColor = labelColor
                    }
                end

                if #menuItems == 0 then
                    menuItems = {{ label = "EMPTY", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }}
                end

                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[MAIN]", {1, 1, 0})

                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        closeAllRadial()
                    elseif hoveredSector >= 1 and hoveredSector <= #activeItems then
                        local item = activeItems[hoveredSector]
                        if item.type == "MENU" then
                            if item.target == "VehicleContext" then
                                contextIsVehicle = inVehicle
                                showRadialMenu[0] = false
                                showContextVehRadial[0] = true
                                menuOpenTime = os.clock()
                            elseif item.target == "AnimCategory" then
                                if not inVehicle then
                                    showRadialMenu[0] = false
                                    showCatRadial[0] = true
                                    menuOpenTime = os.clock()
                                end
                            end
                        elseif item.type == "COMMAND" then
                            if executeCommand(item.cmd) then closeAllRadial() end
                        elseif item.type == "TOGGLE" then
                            local cat = item.category
                            if cat and cat ~= "" then
                                local isOn = toggleState[cat]
                                if isOn then
                                    executeCommand(item.cmdOff)
                                    toggleState[cat] = false
                                else
                                    executeCommand(item.cmdOn)
                                    toggleState[cat] = true
                                end
                                closeAllRadial()
                            end
                        end
                    end
                end
            end

            -- LEVEL 2: CONTEXT VEHICLE (direct toggle, no sub-menu)
            if showContextVehRadial[0] then
                local prefix = contextIsVehicle and "CtxVeh" or "CtxFoot"

                -- Build raw items
                local rawItems = {}
                for i = 1, 4 do
                    local s = iniData[prefix..i] or {}
                    rawItems[i] = {
                        name = s.name or "",
                        type = s.type or "COMMAND",
                        cmd = s.cmd or "",
                        category = s.category or "",
                        labelOn = s.labelOn or "",
                        labelOff = s.labelOff or "",
                        cmdOn = s.cmdOn or "",
                        cmdOff = s.cmdOff or "",
                        target = s.target or "",
                        idx = i
                    }
                end

                -- Dynamic: filter empty
                local activeItems, indexMap = buildDynamicItems(rawItems)
                local menuItems = {}
                for ai, item in ipairs(activeItems) do
                    local label = item.name
                    local labelColor = 0xFFFFFFFF
                    if item.type == "TOGGLE" then
                        local cat = item.category
                        if cat and cat ~= "" then
                            local isOn = toggleState[cat]
                            if isOn then
                                label = item.labelOff ~= "" and item.labelOff or item.name
                                labelColor = 0xFFFF4444  -- RED
                            else
                                label = item.labelOn ~= "" and item.labelOn or item.name
                                labelColor = 0xFF44FF44  -- GREEN
                            end
                        end
                    end
                    menuItems[ai] = {
                        label = label,
                        color = {0.26, 0.71, 0.81},
                        labelColor = labelColor
                    }
                end

                if #menuItems == 0 then
                    menuItems = {{ label = "EMPTY", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }}
                end

                local titleLabel = contextIsVehicle and "[IN-VEHICLE]" or "[ON-FOOT]"
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, titleLabel, {0.53, 0.86, 1.0})

                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        showContextVehRadial[0] = false
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= #activeItems then
                        local item = activeItems[hoveredSector]
                        if item.type == "COMMAND" then
                            if executeCommand(item.cmd) then closeAllRadial() end
                        elseif item.type == "TOGGLE" then
                            local cat = item.category
                            if cat and cat ~= "" then
                                local isOn = toggleState[cat]
                                if isOn then
                                    executeCommand(item.cmdOff)
                                    toggleState[cat] = false
                                else
                                    executeCommand(item.cmdOn)
                                    toggleState[cat] = true
                                end
                                closeAllRadial()
                            end
                        elseif item.type == "MENU" then
                            sampAddChatMessage("{FF8800}[Radial] {FFFFFF}Sub-menu not configured for: " .. item.name, -1)
                        end
                    end
                end
            end

            -- LEVEL 2: ANIM CATEGORY (dynamic)
            if showCatRadial[0] then
                local rawItems = {}
                for i = 1, 4 do
                    rawItems[i] = {
                        name = iniData["CatSector"..i].name or "",
                        type = iniData["CatSector"..i].type or "MENU",
                        cmd = iniData["CatSector"..i].cmd or "",
                        idx = i
                    }
                end

                local activeItems, indexMap = buildDynamicItems(rawItems)
                local menuItems = {}
                for ai, item in ipairs(activeItems) do
                    menuItems[ai] = {
                        label = item.name,
                        color = {0.54, 0.36, 0.76},
                        labelColor = 0xFFFFFFFF
                    }
                end

                if #menuItems == 0 then
                    menuItems = {{ label = "EMPTY", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }}
                end

                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, "[ANIM]", {0, 1, 1})

                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        showCatRadial[0] = false
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= #activeItems then
                        local item = activeItems[hoveredSector]
                        if item.type == "MENU" then
                            loadAnimForCategory(item.name)
                            if #animRadialList > 0 then
                                currentCategory = item.name
                                showCatRadial[0] = false
                                showAnimRadial[0] = true
                                menuOpenTime = os.clock()
                            else
                                sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No animations found. Use /rcmdf to configure: " .. item.name, -1)
                            end
                        elseif item.type == "COMMAND" then
                            if executeCommand(item.cmd) then closeAllRadial() end
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
                        menuItems[#menuItems+1] = { label = pga[i].label, color = {0.54, 0.36, 0.76}, labelColor = 0xFFFFFFFF }
                    end
                end

                if #menuItems == 0 then
                    menuItems = {{ label = "EMPTY", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }}
                end

                local titleText = "[" .. currentCategory .. "] Page " .. animRadialPage .. "/" .. tp
                local hoveredSector, centerHovered = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, titleText, {0, 1, 1})

                local currentTime = os.clock()
                if imgui.IsMouseClicked(0) and (currentTime - lastClickTime) > CLICK_COOLDOWN then
                    lastClickTime = currentTime
                    if centerHovered then
                        if tp <= 1 then
                            showAnimRadial[0] = false
                            showCatRadial[0] = true
                            menuOpenTime = os.clock()
                        elseif animRadialPage < tp then
                            animRadialPage = animRadialPage + 1
                        else
                            animRadialPage = 1
                        end
                    elseif hoveredSector >= 1 and hoveredSector <= #menuItems then
                        -- Map back to pga index
                        local actualIdx = 0
                        local count = 0
                        for i = 1, 4 do
                            if pga[i] then
                                count = count + 1
                                if count == hoveredSector then
                                    actualIdx = i
                                    break
                                end
                            end
                        end
                        if actualIdx > 0 and pga[actualIdx] then
                            executeCommand(pga[actualIdx].cmd)
                            closeAllRadial()
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
