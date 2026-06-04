-- ============================================================================
-- SYSTEM DEPENDENCIES & INI CONFIG
-- ============================================================================
local imgui  = require 'mimgui'
local inicfg = require 'inicfg'

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
-- DEFAULT STRUCTURE: Configure via /rcmdf (single command with tabs)
-- ============================================================================
local defaultStructure = {
    ButtonSettings = { posX = 1100.0, posY = 140.0 },
    HamburgerButton = { enabled = true, posX = 50.0, posY = 300.0, size = 80.0, alpha = 0.8 },
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

-- Config Window Tab State (1=Main, 2=Anim, 3=Vehicle, 4=Profiles)
local configTab = 1

-- Profile Management
local profileNameInput = imgui.new.char[32](currentProfile)
local autoDetectCheckbox = imgui.new.bool(autoDetectServer)
local availableProfiles = {}
local currentServerIP = ""
local currentServerName = ""

-- New Server Detection Dialog
local showNewServerDialog = imgui.new.bool(false)
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

-- toggle state: key=category (lower), true=ON/OPEN aktif, false/nil=OFF/CLOSE
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

-- ============================================================================
-- HELPERS
-- ============================================================================
function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize-1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r+1] = string.char(c)
    end
    return table.concat(r)
end

-- Profile Management Functions
function getProfileFileName(profileName)
    return "RadialMenu_" .. profileName:gsub("[^%w_-]", "_") .. ".ini"
end

function sanitizeProfileName(serverName)
    -- Convert server name to valid profile name
    local name = serverName
    -- Remove special characters, keep alphanumeric, space, dash, underscore
    name = name:gsub("[^%w%s_-]", "")
    -- Replace spaces with underscore
    name = name:gsub("%s+", "_")
    -- Remove leading/trailing underscores
    name = name:gsub("^_+", ""):gsub("_+$", "")
    -- Limit length
    if #name > 32 then name = name:sub(1, 32) end
    -- If empty, use default
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
    
    -- Set input buffer
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
        -- Create new profile with default structure
        inicfg.save(defaultStructure, fileName)
        data = defaultStructure
    end
    
    -- Ensure all sections exist
    for k, v in pairs(defaultStructure) do
        if not data[k] then data[k] = v end
    end
    
    iniData = data
    currentProfile = profileName
    
    -- Update profile settings
    profilesData.Settings.currentProfile = profileName
    inicfg.save(profilesData, profilesFileName)
    
    -- Reload edit buffers
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
    -- This would require file system access, so we'll track in profiles data
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
    
    -- Check if we have a profile mapped for this server
    local mappedProfile = profilesData.ServerMapping[serverIP]
    if mappedProfile and mappedProfile ~= "" and mappedProfile ~= currentProfile then
        sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Auto-detected server: {FFFF00}" .. (serverName or serverIP), -1)
        return loadProfile(mappedProfile)
    elseif not mappedProfile or mappedProfile == "" then
        -- New server detected, show dialog
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
    -- Reload button position
    btnSliderX[0] = iniData.ButtonSettings.posX or 1100.0
    btnSliderY[0] = iniData.ButtonSettings.posY or 140.0
    
    -- Reload hamburger button settings
    if iniData.HamburgerButton then
        hamburgerEnabled[0] = iniData.HamburgerButton.enabled or true
        hamburgerX[0] = iniData.HamburgerButton.posX or 50.0
        hamburgerY[0] = iniData.HamburgerButton.posY or 300.0
        hamburgerSize[0] = iniData.HamburgerButton.size or 80.0
        hamburgerAlpha[0] = iniData.HamburgerButton.alpha or 0.8
    end
    
    -- Reload sectors
    for i = 1, 4 do
        local name = iniData["Sector"..i].name or ""
        local cmd = iniData["Sector"..i].cmd or ""
        for j = 0, 31 do editName[i][j] = 0 end
        for j = 0, 63 do editCmd[i][j] = 0 end
        for j = 1, #name do editName[i][j-1] = string.byte(name, j) end
        for j = 1, #cmd do editCmd[i][j-1] = string.byte(cmd, j) end
    end
    
    -- Reload categories
    for i = 1, 4 do
        local catName = iniData["CatSector"..i].name or ""
        local vehCatName = iniData["VehCatSector"..i].name or ""
        for j = 0, 31 do editCatName[i][j] = 0; editVehCatName[i][j] = 0 end
        for j = 1, #catName do editCatName[i][j-1] = string.byte(catName, j) end
        for j = 1, #vehCatName do editVehCatName[i][j-1] = string.byte(vehCatName, j) end
    end
    
    -- Reload anims
    for i = 1, MAX_ANIM_SLOTS do
        local s = iniData["Anim"..i] or { label="", cmd="", category="" }
        for j = 0, 63 do animEditLabel[i][j] = 0 end
        for j = 0, 127 do animEditCmd[i][j] = 0 end
        for j = 0, 31 do animEditCategory[i][j] = 0 end
        for j = 1, #(s.label or "") do animEditLabel[i][j-1] = string.byte(s.label, j) end
        for j = 1, #(s.cmd or "") do animEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do animEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    
    -- Reload vehicles
    for i = 1, MAX_VEH_SLOTS do
        local s = iniData["Veh"..i] or { label="", cmd="", category="" }
        for j = 0, 63 do vehEditLabel[i][j] = 0 end
        for j = 0, 127 do vehEditCmd[i][j] = 0 end
        for j = 0, 31 do vehEditCategory[i][j] = 0 end
        for j = 1, #(s.label or "") do vehEditLabel[i][j-1] = string.byte(s.label, j) end
        for j = 1, #(s.cmd or "") do vehEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do vehEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    
    rebuildAnimList()
    rebuildVehList()
