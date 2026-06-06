-- ============================================================================
-- RADIAL MENU v2.0 - PIE CHART STYLE
-- Modern radial/pie menu with ease animations and context detection
-- Libraries: mimgui, inicfg, ease, fAwesome6 (optional)
-- ============================================================================

script_name("Radial Menu v2.0")
script_author("OnlyDexterZ")

local imgui  = require 'mimgui'
local inicfg = require 'inicfg'

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
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
    CtxFoot1 = { name = "LOCK", onCmd = "/lock", offCmd = "/unlock" },
    CtxFoot2 = { name = "TRUNK", onCmd = "/trunk", offCmd = "/trunk" },
    CtxFoot3 = { name = "HOOD", onCmd = "/hood", offCmd = "/hood" },
    CtxFoot4 = { name = "-", onCmd = "", offCmd = "" },
    Sector1 = { name = "VEHICLE", cmd = "" },
    Sector2 = { name = "-",       cmd = "" },
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
local showNewServerDialog = imgui.new.bool(false)

-- Menu animations
local menuOpenTime = 0
local menuScale = 0

-- Config Tab State (1=Main, 2=Anim, 3=Vehicle, 4=Profiles)
local configTab = 1

-- Profile Management
local profileNameInput = imgui.new.char[32](currentProfile)
local autoDetectCheckbox = imgui.new.bool(autoDetectServer)
local availableProfiles = {}
local currentServerIP = ""
local currentServerName = ""

-- New Server Detection Dialog
local newServerDetected = {
    ip = "",
    name = "",
    suggestedProfileName = ""
}
local newProfileNameInput = imgui.new.char[64]("")

local currentCategory    = ""
local animRadialPage     = 1
local animRadialList     = {}
local currentVehCategory = ""
local vehRadialPage      = 1
local vehRadialList      = {}

-- Context-aware vehicle radial
local contextVehCommands = {}
local ctxSubRadialItem = { name = "", onCmd = "", offCmd = "" }

-- Toggle state: key=category (lower), true=ON/OPEN, false/nil=OFF/CLOSE
local toggleState = {}

-- Label yang dianggap tombol "ON" (aktifkan)
local ON_LABELS  = { on=true, open=true, hidup=true, nyala=true, start=true, buka=true }
-- Label yang dianggap tombol "OFF" (nonaktifkan)
local OFF_LABELS = { off=true, close=true, mati=true, stop=true, tutup=true }

function isOnLabel(lbl)
    if not lbl or lbl == "" then return false end
    return ON_LABELS[lbl:lower()] == true
end


function isOffLabel(lbl)
    if not lbl or lbl == "" then return false end
    return OFF_LABELS[lbl:lower()] == true
end

function isDummySlot(slot)
    if not slot then return true end
    local lbl = slot.label or ""
    local cmd = slot.cmd   or ""
    return lbl == "" or lbl == "-" or cmd == ""
end

-- UI Buffers
local btnSliderX = imgui.new.float(iniData.ButtonSettings.posX or 1100.0)
local btnSliderY = imgui.new.float(iniData.ButtonSettings.posY or 140.0)

-- Hamburger Button Variables
local hamburgerEnabled = imgui.new.bool(iniData.HamburgerButton and iniData.HamburgerButton.enabled or true)
local hamburgerX = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.posX or 50.0)
local hamburgerY = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.posY or 300.0)
local hamburgerSize = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.size or 80.0)
local hamburgerAlpha = imgui.new.float(iniData.HamburgerButton and iniData.HamburgerButton.alpha or 0.8)
local hamburgerPulse = 0  -- Animation variable

