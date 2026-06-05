script_name("Custom HUD")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

-- ============================================================================
-- CONFIG (flat structure like RadialMenu - proven to work)
-- ============================================================================
local configFile = "CustomHUD.ini"
local defaultConfig = {
    General = {
        hideDefaultHud = true,
        hideDefaultRadar = true,
        globalOpacity = 0.9,
        globalScale = 1.0,
    },
    Elements = {
        showHP = true,
        showArmor = true,
        showMoney = true,
        showWeapon = true,
        showWanted = true,
        showSpeed = true,
        showFPS = true,
        showZone = true,
        showTime = true,
    },
    Positions = {
        hpX = 20, hpY = 0,
        armorX = 20, armorY = 0,
        moneyX = 0, moneyY = 20,
        weaponX = 0, weaponY = 0,
        wantedX = 0, wantedY = 50,
        speedX = 0, speedY = 0,
        fpsX = 20, fpsY = 20,
        zoneX = 20, zoneY = 0,
        timeX = 20, timeY = 50,
    },
}

local cfg = inicfg.load(defaultConfig, configFile)
if not cfg then
    inicfg.save(defaultConfig, configFile)
    cfg = defaultConfig
end
for k, v in pairs(defaultConfig) do
    if not cfg[k] then cfg[k] = v end
end