end

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

-- Auto-layout: susun item ke posisi sektor berdasarkan jumlahnya
-- Return: table [1..4] berisi slot atau nil (spacer otomatis)
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
    local result = { nil, nil, nil, nil }  -- [1]=atas, [2]=kanan, [3]=bawah, [4]=kiri

    if count == 1 then
        result[1] = items[1]                        -- atas
    elseif count == 2 then
        result[1] = items[1]                        -- atas
        result[3] = items[2]                        -- bawah
    elseif count == 3 then
        result[1] = items[1]                        -- atas
        result[2] = items[2]                        -- kanan
        result[3] = items[3]                        -- bawah
    elseif count == 4 then
        result[1] = items[1]                        -- atas
        result[2] = items[2]                        -- kanan
        result[3] = items[3]                        -- bawah
        result[4] = items[4]                        -- kiri
    end

    return result
end

function closeAllRadial()
    showRadialMenu[0]   = false
    showCatRadial[0]    = false
    showAnimRadial[0]   = false
    showVehCatRadial[0] = false
    showVehRadial[0]    = false
end

function executeCommand(cmd)
    if cmd and cmd ~= "" and type(cmd) == "string" then 
        sampProcessChatInput(cmd)
        return true
    end
    return false
end

-- ============================================================================
-- HAMBURGER BUTTON WIDGET
-- ============================================================================
function drawHamburgerButton(draw_list)
    local px = hamburgerX[0]
    local py = hamburgerY[0]
    local ps = hamburgerSize[0]
    local pa = hamburgerAlpha[0]
    
    -- Update pulse animation
    hamburgerPulse = (hamburgerPulse + 0.05) % (math.pi * 2)
    local pulse = math.sin(hamburgerPulse) * 0.15 + 1.0
    
    -- Outer glow (animated pulse)
    local radiusOuter = (ps/2) * pulse
    local glowAlpha = math.floor(pa * 100 * (1.0 - (pulse - 1.0) * 3))
    local glowColor = glowAlpha * 0x01000000 + 0x0044AAFF  -- Blue glow
    
    draw_list:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        radiusOuter,
        glowColor,
        32
    )
    
    -- Inner circle (main button)
    local bgAlpha = math.floor(pa * 220)
    local bgColor = bgAlpha * 0x01000000 + 0x00222222  -- Dark background
    
    draw_list:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        ps/2,
        bgColor,
        32
    )
    
    -- Border
    local borderAlpha = math.floor(pa * 255)
    local borderColor = borderAlpha * 0x01000000 + 0x0088DDFF  -- Light blue border
    
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
    local iconColor = iconAlpha * 0x01000000 + 0x00FFFFFF  -- White
    
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
    
    -- Label below button
    local label = "MENU"
    local labelSize = imgui.CalcTextSize(label)
    local labelAlpha = math.floor(pa * 200)
    local labelColor = labelAlpha * 0x01000000 + 0x00AAAAAA
    
    draw_list:AddText(
        imgui.ImVec2(px + ps/2 - labelSize.x/2, py + ps + 5),
        labelColor,
        label
    )
end

