-- ============================================================================
-- WEAPON DISPLAY TEST (Fase 1 - Minimalist)
-- Test: detect current weapon + ammo, display via ImGui text
-- This is a standalone test - does NOT modify RadialMenu.lua
-- ============================================================================

script_name("Weapon Display Test")
script_author("OnlyDexterZ")
script_version("1.0")

local imgui = require 'mimgui'

-- ============================================================================
-- WEAPON NAMES TABLE (ID 0-46)
-- ============================================================================
local WEAPON_NAMES = {
    [0]  = "Fist",
    [1]  = "Brass Knuckles",
    [2]  = "Golf Club",
    [3]  = "Nightstick",
    [4]  = "Knife",
    [5]  = "Baseball Bat",
    [6]  = "Shovel",
    [7]  = "Pool Cue",
    [8]  = "Katana",
    [9]  = "Chainsaw",
    [10] = "Purple Dildo",
    [11] = "Dildo",
    [12] = "Vibrator",
    [13] = "Silver Vibrator",
    [14] = "Flowers",
    [15] = "Cane",
    [16] = "Grenade",
    [17] = "Tear Gas",
    [18] = "Molotov",
    [22] = "9mm Pistol",
    [23] = "Silenced 9mm",
    [24] = "Desert Eagle",
    [25] = "Shotgun",
    [26] = "Sawnoff",
    [27] = "Combat Shotgun",
    [28] = "Micro SMG",
    [29] = "MP5",
    [30] = "AK-47",
    [31] = "M4",
    [32] = "Tec-9",
    [33] = "Country Rifle",
    [34] = "Sniper Rifle",
    [35] = "RPG",
    [36] = "HS Rocket",
    [37] = "Flamethrower",
    [38] = "Minigun",
    [39] = "Satchel Charge",
    [40] = "Detonator",
    [41] = "Spray Can",
    [42] = "Fire Extinguisher",
    [43] = "Camera",
    [44] = "Night Vision",
    [45] = "Thermal Vision",
    [46] = "Parachute",
}

-- ============================================================================
-- STATE
-- ============================================================================
local showWidget = true
local currentWeaponId = 0
local currentWeaponName = "Fist"
local currentAmmo = 0
local currentClip = 0

-- Widget position (configurable)
local widgetX = 0
local widgetY = 0

-- ============================================================================
-- GET WEAPON DATA
-- ============================================================================
local function getWeaponData()
    local ok, err = pcall(function()
        -- Get current weapon ID
        local weaponId = getCurrentCharWeapon(PLAYER_PED)
        currentWeaponId = weaponId or 0
        currentWeaponName = WEAPON_NAMES[currentWeaponId] or ("Unknown [" .. currentWeaponId .. "]")
        
        -- Get ammo
        local ammo = getAmmoInCharWeapon(PLAYER_PED, currentWeaponId)
        currentAmmo = ammo or 0
        
        -- Try get clip ammo (ammo in magazine)
        local ok2, clip = pcall(function()
            return getAmmoInClip(PLAYER_PED, currentWeaponId)
        end)
        currentClip = ok2 and clip or -1
    end)
    
    if not ok then
        currentWeaponName = "ERROR: " .. tostring(err)
    end
end

-- ============================================================================
-- RENDER
-- ============================================================================
imgui.OnFrame(
    function() return showWidget end,
    function()
        local sw, sh = getScreenResolution()
        local draw = imgui.GetBackgroundDrawList()
        
        -- Position: bottom right corner
        local px = widgetX > 0 and widgetX or (sw - 280)
        local py = widgetY > 0 and widgetY or (sh - 80)
        
        -- Background box
        draw:AddRectFilled(
            imgui.ImVec2(px, py),
            imgui.ImVec2(px + 260, py + 60),
            0xCC111111,  -- dark semi-transparent
            8            -- rounded corners
        )
        
        -- Border
        draw:AddRect(
            imgui.ImVec2(px, py),
            imgui.ImVec2(px + 260, py + 60),
            0xFF444444,
            8, 0, 2
        )
        
        -- Weapon name (big text)
        draw:AddText(
            imgui.ImVec2(px + 15, py + 8),
            0xFFFFFFFF,
            currentWeaponName
        )
        
        -- Ammo display
        local ammoText = ""
        if currentWeaponId == 0 then
            ammoText = "MELEE"
        elseif currentAmmo == 0 and currentWeaponId > 0 then
            ammoText = "NO AMMO"
        elseif currentClip >= 0 then
            ammoText = string.format("AMMO: %d / %d", currentClip, currentAmmo)
        else
            ammoText = string.format("AMMO: %d", currentAmmo)
        end
        
        draw:AddText(
            imgui.ImVec2(px + 15, py + 32),
            0xFFAADDFF,
            ammoText
        )
        
        -- Weapon ID (small, for debug)
        draw:AddText(
            imgui.ImVec2(px + 200, py + 42),
            0x88888888,
            string.format("ID:%d", currentWeaponId)
        )
    end
)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FFFF}[Weapon Test] {FFFFFF}Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[Weapon Test] {FFFFFF}Weapon display active (bottom-right)", -1)
    sampAddChatMessage("{00FFFF}[Weapon Test] {FFFFFF}Commands: {FFFF00}/wep {FFFFFF}| {FFFF00}/wephide {FFFFFF}| {FFFF00}/wepmove", -1)
    
    -- Command: show weapon info in chat
    sampRegisterChatCommand("wep", function()
        getWeaponData()
        sampAddChatMessage(string.format(
            "{00FFFF}[Weapon] {FFFFFF}%s (ID:%d) | Ammo: %d | Clip: %s",
            currentWeaponName, currentWeaponId, currentAmmo,
            currentClip >= 0 and tostring(currentClip) or "N/A"
        ), -1)
    end)
    
    -- Command: toggle widget
    sampRegisterChatCommand("wephide", function()
        showWidget = not showWidget
        sampAddChatMessage("{00FFFF}[Weapon] {FFFFFF}Widget: " .. 
            (showWidget and "{00FF00}ON" or "{FF0000}OFF"), -1)
    end)
    
    -- Command: move widget position
    sampRegisterChatCommand("wepmove", function(param)
        local x, y = param:match("(%S+)%s+(%S+)")
        x, y = tonumber(x), tonumber(y)
        if x and y then
            widgetX = x
            widgetY = y
            sampAddChatMessage(string.format(
                "{00FFFF}[Weapon] {FFFFFF}Widget moved to: %d, %d", x, y), -1)
        else
            sampAddChatMessage("{FFFF00}[Weapon] {FFFFFF}Usage: /wepmove X Y", -1)
        end
    end)
    
    -- Main loop - update weapon data
    while true do
        wait(100)
        if sampIsLocalPlayerSpawned() then
            getWeaponData()
        end
    end
end
