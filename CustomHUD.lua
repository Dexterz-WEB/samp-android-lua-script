script_name("Custom HUD")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

-- ============================================================================
-- CONFIG (same flat style as RadialMenu - proven to work)
-- ============================================================================
local configFile = "CustomHUDConfig.ini"
local defaultCfg = {
    LeftPanel = { posX = 15.0, posY = 0.0 },
    RightPanel = { posX = 0.0, posY = 0.0 },
    MoneyPanel = { posX = 0.0, posY = 15.0 },
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
-- STATE
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

-- Sliders (loaded from config)
local buf_leftX = imgui.new.float(cfg.LeftPanel.posX or 15.0)
local buf_leftY = imgui.new.float(cfg.LeftPanel.posY or 0.0)
local buf_rightX = imgui.new.float(cfg.RightPanel.posX or 0.0)
local buf_rightY = imgui.new.float(cfg.RightPanel.posY or 0.0)
local buf_moneyX = imgui.new.float(cfg.MoneyPanel.posX or 0.0)
local buf_moneyY = imgui.new.float(cfg.MoneyPanel.posY or 15.0)

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
-- RENDER HUD (same pattern as WeaponDisplayTest - PROVEN WORK)
-- ============================================================================
imgui.OnFrame(function() return showHud end, function()
    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end
    if showConfig[0] then return end

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()

    -- Positions
    local leftX = buf_leftX[0]
    local leftY = (buf_leftY[0] == 0) and (sh - 155) or buf_leftY[0]
    local rightX = (buf_rightX[0] == 0) and (sw - 240) or buf_rightX[0]
    local rightY = (buf_rightY[0] == 0) and (sh - 110) or buf_rightY[0]
    local moneyX = (buf_moneyX[0] == 0) and (sw - 180) or buf_moneyX[0]
    local moneyY = buf_moneyY[0]

    -- ========================================================================
    -- BOTTOM-LEFT PANEL (Zone, HP, Armor, Time)
    -- ========================================================================
    local blW, blH = 260, 140
    dl:AddRectFilled(imgui.ImVec2(leftX, leftY), imgui.ImVec2(leftX + blW, leftY + blH), 0x88000000, 8)

    -- Zone
    dl:AddText(imgui.ImVec2(leftX + 12, leftY + 8), 0xFFDDDDDD, hudData.zoneName)

    -- Separator
    dl:AddLine(imgui.ImVec2(leftX + 10, leftY + 28), imgui.ImVec2(leftX + blW - 10, leftY + 28), 0x44FFFFFF, 1)

    -- HP Bar
    local hpX, hpY = leftX + 12, leftY + 38
    local hpBarW = 200
    local hpFill = math.max(0, math.min(hudData.health / 100, 1.0)) * hpBarW
    dl:AddText(imgui.ImVec2(hpX, hpY - 1), 0xCC50AF4C, "HP")
    dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpBarW, hpY + 16), 0xFF1A2E1A, 3)
    if hpFill > 0 then
        dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpFill, hpY + 16), 0xFF50AF4C, 3)
    end
    dl:AddText(imgui.ImVec2(hpX + 25 + hpBarW + 5, hpY + 1), 0xFF50AF4C, tostring(math.floor(hudData.health)))

    -- Armor Bar (only if > 0)
    if hudData.armor > 0 then
        local arX, arY = leftX + 12, leftY + 62
        local arBarW = 200
        local arFill = math.max(0, math.min(hudData.armor / 100, 1.0)) * arBarW
        dl:AddText(imgui.ImVec2(arX, arY - 1), 0xCCF39621, "AR")
        dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arBarW, arY + 16), 0xFF0D2A3E, 3)
        if arFill > 0 then
            dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arFill, arY + 16), 0xFFF39621, 3)
        end
        dl:AddText(imgui.ImVec2(arX + 25 + arBarW + 5, arY + 1), 0xFFF39621, tostring(math.floor(hudData.armor)))
    end

    -- Time
    dl:AddText(imgui.ImVec2(leftX + 12, leftY + blH - 25), 0xFFAAAAAA, hudData.serverTime)

    -- ========================================================================
    -- TOP-RIGHT (Money)
    -- ========================================================================
    local moneyText = "$" .. tostring(hudData.money)
    dl:AddRectFilled(imgui.ImVec2(moneyX - 10, moneyY - 5), imgui.ImVec2(moneyX + 160, moneyY + 22), 0x88000000, 6)
    dl:AddText(imgui.ImVec2(moneyX, moneyY), 0xFF50AF4C, moneyText)

    -- ========================================================================
    -- BOTTOM-RIGHT PANEL (Weapon, Speed, FPS)
    -- ========================================================================
    local brW, brH = 225, 95
    dl:AddRectFilled(imgui.ImVec2(rightX, rightY), imgui.ImVec2(rightX + brW, rightY + brH), 0x88000000, 8)

    -- Weapon
    local wepName = weaponNames[hudData.weaponId] or "Unknown"
    local ammoText
    if hudData.weaponId == 0 then
        ammoText = wepName
    else
        ammoText = wepName .. "  " .. hudData.ammoClip .. " / " .. hudData.ammoTotal
    end
    dl:AddText(imgui.ImVec2(rightX + 12, rightY + 12), 0xFFFFFFFF, ammoText)

    -- Separator
    dl:AddLine(imgui.ImVec2(rightX + 10, rightY + 35), imgui.ImVec2(rightX + brW - 10, rightY + 35), 0x44FFFFFF, 1)

    -- Speed
    if hudData.inVehicle then
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + 42), 0xFFFFFFFF, tostring(hudData.speed) .. " km/h")
    else
        dl:AddText(imgui.ImVec2(rightX + 12, rightY + 42), 0xFF666666, "On Foot")
    end

    -- FPS
    dl:AddText(imgui.ImVec2(rightX + 12, rightY + brH - 25), 0xFFAAAAAA, "FPS: " .. tostring(hudData.fps))