-- ============================================================================
-- SAVE
-- ============================================================================
function saveAllConfig()
    iniData.ButtonSettings.posX = btnSliderX[0]
    iniData.ButtonSettings.posY = btnSliderY[0]
    
    -- Save hamburger button settings
    if not iniData.HamburgerButton then iniData.HamburgerButton = {} end
    iniData.HamburgerButton.enabled = hamburgerEnabled[0]
    iniData.HamburgerButton.posX = hamburgerX[0]
    iniData.HamburgerButton.posY = hamburgerY[0]
    iniData.HamburgerButton.size = hamburgerSize[0]
    iniData.HamburgerButton.alpha = hamburgerAlpha[0]
    
    -- Save sectors & categories
    for i = 1, 4 do
        iniData["Sector"..i].name       = readCharBuffer(editName[i], 32)
        iniData["Sector"..i].cmd        = readCharBuffer(editCmd[i], 64)
        iniData["CatSector"..i].name    = readCharBuffer(editCatName[i], 32)
        iniData["VehCatSector"..i].name = readCharBuffer(editVehCatName[i], 32)
    end
    
    -- Save animations (only rebuild if changed)
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
    
    -- Save vehicles (only rebuild if changed)
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
    
    -- Save to file
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
-- DRAW RADIAL — label auto-center & auto-wrap
-- ============================================================================
local SECTOR_CENTERS = {
    { x =   0, y = -92 },
    { x =  92, y =   0 },
    { x =   0, y =  92 },
    { x = -92, y =   0 },
}