local editName = {
    imgui.new.char[32](iniData.Sector1.name or "VEHICLE"),
    imgui.new.char[32](iniData.Sector2.name or "HEAL"),
    imgui.new.char[32](iniData.Sector3.name or "ANIM"),
    imgui.new.char[32](iniData.Sector4.name or "LOCK"),
}
local editCmd = {
    imgui.new.char[64](iniData.Sector1.cmd or ""),
    imgui.new.char[64](iniData.Sector2.cmd or "/heal"),
    imgui.new.char[64](iniData.Sector3.cmd or "/anim"),
    imgui.new.char[64](iniData.Sector4.cmd or "/lock"),
}
local editCatName = {
    imgui.new.char[32](iniData.CatSector1.name or "Dance"),
    imgui.new.char[32](iniData.CatSector2.name or "Action"),
    imgui.new.char[32](iniData.CatSector3.name or "Gangs"),
    imgui.new.char[32](iniData.CatSector4.name or "Misc"),
}
local editVehCatName = {
    imgui.new.char[32](iniData.VehCatSector1.name or "Car"),
    imgui.new.char[32](iniData.VehCatSector2.name or "Bike"),
    imgui.new.char[32](iniData.VehCatSector3.name or "Boat"),
    imgui.new.char[32](iniData.VehCatSector4.name or "Air"),
}


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
local ctxVehName = {}
local ctxVehOn = {}
local ctxVehOff = {}
for i = 1, 4 do
    local s = iniData["CtxVeh"..i] or { name = "", onCmd = "", offCmd = "" }
    ctxVehName[i] = imgui.new.char[32](s.name or "")
    ctxVehOn[i] = imgui.new.char[64](s.onCmd or "")
    ctxVehOff[i] = imgui.new.char[64](s.offCmd or "")
end

-- Context Foot Command Buffers
local ctxFootName = {}
local ctxFootOn = {}
local ctxFootOff = {}
for i = 1, 4 do
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
    -- Fallback: simple linear
    return x
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
    if #words > 0 then
        name = table.concat(words, "_")
    end
    if #name > 32 then name = name:sub(1, 32) end
    if name == "" then name = "server_" .. os.time() end
    return name
end

function isServerMapped(serverIP)
    if not serverIP or serverIP == "" then return false end
    local mapped = profilesData.ServerMapping[serverIP]
    return mapped ~= nil and mapped ~= ""
end


function showNewServerDetectionDialog(serverIP, serverName)
    newServerDetected.ip = serverIP
    newServerDetected.name = serverName
    newServerDetected.suggestedProfileName = sanitizeProfileName(serverName)
    
    local suggested = newServerDetected.suggestedProfileName
    for i = 0, 63 do newProfileNameInput[i] = 0 end
    for i = 1, #suggested do
        newProfileNameInput[i-1] = string.byte(suggested, i)
    end
    
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
        local serverIP = ip .. ":" .. port
        local serverName = sampGetCurrentServerName()
        return serverIP, serverName
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
    
    for i = 1, 4 do
        local s = iniData["CtxVeh"..i] or { name = "", onCmd = "", offCmd = "" }
        for j = 0, 31 do ctxVehName[i][j] = 0 end
        for j = 0, 63 do ctxVehOn[i][j] = 0; ctxVehOff[i][j] = 0 end
        for j = 1, #(s.name or "") do ctxVehName[i][j-1] = string.byte(s.name, j) end
        for j = 1, #(s.onCmd or "") do ctxVehOn[i][j-1] = string.byte(s.onCmd, j) end
        for j = 1, #(s.offCmd or "") do ctxVehOff[i][j-1] = string.byte(s.offCmd, j) end
    end
    
    for i = 1, 4 do
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
-- ANIM & VEH LIST MANAGEMENT
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


