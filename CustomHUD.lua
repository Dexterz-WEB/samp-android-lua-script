script_name("Custom HUD")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'

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
local hideDefaultHud = false
local hideDefaultRadar = false

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

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()

    -- ========================================================================
    -- BOTTOM-LEFT GROUP (HP, Armor, Zone)
    -- ========================================================================

    -- Background panel bottom-left
    local blX, blY = 15, sh - 155
    local blW, blH = 260, 140
    dl:AddRectFilled(imgui.ImVec2(blX, blY), imgui.ImVec2(blX + blW, blY + blH), 0x88000000, 8)

    -- Zone Name (top of bottom-left panel)
    local zoneTxt = hudData.zoneName or "Unknown"
    dl:AddText(imgui.ImVec2(blX + 12, blY + 8), 0xFFDDDDDD, zoneTxt)

    -- Thin separator line
    dl:AddLine(imgui.ImVec2(blX + 10, blY + 28), imgui.ImVec2(blX + blW - 10, blY + 28), 0x44FFFFFF, 1)

    -- HP Bar
    local hpX, hpY = blX + 12, blY + 38
    local hpBarW, hpBarH = 210, 16
    local hpFill = math.max(0, math.min(hudData.health / 100, 1.0)) * hpBarW
    -- Label
    dl:AddText(imgui.ImVec2(hpX, hpY - 1), 0xCC50AF4C, "HP")
    -- Bar background
    dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpBarW, hpY + hpBarH), 0xFF1A2E1A, 3)
    -- Bar fill
    if hpFill > 0 then
        dl:AddRectFilled(imgui.ImVec2(hpX + 25, hpY), imgui.ImVec2(hpX + 25 + hpFill, hpY + hpBarH), 0xFF50AF4C, 3)
    end
    -- Value
    dl:AddText(imgui.ImVec2(hpX + 25 + hpBarW + 5, hpY + 1), 0xFF50AF4C, tostring(math.floor(hudData.health)))

    -- Armor Bar (only if armor > 0)
    if hudData.armor > 0 then
        local arX, arY = blX + 12, blY + 62
        local arBarW, arBarH = 210, 16
        local arFill = math.max(0, math.min(hudData.armor / 100, 1.0)) * arBarW
        -- Label
        dl:AddText(imgui.ImVec2(arX, arY - 1), 0xCCF39621, "AR")
        -- Bar background
        dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arBarW, arY + arBarH), 0xFF0D2A3E, 3)
        -- Bar fill
        if arFill > 0 then
            dl:AddRectFilled(imgui.ImVec2(arX + 25, arY), imgui.ImVec2(arX + 25 + arFill, arY + arBarH), 0xFFF39621, 3)
        end
        -- Value
        dl:AddText(imgui.ImVec2(arX + 25 + arBarW + 5, arY + 1), 0xFFF39621, tostring(math.floor(hudData.armor)))
    end

    -- Server Time (bottom of panel)
    dl:AddText(imgui.ImVec2(blX + 12, blY + blH - 25), 0xFFAAAAAA, hudData.serverTime)

    -- ========================================================================
    -- TOP-RIGHT GROUP (Money, Wanted)
    -- ========================================================================

    -- Money
    local moneyText = "$" .. tostring(hudData.money)
    local moneyX = sw - 180
    local moneyY = 15
    -- Background
    dl:AddRectFilled(imgui.ImVec2(moneyX - 10, moneyY - 5), imgui.ImVec2(sw - 10, moneyY + 22), 0x88000000, 6)
    dl:AddText(imgui.ImVec2(moneyX, moneyY), 0xFF50AF4C, moneyText)

    -- ========================================================================
    -- BOTTOM-RIGHT GROUP (Weapon, Speed)
    -- ========================================================================

    local brX = sw - 240
    local brY = sh - 110
    local brW = 225
    local brH = 95

    -- Background
    dl:AddRectFilled(imgui.ImVec2(brX, brY), imgui.ImVec2(brX + brW, brY + brH), 0x88000000, 8)

    -- Weapon name + ammo
    local wepName = weaponNames[hudData.weaponId] or "Unknown"
    local ammoText
    if hudData.weaponId == 0 then
        ammoText = wepName
    else
        ammoText = wepName .. "  " .. hudData.ammoClip .. " / " .. hudData.ammoTotal
    end
    dl:AddText(imgui.ImVec2(brX + 12, brY + 12), 0xFFFFFFFF, ammoText)

    -- Thin separator
    dl:AddLine(imgui.ImVec2(brX + 10, brY + 35), imgui.ImVec2(brX + brW - 10, brY + 35), 0x44FFFFFF, 1)

    -- Speed (only in vehicle)
    if hudData.inVehicle then
        local speedStr = tostring(hudData.speed)
        dl:AddText(imgui.ImVec2(brX + 12, brY + 42), 0xFFFFFFFF, speedStr)
        dl:AddText(imgui.ImVec2(brX + 12 + (#speedStr * 11), brY + 45), 0xFFAAAAAA, " km/h")
    else
        dl:AddText(imgui.ImVec2(brX + 12, brY + 42), 0xFF666666, "On Foot")
    end

    -- FPS (bottom of panel)
    dl:AddText(imgui.ImVec2(brX + 12, brY + brH - 25), 0xFFAAAAAA, "FPS: " .. tostring(hudData.fps))

    -- ========================================================================
    -- TOP-LEFT: HUD STATUS INDICATOR (small)
    -- ========================================================================
    if hideDefaultHud then
        dl:AddText(imgui.ImVec2(15, 15), 0xFF00FFFF, "[CUSTOM HUD]")
    end
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}GTA V Style HUD loaded!", -1)
    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Commands:", -1)
    sampAddChatMessage("{FFFF00}/chud {FFFFFF}- Toggle custom HUD on/off", -1)
    sampAddChatMessage("{FFFF00}/chudhide {FFFFFF}- Toggle hide default HUD", -1)
    sampAddChatMessage("{FFFF00}/chudradar {FFFFFF}- Toggle hide default radar", -1)

    -- Toggle custom HUD
    sampRegisterChatCommand("chud", function()
        showHud = not showHud
        sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Custom HUD: " ..
            (showHud and "{00FF00}ON" or "{FF0000}OFF"), -1)
    end)

    -- Toggle hide default HUD
    sampRegisterChatCommand("chudhide", function()
        hideDefaultHud = not hideDefaultHud
        sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Default HUD: " ..
            (hideDefaultHud and "{FF0000}HIDDEN" or "{00FF00}VISIBLE"), -1)
    end)

    -- Toggle hide default radar
    sampRegisterChatCommand("chudradar", function()
        hideDefaultRadar = not hideDefaultRadar
        sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Default Radar: " ..
            (hideDefaultRadar and "{FF0000}HIDDEN" or "{00FF00}VISIBLE"), -1)
    end)

    while true do
        wait(100)

        if sampIsLocalPlayerSpawned() then
            -- Hide/show default HUD (only when toggled by user)
            if hideDefaultHud then
                pcall(displayHud, false)
            else
                pcall(displayHud, true)
            end
            if hideDefaultRadar then
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
