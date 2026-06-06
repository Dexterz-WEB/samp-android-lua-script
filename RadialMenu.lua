-- ============================================================================
-- RADIAL MENU - Rebuilt with PieMenuDemo Structure
-- Modern pie chart rendering with angle-based interaction
-- ============================================================================

script_name("Radial Menu")
script_author("OnlyDexterZ")
script_version("1.4.0")

-- ============================================================================
-- SYSTEM DEPENDENCIES
-- ============================================================================
local imgui  = require 'mimgui'
local inicfg = require 'inicfg'

local iniFileName = "RadialMenuConfig.ini"
local profilesFileName = "RadialMenuProfiles.ini"

-- ============================================================================
-- SAFE LIBRARY LOADING (Optional libraries with fallback)
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

local notif_loaded = false
local Notifications = nil
pcall(function()
    require 'notifications'
    Notifications = _G.Notifications
    notif_loaded = true
end)

-- ============================================================================
-- ICON MAPPINGS (FontAwesome fallback)
-- ============================================================================
local function getIcon(iconName)
    if not iconName or iconName == "" then return "" end
    if fa_loaded and faicons then
        local success, icon = pcall(function() return faicons(iconName) end)
        if success and icon then return icon end
    end

    local fallbacks = {
        CAR = "[V]", VEHICLE = "[V]", ENGINE = "[E]",
        PERSON_RUNNING = "[A]", ANIM = "[A]", RUNNING = "[R]",
        HEART = "[H]", HEAL = "[+]", MEDKIT = "[+]",
        LOCK = "[L]", UNLOCK = "[U]", KEY = "[K]",
        LIGHTBULB = "[L]", LIGHT = "[L]", LIGHTS = "[L]",
        BOX_OPEN = "[T]", TRUNK = "[T]",
        WRENCH = "[W]", HOOD = "[H]", TOOLS = "[T]",
        CIRCLE_NODES = "[M]", MENU = "[M]",
        XMARK = "[X]", TIMES = "[X]", CLOSE = "[X]"
    }
    return fallbacks[iconName:upper()] or "[?]"
end

-- ============================================================================
-- DEFAULT CONFIG STRUCTURE
-- ============================================================================
local defaultStructure = {
    ButtonSettings = { posX = 50.0, posY = 300.0, size = 80.0, alpha = 0.8 },
    Sector1 = { name = "VEHICLE", cmd = "", icon = "CAR" },
    Sector2 = { name = "HEAL", cmd = "/heal", icon = "HEART" },
    Sector3 = { name = "ANIM", cmd = "", icon = "PERSON_RUNNING" },
    Sector4 = { name = "LOCK", cmd = "/lock", icon = "LOCK" },
    CtxVeh1 = { name = "ENGINE", onCmd = "/engine", offCmd = "/engine", icon = "ENGINE" },
    CtxVeh2 = { name = "LOCK", onCmd = "/lock", offCmd = "/unlock", icon = "LOCK" },
    CtxVeh3 = { name = "LIGHT", onCmd = "/lights", offCmd = "/lights", icon = "LIGHTBULB" },
    CtxVeh4 = { name = "-", onCmd = "", offCmd = "", icon = "" },
    CtxFoot1 = { name = "LOCK", onCmd = "/lock", offCmd = "/unlock", icon = "LOCK" },
    CtxFoot2 = { name = "TRUNK", onCmd = "/trunk", offCmd = "/trunk", icon = "BOX_OPEN" },
    CtxFoot3 = { name = "HOOD", onCmd = "/hood", offCmd = "/hood", icon = "WRENCH" },
    CtxFoot4 = { name = "-", onCmd = "", offCmd = "", icon = "" },
    CatSector1 = { name = "Dance", icon = "" },
    CatSector2 = { name = "Action", icon = "" },
    CatSector3 = { name = "Gangs", icon = "" },
    CatSector4 = { name = "Misc", icon = "" },
    VehCatSector1 = { name = "Car", icon = "" },
    VehCatSector2 = { name = "Bike", icon = "" },
    VehCatSector3 = { name = "Boat", icon = "" },
    VehCatSector4 = { name = "Air", icon = "" },
}