-- ============================================================================
-- WEAPON NAMES
-- ============================================================================
local weaponNames = {
    [0] = "Fist", [1] = "Brass Knuckles", [2] = "Golf Club",
    [3] = "Nightstick", [4] = "Knife", [5] = "Baseball Bat",
    [6] = "Shovel", [7] = "Pool Cue", [8] = "Katana", [9] = "Chainsaw",
    [10] = "Purple Dildo", [11] = "Dildo", [12] = "Vibrator",
    [13] = "Silver Vibrator", [14] = "Flowers", [15] = "Cane",
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
-- HUD DATA
-- ============================================================================
local hudData = {
    health = 100, armor = 0, money = 0,
    weaponId = 0, ammoClip = 0, ammoTotal = 0,
    inVehicle = false, speed = 0, wantedLevel = 0,
    fps = 0, zoneName = "Los Santos", serverTime = "00:00",
}

local fpsCounter = 0
local fpsLastTime = os.clock()
local fpsValue = 0

-- ============================================================================
-- CONFIG WINDOW
-- ============================================================================
local showConfig = imgui.new.bool(false)

-- Buffers
local buf_opacity = imgui.new.float(cfg.General.globalOpacity or 0.9)
local buf_scale = imgui.new.float(cfg.General.globalScale or 1.0)
local buf_hideHud = imgui.new.bool(cfg.General.hideDefaultHud)
local buf_hideRadar = imgui.new.bool(cfg.General.hideDefaultRadar)
local buf_showHP = imgui.new.bool(cfg.Elements.showHP)
local buf_showArmor = imgui.new.bool(cfg.Elements.showArmor)
local buf_showMoney = imgui.new.bool(cfg.Elements.showMoney)
local buf_showWeapon = imgui.new.bool(cfg.Elements.showWeapon)
local buf_showWanted = imgui.new.bool(cfg.Elements.showWanted)
local buf_showSpeed = imgui.new.bool(cfg.Elements.showSpeed)
local buf_showFPS = imgui.new.bool(cfg.Elements.showFPS)
local buf_showZone = imgui.new.bool(cfg.Elements.showZone)
local buf_showTime = imgui.new.bool(cfg.Elements.showTime)

-- ============================================================================
-- HELPERS
-- ============================================================================
local function formatMoney(amount)
    local formatted = tostring(math.abs(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return (amount < 0 and "-$" or "$") .. formatted
end

local function getWeaponName(id)
    return weaponNames[id] or ("Weapon " .. tostring(id))
end

-- ============================================================================
-- UPDATE HUD DATA
-- ============================================================================
local function updateHudData()
    pcall(function() hudData.health = getCharHealth(PLAYER_PED) end)
    pcall(function() hudData.armor = getCharArmour(PLAYER_PED) end)
    pcall(function() hudData.money = getPlayerMoney(0) end)
    pcall(function() hudData.weaponId = getCurrentCharWeapon(PLAYER_PED) end)
    pcall(function()
        if hudData.weaponId > 0 then
            hudData.ammoTotal = getAmmoInCharWeapon(PLAYER_PED, hudData.weaponId)
            local ok, clip = pcall(getAmmoInClip, PLAYER_PED, hudData.weaponId)
            hudData.ammoClip = ok and clip or 0
        else
            hudData.ammoTotal = 0
            hudData.ammoClip = 0
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
        if getPlayerWantedLevel then
            hudData.wantedLevel = getPlayerWantedLevel(0)
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

    -- FPS
    fpsCounter = fpsCounter + 1
    local now = os.clock()
    if now - fpsLastTime >= 1.0 then
        fpsValue = fpsCounter
        fpsCounter = 0
        fpsLastTime = now
    end
    hudData.fps = fpsValue
end

-- ============================================================================
-- RENDER HUD
-- ============================================================================
imgui.OnFrame(function() return true end, function()
    -- Hide if chat active
    local chatActive = false
    pcall(function() chatActive = sampIsChatInputActive() end)
    if chatActive then return end

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()
    local scale = cfg.General.globalScale or 1.0
    local opacity = cfg.General.globalOpacity or 0.9

    -- Draw text (simple, no shadow - same pattern as WeaponDisplayTest)
    local function txt(x, y, color, text)
        dl:AddText(imgui.ImVec2(x, y), color, text)
    end

    -- Draw bar
    local function bar(x, y, w, h, value, maxVal, fgCol, bgCol)
        local bw = w * scale
        local bh = h * scale
        local fill = bw * (math.min(value, maxVal) / maxVal)
        dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + bw, y + bh), bgCol, 4)
        if fill > 0 then
            dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + fill, y + bh), fgCol, 4)
        end
    end

    -- 1. FPS (top-left)
    if cfg.Elements.showFPS then
        local fx = cfg.Positions.fpsX
        local fy = cfg.Positions.fpsY
        dl:AddRectFilled(imgui.ImVec2(fx - 5, fy - 2), imgui.ImVec2(fx + 70 * scale, fy + 16 * scale), 0xCC111111, 4)
        txt(fx, fy, 0xFFFFFFFF, "FPS: " .. hudData.fps)
    end

    -- 2. Time (top-left below FPS)
    if cfg.Elements.showTime then
        local tx = cfg.Positions.timeX
        local ty = cfg.Positions.timeY
        dl:AddRectFilled(imgui.ImVec2(tx - 5, ty - 2), imgui.ImVec2(tx + 60 * scale, ty + 16 * scale), 0xCC111111, 4)
        txt(tx, ty, 0xFFFFFFFF, hudData.serverTime)
    end

    -- 3. HP Bar (bottom-left)
    if cfg.Elements.showHP then
        local hx = cfg.Positions.hpX
        local hy = (cfg.Positions.hpY == 0) and (sh - 120) or cfg.Positions.hpY
        dl:AddRectFilled(imgui.ImVec2(hx - 5, hy - 3), imgui.ImVec2(hx + 250 * scale, hy + 22 * scale), 0xCC111111, 4)
        bar(hx, hy, 200, 18, hudData.health, 100, 0xFF50AF4C, 0xCC1A3A18)
        txt(hx + 205 * scale, hy + 2, 0xFF50AF4C, tostring(math.floor(hudData.health)))
    end

    -- 4. Armor Bar (bottom-left below HP)
    if cfg.Elements.showArmor and hudData.armor > 0 then
        local ax = cfg.Positions.armorX
        local ay = (cfg.Positions.armorY == 0) and (sh - 90) or cfg.Positions.armorY
        dl:AddRectFilled(imgui.ImVec2(ax - 5, ay - 3), imgui.ImVec2(ax + 250 * scale, ay + 22 * scale), 0xCC111111, 4)
        bar(ax, ay, 200, 18, hudData.armor, 100, 0xFFF39621, 0xCC0D3A5E)
        txt(ax + 205 * scale, ay + 2, 0xFFF39621, tostring(math.floor(hudData.armor)))
    end

    -- 5. Zone (bottom-left below armor)
    if cfg.Elements.showZone then
        local zx = cfg.Positions.zoneX
        local zy = (cfg.Positions.zoneY == 0) and (sh - 60) or cfg.Positions.zoneY
        dl:AddRectFilled(imgui.ImVec2(zx - 5, zy - 2), imgui.ImVec2(zx + 180 * scale, zy + 16 * scale), 0xCC111111, 4)
        txt(zx, zy, 0xFFFFFFFF, hudData.zoneName)
    end

    -- 6. Money (top-right)
    if cfg.Elements.showMoney then
        local mx = (cfg.Positions.moneyX == 0) and (sw - 180) or cfg.Positions.moneyX
        local my = cfg.Positions.moneyY
        local moneyText = formatMoney(hudData.money)
        dl:AddRectFilled(imgui.ImVec2(mx - 5, my - 2), imgui.ImVec2(mx + 170 * scale, my + 20 * scale), 0xCC111111, 4)
        txt(mx, my, 0xFF50AF4C, moneyText)
    end

    -- 7. Wanted (top-right below money)
    if cfg.Elements.showWanted and hudData.wantedLevel > 0 then
        local wx = (cfg.Positions.wantedX == 0) and (sw - 180) or cfg.Positions.wantedX
        local wy = cfg.Positions.wantedY
        dl:AddRectFilled(imgui.ImVec2(wx - 5, wy - 2), imgui.ImVec2(wx + 120 * scale, wy + 18 * scale), 0xCC111111, 4)
        local stars = ""
        for i = 1, 6 do
            stars = stars .. (i <= hudData.wantedLevel and "*" or ".")
        end
        txt(wx, wy, 0xFF00D7FF, stars)
    end

    -- 8. Weapon + Ammo (bottom-right)
    if cfg.Elements.showWeapon then
        local wpx = (cfg.Positions.weaponX == 0) and (sw - 220) or cfg.Positions.weaponX
        local wpy = (cfg.Positions.weaponY == 0) and (sh - 90) or cfg.Positions.weaponY
        local wepName = getWeaponName(hudData.weaponId)
        local ammoText
        if hudData.weaponId == 0 then
            ammoText = wepName
        else
            ammoText = wepName .. " | " .. hudData.ammoClip .. "/" .. hudData.ammoTotal
        end
        dl:AddRectFilled(imgui.ImVec2(wpx - 5, wpy - 2), imgui.ImVec2(wpx + 210 * scale, wpy + 18 * scale), 0xCC111111, 4)
        txt(wpx, wpy, 0xFFFFFFFF, ammoText)
    end

    -- 9. Speed (bottom-right below weapon, only in vehicle)
    if cfg.Elements.showSpeed and hudData.inVehicle then
        local sx = (cfg.Positions.speedX == 0) and (sw - 220) or cfg.Positions.speedX
        local sy = (cfg.Positions.speedY == 0) and (sh - 60) or cfg.Positions.speedY
        local speedText = tostring(hudData.speed) .. " km/h"
        dl:AddRectFilled(imgui.ImVec2(sx - 5, sy - 2), imgui.ImVec2(sx + 120 * scale, sy + 18 * scale), 0xCC111111, 4)
        txt(sx, sy, 0xFFFFFFFF, speedText)
    end
end)