end)

-- ============================================================================
-- CONFIG WINDOW (sliders only - position per panel)
-- ============================================================================
imgui.OnFrame(function() return showConfig[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(50, 50), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.FirstUseEver)
    imgui.Begin("Custom HUD Config", showConfig)

    imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "--- POSITIONS ---")
    imgui.Spacing()

    imgui.Text("Left Panel (HP/Armor/Zone/Time):")
    imgui.SliderFloat("Left X", buf_leftX, 0, sw - 300, "%.0f")
    imgui.SliderFloat("Left Y", buf_leftY, 0, sh - 200, "%.0f")

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    imgui.Text("Right Panel (Weapon/Speed/FPS):")
    imgui.SliderFloat("Right X", buf_rightX, 0, sw - 250, "%.0f")
    imgui.SliderFloat("Right Y", buf_rightY, 0, sh - 150, "%.0f")

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    imgui.Text("Money:")
    imgui.SliderFloat("Money X", buf_moneyX, 0, sw - 200, "%.0f")
    imgui.SliderFloat("Money Y", buf_moneyY, 0, sh - 50, "%.0f")

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 35)) then
        cfg.LeftPanel.posX = buf_leftX[0]
        cfg.LeftPanel.posY = buf_leftY[0]
        cfg.RightPanel.posX = buf_rightX[0]
        cfg.RightPanel.posY = buf_rightY[0]
        cfg.MoneyPanel.posX = buf_moneyX[0]
        cfg.MoneyPanel.posY = buf_moneyY[0]
        inicfg.save(cfg, configFile)
        sampAddChatMessage("{00FF00}[CustomHUD] {FFFFFF}Positions saved!", -1)
    end

    imgui.End()
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}GTA V Style HUD loaded!", -1)
    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Use {FFFF00}/chud{FFFFFF} to adjust positions", -1)

    sampRegisterChatCommand("chud", function()
        showConfig[0] = not showConfig[0]
    end)

    while true do
        wait(100)

        if sampIsLocalPlayerSpawned() then
            pcall(function() hudData.health = getCharHealth(PLAYER_PED) end)
            pcall(function() hudData.armor = getCharArmour(PLAYER_PED) end)
            pcall(function() hudData.money = getPlayerMoney(0) end)
            pcall(function() hudData.weaponId = getCurrentCharWeapon(PLAYER_PED) end)
            pcall(function()
                if hudData.weaponId > 0 then
                    hudData.ammoTotal = getAmmoInCharWeapon(PLAYER_PED, hudData.weaponId)
                    local ok, clip = pcall(getAmmoInClip, PLAYER_PED, hudData.weaponId)
                    hudData.ammoClip = ok and clip or 0
                end
            end)
            pcall(function()
                hudData.inVehicle = isCharInAnyCar(PLAYER_PED)
                if hudData.inVehicle then
                    local veh = storeCarCharIsInNoSave(PLAYER_PED)
                    if veh then hudData.speed = math.floor(getCarSpeed(veh) * 3.6) end
                else
                    hudData.speed = 0
                end
            end)
            pcall(function()
                if getTimeOfDay then
                    local h, m = getTimeOfDay()
                    hudData.serverTime = string.format("%02d:%02d", h, m)
                end
            end)
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