for i = 1, 21 do
    defaultStructure["Anim"..i] = { label = "", cmd = "", category = "" }
    defaultStructure["Veh"..i]  = { label = "", cmd = "", category = "" }
end


-- Load configuration
local iniData = inicfg.load(defaultStructure, iniFileName)
if not iniData then
    inicfg.save(defaultStructure, iniFileName)
    iniData = defaultStructure
end
for k, v in pairs(defaultStructure) do
    if not iniData[k] then iniData[k] = v end
end

-- ============================================================================
-- PROFILES & SERVER DETECTION
-- ============================================================================
local profilesData = inicfg.load({
    Settings = { currentProfile = "default", autoDetectServer = true },
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
-- STATE VARIABLES
-- ============================================================================
local showPieMenu = false
local showConfigWindow = imgui.new.bool(false)
local menuOpenTime = 0
local menuScale = 0
local selectedSector = -1
local lastExecuted = ""

-- Menu stack for navigation
local menuStack = {}
local currentMenu = "main"
local currentCategory = ""
local currentPage = 1

-- Toggle states for ON/OFF commands
local toggleState = {}

-- Button settings
local btnX = imgui.new.float(iniData.ButtonSettings.posX or 50.0)
local btnY = imgui.new.float(iniData.ButtonSettings.posY or 300.0)

local btnSize = imgui.new.float(iniData.ButtonSettings.size or 80.0)
local btnAlpha = imgui.new.float(iniData.ButtonSettings.alpha or 0.8)
local btnPulse = 0

-- Animation lists
local animList = {}
local vehList = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function getEase(easeFunc, x)
    if ease_loaded and ease and ease[easeFunc] then
        return ease[easeFunc](x)
    end
    return x
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function showNotification(message, notifType, duration)
    duration = duration or 3
    if notif_loaded and Notifications then
        Notifications.Show(message, notifType or Notifications.TYPE.INFO, duration)
    else
        pcall(function()
            sampAddChatMessage("{00BFFF}[RadialMenu] {FFFFFF}" .. message, -1)
        end)
    end
end

local function togglePieMenu()
    showPieMenu = not showPieMenu
    menuOpenTime = os.clock()
    if showPieMenu then
        currentMenu = "main"
        menuStack = {}
    end
end

local function executeCommand(cmd)
    if not cmd or cmd == "" then return end

    lastExecuted = cmd
    pcall(function()
        sampProcessChatInput(cmd)
    end)
    showNotification("Executed: " .. cmd, notif_loaded and Notifications.TYPE.OK, 2)
end

-- ============================================================================
-- ANIMATION & VEHICLE LIST BUILDERS
-- ============================================================================
local function rebuildAnimList()
    animList = {}
    for i = 1, 21 do
        local e = iniData["Anim"..i]
        if e and e.label ~= "" and e.category ~= "" then
            animList[#animList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end

local function rebuildVehList()
    vehList = {}
    for i = 1, 21 do
        local e = iniData["Veh"..i]
        if e and e.label ~= "" and e.category ~= "" then
            vehList[#vehList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end

local function getAnimsForCategory(cat)
    local result = {}
    for _, a in ipairs(animList) do
        if a.category:lower() == cat:lower() then
            result[#result+1] = a
        end
    end
    return result
end

local function getVehiclesForCategory(cat)
    local result = {}
    for _, v in ipairs(vehList) do
        if v.category:lower() == cat:lower() then
            result[#result+1] = v
        end
    end
    return result
end

rebuildAnimList()
rebuildVehList()


-- ============================================================================
-- CONTEXT DETECTION
-- ============================================================================
local function getInVehicleCommands()
    local cmds = {}
    for i = 1, 4 do
        local s = iniData["CtxVeh"..i] or { name = "-", onCmd = "", offCmd = "", icon = "" }
        cmds[i] = {
            name = s.name or "-",
            onCmd = s.onCmd or "",
            offCmd = s.offCmd or "",
            icon = s.icon or ""
        }
    end
    return cmds
end

local function getOnFootCommands()
    local cmds = {}
    for i = 1, 4 do
        local s = iniData["CtxFoot"..i] or { name = "-", onCmd = "", offCmd = "", icon = "" }
        cmds[i] = {
            name = s.name or "-",
            onCmd = s.onCmd or "",
            offCmd = s.offCmd or "",
            icon = s.icon or ""
        }
    end
    return cmds
end

local function isPlayerInVehicle()
    local result = false
    pcall(function()
        result = isCharInAnyCar(PLAYER_PED)
    end)
    return result
end

-- ============================================================================
-- PIE MENU RENDERING (Based on PieMenuDemo.lua)
-- ============================================================================
local function drawPieMenu(draw_list, centerX, centerY, items, centerLabel)
    local itemCount = #items
    if itemCount == 0 then return nil end
    
    local baseRadius = 120
    local innerR = 35
    local outerR = baseRadius + 35

    local sectorAngle = (2 * math.pi) / itemCount
    local startAngle = -math.pi / 2  -- Start from top
    
    -- Apply animation scale
    innerR = innerR * menuScale
    outerR = outerR * menuScale
    
    -- Detect which sector is hovered
    local mousePos = imgui.GetIO().MousePos
    local dx = mousePos.x - centerX
    local dy = mousePos.y - centerY
    local dist = math.sqrt(dx * dx + dy * dy)
    local mouseAngle = math.atan2(dy, dx)
    
    local hoveredSector = -1
    if dist > innerR and dist < outerR then
        local normAngle = mouseAngle - startAngle
        if normAngle < 0 then normAngle = normAngle + 2 * math.pi end
        hoveredSector = math.floor(normAngle / sectorAngle) + 1
        if hoveredSector > itemCount then hoveredSector = 1 end
    end
    
    selectedSector = hoveredSector
    
    -- Draw background circle
    local bgAlpha = 0.85 * menuScale
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
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * menuScale)),
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
        local sectorAlpha = isHovered and (0.6 * menuScale) or (0.2 * menuScale)
        
        -- Sector colors (Blue, Orange, Pink, Green)
        local sectorColors = {
            imgui.ImVec4(0.33, 0.67, 0.87, sectorAlpha),
            imgui.ImVec4(1.0, 0.53, 0.27, sectorAlpha),
            imgui.ImVec4(1.0, 0.27, 0.53, sectorAlpha),
            imgui.ImVec4(0.27, 1.0, 0.53, sectorAlpha),
        }
        
        local col = sectorColors[((i - 1) % 4) + 1]
        
        -- Draw filled arc segment
        local arcSegments = 20
        for seg = 0, arcSegments - 1 do
            local a1 = angle1 + (angle2 - angle1) * seg / arcSegments
            local a2 = angle1 + (angle2 - angle1) * (seg + 1) / arcSegments
            local p1 = imgui.ImVec2(centerX + math.cos(a1) * innerR, centerY + math.sin(a1) * innerR)
            local p2 = imgui.ImVec2(centerX + math.cos(a1) * outerR, centerY + math.sin(a1) * outerR)
            local p3 = imgui.ImVec2(centerX + math.cos(a2) * outerR, centerY + math.sin(a2) * outerR)
            local p4 = imgui.ImVec2(centerX + math.cos(a2) * innerR, centerY + math.sin(a2) * innerR)
            local fillColor = imgui.ColorConvertFloat4ToU32(col)
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
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * menuScale)),
            1.5
        )

        
        -- Draw icon and label at sector center
        local iconDist = (innerR + outerR) / 2
        local iconX = centerX + math.cos(midAngle) * iconDist
        local iconY = centerY + math.sin(midAngle) * iconDist
        
        -- Icon
        if item.icon and item.icon ~= "" then
            local iconText = getIcon(item.icon)
            local iconSize = imgui.CalcTextSize(iconText)
            draw_list:AddText(
                imgui.ImVec2(iconX - iconSize.x / 2, iconY - iconSize.y - 2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, menuScale)),
                iconText
            )
        end
        
        -- Label
        local label = item.label or item.name or "---"
        local labelSize = imgui.CalcTextSize(label)
        local labelAlpha = isHovered and menuScale or (0.7 * menuScale)
        draw_list:AddText(
            imgui.ImVec2(iconX - labelSize.x / 2, iconY + 4),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.9, 0.9, labelAlpha)),
            label
        )
        
        ::continue::
    end
    
    -- Draw center circle (close/back button)
    local centerR = 30 * menuScale
    local centerHovered = (dist < centerR)
    local centerAlpha = centerHovered and (0.9 * menuScale) or (0.6 * menuScale)
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.22, centerAlpha)),
        32
    )
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.8, 0.5 * menuScale)),
        32,
        1.5
    )

    
    -- Center label
    local closeIcon = centerLabel or (fa_loaded and faicons('XMARK') or "X")
    local closeSize = imgui.CalcTextSize(closeIcon)
    draw_list:AddText(
        imgui.ImVec2(centerX - closeSize.x / 2, centerY - closeSize.y / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 0.4, 0.4, menuScale)),
        closeIcon
    )
    
    -- Handle clicks
    if imgui.IsMouseClicked(0) then
        if centerHovered then
            return "back"
        elseif hoveredSector >= 1 and hoveredSector <= itemCount then
            return hoveredSector
        end
    end
    
    return nil