function layoutVehPage(page)
    local s = (page - 1) * 4 + 1
    local items = {}
    for i = 0, 3 do
        local slot = vehRadialList[s + i]
        if slot and not isDummySlot(slot) then
            items[#items + 1] = slot
        end
    end

    local count  = #items
    local result = { nil, nil, nil, nil }

    if count == 1 then
        result[1] = items[1]
    elseif count == 2 then
        result[1] = items[1]
        result[3] = items[2]
    elseif count == 3 then
        result[1] = items[1]
        result[2] = items[2]
        result[3] = items[3]
    elseif count == 4 then
        result[1] = items[1]
        result[2] = items[2]
        result[3] = items[3]
        result[4] = items[4]
    end

    return result
end

function getInVehicleCommands()
    local cmds = {}
    for i = 1, 4 do
        local s = iniData["CtxVeh"..i] or { name = "-", onCmd = "", offCmd = "" }
        cmds[i] = { name = s.name or "-", onCmd = s.onCmd or "", offCmd = s.offCmd or "" }
    end
    return cmds
end

function getOnFootCommands()
    local cmds = {}
    for i = 1, 4 do
        local s = iniData["CtxFoot"..i] or { name = "-", onCmd = "", offCmd = "" }
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
        
        if iniData["Anim"..i].label ~= newLabel or 
           iniData["Anim"..i].cmd ~= newCmd or 
           iniData["Anim"..i].category ~= newCat then
            animChanged = true
        end
        
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
        
        if iniData["Veh"..i].label ~= newLabel or 
           iniData["Veh"..i].cmd ~= newCmd or 
           iniData["Veh"..i].category ~= newCat then
            vehChanged = true
        end
        
        iniData["Veh"..i].label = newLabel
        iniData["Veh"..i].cmd = newCmd
        iniData["Veh"..i].category = newCat
    end
    
    for i = 1, 4 do
        if not iniData["CtxVeh"..i] then iniData["CtxVeh"..i] = {} end
        iniData["CtxVeh"..i].name = readCharBuffer(ctxVehName[i], 32)
        iniData["CtxVeh"..i].onCmd = readCharBuffer(ctxVehOn[i], 64)
        iniData["CtxVeh"..i].offCmd = readCharBuffer(ctxVehOff[i], 64)
    end
    
    for i = 1, 4 do
        if not iniData["CtxFoot"..i] then iniData["CtxFoot"..i] = {} end
        iniData["CtxFoot"..i].name = readCharBuffer(ctxFootName[i], 32)
        iniData["CtxFoot"..i].onCmd = readCharBuffer(ctxFootOn[i], 64)
        iniData["CtxFoot"..i].offCmd = readCharBuffer(ctxFootOff[i], 64)
    end

    
    if inicfg.save(iniData, iniFileName) then
        if animChanged then rebuildAnimList() end
        if vehChanged then rebuildVehList() end
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Configuration saved!", -1)
        return true
    else
        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Failed to save config!", -1)
        return false
    end
end

-- ============================================================================
-- PIE MENU RENDERING FUNCTIONS (from PieMenuDemo)
-- ============================================================================
function drawPieMenu(draw_list, centerX, centerY, items, scale, onSelectCallback)
    local itemCount = #items
    if itemCount == 0 then return end
    
    local baseRadius = 120 * scale
    local sectorAngle = (2 * math.pi) / itemCount
    local startAngle = -math.pi / 2  -- Start from top

    -- Detect which sector is hovered
    local mousePos = imgui.GetIO().MousePos
    local dx = mousePos.x - centerX
    local dy = mousePos.y - centerY
    local dist = math.sqrt(dx * dx + dy * dy)
    local mouseAngle = math.atan2(dy, dx)

    local hoveredSector = -1
    if dist > 30 * scale and dist < (baseRadius + 50) * scale then
        local normAngle = mouseAngle - startAngle
        if normAngle < 0 then normAngle = normAngle + 2 * math.pi end
        hoveredSector = math.floor(normAngle / sectorAngle) + 1
        if hoveredSector > itemCount then hoveredSector = 1 end
    end

    -- Draw background circle
    local bgAlpha = 0.85 * scale
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        baseRadius + 40,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.12, bgAlpha)),
        64
    )

    -- Draw outer ring
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        baseRadius + 42,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * scale)),
        64,
        2
    )

    -- Draw sectors
    for i = 1, itemCount do
        local item = items[i]
        if not item then goto continue end
        
        local angle1 = startAngle + (i - 1) * sectorAngle
        local angle2 = startAngle + i * sectorAngle
        local midAngle = (angle1 + angle2) / 2


        -- Sector highlight
        local isHovered = (hoveredSector == i)
        local sectorAlpha = isHovered and (0.6 * scale) or (0.2 * scale)
        local col = item.color or { 0.26, 0.71, 0.81, 1.0 }
        
        -- Check if item is disabled (grey out)
        local isDisabled = item.disabled or false
        if isDisabled then
            sectorAlpha = 0.1 * scale
            col = { 0.3, 0.3, 0.3, 1.0 }
        end

        -- Draw filled arc segment (approximate with triangles)
        local arcSegments = 20
        local innerR = 35 * scale
        local outerR = (baseRadius + 35) * scale
        for seg = 0, arcSegments - 1 do
            local a1 = angle1 + (angle2 - angle1) * seg / arcSegments
            local a2 = angle1 + (angle2 - angle1) * (seg + 1) / arcSegments
            local p1 = imgui.ImVec2(centerX + math.cos(a1) * innerR, centerY + math.sin(a1) * innerR)
            local p2 = imgui.ImVec2(centerX + math.cos(a1) * outerR, centerY + math.sin(a1) * outerR)
            local p3 = imgui.ImVec2(centerX + math.cos(a2) * outerR, centerY + math.sin(a2) * outerR)
            local p4 = imgui.ImVec2(centerX + math.cos(a2) * innerR, centerY + math.sin(a2) * innerR)
            local fillColor = imgui.ColorConvertFloat4ToU32(
                imgui.ImVec4(col[1], col[2], col[3], sectorAlpha)
            )
            draw_list:AddQuadFilled(p1, p2, p3, p4, fillColor)
        end

        -- Draw sector divider lines
        local lineStart = imgui.ImVec2(
            centerX + math.cos(angle1) * innerR,
            centerY + math.sin(angle1) * innerR
        )
        local lineEnd = imgui.ImVec2(
            centerX + math.cos(angle1) * outerR,
            centerY + math.sin(angle1) * outerR
        )
        draw_list:AddLine(lineStart, lineEnd,
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * scale)),
            1.5
        )

        -- Draw label at sector center
        local labelDist = (innerR + outerR) / 2
        local labelX = centerX + math.cos(midAngle) * labelDist
        local labelY = centerY + math.sin(midAngle) * labelDist

        local labelText = item.label or item.name or "---"
        local labelSize = imgui.CalcTextSize(labelText)
        local labelAlpha = isHovered and scale or (0.7 * scale)
        if isDisabled then labelAlpha = 0.3 * scale end
        draw_list:AddText(
            imgui.ImVec2(labelX - labelSize.x / 2, labelY - labelSize.y / 2),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.9, 0.9, labelAlpha)),
            labelText
        )

        ::continue::
    end


    -- Draw center circle (close button)
    local centerR = 30 * scale
    local centerHovered = (dist < centerR)
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

    -- "X" or "CLOSE" in center
    local closeIcon = fa_loaded and faicons('XMARK') or "X"
    local closeSize = imgui.CalcTextSize(closeIcon)
    draw_list:AddText(
        imgui.ImVec2(centerX - closeSize.x / 2, centerY - closeSize.y / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 0.4, 0.4, scale)),
        closeIcon
    )

    -- Handle clicks
    if imgui.IsMouseClicked(0) then
        if centerHovered then
            -- Close menu
            return -1
        elseif hoveredSector >= 1 and hoveredSector <= itemCount then
            -- Check if item is disabled
            if not (items[hoveredSector] and items[hoveredSector].disabled) then
                return hoveredSector
            end
        end
    end

    return 0