-- ============================================================================
-- CONFIG WINDOW
-- ============================================================================
imgui.OnFrame(function() return showConfig[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(50, 50), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(400, 500), imgui.Cond.FirstUseEver)
    imgui.Begin("Custom HUD Config", showConfig)

    imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "--- GENERAL ---")
    if imgui.Checkbox("Hide Default HUD", buf_hideHud) then cfg.General.hideDefaultHud = buf_hideHud[0] end
    if imgui.Checkbox("Hide Default Radar", buf_hideRadar) then cfg.General.hideDefaultRadar = buf_hideRadar[0] end
    imgui.SliderFloat("Opacity", buf_opacity, 0.3, 1.0, "%.2f")
    cfg.General.globalOpacity = buf_opacity[0]
    imgui.SliderFloat("Scale", buf_scale, 0.5, 2.0, "%.2f")
    cfg.General.globalScale = buf_scale[0]

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "--- SHOW/HIDE ELEMENTS ---")
    if imgui.Checkbox("HP Bar", buf_showHP) then cfg.Elements.showHP = buf_showHP[0] end
    if imgui.Checkbox("Armor Bar", buf_showArmor) then cfg.Elements.showArmor = buf_showArmor[0] end
    if imgui.Checkbox("Money", buf_showMoney) then cfg.Elements.showMoney = buf_showMoney[0] end
    if imgui.Checkbox("Weapon + Ammo", buf_showWeapon) then cfg.Elements.showWeapon = buf_showWeapon[0] end
    if imgui.Checkbox("Wanted Stars", buf_showWanted) then cfg.Elements.showWanted = buf_showWanted[0] end
    if imgui.Checkbox("Vehicle Speed", buf_showSpeed) then cfg.Elements.showSpeed = buf_showSpeed[0] end
    if imgui.Checkbox("FPS Counter", buf_showFPS) then cfg.Elements.showFPS = buf_showFPS[0] end
    if imgui.Checkbox("Zone Name", buf_showZone) then cfg.Elements.showZone = buf_showZone[0] end
    if imgui.Checkbox("Server Time", buf_showTime) then cfg.Elements.showTime = buf_showTime[0] end

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 35)) then
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
    sampAddChatMessage("{00FFFF}[CustomHUD] {FFFFFF}Use {FFFF00}/chud{FFFFFF} to configure", -1)

    sampRegisterChatCommand("chud", function()
        showConfig[0] = not showConfig[0]
    end)

    while true do
        wait(100)

        -- Hide/Show default HUD
        if cfg.General.hideDefaultHud then
            pcall(displayHud, false)
        else
            pcall(displayHud, true)
        end
        if cfg.General.hideDefaultRadar then
            pcall(displayRadar, false)
        else
            pcall(displayRadar, true)
        end

        -- Update data
        if sampIsLocalPlayerSpawned() then
            updateHudData()
        end
    end
end
