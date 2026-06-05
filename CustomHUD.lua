script_name("Custom HUD")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

-- ============================================================================
-- CONFIG (flat structure - proven to work with inicfg on MonetLoader)
-- ============================================================================
local configFile = "CustomHUD.ini"
local defaultCfg = {
    Settings = {
        hideHud = false,
        hideRadar = false,
        opacity = 0.9,
        scale = 1.0,
        showHP = true,
        showArmor = true,
        showMoney = true,
        showWeapon = true,
        showSpeed = true,
        showFPS = true,
        showZone = true,
        showTime = true,
    },
    PanelLeft = { posX = 15.0, posY = 0.0 },
    PanelRight = { posX = 0.0, posY = 0.0 },
    PanelMoney = { posX = 0.0, posY = 15.0 },
}

local cfg = inicfg.load(defaultCfg, configFile)
if not cfg then
    inicfg.save(defaultCfg, configFile)
    cfg = defaultCfg
end
for k, v in pairs(defaultCfg) do
    if not cfg[k] then cfg[k] = v end
end

-- ============================================================================
-- HUD DATA
-- ============================================================================
local hudData = {
    health = 100, armor = 0, money = 0,
    weaponId = 0, ammoClip = 0, ammoTotal = 0,
    inVehicle = false, speed = 0,
    fps = 0, zoneName = "Los Santos", serverTime = "00:00",
}

local fpsCounter = 0
local fpsLastTime = os.clock()
local showHud = true
local showConfig = imgui.new.bool(false)

-- Config sliders
local buf_opacity = imgui.new.float(cfg.Settings.opacity or 0.9)
local buf_scale = imgui.new.float(cfg.Settings.scale or 1.0)
local buf_hideHud = imgui.new.bool(cfg.Settings.hideHud or false)
local buf_hideRadar = imgui.new.bool(cfg.Settings.hideRadar or false)
local buf_showHP = imgui.new.bool(cfg.Settings.showHP ~= false)
local buf_showArmor = imgui.new.bool(cfg.Settings.showArmor ~= false)
local buf_showMoney = imgui.new.bool(cfg.Settings.showMoney ~= false)
local buf_showWeapon = imgui.new.bool(cfg.Settings.showWeapon ~= false)
local buf_showSpeed = imgui.new.bool(cfg.Settings.showSpeed ~= false)
local buf_showFPS = imgui.new.bool(cfg.Settings.showFPS ~= false)
local buf_showZone = imgui.new.bool(cfg.Settings.showZone ~= false)
local buf_showTime = imgui.new.bool(cfg.Settings.showTime ~= false)
local buf_leftX = imgui.new.float(cfg.PanelLeft.posX or 15.0)
local buf_leftY = imgui.new.float(cfg.PanelLeft.posY or 0.0)
local buf_rightX = imgui.new.float(cfg.PanelRight.posX or 0.0)
local buf_rightY = imgui.new.float(cfg.PanelRight.posY or 0.0)
local buf_moneyX = imgui.new.float(cfg.PanelMoney.posX or 0.0)
local buf_moneyY = imgui.new.float(cfg.PanelMoney.posY or 15.0)

-- ============================================================================
-- WEAPON NAMES
-- ============================================================================
local weaponNames = {
    [0] = "Fist", [1] = "Brass Knuckles", [2] = "Golf Club",
    [3] = "Nightstick", [4] = "Knife", [5] = "Baseball Bat",
    [6] = "Shovel", [7] = "Pool Cue", [8] = "Katana", [9] = "Chainsaw",
    [16] = "Grenade", [17] = "Tear Gas", [18] = "Molotov",
    [22] = "9mm", [23] = "Silenced 9mm", [24] = "Desert Eagle",
    [25] = "Shotgun", [26] = "Sawnoff", [27] = "Combat Shotgun",
    [28] = "Micro SMG", [29] = "MP5", [30] = "AK-47", [31] = "M4",
    [32] = "Tec-9", [33] = "Country Rifle", [34] = "Sniper",
    [35] = "RPG", [36] = "HS Rocket", [37] = "Flamethrower",
    [38] = "Minigun", [39] = "Satchel", [40] = "Detonator",
    [41] = "Spray Can", [42] = "Fire Extinguisher", [43] = "Camera",
    [44] = "Night Vision", [45] = "Thermal", [46] = "Parachute",
}