end

-- ============================================================================
-- HAMBURGER BUTTON (always visible trigger)
-- ============================================================================
function drawHamburgerButton(draw_list, px, py, ps, pa)
    hamburgerPulse = (hamburgerPulse + 0.05) % (math.pi * 2)
    local pulse = math.sin(hamburgerPulse) * 0.15 + 1.0
    
    -- Outer glow (animated pulse)
    local radiusOuter = (ps/2) * pulse
    local glowAlpha = math.floor(pa * 100 * (1.0 - (pulse - 1.0) * 3))
    local glowColor = glowAlpha * 0x01000000 + 0x0044AAFF
    
    draw_list:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        radiusOuter,
        glowColor,
        32
    )

    
    -- Inner circle (main button)
    local bgAlpha = math.floor(pa * 220)
    local bgColor = bgAlpha * 0x01000000 + 0x00222222
    
    draw_list:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        ps/2,
        bgColor,
        32
    )
    
    -- Border
    local borderAlpha = math.floor(pa * 255)
    local borderColor = borderAlpha * 0x01000000 + 0x0088DDFF
    
    draw_list:AddCircle(
        imgui.ImVec2(px + ps/2, py + ps/2),
        ps/2,
        borderColor,
        32,
        3.0
    )
    
    -- Hamburger menu icon (3 horizontal lines - WHITE)
    local centerX = px + ps/2
    local centerY = py + ps/2
    local iconSize = ps * 0.4
    local iconAlpha = math.floor(pa * 255)
    local iconColor = iconAlpha * 0x01000000 + 0x00FFFFFF
    
    local lineWidth = iconSize * 0.8
    local lineHeight = iconSize * 0.12
    local lineSpacing = iconSize * 0.25
    
    -- Top line
    draw_list:AddRectFilled(
        imgui.ImVec2(centerX - lineWidth/2, centerY - lineSpacing - lineHeight/2),
        imgui.ImVec2(centerX + lineWidth/2, centerY - lineSpacing + lineHeight/2),
        iconColor,
        lineHeight/2
    )
    
    -- Middle line
    draw_list:AddRectFilled(
        imgui.ImVec2(centerX - lineWidth/2, centerY - lineHeight/2),
        imgui.ImVec2(centerX + lineWidth/2, centerY + lineHeight/2),
        iconColor,
        lineHeight/2
    )
    
    -- Bottom line
    draw_list:AddRectFilled(
        imgui.ImVec2(centerX - lineWidth/2, centerY + lineSpacing - lineHeight/2),
        imgui.ImVec2(centerX + lineWidth/2, centerY + lineSpacing + lineHeight/2),
        iconColor,
        lineHeight/2
    )
