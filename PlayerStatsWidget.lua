-- ============================================================================
-- PLAYER STATS WIDGET v1.0
-- GTA V Minimalist Style HUD - Flat bars, bottom-left layout
-- ============================================================================

script_name("PlayerStatsWidget")
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

local zones_loaded = false
local zones = nil
pcall(function()
    zones = require 'zones'
    zones_loaded = true
end)

-- ============================================================================
-- ZONE DATA (fallback if zones.lua doesn't provide calculateZone)
-- ============================================================================
local zoneData = {
    {"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
    {"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
    {"Los Santos", -3000, -3000, -100, 3000, 3000, 1000},
}

local function getZoneNameFallback(x, y, z)
    if zones_loaded and zones and zones.calculateZone then
        return zones.calculateZone(x, y, z)
    end
    if zones_loaded and zones and type(zones) == "function" then
        return zones(x, y, z)
    end
    return "San Andreas"
end

-- ============================================================================
-- WEAPON NAMES TABLE
-- ============================================================================
local weaponNames = {
    [0] = "Fist", [1] = "Brass Knuckles", [2] = "Golf Club", [3] = "Nightstick",
    [4] = "Knife", [5] = "Baseball Bat", [6] = "Shovel", [7] = "Pool Cue",
    [8] = "Katana", [9] = "Chainsaw", [10] = "Purple Dildo", [11] = "Dildo",
    [12] = "Vibrator", [13] = "Silver Vibrator", [14] = "Flowers", [15] = "Cane",
    [16] = "Grenade", [17] = "Tear Gas", [18] = "Molotov", [22] = "9mm",
    [23] = "Silenced 9mm", [24] = "Desert Eagle", [25] = "Shotgun",
    [26] = "Sawnoff Shotgun", [27] = "Combat Shotgun", [28] = "Micro SMG",
    [29] = "MP5", [30] = "AK-47", [31] = "M4", [32] = "Tec-9",
    [33] = "Country Rifle", [34] = "Sniper Rifle", [35] = "RPG",
    [36] = "HS Rocket", [37] = "Flamethrower", [38] = "Minigun",
    [39] = "Satchel Charge", [40] = "Detonator", [41] = "Spraycan",
    [42] = "Fire Extinguisher", [43] = "Camera", [44] = "Night Vis Goggles",
    [45] = "Thermal Goggles", [46] = "Parachute",
}

local function getWeaponNameById(id)
    return weaponNames[id] or "Unknown"
end

-- ============================================================================
-- CONFIG
-- ============================================================================
local iniFileName = "PlayerStatsWidget.ini"

local defaultConfig = {
    Settings = {
        enabled = true,
        hideGameHud = false,
        posX = 20.0,
        posY = 0.85,
        opacity = 0.80,
        showHP = true,
        showArmor = true,
        showMoney = true,
        showWeapon = true,
        showZone = true,
        showFPS = true,
    }
}

local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end
if not iniData.Settings then iniData.Settings = defaultConfig.Settings end
for k, v in pairs(defaultConfig.Settings) do
    if iniData.Settings[k] == nil then
        iniData.Settings[k] = v
    end
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local showConfigWindow = imgui.new.bool(false)

-- Config imgui bindings
local cfgEnabled = imgui.new.bool(iniData.Settings.enabled)
local cfgHideGameHud = imgui.new.bool(iniData.Settings.hideGameHud)
local cfgPosX = imgui.new.float(iniData.Settings.posX)
local cfgPosY = imgui.new.float(iniData.Settings.posY)
local cfgOpacity = imgui.new.float(iniData.Settings.opacity)
local cfgShowHP = imgui.new.bool(iniData.Settings.showHP)
local cfgShowArmor = imgui.new.bool(iniData.Settings.showArmor)
local cfgShowMoney = imgui.new.bool(iniData.Settings.showMoney)
local cfgShowWeapon = imgui.new.bool(iniData.Settings.showWeapon)
local cfgShowZone = imgui.new.bool(iniData.Settings.showZone)
local cfgShowFPS = imgui.new.bool(iniData.Settings.showFPS)

-- FPS counter
local fpsCounter = 0
local fpsValue = 0
local fpsLastTime = 0

-- Cached values (update every few frames for performance)
local cachedHP = 100
local cachedArmor = 0
local cachedMoney = 0
local cachedWeaponName = "Fist"
local cachedAmmo = 0
local cachedZone = "San Andreas"
local cacheUpdateTimer = 0
local CACHE_INTERVAL = 0.25 -- update every 250ms

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function lerpColor(r1, g1, b1, r2, g2, b2, t)
    t = clamp(t, 0, 1)
    return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t
end

local function formatMoney(amount)
    local formatted = tostring(math.abs(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    if amount < 0 then
        return "-$" .. formatted
    end
    return "$" .. formatted
end

local function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize - 1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r + 1] = string.char(c)
    end
    return table.concat(r)
end

-- ============================================================================
-- DATA UPDATE FUNCTION
-- ============================================================================
local function updateCachedData()
    local now = os.clock()
    if now - cacheUpdateTimer < CACHE_INTERVAL then return end
    cacheUpdateTimer = now

    -- HP
    pcall(function()
        local hp = 0
        if PLAYER_PED and PLAYER_PED ~= 0 then
            local result, val = pcall(getCharHealth, PLAYER_PED)
            if result then hp = val - 5 end -- SA-MP subtracts 5 from displayed HP
        end
        cachedHP = clamp(hp, 0, 100)
    end)

    -- Armor
    pcall(function()
        if PLAYER_PED and PLAYER_PED ~= 0 then
            local result, val = pcall(getCharArmour, PLAYER_PED)
            if result then cachedArmor = clamp(val, 0, 100) end
        end
    end)

    -- Money
    pcall(function()
        local result, val = pcall(getPlayerMoney, 0)
        if result then cachedMoney = val end
    end)

    -- Weapon
    pcall(function()
        if PLAYER_PED and PLAYER_PED ~= 0 then
            local result, weapId = pcall(getCurrentCharWeapon, PLAYER_PED)
            if result then
                cachedWeaponName = getWeaponNameById(weapId)
                local res2, ammo = pcall(getAmmoInCharWeapon, PLAYER_PED, weapId)
                if res2 then
                    cachedAmmo = ammo
                else
                    cachedAmmo = 0
                end
            end
        end
    end)

    -- Zone
    pcall(function()
        if PLAYER_PED and PLAYER_PED ~= 0 then
            local x, y, z
            local result
            result, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
            if result and x then
                cachedZone = getZoneNameFallback(x, y, z)
            end
        end
    end)
end

-- ============================================================================
-- FPS CALCULATION
-- ============================================================================
local function updateFPS()
    fpsCounter = fpsCounter + 1
    local now = os.clock()
    if now - fpsLastTime >= 1.0 then
        fpsValue = fpsCounter
        fpsCounter = 0
        fpsLastTime = now
    end
end

-- ============================================================================
-- SAVE CONFIG
-- ============================================================================
local function saveConfig()
    iniData.Settings.enabled = cfgEnabled[0]
    iniData.Settings.hideGameHud = cfgHideGameHud[0]
    iniData.Settings.posX = cfgPosX[0]
    iniData.Settings.posY = cfgPosY[0]
    iniData.Settings.opacity = cfgOpacity[0]
    iniData.Settings.showHP = cfgShowHP[0]
    iniData.Settings.showArmor = cfgShowArmor[0]
    iniData.Settings.showMoney = cfgShowMoney[0]
    iniData.Settings.showWeapon = cfgShowWeapon[0]
    iniData.Settings.showZone = cfgShowZone[0]
    iniData.Settings.showFPS = cfgShowFPS[0]

    if inicfg.save(iniData, iniFileName) then
        sampAddChatMessage("{00FF00}[HUD] {FFFFFF}Configuration saved!", -1)
    else
        sampAddChatMessage("{FF0000}[HUD] {FFFFFF}Failed to save config!", -1)
    end
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[PlayerStats HUD] {FFFFFF}Loaded! Use {FFFF00}/hudcfg{FFFFFF} to configure.", -1)

    sampRegisterChatCommand("hudcfg", function()
        showConfigWindow[0] = not showConfigWindow[0]
    end)

    fpsLastTime = os.clock()

    -- Apply game HUD toggle on load
    pcall(function()
        if cfgHideGameHud[0] then
            displayHud(false)
        end
    end)

    imgui.OnFrame(function() return true end, function()
        local sw, sh = getScreenResolution()
        local draw_list = imgui.GetBackgroundDrawList()

        -- Update FPS
        updateFPS()

        -- Check if spawned
        local spawned = false
        pcall(function() spawned = sampIsLocalPlayerSpawned() end)

        -- Draw HUD
        if spawned and cfgEnabled[0] then
            updateCachedData()

            -- Apply game HUD setting
            pcall(function()
                displayHud(not cfgHideGameHud[0])
            end)

            local opacity = cfgOpacity[0]
            local baseX = cfgPosX[0]
            local baseY = cfgPosY[0] * sh

            -- HUD dimensions
            local barWidth = 160
            local barHeight = 8
            local lineHeight = 20
            local padding = 10
            local bgPadding = 12

            -- Calculate total height based on visible elements
            local totalElements = 0
            if cfgShowHP[0] then totalElements = totalElements + 1 end
            if cfgShowArmor[0] then totalElements = totalElements + 1 end
            if cfgShowZone[0] then totalElements = totalElements + 1 end
            if cfgShowMoney[0] then totalElements = totalElements + 1 end
            if cfgShowWeapon[0] then totalElements = totalElements + 1 end
            if cfgShowFPS[0] then totalElements = totalElements + 1 end

            local totalHeight = totalElements * lineHeight + bgPadding * 2
            local totalWidth = barWidth + 60 + bgPadding * 2

            -- Semi-transparent dark background
            local bgX1 = baseX - bgPadding
            local bgY1 = baseY - bgPadding
            local bgX2 = baseX + totalWidth
            local bgY2 = baseY + totalHeight - bgPadding

            draw_list:AddRectFilled(
                imgui.ImVec2(bgX1, bgY1),
                imgui.ImVec2(bgX2, bgY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.05, 0.05, 0.08, 0.7 * opacity)),
                6, 15
            )

            -- Subtle border
            draw_list:AddRect(
                imgui.ImVec2(bgX1, bgY1),
                imgui.ImVec2(bgX2, bgY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.25, 0.3 * opacity)),
                6, 15, 1
            )

            local curY = baseY
            local textX = baseX

            -- HP BAR
            if cfgShowHP[0] then
                local hpPercent = cachedHP / 100.0
                -- Color: green when high, yellow when mid, red when low
                local r, g, b
                if cachedHP > 50 then
                    r, g, b = lerpColor(1.0, 1.0, 0.0, 0.18, 0.8, 0.34, (cachedHP - 50) / 50.0)
                else
                    r, g, b = lerpColor(0.9, 0.15, 0.15, 1.0, 1.0, 0.0, cachedHP / 50.0)
                end

                -- Bar background
                draw_list:AddRectFilled(
                    imgui.ImVec2(textX, curY + 4),
                    imgui.ImVec2(textX + barWidth, curY + 4 + barHeight),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.18, 0.6 * opacity)),
                    3, 15
                )
                -- Bar fill
                if hpPercent > 0 then
                    draw_list:AddRectFilled(
                        imgui.ImVec2(textX, curY + 4),
                        imgui.ImVec2(textX + barWidth * hpPercent, curY + 4 + barHeight),
                        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, 0.9 * opacity)),
                        3, 15
                    )
                end
                -- HP value text
                local hpText = tostring(math.floor(cachedHP))
                draw_list:AddText(
                    imgui.ImVec2(textX + barWidth + 8, curY + 1),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, opacity)),
                    hpText
                )
                curY = curY + lineHeight
            end

            -- ARMOR BAR
            if cfgShowArmor[0] then
                local armorPercent = cachedArmor / 100.0
                -- Blue color for armor
                local ar, ag, ab = 0.2, 0.5, 0.95

                -- Bar background
                draw_list:AddRectFilled(
                    imgui.ImVec2(textX, curY + 4),
                    imgui.ImVec2(textX + barWidth, curY + 4 + barHeight),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.18, 0.6 * opacity)),
                    3, 15
                )
                -- Bar fill
                if armorPercent > 0 then
                    draw_list:AddRectFilled(
                        imgui.ImVec2(textX, curY + 4),
                        imgui.ImVec2(textX + barWidth * armorPercent, curY + 4 + barHeight),
                        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(ar, ag, ab, 0.9 * opacity)),
                        3, 15
                    )
                end
                -- Armor value text
                local armorText = tostring(math.floor(cachedArmor))
                draw_list:AddText(
                    imgui.ImVec2(textX + barWidth + 8, curY + 1),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(ar, ag, ab, opacity)),
                    armorText
                )
                curY = curY + lineHeight
            end

            -- ZONE NAME
            if cfgShowZone[0] then
                draw_list:AddText(
                    imgui.ImVec2(textX, curY + 2),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.75, 0.75, 0.8, 0.9 * opacity)),
                    cachedZone
                )
                curY = curY + lineHeight
            end

            -- MONEY
            if cfgShowMoney[0] then
                local moneyColor
                if cachedMoney >= 0 then
                    moneyColor = imgui.ImVec4(0.18, 0.85, 0.3, opacity)
                else
                    moneyColor = imgui.ImVec4(0.9, 0.2, 0.2, opacity)
                end
                draw_list:AddText(
                    imgui.ImVec2(textX, curY + 2),
                    imgui.ColorConvertFloat4ToU32(moneyColor),
                    formatMoney(cachedMoney)
                )
                curY = curY + lineHeight
            end

            -- WEAPON + AMMO
            if cfgShowWeapon[0] then
                local weaponText
                if cachedWeaponName == "Fist" or cachedAmmo == 0 then
                    weaponText = cachedWeaponName
                else
                    weaponText = cachedWeaponName .. " | " .. tostring(cachedAmmo)
                end
                draw_list:AddText(
                    imgui.ImVec2(textX, curY + 2),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.9, 0.95, 0.9 * opacity)),
                    weaponText
                )
                curY = curY + lineHeight
            end

            -- FPS
            if cfgShowFPS[0] then
                draw_list:AddText(
                    imgui.ImVec2(textX, curY + 2),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.9, 0.2, 0.9 * opacity)),
                    "FPS: " .. tostring(fpsValue)
                )
                curY = curY + lineHeight
            end
        end

        -- CONFIG WINDOW
        if showConfigWindow[0] then
            local winW = 420
            local winH = 420

            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
            imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
            imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.2, 0.8, 0.4, 1.0))
            imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
            imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))

            imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.FirstUseEver)
            imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))
            imgui.Begin("HUD Config", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

            -- Title
            imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.6, 1), "PLAYER STATS HUD")
            imgui.SameLine()
            imgui.TextDisabled("v1.0")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Main toggles
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1), "GENERAL")
            imgui.Spacing()
            imgui.Checkbox("Enable Custom HUD", cfgEnabled)
            imgui.Checkbox("Hide Game Default HUD", cfgHideGameHud)
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Position & Opacity
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1), "POSITION & STYLE")
            imgui.Spacing()
            imgui.Text("Position X:")
            imgui.SetNextItemWidth(-1)
            imgui.SliderFloat("##posX", cfgPosX, 0, sw * 0.8, "%.0f")
            imgui.Text("Position Y (screen ratio):")
            imgui.SetNextItemWidth(-1)
            imgui.SliderFloat("##posY", cfgPosY, 0.1, 0.95, "%.2f")
            imgui.Text("Opacity:")
            imgui.SetNextItemWidth(-1)
            imgui.SliderFloat("##opacity", cfgOpacity, 0.1, 1.0, "%.2f")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Element toggles
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1), "ELEMENTS")
            imgui.Spacing()
            imgui.Checkbox("Show HP Bar", cfgShowHP)
            imgui.SameLine(210)
            imgui.Checkbox("Show Armor Bar", cfgShowArmor)
            imgui.Checkbox("Show Zone Name", cfgShowZone)
            imgui.SameLine(210)
            imgui.Checkbox("Show Money", cfgShowMoney)
            imgui.Checkbox("Show Weapon/Ammo", cfgShowWeapon)
            imgui.SameLine(210)
            imgui.Checkbox("Show FPS", cfgShowFPS)
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Save button
            if imgui.Button("SAVE CONFIG", imgui.ImVec2(-1, 35)) then
                saveConfig()
                showConfigWindow[0] = false
            end

            imgui.End()
            imgui.PopStyleColor(8)
            imgui.PopStyleVar(4)
        end
    end)

    while true do wait(100) end
end