-- ============================================================================
-- RENDER HUD (GTA V Style)
-- ============================================================================
imgui.OnFrame(function() return showHud end, function()
    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end
    if showConfig[0] then return end

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()
    local scale = buf_scale[0]

    -- Panel positions
    local leftX = buf_leftX[0]
    local leftY = (buf_leftY[0] == 0) and (sh - 155) or buf_leftY[0]
    local rightX = (buf_rightX[0] == 0) and (sw - 240) or buf_rightX[0]
    local rightY = (buf_rightY[0] == 0) and (sh - 110) or buf_rightY[0]
    local moneyX = (buf_moneyX[0] == 0) and (sw - 180) or buf_moneyX[0]
    local moneyY = buf_moneyY[0]

    -- ========================================================================
    -- BOTTOM-LEFT PANEL (HP, Armor, Zone, Time)
    -- ========================================================================
    local blW, blH = 260 * scale, 140 * scale
    dl:AddRectFilled(imgui.ImVec2(leftX, leftY), imgui.ImVec2(leftX + blW, leftY + blH), 0x88000000, 8)

    -- Zone Name
    if buf_showZone[0] then
        dl:AddText(imgui.ImVec2(leftX + 12, leftY + 8), 0xFFDDDDDD, hudData.zoneName)
    end

    -- Separator
    dl:AddLine(imgui.ImVec2(leftX + 10, leftY + 28), imgui.ImVec2(leftX + blW - 10, leftY + 28), 0x44FFFFFF, 1)

    -- HP Bar
    if buf_showHP[0] then
        local hpX, hpY = leftX + 12, leftY + 38
        local hpBarW = 200 * scale
        local hpFill = math.max(0, math.min(hudData.health / 100, 1.0)) * hpBarW
        dl:AddText(imgui.ImVec2(hpX, hpY - 1), 0xCC50AF4C, "HP")
        dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpBarW, hpY + 16 * scale), 0xFF1A2E1A, 3)
        if hpFill > 0 then
            dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpFill, hpY + 16 * scale), 0xFF50AF4C, 3)
        end
        dl:AddText(imgui.ImVec2(hpX + 25 + hpBarW + 5, hpY + 1), 0xFF50AF4C, tostring(math.floor(hudData.health)))
    end

    -- Armor Bar
    if buf_showArmor[0] and hudData.armor > 0 then
        local arX, arY = leftX + 12, leftY + 62
        local arBarW = 200 * scale
        local arFill = math.max(0, math.min(hudData.armor / 100, 1.0)) * arBarW
        dl:AddText(imgui.ImVec2(arX, arY - 1), 0xCCF39621, "AR")
        dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arBarW, arY + 16 * scale), 0xFF0D2A3E, 3)
        if arFill > 0 then
            dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arFill, arY + 16 * scale), 0xFFF39621, 3)
        end
        dl:AddText(imgui.ImVec2(arX + 25 + arBarW + 5, arY + 1), 0xFFF39621, tostring(math.floor(hudData.armor)))
    end

    -- Server Time
    if buf_showTime[0] then
        dl:AddText(imgui.ImVec2(leftX + 12, leftY + blH - 25), 0xFFAAAAAA, hudData.serverTime)
    end

    -- ========================================================================
    -- TOP-RIGHT (Money)
    -- ========================================================================
    if buf_showMoney[0] then
        local moneyText = "$" .. tostring(hudData.money)
        dl:AddRectFilled(imgui.ImVec2(moneyX - 10, moneyY - 5), imgui.ImVec2(moneyX + 160 * scale, moneyY + 22), 0x88000000, 6)
        dl:AddText(imgui.ImVec2(moneyX, moneyY), 0xFF50AF4C, moneyText)
    end

    -- ========================================================================
    -- BOTTOM-RIGHT PANEL (Weapon, Speed, FPS)
    -- ========================================================================
    local brW, brH = 225 * scale, 95 * scale
    dl:AddRectFilled(imgui.ImVec2(rightX, rightY), imgui.ImVec2(rightX + brW, rightY + brH), 0x88000000, 8)

    -- Weapon + Ammo
    if buf_showWeapon[0] then
        local wepName = weaponNames[hudData.weaponId] or "Unknown"
        local ammoText
        if hudData.weaponId == 0 then
            ammoText = wepName
        else
            ammoText = wepName .. "  " .. hudData.ammoClip .. " / " .. hudData.ammoTotal
        end
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + 12), 0xFFFFFFFF, ammoText)
    end

    -- Separator
    dl:AddLine(imgui.ImVec2(rightX + 10, rightY + 35), imgui.ImVec2(rightX + brW - 10, rightY + 35), 0x44FFFFFF, 1)

    -- Speed
    if buf_showSpeed[0] and hudData.inVehicle then
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + 42), 0xFFFFFFFF, tostring(hudData.speed) .. " km/h")
    elseif buf_showSpeed[0] then
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + 42), 0xFF666666, "On Foot")
    end

    -- FPS
    if buf_showFPS[0] then
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + brH - 25), 0xFFAAAAAA, "FPS: " .. tostring(hudData.fps))
    end

    -- HUD indicator
    if buf_hideHud[0] then
        dl:AddText(imgui.ImVec2(15, 15), 0xFF00FFFF, "[CUSTOM HUD]")
    end