end


-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu v2.0] {FFFFFF}PIE CHART MODE - Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rcmdf{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. currentProfile, -1)

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
        end
    end)

    
    -- Auto-detect server on spawn
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

    -- Main render loop
    imgui.OnFrame(function() return true end, function()
        local sw, sh = getScreenResolution()
        local draw_list = imgui.GetBackgroundDrawList()
        local cx = sw / 2
        local cy = sh / 2

        -- Auto-close radial when dialog active
        local dialogActive = false
        pcall(function() dialogActive = sampIsDialogActive() end)
        if dialogActive then
            if showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] or showVehCatRadial[0] or showVehRadial[0] or showContextVehRadial[0] or showCtxSubRadial[0] then
                closeAllRadial()
            end
        end

        -- ====================================================================
        -- NEW SERVER DETECTION DIALOG
        -- ====================================================================
        if showNewServerDialog[0] then
            -- Use CORRECT MonetLoader functions
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.6, 1.0, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.7, 1.0, 1.0))
            
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
            imgui.PopStyleColor(3)
            imgui.PopStyleVar(2)
        end

        -- ====================================================================
        -- CONFIG WINDOW (MODERN STYLE from ConfigWindowRedesign)
        -- ====================================================================
        if showConfigWindow[0] then
            -- Adaptive window size per tab
            local winW = 500
            local winH = 250
            if configTab == 2 then winH = 380 end
            if configTab == 3 then winH = 400 end
            if configTab == 4 then winH = 280 end
            
            -- CORRECT MonetLoader styling functions
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
            imgui.Begin("Radial Menu Config v2.0", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

            -- TAB BAR (compact buttons)
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

            -- TAB 2: ANIM
            elseif configTab == 2 then
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIMATION COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 8 do
                    imgui.PushItemWidth(100); imgui.InputText("##ac"..i, animEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##al"..i, animEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##acmd"..i, animEditCmd[i], 128); imgui.PopItemWidth()
                end


            -- TAB 3: VEHICLE
            elseif configTab == 3 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "IN-VEHICLE COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 4 do
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
                for i = 1, 4 do
                    imgui.PushItemWidth(100); imgui.InputText("##fn"..i, ctxFootName[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(150); imgui.InputText("##fo"..i, ctxFootOn[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(310)
                    imgui.PushItemWidth(-1); imgui.InputText("##ff"..i, ctxFootOff[i], 64); imgui.PopItemWidth()
                end

            -- TAB 4: PROFILE
            elseif configTab == 4 then
                imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.8, 1), "PROFILE MANAGEMENT")
                imgui.Spacing()
                imgui.Text("Current Profile:"); imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), currentProfile)
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextDisabled("Profile management features here...")
            end

            imgui.Spacing()
            if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 40)) then
                saveAllConfig()
            end

            imgui.End()
            imgui.PopStyleColor(5)
            imgui.PopStyleVar(4)
        end


        -- ====================================================================
        -- HAMBURGER BUTTON (TRIGGER)
        -- ====================================================================
        if not showConfigWindow[0] then
            local hbx = hamburgerX[0]
            local hby = hamburgerY[0]
            local hbs = hamburgerSize[0]
            local hba = hamburgerAlpha[0]
            
            -- Draw hamburger icon
            drawHamburgerButton(draw_list, hbx, hby, hbs, hba)
            
            -- Touch handler
            imgui.SetNextWindowPos(imgui.ImVec2(hbx, hby), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(hbs, hbs))
            imgui.Begin("RadialBtn", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize 
                + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollbar)
                if imgui.InvisibleButton("##hamburger_main", imgui.ImVec2(hbs - 10, hbs - 10)) then
                    local anyOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] 
                                    or showVehCatRadial[0] or showVehRadial[0] 
                                    or showContextVehRadial[0] or showCtxSubRadial[0]
                    if anyOpen then
                        closeAllRadial()
                    else
                        showRadialMenu[0] = true
                        menuOpenTime = os.clock()
                    end
                end
            imgui.End()
        end

        -- ====================================================================
        -- PIE MENU ANIMATIONS
        -- ====================================================================
        local elapsed = os.clock() - menuOpenTime
        local animDuration = 0.3
        local anyMenuOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0] 
                            or showVehCatRadial[0] or showVehRadial[0] 
                            or showContextVehRadial[0] or showCtxSubRadial[0]

        if anyMenuOpen then
            local t = clamp(elapsed / animDuration, 0, 1.0)
            menuScale = getEase('outCubic', t)
        else
            local t = clamp(elapsed / animDuration, 0, 1.0)
            menuScale = 1.0 - getEase('inCubic', t)
        end
        menuScale = clamp(menuScale, 0, 1.0)

        -- Skip rendering if scale is too small
        if menuScale < 0.01 and not anyMenuOpen then
            return
        end


        -- ====================================================================
        -- LEVEL 1: MAIN RADIAL MENU (PIE CHART)
        -- ====================================================================
        if showRadialMenu[0] and menuScale > 0.01 then
            -- Full screen overlay for pie menu
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlayMain', nil, imgui.WindowFlags.NoTitleBar
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            -- Check if player is in vehicle
            local inVehicle = false
            pcall(function() inVehicle = isCharInAnyCar(PLAYER_PED) end)

            -- Build menu items (4 sectors)
            local menuItems = {}
            for i = 1, 4 do
                local sector = iniData["Sector"..i]
                local item = {
                    label = sector.name or "---",
                    cmd = sector.cmd or "",
                    color = { 0.26, 0.71, 0.81, 1.0 },
                    disabled = false
                }
                
                -- Grey out ANIM sector when in vehicle (sector 3)
                if i == 3 and inVehicle then
                    item.disabled = true
                end
                
                menuItems[i] = item
            end

            -- Render pie menu
            local selected = drawPieMenu(draw_list, cx, cy, menuItems, menuScale, nil)
            
            if selected == -1 then
                -- Close
                closeAllRadial()
            elseif selected == 1 then
                -- VEHICLE sector - context aware
                if inVehicle then
                    contextVehCommands = getInVehicleCommands()
                else
                    contextVehCommands = getOnFootCommands()
                end
                showRadialMenu[0] = false
                showContextVehRadial[0] = true
                menuOpenTime = os.clock()
            elseif selected == 2 then
                -- Sector 2 - direct command
                local cmd = menuItems[2].cmd
                if executeCommand(cmd) then closeAllRadial() end
            elseif selected == 3 then
                -- ANIM sector - category selection (only if not in vehicle)
                if not inVehicle then
                    showRadialMenu[0] = false
                    showCatRadial[0] = true
                    menuOpenTime = os.clock()
                end
            elseif selected == 4 then
                -- Sector 4 - direct command
                local cmd = menuItems[4].cmd
                if executeCommand(cmd) then closeAllRadial() end
            end

            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end


        -- ====================================================================
        -- LEVEL 2: CATEGORY SELECTION (ANIM)
        -- ====================================================================
        if showCatRadial[0] and menuScale > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlayCat', nil, imgui.WindowFlags.NoTitleBar
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            local catItems = {}
            for i = 1, 4 do
                local cat = iniData["CatSector"..i]
                catItems[i] = {
                    label = cat.name or "---",
                    color = { 0.54, 0.36, 0.76, 1.0 }
                }
            end

            local selected = drawPieMenu(draw_list, cx, cy, catItems, menuScale, nil)
            
            if selected == -1 then
                showCatRadial[0] = false
                showRadialMenu[0] = true
                menuOpenTime = os.clock()
            elseif selected >= 1 and selected <= 4 then
                currentCategory = catItems[selected].label
                loadAnimForCategory(currentCategory)
                showCatRadial[0] = false
                showAnimRadial[0] = true
                menuOpenTime = os.clock()
            end

            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end

        -- ====================================================================
        -- LEVEL 3: ANIMATION ITEMS
        -- ====================================================================
        if showAnimRadial[0] and menuScale > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlayAnim', nil, imgui.WindowFlags.NoTitleBar
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            local pageItems = getAnimPage(animRadialPage)
            local animItems = {}
            for i = 1, 4 do
                if pageItems[i] then
                    animItems[i] = {
                        label = pageItems[i].label,
                        cmd = pageItems[i].cmd,
                        color = { 0.91, 0.30, 0.40, 1.0 }
                    }
                end
            end

            local selected = drawPieMenu(draw_list, cx, cy, animItems, menuScale, nil)
            
            if selected == -1 then
                showAnimRadial[0] = false
                showCatRadial[0] = true
                menuOpenTime = os.clock()
            elseif selected >= 1 and selected <= 4 and animItems[selected] then
                if executeCommand(animItems[selected].cmd) then
                    closeAllRadial()
                end
            end

            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end


        -- ====================================================================
        -- CONTEXT VEHICLE RADIAL (IN-VEHICLE or ON-FOOT)
        -- ====================================================================
        if showContextVehRadial[0] and menuScale > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlayCtx', nil, imgui.WindowFlags.NoTitleBar
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            local ctxItems = {}
            for i = 1, 4 do
                local cmd = contextVehCommands[i]
                if cmd then
                    ctxItems[i] = {
                        label = cmd.name or "---",
                        onCmd = cmd.onCmd or "",
                        offCmd = cmd.offCmd or "",
                        color = { 0.26, 0.81, 0.46, 1.0 }
                    }
                end
            end

            local selected = drawPieMenu(draw_list, cx, cy, ctxItems, menuScale, nil)
            
            if selected == -1 then
                showContextVehRadial[0] = false
                showRadialMenu[0] = true
                menuOpenTime = os.clock()
            elseif selected >= 1 and selected <= 4 and ctxItems[selected] then
                -- Open sub-radial for ON/OFF selection
                ctxSubRadialItem = ctxItems[selected]
                showContextVehRadial[0] = false
                showCtxSubRadial[0] = true
                menuOpenTime = os.clock()
            end

            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end

        -- ====================================================================
        -- CTX SUB-RADIAL (ON/OFF SELECTION)
        -- ====================================================================
        if showCtxSubRadial[0] and menuScale > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlaySub', nil, imgui.WindowFlags.NoTitleBar
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            local subItems = {
                { label = "ON", cmd = ctxSubRadialItem.onCmd, color = { 0.2, 0.9, 0.4, 1.0 } },
                { label = "OFF", cmd = ctxSubRadialItem.offCmd, color = { 0.9, 0.3, 0.3, 1.0 } }
            }

            local selected = drawPieMenu(draw_list, cx, cy, subItems, menuScale, nil)
            
            if selected == -1 then
                showCtxSubRadial[0] = false
                showContextVehRadial[0] = true
                menuOpenTime = os.clock()
            elseif selected >= 1 and selected <= 2 then
                if executeCommand(subItems[selected].cmd) then
                    closeAllRadial()
                end
            end

            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end

    end)

    wait(-1)
end