function drawLabelCentered(draw_list, text, cx, cy, color)
    local maxW = 78
    if not text or text == "" then text = "---"; color = 0x55FFFFFF end
    local ts = imgui.CalcTextSize(text)
    if ts.x <= maxW then
        draw_list:AddText(imgui.ImVec2(cx - ts.x * 0.5, cy - ts.y * 0.5), color, text)
    else
        local mid = math.floor(#text / 2)
        local split = mid
        for d = 0, mid do
            if text:sub(mid-d, mid-d) == " " then split = mid-d; break end
            if text:sub(mid+d, mid+d) == " " then split = mid+d; break end
        end
        local l1 = text:sub(1, split):match("^%s*(.-)%s*$")
        local l2 = text:sub(split+1):match("^%s*(.-)%s*$")
        local t1 = imgui.CalcTextSize(l1)
        local t2 = imgui.CalcTextSize(l2)
        draw_list:AddText(imgui.ImVec2(cx - t1.x*0.5, cy - t1.y), color, l1)
        draw_list:AddText(imgui.ImVec2(cx - t2.x*0.5, cy        ), color, l2)
    end
end

function drawRadialMenu(draw_list, centerX, centerY, labels, centerLabel, centerColor, winId, labelColors)
    local rO = 135
    local rI = 50
    draw_list:AddCircleFilled(imgui.ImVec2(centerX, centerY), rO, 0xDD151515, 64)
    draw_list:AddCircleFilled(imgui.ImVec2(centerX, centerY), rI, 0xFF222222, 64)

    local oi, oo = rI * 0.7071, rO * 0.7071
    draw_list:AddLine(imgui.ImVec2(centerX+oi, centerY-oi), imgui.ImVec2(centerX+oo, centerY-oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX+oi, centerY+oi), imgui.ImVec2(centerX+oo, centerY+oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX-oi, centerY+oi), imgui.ImVec2(centerX-oo, centerY+oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX-oi, centerY-oi), imgui.ImVec2(centerX-oo, centerY-oo), 0x55FFFFFF, 1.0)

    for i, lbl in ipairs(labels) do
        local sc    = SECTOR_CENTERS[i]
        local color = (labelColors and labelColors[i]) or 0xFFFFFFFF
        drawLabelCentered(draw_list, lbl, centerX + sc.x, centerY + sc.y, color)
    end

    local cl  = centerLabel or ""
    local cts = imgui.CalcTextSize(cl)
    draw_list:AddText(imgui.ImVec2(centerX - cts.x*0.5, centerY - cts.y*0.5), centerColor or 0xFFFFFF00, cl)

    local pressed = nil
    imgui.SetCursorPos(imgui.ImVec2(110,  20)); if imgui.InvisibleButton("##top_"..winId,    imgui.ImVec2(120, 70)) then pressed = 1 end
    imgui.SetCursorPos(imgui.ImVec2( 20, 135)); if imgui.InvisibleButton("##left_"..winId,   imgui.ImVec2( 85, 70)) then pressed = 4 end
    imgui.SetCursorPos(imgui.ImVec2(125, 135)); if imgui.InvisibleButton("##center_"..winId, imgui.ImVec2( 90, 70)) then pressed = 5 end
    imgui.SetCursorPos(imgui.ImVec2(235, 135)); if imgui.InvisibleButton("##right_"..winId,  imgui.ImVec2( 85, 70)) then pressed = 2 end
    imgui.SetCursorPos(imgui.ImVec2(110, 250)); if imgui.InvisibleButton("##bottom_"..winId, imgui.ImVec2(120, 70)) then pressed = 3 end
    return pressed
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rcmdf{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. currentProfile, -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    -- Single command with optional tab parameter
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
    
    -- Profile management commands
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
                    
                    -- Try auto-load profile
                    if autoDetectServer then
                        autoLoadProfileForServer()
                    end
                end
            end
        end
    end)

    imgui.OnFrame(function() return true end, function()
        local sw, sh    = getScreenResolution()
        local draw_list = imgui.GetBackgroundDrawList()
        local menuSize  = 340
        local cx        = sw / 2
        local cy        = sh / 2

        -- NEW SERVER DETECTION DIALOG
        if showNewServerDialog[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - 250, sh/2 - 150), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(500, 300))
            imgui.Begin("New Server Detected", showNewServerDialog, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
            
            imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "NEW SERVER DETECTED!")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            imgui.Text("Server:")
            imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), newServerDetected.name)
            
            imgui.Text("IP:")
            imgui.SameLine()
            imgui.TextDisabled(newServerDetected.ip)
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "Create profile for this server?")
            imgui.Spacing()
            
            imgui.Text("Profile name:")
            imgui.SetNextItemWidth(-1)
            imgui.InputText("##newprofilename", newProfileNameInput, 64)
            imgui.TextDisabled("(You can edit the name before creating)")
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            -- Buttons
            if imgui.Button("CREATE & MAP", imgui.ImVec2(230, 40)) then
                local profileName = readCharBuffer(newProfileNameInput, 64)
                if profileName ~= "" then
                    -- Create and load profile
                    loadProfile(profileName)
                    -- Map server to profile
                    mapServerToProfile(newServerDetected.ip, profileName)
                    -- Save
                    saveProfile(profileName)
                    -- Close dialog
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

        -- CONFIG PANEL WITH TABS
        if showConfigWindow[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(50, sh/4), imgui.Cond.FirstUseEver)
            imgui.SetNextWindowSize(imgui.ImVec2(700, 580))
            imgui.Begin("Radial Menu Config", showConfigWindow)
            
            -- Tab Buttons
            if imgui.Button("1. MAIN", imgui.ImVec2(165, 35)) then configTab = 1 end
            imgui.SameLine()
            if imgui.Button("2. ANIM", imgui.ImVec2(165, 35)) then configTab = 2 end
            imgui.SameLine()
            if imgui.Button("3. VEHICLE", imgui.ImVec2(165, 35)) then configTab = 3 end
            imgui.SameLine()
            if imgui.Button("4. PROFILES", imgui.ImVec2(165, 35)) then configTab = 4 end
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            
            -- TAB 1: MAIN CONFIG
            if configTab == 1 then
                imgui.TextColored(imgui.ImVec4(0,1,0,1), "--- HAMBURGER MENU POSITION ---")
                imgui.SliderFloat("X", btnSliderX, 0, sw-120, "%.0f")
                imgui.SliderFloat("Y", btnSliderY, 0, sh-50,  "%.0f")
                imgui.SliderFloat("Size", hamburgerSize, 50, 150, "%.0f")
                imgui.SliderFloat("Opacity", hamburgerAlpha, 0.3, 1.0, "%.2f")
                imgui.TextDisabled("Tap hamburger button to open/close radial menu")

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0,1,1,1), "--- MAIN SECTORS ---")
                for i = 1, 4 do
                    imgui.Text("Sector "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(120); imgui.InputText("Name##n"..i, editName[i], 32); imgui.SameLine()
                    if i == 1 or i == 3 then 
                        imgui.TextDisabled(i == 1 and "(vehicle menu)" or "(anim menu)")
                    else 
                        imgui.SetNextItemWidth(180); imgui.InputText("Cmd##c"..i, editCmd[i], 64) 
                    end
                end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(1,0.5,0,1), "--- ANIM CATEGORIES ---")
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(200); imgui.InputText("##ca"..i, editCatName[i], 32)
                end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1), "--- VEHICLE CATEGORIES ---")
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(200); imgui.InputText("##cv"..i, editVehCatName[i], 32)
                end
            
            -- TAB 2: ANIMATIONS
            elseif configTab == 2 then
                imgui.TextColored(imgui.ImVec4(1,1,0,1), "Edit animations")
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##animscroll", imgui.ImVec2(-1,-50), true)
                    for i = 1, MAX_ANIM_SLOTS do
                        imgui.Text(string.format("Slot%2d|", i)); imgui.SameLine()
                        imgui.SetNextItemWidth(110); imgui.InputText("Lbl##al"..i, animEditLabel[i], 64); imgui.SameLine()
                        imgui.SetNextItemWidth(240); imgui.InputText("Cmd##ac"..i, animEditCmd[i], 128); imgui.SameLine()
                        imgui.SetNextItemWidth(100); imgui.InputText("Cat##ak"..i, animEditCategory[i], 32)
                    end
                imgui.EndChild()
            
            -- TAB 3: VEHICLES
            elseif configTab == 3 then
                imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1), "Edit vehicles")
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##vehscroll", imgui.ImVec2(-1,-50), true)
                    for i = 1, MAX_VEH_SLOTS do
                        imgui.Text(string.format("Slot%2d|", i)); imgui.SameLine()
                        imgui.SetNextItemWidth(110); imgui.InputText("Lbl##vl"..i, vehEditLabel[i], 64); imgui.SameLine()
                        imgui.SetNextItemWidth(240); imgui.InputText("Cmd##vc"..i, vehEditCmd[i], 128); imgui.SameLine()
                        imgui.SetNextItemWidth(100); imgui.InputText("Cat##vk"..i, vehEditCategory[i], 32)
                    end
                imgui.EndChild()
            
            -- TAB 4: PROFILES
            elseif configTab == 4 then
                imgui.TextColored(imgui.ImVec4(1,0.8,0,1), "Profile Management")
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                -- Current Profile Info
                imgui.TextColored(imgui.ImVec4(0,1,0,1), "Current Profile:")
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(1,1,0,1), currentProfile)
                
                imgui.Spacing()
                
                -- Server Info
                if currentServerIP ~= "" then
                    imgui.TextColored(imgui.ImVec4(0,1,1,1), "Current Server:")
                    imgui.Text(currentServerName)
                    imgui.TextDisabled(currentServerIP)
                    
                    local mappedProfile = profilesData.ServerMapping[currentServerIP] or "none"
                    imgui.Text("Mapped to: " .. mappedProfile)
                else
                    imgui.TextColored(imgui.ImVec4(1,0.5,0,1), "Not connected to server")
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                -- Auto-detect toggle
                if imgui.Checkbox("Auto-detect server and load profile", autoDetectCheckbox) then
                    autoDetectServer = autoDetectCheckbox[0]
                    profilesData.Settings.autoDetectServer = autoDetectServer
                    inicfg.save(profilesData, profilesFileName)
                    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Auto-detect: " .. (autoDetectServer and "ON" or "OFF"), -1)
                end
                imgui.TextDisabled("Automatically load profile when connecting to mapped server")
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                -- CREATE NEW PROFILE
                imgui.TextColored(imgui.ImVec4(0,1,1,1), "CREATE NEW PROFILE:")
                imgui.SetNextItemWidth(300)
                imgui.InputText("##profilename", profileNameInput, 32)
                imgui.SameLine()
                if imgui.Button("Create", imgui.ImVec2(80, 25)) then
                    local pName = readCharBuffer(profileNameInput, 32)
                    if pName ~= "" then
                        loadProfile(pName)
                        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile created: " .. pName, -1)
                    else
                        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Please enter profile name!", -1)
                    end
                end
                
                imgui.Spacing()
                
                -- MAP CURRENT SERVER
                if currentServerIP ~= "" then
                    imgui.TextColored(imgui.ImVec4(1,0.8,0,1), "MAP CURRENT SERVER:")
                    imgui.Text("Map \"" .. currentServerName .. "\" to:")
                    
                    imgui.SetNextItemWidth(300)
                    imgui.InputText("##mapprofilename", profileNameInput, 32)
                    imgui.SameLine()
                    if imgui.Button("Map to Profile", imgui.ImVec2(140, 25)) then
                        local pName = readCharBuffer(profileNameInput, 32)
                        if pName == "" then pName = currentProfile end
                        mapServerToProfile(currentServerIP, pName)
                    end
                    
                    imgui.SameLine()
                    if imgui.Button("Map to Current", imgui.ImVec2(140, 25)) then
                        mapServerToProfile(currentServerIP, currentProfile)
                    end
                    
                    imgui.TextDisabled("Server will auto-load this profile on next connect")
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                -- AVAILABLE PROFILES LIST
                imgui.TextColored(imgui.ImVec4(1,1,0,1), "AVAILABLE PROFILES:")
                imgui.BeginChild("##profilelist", imgui.ImVec2(-1, 180), true)
                    availableProfiles = listProfiles()
                    for i, pName in ipairs(availableProfiles) do
                        local isCurrent = (pName == currentProfile)
                        
                        -- Profile name with active indicator
                        if isCurrent then
                            imgui.TextColored(imgui.ImVec4(0,1,0,1), "[ACTIVE] " .. pName)
                        else
                            imgui.Text(pName)
                            imgui.SameLine(200)
                            if imgui.Button("Load##" .. i, imgui.ImVec2(60, 20)) then
                                loadProfile(pName)
                            end
                        end
                        
                        -- Show mapped servers for this profile
                        local mappedServers = {}
                        for ip, profile in pairs(profilesData.ServerMapping or {}) do
                            if profile == pName then
                                table.insert(mappedServers, ip)
                            end
                        end
                        if #mappedServers > 0 then
                            imgui.TextDisabled("  └─ Mapped: " .. table.concat(mappedServers, ", "))
                        end
                    end
                imgui.EndChild()
                
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0,1,0,1), "TIP:")
                imgui.TextDisabled("1. Create profile → 2. Configure → 3. Map to server")
                imgui.TextDisabled("Next time you connect, it auto-loads!")
            end
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 35)) then
                saveAllConfig()
            end
            
            imgui.End()
        end

        -- TOMBOL MENU (Hamburger Button)
        local hbx = btnSliderX[0]
        local hby = btnSliderY[0]
        local hbs = hamburgerSize[0]
        local hba = hamburgerAlpha[0]
        
        local anyRadialOpen2 = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0]
                            or showVehCatRadial[0] or showVehRadial[0]
        
        -- Draw hamburger icon using background draw list
        local hCenterX = hbx + hbs/2
        local hCenterY = hby + hbs/2
        
        -- Pulse animation
        hamburgerPulse = (hamburgerPulse + 0.05) % (math.pi * 2)
        local hPulse = math.sin(hamburgerPulse) * 0.15 + 1.0
        
        -- Outer glow
        local hGlowAlpha = math.floor(hba * 100 * (1.0 - (hPulse - 1.0) * 3))
        local hGlowColor = hGlowAlpha * 0x01000000 + 0x0044AAFF
        draw_list:AddCircleFilled(imgui.ImVec2(hCenterX, hCenterY), (hbs/2) * hPulse, hGlowColor, 32)
        
        -- Inner circle
        local hBgAlpha = math.floor(hba * 220)
        draw_list:AddCircleFilled(imgui.ImVec2(hCenterX, hCenterY), hbs/2, hBgAlpha * 0x01000000 + 0x00222222, 32)
        
        -- Border
        local hBorderAlpha = math.floor(hba * 255)
        draw_list:AddCircle(imgui.ImVec2(hCenterX, hCenterY), hbs/2, hBorderAlpha * 0x01000000 + 0x0088DDFF, 32, 3.0)
        
        -- Hamburger icon (3 white lines)
        local hIconSize = hbs * 0.4
        local hIconAlpha = math.floor(hba * 255)
        local hIconColor = hIconAlpha * 0x01000000 + 0x00FFFFFF
        local hLineW = hIconSize * 0.8
        local hLineH = hIconSize * 0.12
        local hLineS = hIconSize * 0.25
        
        draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineW/2, hCenterY - hLineS - hLineH/2), imgui.ImVec2(hCenterX + hLineW/2, hCenterY - hLineS + hLineH/2), hIconColor, hLineH/2)
        draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineW/2, hCenterY - hLineH/2), imgui.ImVec2(hCenterX + hLineW/2, hCenterY + hLineH/2), hIconColor, hLineH/2)
        draw_list:AddRectFilled(imgui.ImVec2(hCenterX - hLineW/2, hCenterY + hLineS - hLineH/2), imgui.ImVec2(hCenterX + hLineW/2, hCenterY + hLineS + hLineH/2), hIconColor, hLineH/2)
        
        -- Touch handler
        imgui.SetNextWindowPos(imgui.ImVec2(hbx, hby), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(hbs, hbs))
        imgui.Begin("RadialBtn", nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollbar)
            if imgui.InvisibleButton("##hamburger_main", imgui.ImVec2(hbs - 10, hbs - 10)) then
                if anyRadialOpen2 then
                    closeAllRadial()
                else
                    showRadialMenu[0] = true
                end
            end
        imgui.End()

        -- Helper: render radial tanpa animasi
        local function renderWithScale(key, showFlag)
            if not showFlag or not showFlag[0] then return false end
            imgui.SetNextWindowPos(imgui.ImVec2(cx - menuSize/2, cy - menuSize/2), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(menuSize, menuSize))
            return true, 1
        end

        -- LEVEL 1: RADIAL UTAMA
        do
            local s
            local ok; ok, s = renderWithScale("main", showRadialMenu)
            if ok then
                imgui.Begin("RadialMain", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then  -- jangan register klik saat animasi belum keliatan
                        local lbls = {
                            tostring(iniData.Sector1.name), tostring(iniData.Sector2.name),
                            tostring(iniData.Sector3.name), tostring(iniData.Sector4.name),
                        }
                        local p = drawRadialMenu(draw_list, cx, cy, lbls, "CLOSE", 0xFFFFFF00, "main")
                        if     p == 1 then showRadialMenu[0] = false; showVehCatRadial[0] = true
                        elseif p == 2 then 
                            local cmd = tostring(iniData.Sector2.cmd or "")
                            if executeCommand(cmd) then closeAllRadial() end
                        elseif p == 3 then showRadialMenu[0] = false; showCatRadial[0] = true
                        elseif p == 4 then 
                            local cmd = tostring(iniData.Sector4.cmd or "")
                            if executeCommand(cmd) then closeAllRadial() end
                        elseif p == 5 then showRadialMenu[0] = false end
                    end
                imgui.End()
            end
        end

        -- LEVEL 2a: CATEGORY ANIM
        do
            local s
            local ok; ok, s = renderWithScale("cat", showCatRadial)
            if ok then
                imgui.Begin("RadialCat", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local cats = {
                            tostring(iniData.CatSector1.name), tostring(iniData.CatSector2.name),
                            tostring(iniData.CatSector3.name), tostring(iniData.CatSector4.name),
                        }
                        local p = drawRadialMenu(draw_list, cx, cy, cats, "BACK", 0xFF00FFFF, "cat")
                        if p and p >= 1 and p <= 4 then
                            local sectorName = tostring(cats[p] or "")
                            if sectorName ~= "" and sectorName ~= "-" then
                                loadAnimForCategory(sectorName)
                                if #animRadialList > 0 then
                                    currentCategory = sectorName
                                    showCatRadial[0] = false
                                    showAnimRadial[0] = true
                                else
                                    sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No animations found. Use /rcmdf to configure: "..sectorName, -1)
                                end
                            end
                        elseif p == 5 then
                            showCatRadial[0] = false
                            showRadialMenu[0] = true
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 3a: ANIM
        do
            local s
            local ok; ok, s = renderWithScale("anim", showAnimRadial)
            if ok then
                imgui.Begin("RadialAnim", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local tp  = totalAnimPages()
                        local pga = getAnimPage(animRadialPage)
                        local al  = {}
                        for i = 1, 4 do al[i] = pga[i] and pga[i].label or nil end
                        local cl, cc = "BACK", 0xFF00FFFF
                        if tp > 1 then cl = animRadialPage < tp and "NEXT" or "PREV"; cc = 0xFF00FF88 end
                        draw_list:AddText(imgui.ImVec2(cx-30, cy+110), 0xAAFFFFFF, string.format("Hal %d/%d", animRadialPage, tp))
                        draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF00FFFF, "["..currentCategory.."]")
                        local p = drawRadialMenu(draw_list, cx, cy, al, cl, cc, "anim")
                        for i = 1, 4 do
                            if p == i and pga[i] then executeCommand(pga[i].cmd); closeAllRadial() end
                        end
                        if p == 5 then
                            if tp <= 1 then
                                showAnimRadial[0] = false
                                showCatRadial[0] = true
                            elseif animRadialPage < tp then animRadialPage = animRadialPage + 1
                            else animRadialPage = animRadialPage - 1 end
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 2b: CATEGORY VEHICLE
        do
            local s
            local ok; ok, s = renderWithScale("vehcat", showVehCatRadial)
            if ok then
                imgui.Begin("RadialVehCat", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local vcats = {
                            tostring(iniData.VehCatSector1.name), tostring(iniData.VehCatSector2.name),
                            tostring(iniData.VehCatSector3.name), tostring(iniData.VehCatSector4.name),
                        }
                        draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF88DDFF, "[VEHICLE]")
                        local p = drawRadialMenu(draw_list, cx, cy, vcats, "BACK", 0xFF88DDFF, "vehcat")
                        if p and p >= 1 and p <= 4 then
                            local sectorName = tostring(vcats[p] or "")
                            if sectorName ~= "" and sectorName ~= "-" then
                                loadVehForCategory(sectorName)
                                if #vehRadialList > 0 then
                                    currentVehCategory = sectorName
                                    showVehCatRadial[0] = false
                                    showVehRadial[0] = true
                                else
                                    sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No vehicles found. Use /rcmdf to configure: "..sectorName, -1)
                                end
                            end
                        elseif p == 5 then
                            showVehCatRadial[0] = false
                            showRadialMenu[0] = true
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 3b: VEHICLE
        do
            local s
            local ok; ok, s = renderWithScale("veh", showVehRadial)
            if ok then
                imgui.Begin("RadialVeh", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                local tp  = totalVehPages()
                local pgv = layoutVehPage(vehRadialPage)
                local cl, cc = "BACK", 0xFF88DDFF
                if tp > 1 then cl = vehRadialPage < tp and "NEXT" or "PREV"; cc = 0xFF44BBFF end
                draw_list:AddText(imgui.ImVec2(cx-30, cy+110), 0xAAFFFFFF, string.format("Hal %d/%d", vehRadialPage, tp))
                draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF88DDFF, "["..currentVehCategory.."]")

                -- Hitung warna & disabled state tiap slot
                local vlColors   = {}
                local vlDisabled = {}  -- true = beneran disabled, ga bisa dipencet
                for i = 1, 4 do
                    local slot = pgv[i]
                    if isDummySlot(slot) then
                        vlColors[i]   = 0x33FFFFFF
                        vlDisabled[i] = true
                    else
                        local cat   = (slot.category or ""):lower()
                        local lbl   = slot.label or ""
                        local isOn  = toggleState[cat]  -- true = kondisi aktif/ON

                        if isOnLabel(lbl) then
                            -- Tombol ON: disabled kalau state sudah ON
                            if isOn then
                                vlColors[i]   = 0x33FFFFFF  -- grey
                                vlDisabled[i] = true
                            else
                                vlColors[i]   = 0xFF44FF44  -- hijau = bisa dipencet
                                vlDisabled[i] = false
                            end
                        elseif isOffLabel(lbl) then
                            -- Tombol OFF: disabled kalau state masih OFF
                            if not isOn then
                                vlColors[i]   = 0x33FFFFFF  -- grey
                                vlDisabled[i] = true
                            else
                                vlColors[i]   = 0xFFFF4444  -- merah = bisa dipencet
                                vlDisabled[i] = false
                            end
                        else
                            -- Slot biasa (bukan ON/OFF pair) — selalu bisa dipencet
                            vlColors[i]   = 0xFFFFFFFF
                            vlDisabled[i] = false
                        end
                    end
                end

                -- Gambar label
                local vl = {}
                for i = 1, 4 do vl[i] = pgv[i] and not isDummySlot(pgv[i]) and pgv[i].label or nil end

                -- Gambar radial (tanpa invisible button dulu)
                local rO = 135
                local rI = 50
                draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), rO, 0xDD151515, 64)
                draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), rI, 0xFF222222, 64)
                local oi, oo = rI * 0.7071, rO * 0.7071
                draw_list:AddLine(imgui.ImVec2(cx+oi, cy-oi), imgui.ImVec2(cx+oo, cy-oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx+oi, cy+oi), imgui.ImVec2(cx+oo, cy+oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx-oi, cy+oi), imgui.ImVec2(cx-oo, cy+oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx-oi, cy-oi), imgui.ImVec2(cx-oo, cy-oo), 0x55FFFFFF, 1.0)

                for i = 1, 4 do
                    local sc  = SECTOR_CENTERS[i]
                    local lbl = vl[i]
                    drawLabelCentered(draw_list, lbl, cx + sc.x, cy + sc.y, vlColors[i])
                end

                -- Center label (BACK/NEXT/PREV)
                local cts = imgui.CalcTextSize(cl)
                draw_list:AddText(imgui.ImVec2(cx - cts.x*0.5, cy - cts.y*0.5), cc, cl)

                -- Invisible buttons — skip kalau disabled
                local sectorPos = {
                    { x=110, y= 20,  w=120, h=70 },  -- 1 atas
                    { x=235, y=135,  w= 85, h=70 },  -- 2 kanan
                    { x=110, y=250,  w=120, h=70 },  -- 3 bawah
                    { x= 20, y=135,  w= 85, h=70 },  -- 4 kiri
                }
                local pressed = nil
                for i = 1, 4 do
                    imgui.SetCursorPos(imgui.ImVec2(sectorPos[i].x, sectorPos[i].y))
                    if not vlDisabled[i] then
                        if imgui.InvisibleButton("##vs"..i.."_veh", imgui.ImVec2(sectorPos[i].w, sectorPos[i].h)) then
                            pressed = i
                        end
                    else
                        -- render dummy area (tidak clickable)
                        imgui.Dummy(imgui.ImVec2(sectorPos[i].w, sectorPos[i].h))
                    end
                end
                -- center button
                imgui.SetCursorPos(imgui.ImVec2(125, 135))
                if imgui.InvisibleButton("##vcenter_veh", imgui.ImVec2(90, 70)) then pressed = 5 end

                -- Handle klik
                for i = 1, 4 do
                    if pressed == i and pgv[i] and not vlDisabled[i] then
                        local slot = pgv[i]
                        local cat  = (slot.category or ""):lower()
                        local lbl  = slot.label or ""

                        executeCommand(slot.cmd)

                        if isOnLabel(lbl) then
                            toggleState[cat] = true
                        elseif isOffLabel(lbl) then
                            toggleState[cat] = false
                        end
                        closeAllRadial()
                    end
                end
                if pressed == 5 then
                    if tp <= 1 then
                        showVehRadial[0] = false
                        showVehCatRadial[0] = true
                    elseif vehRadialPage < tp then vehRadialPage = vehRadialPage + 1
                    else vehRadialPage = vehRadialPage - 1 end
                end
                    end  -- if s > 0.3
                imgui.End()
            end  -- if ok
        end  -- do

    end)

    while true do wait(100) end
end