end)

-- ============================================================================
-- CONFIG WINDOW
-- ============================================================================
imgui.OnFrame(function() return showConfig[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(50, 50), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(450, 550), imgui.Cond.FirstUseEver)
    imgui.Begin("Custom HUD Config", showConfig)

    -- General
    imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "--- GENERAL ---")
    imgui.Checkbox("Hide Default HUD", buf_hideHud)
    imgui.Checkbox("Hide Default Radar", buf_hideRadar)
    imgui.SliderFloat("Opacity", buf_opacity, 0.3, 1.0, "%.2f")
    imgui.SliderFloat("Scale", buf_scale, 0.5, 2.0, "%.2f")

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    -- Elements
    imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "--- SHOW/HIDE ---")
    imgui.Checkbox("HP Bar", buf_showHP)
    imgui.Checkbox("Armor Bar", buf_showArmor)
    imgui.Checkbox("Money", buf_showMoney)
    imgui.Checkbox("Weapon + Ammo", buf_showWeapon)
    imgui.Checkbox("Speed", buf_showSpeed)
    imgui.Checkbox("FPS", buf_showFPS)
    imgui.Checkbox("Zone Name", buf_showZone)
    imgui.Checkbox("Server Time", buf_showTime)

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    -- Positions
    imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "--- POSITIONS ---")
    imgui.Text("Left Panel (HP/Armor/Zone):")
    imgui.SliderFloat("Left X", buf_leftX, 0, sw - 300, "%.0f")
    imgui.SliderFloat("Left Y", buf_leftY, 0, sh - 200, "%.0f")
    imgui.Spacing()
    imgui.Text("Right Panel (Weapon/Speed/FPS):")
    imgui.SliderFloat("Right X", buf_rightX, 0, sw - 250, "%.0f")
    imgui.SliderFloat("Right Y", buf_rightY, 0, sh - 150, "%.0f")
    imgui.Spacing()
    imgui.Text("Money:")
    imgui.SliderFloat("Money X", buf_moneyX, 0, sw - 200, "%.0f")
    imgui.SliderFloat("Money Y", buf_moneyY, 0, sh - 50, "%.0f")

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    -- Save
    if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 35)) then
        cfg.Settings.hideHud = buf_hideHud[0]
        cfg.Settings.hideRadar = buf_hideRadar[0]
        cfg.Settings.opacity = buf_opacity[0]
        cfg.Settings.scale = buf_scale[0]
        cfg.Settings.showHP = buf_showHP[0]
        cfg.Settings.showArmor = buf_showArmor[0]
        cfg.Settings.showMoney = buf_showMoney[0]
        cfg.Settings.showWeapon = buf_showWeapon[0]
        cfg.Settings.showSpeed = buf_showSpeed[0]
        cfg.Settings.showFPS = buf_showFPS[0]
        cfg.Settings.showZone = buf_showZone[0]
        cfg.Settings.showTime = buf_showTime[0]
        cfg.PanelLeft.posX = buf_leftX[0]
        cfg.PanelLeft.posY = buf_leftY[0]
        cfg.PanelRight.posX = buf_rightX[0]
        cfg.PanelRight.posY = buf_rightY[0]
        cfg.PanelMoney.posX = buf_moneyX[0]
        cfg.PanelMoney.posY = buf_moneyY[0]
        inicfg.save(cfg, configFile)
        sampAddChatMessage("{00FF00}[CustomHUD] {FFFFFF}Settings saved!", -1)
    end

    imgui.End()
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}GTA V Style HUD loaded!", -1)
    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Use {FFFF00}/chud{FFFFFF} to open config", -1)

    -- Toggle config window
    sampRegisterChatCommand("chud", function()
        showConfig[0] = not showConfig[0]
    end)

    while true do
        wait(100)

        if sampIsLocalPlayerSpawned() then
            -- Hide/show default HUD
            if buf_hideHud[0] then
                pcall(displayHud, false)
            else
                pcall(displayHud, true)
            end
            if buf_hideRadar[0] then
                pcall(displayRadar, false)
            else
                pcall(displayRadar, true)
            end

            -- Health
            pcall(function() hudData.health = getCharHealth(PLAYER_PED) end)
            -- Armor
            pcall(function() hudData.armor = getCharArmour(PLAYER_PED) end)
            -- Money
            pcall(function() hudData.money = getPlayerMoney(0) end)
            -- Weapon
            pcall(function() hudData.weaponId = getCurrentCharWeapon(PLAYER_PED) end)
            -- Ammo
            pcall(function()
                if hudData.weaponId > 0 then
                    hudData.ammoTotal = getAmmoInCharWeapon(PLAYER_PED, hudData.weaponId)
                    local ok, clip = pcall(getAmmoInClip, PLAYER_PED, hudData.weaponId)
                    hudData.ammoClip = ok and clip or 0
                end
            end)
            -- Vehicle + Speed
            pcall(function()
                hudData.inVehicle = isCharInAnyCar(PLAYER_PED)
                if hudData.inVehicle then
                    local veh = storeCarCharIsInNoSave(PLAYER_PED)
                    if veh then hudData.speed = math.floor(getCarSpeed(veh) * 3.6) end
                else
                    hudData.speed = 0
                end
            end)
            -- Time
            pcall(function()
                if getTimeOfDay then
                    local h, m = getTimeOfDay()
                    hudData.serverTime = string.format("%02d:%02d", h, m)
                end
            end)
            -- Zone
            pcall(function()
                if getNameOfZone then
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    hudData.zoneName = getNameOfZone(x, y, z) or "Unknown"
                end
            end)
        end

        -- FPS
        fpsCounter = fpsCounter + 1
        local now = os.clock()
        if now - fpsLastTime >= 1.0 then
            hudData.fps = fpsCounter
            fpsCounter = 0
            fpsLastTime = now
        end
    end
end
