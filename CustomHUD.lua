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
    fps = 0,
}

local fpsCounter = 0
local fpsLastTime = os.clock()
local showHud = true

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
-- RENDER (same pattern as WeaponDisplayTest - PROVEN WORK)
-- ============================================================================
imgui.OnFrame(function() return showHud end, function()
    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()

    -- HP Bar (bottom-left)
    local hx, hy = 20, sh - 130
    local hpWidth = math.max(0, (hudData.health / 100) * 200)
    dl:AddRectFilled(imgui.ImVec2(hx, hy), imgui.ImVec2(hx + 200, hy + 18), 0xCC1A3A18, 4)
    dl:AddRectFilled(imgui.ImVec2(hx, hy), imgui.ImVec2(hx + hpWidth, hy + 18), 0xFF50AF4C, 4)
    dl:AddText(imgui.ImVec2(hx + 205, hy + 2), 0xFF50AF4C, tostring(math.floor(hudData.health)))

    -- Armor Bar (bottom-left, below HP)
    if hudData.armor > 0 then
        local ax, ay = 20, sh - 105
        local armorWidth = math.max(0, (hudData.armor / 100) * 200)
        dl:AddRectFilled(imgui.ImVec2(ax, ay), imgui.ImVec2(ax + 200, ay + 18), 0xCC0D3A5E, 4)
        dl:AddRectFilled(imgui.ImVec2(ax, ay), imgui.ImVec2(ax + armorWidth, ay + 18), 0xFFF39621, 4)
        dl:AddText(imgui.ImVec2(ax + 205, ay + 2), 0xFFF39621, tostring(math.floor(hudData.armor)))
    end

    -- Money (top-right)
    local moneyText = "$" .. tostring(hudData.money)
    dl:AddText(imgui.ImVec2(sw - 180, 20), 0xFF50AF4C, moneyText)

    -- Weapon + Ammo (bottom-right)
    local wepName = weaponNames[hudData.weaponId] or "Unknown"
    local ammoText
    if hudData.weaponId == 0 then
        ammoText = wepName
    else
        ammoText = wepName .. " | " .. hudData.ammoClip .. "/" .. hudData.ammoTotal
    end
    dl:AddText(imgui.ImVec2(sw - 220, sh - 90), 0xFFFFFFFF, ammoText)

    -- Speed (only in vehicle)
    if hudData.inVehicle then
        dl:AddText(imgui.ImVec2(sw - 220, sh - 60), 0xFFFFFFFF, tostring(hudData.speed) .. " km/h")
    end

    -- FPS (top-left)
    dl:AddText(imgui.ImVec2(20, 20), 0xFFFFFFFF, "FPS: " .. tostring(hudData.fps))
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Loaded! Use /chud to toggle", -1)

    sampRegisterChatCommand("chud", function()
        showHud = not showHud
        sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}HUD: " ..
            (showHud and "{00FF00}ON" or "{FF0000}OFF"), -1)
    end)

    while true do
        wait(100)

        if sampIsLocalPlayerSpawned() then
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