end

-- ============================================================================
-- MENU NAVIGATION
-- ============================================================================
local function getMenuItems()
    -- MAIN MENU
    if currentMenu == "main" then
        return {
            { name = iniData.Sector1.name, icon = iniData.Sector1.icon, action = "vehicle" },
            { name = iniData.Sector2.name, icon = iniData.Sector2.icon, cmd = iniData.Sector2.cmd },
            { name = iniData.Sector3.name, icon = iniData.Sector3.icon, action = "anim" },
            { name = iniData.Sector4.name, icon = iniData.Sector4.icon, cmd = iniData.Sector4.cmd },
        }
    
    -- CONTEXT VEHICLE MENU (IN VEHICLE)
    elseif currentMenu == "ctx_veh" then
        return getInVehicleCommands()
    
    -- CONTEXT VEHICLE MENU (ON FOOT)
    elseif currentMenu == "ctx_foot" then
        return getOnFootCommands()
    
    -- ANIMATION CATEGORIES
    elseif currentMenu == "anim_cat" then
        return {
            { name = iniData.CatSector1.name, icon = iniData.CatSector1.icon, category = iniData.CatSector1.name },
            { name = iniData.CatSector2.name, icon = iniData.CatSector2.icon, category = iniData.CatSector2.name },

            { name = iniData.CatSector3.name, icon = iniData.CatSector3.icon, category = iniData.CatSector3.name },
            { name = iniData.CatSector4.name, icon = iniData.CatSector4.icon, category = iniData.CatSector4.name },
        }
    
    -- ANIMATION ITEMS
    elseif currentMenu == "anim_items" then
        local anims = getAnimsForCategory(currentCategory)
        local start = (currentPage - 1) * 4 + 1
        local result = {}
        for i = 0, 3 do
            local anim = anims[start + i]
            if anim then
                result[#result + 1] = { name = anim.label, cmd = anim.cmd, icon = "" }
            end
        end
        return result
    
    -- VEHICLE CATEGORIES
    elseif currentMenu == "veh_cat" then
        return {
            { name = iniData.VehCatSector1.name, icon = iniData.VehCatSector1.icon, category = iniData.VehCatSector1.name },
            { name = iniData.VehCatSector2.name, icon = iniData.VehCatSector2.icon, category = iniData.VehCatSector2.name },
            { name = iniData.VehCatSector3.name, icon = iniData.VehCatSector3.icon, category = iniData.VehCatSector3.name },
            { name = iniData.VehCatSector4.name, icon = iniData.VehCatSector4.icon, category = iniData.VehCatSector4.name },
        }
    
    -- VEHICLE ITEMS
    elseif currentMenu == "veh_items" then
        local vehs = getVehiclesForCategory(currentCategory)
        local start = (currentPage - 1) * 4 + 1
        local result = {}
        for i = 0, 3 do
            local veh = vehs[start + i]
            if veh then
                result[#result + 1] = { name = veh.label, cmd = veh.cmd, icon = "" }
            end
        end
        return result
    end
    
    return {}
end

local function handleMenuAction(action)
    if action == "back" then
        if #menuStack > 0 then
            local prev = table.remove(menuStack)
            currentMenu = prev.menu
            currentCategory = prev.category or ""
            currentPage = prev.page or 1
        else
            showPieMenu = false
            menuOpenTime = os.clock()
        end

        return
    end
    
    local items = getMenuItems()
    if type(action) == "number" and action >= 1 and action <= #items then
        local item = items[action]
        
        -- Execute command if present
        if item.cmd and item.cmd ~= "" then
            executeCommand(item.cmd)
            showPieMenu = false
            menuOpenTime = os.clock()
            return
        end
        
        -- Navigate to submenu
        if item.action == "vehicle" then
            if isPlayerInVehicle() then
                table.insert(menuStack, { menu = currentMenu, category = currentCategory, page = currentPage })
                currentMenu = "ctx_veh"
            else
                table.insert(menuStack, { menu = currentMenu, category = currentCategory, page = currentPage })
                currentMenu = "ctx_foot"
            end
        elseif item.action == "anim" then
            table.insert(menuStack, { menu = currentMenu, category = currentCategory, page = currentPage })
            currentMenu = "anim_cat"
        elseif item.category then
            -- Category selected, go to items
            table.insert(menuStack, { menu = currentMenu, category = currentCategory, page = currentPage })
            currentCategory = item.category
            currentPage = 1
            if currentMenu == "anim_cat" then
                currentMenu = "anim_items"
            elseif currentMenu == "veh_cat" then
                currentMenu = "veh_items"
            end
        end
    end
end

-- ============================================================================
-- IMGUI FRAME
-- ============================================================================
local showTrigger = imgui.new.bool(true)

imgui.OnFrame(function() return showTrigger[0] end, function(self)
    self.HideCursor = not showPieMenu and not showConfigWindow[0]
    
    local sw, sh = getScreenResolution()
    local centerX = sw / 2
    local centerY = sh / 2

    
    -- Calculate animation scale
    local elapsed = os.clock() - menuOpenTime
    local animDuration = 0.3
    
    if showPieMenu then
        local t = clamp(elapsed / animDuration, 0, 1.0)
        menuScale = getEase('outCubic', t)
    else
        local t = clamp(elapsed / animDuration, 0, 1.0)
        menuScale = 1.0 - getEase('inCubic', t)
    end
    
    menuScale = clamp(menuScale, 0, 1.0)
    
    -- ========================================================================
    -- TRIGGER BUTTON (hamburger menu - always visible when config closed)
    -- ========================================================================
    if not showConfigWindow[0] then
        local bx = btnX[0]
        local by = btnY[0]
        local bs = btnSize[0]
        local ba = btnAlpha[0]
        
        btnPulse = (btnPulse + 0.05) % (math.pi * 2)
        local pulse = math.sin(btnPulse) * 0.15 + 1.0
        
        local draw_list = imgui.GetBackgroundDrawList()
        
        -- Outer glow
        local glowAlpha = math.floor(ba * 100 * (1.0 - (pulse - 1.0) * 3))
        local glowColor = glowAlpha * 0x01000000 + 0x0044AAFF
        draw_list:AddCircleFilled(
            imgui.ImVec2(bx + bs/2, by + bs/2),
            (bs/2) * pulse,
            glowColor,
            16
        )
        
        -- Inner circle
        local bgAlpha = math.floor(ba * 220)
        draw_list:AddCircleFilled(
            imgui.ImVec2(bx + bs/2, by + bs/2),
            bs/2,
            bgAlpha * 0x01000000 + 0x00222222,
            32
        )

        
        -- Border
        local borderAlpha = math.floor(ba * 255)
        draw_list:AddCircle(
            imgui.ImVec2(bx + bs/2, by + bs/2),
            bs/2,
            borderAlpha * 0x01000000 + 0x0088DDFF,
            32,
            3.0
        )
        
        -- Hamburger icon (3 lines)
        local iconSize = bs * 0.4
        local iconAlpha = math.floor(ba * 255)
        local iconColor = iconAlpha * 0x01000000 + 0x00FFFFFF
        local lineW = iconSize * 0.8
        local lineH = iconSize * 0.12
        local lineS = iconSize * 0.25
        local centerX = bx + bs/2
        local centerY = by + bs/2
        
        draw_list:AddRectFilled(
            imgui.ImVec2(centerX - lineW/2, centerY - lineS - lineH/2),
            imgui.ImVec2(centerX + lineW/2, centerY - lineS + lineH/2),
            iconColor,
            lineH/2
        )
        draw_list:AddRectFilled(
            imgui.ImVec2(centerX - lineW/2, centerY - lineH/2),
            imgui.ImVec2(centerX + lineW/2, centerY + lineH/2),
            iconColor,
            lineH/2
        )
        draw_list:AddRectFilled(
            imgui.ImVec2(centerX - lineW/2, centerY + lineS - lineH/2),
            imgui.ImVec2(centerX + lineW/2, centerY + lineS + lineH/2),
            iconColor,
            lineH/2
        )
        
        -- Touch handler
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        
        imgui.SetNextWindowPos(imgui.ImVec2(bx, by), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(bs, bs), imgui.Cond.Always)

        imgui.Begin('##TriggerBtn', showTrigger,
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar)
        
        if imgui.InvisibleButton('##trigger', imgui.ImVec2(bs - 10, bs - 10)) then
            togglePieMenu()
        end
        
        imgui.End()
        imgui.PopStyleColor(2)
        imgui.PopStyleVar(2)
    end
    
    -- ========================================================================
    -- PIE MENU (only when animating or open)
    -- ========================================================================
    if menuScale <= 0.01 and not showPieMenu then return end
    
    -- Full screen overlay
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
    
    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    imgui.Begin('##PieOverlay', showTrigger,
        imgui.WindowFlags.NoTitleBar +
        imgui.WindowFlags.NoResize +
        imgui.WindowFlags.NoMove +
        imgui.WindowFlags.NoScrollbar +
        imgui.WindowFlags.NoSavedSettings)
    
    local draw_list = imgui.GetWindowDrawList()
    
    -- Get current menu items
    local items = getMenuItems()
    
    -- Draw pie menu
    local action = drawPieMenu(draw_list, centerX, centerY, items, "BACK")
    
    -- Handle action
    if action then
        handleMenuAction(action)
    end

    
    -- Status text
    if lastExecuted ~= "" then
        local statusText = "Last: " .. lastExecuted
        local statusSize = imgui.CalcTextSize(statusText)
        draw_list:AddText(
            imgui.ImVec2(centerX - statusSize.x / 2, centerY + 200),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.8, 1.0, 0.7 * menuScale)),
            statusText
        )
    end
    
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(2)
end)

-- ============================================================================
-- CONFIG MANAGEMENT (Missing from rebuild - TODO)
-- ============================================================================
-- TODO: Add config window UI
-- TODO: Add profile management functions
-- TODO: Add save/load functions
-- TODO: Add ImGui editor buffers
-- TODO: Add profile dialog
-- NOTE: Config functionality is preserved in INI files but UI is missing
-- Use /rcfg command placeholder for now

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    wait(500)
    
    -- Register commands
    sampRegisterChatCommand("rmenu", function()
        togglePieMenu()
    end)
    
    sampRegisterChatCommand("rcfg", function()
        showNotification("Config UI coming soon! Config files still work.", notif_loaded and Notifications.TYPE.INFO, 3)
        showConfigWindow[0] = not showConfigWindow[0]
    end)
    
    -- Startup messages
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}v1.4.0-alpha loaded!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rmenu{FFFFFF} to toggle menu", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Config: Edit .ini files manually (UI coming soon)", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Profile: {FFFF00}" .. currentProfile, -1)
    
    -- Startup notification
    if notif_loaded and Notifications then
        Notifications.Show("Radial Menu loaded! Use /rmenu", Notifications.TYPE.INFO, 4)
    end
    
    -- Main loop
    while true do
        wait(0)
    end
end
