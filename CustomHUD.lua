script_name("Custom HUD")
script_author("OnlyDexterZ")
script_description("GTA V Style Custom HUD for SA-MP Android - MonetLoader 3.8.0")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

-- Config defaults
local configFile = "CustomHUD.ini"
local defaultConfig = {
    general = {
        hideDefaultHud = true,
        hideDefaultRadar = true,
        globalOpacity = 0.9,
        globalScale = 1.0,
    },
    elements = {
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
    positions = {
        hpX = 20,
        hpY = -120,
        armorX = 20,
        armorY = -90,
        moneyX = -200,
        moneyY = 20,
        weaponX = -200,
        weaponY = -90,
        wantedX = -200,
        wantedY = 50,
        speedX = -200,
        speedY = -60,
        fpsX = 20,
        fpsY = 20,
        zoneX = 20,
        zoneY = -60,
        timeX = 20,
        timeY = 50,
    },
}

local cfg = inicfg.load(defaultConfig, configFile)
if not cfg then
    cfg = defaultConfig
end

-- HUD data (updated in main loop)
local hudData = {
    health = 100,
    armor = 0,
    money = 0,
    weaponId = 0,
    ammoClip = 0,
    ammoTotal = 0,
    inVehicle = false,
    speed = 0,
    wantedLevel = 0,
    fps = 0,
    zoneName = "Los Santos",
    serverTime = "00:00",
}

-- FPS calculation
local fpsCounter = 0
local fpsLastTime = os.clock()
local fpsValue = 0

-- Config window state
local configWindow = imgui.new.bool(false)

-- ImGui buffer variables for config
local buf_globalOpacity = imgui.new.float(cfg.general.globalOpacity)
local buf_globalScale = imgui.new.float(cfg.general.globalScale)
local buf_hideDefaultHud = imgui.new.bool(cfg.general.hideDefaultHud)
local buf_hideDefaultRadar = imgui.new.bool(cfg.general.hideDefaultRadar)
local buf_showHP = imgui.new.bool(cfg.elements.showHP)
local buf_showArmor = imgui.new.bool(cfg.elements.showArmor)
local buf_showMoney = imgui.new.bool(cfg.elements.showMoney)
local buf_showWeapon = imgui.new.bool(cfg.elements.showWeapon)
local buf_showWanted = imgui.new.bool(cfg.elements.showWanted)
local buf_showSpeed = imgui.new.bool(cfg.elements.showSpeed)
local buf_showFPS = imgui.new.bool(cfg.elements.showFPS)
local buf_showZone = imgui.new.bool(cfg.elements.showZone)
local buf_showTime = imgui.new.bool(cfg.elements.showTime)
local buf_hpX = imgui.new.int(cfg.positions.hpX)
local buf_hpY = imgui.new.int(cfg.positions.hpY)
local buf_armorX = imgui.new.int(cfg.positions.armorX)
local buf_armorY = imgui.new.int(cfg.positions.armorY)
local buf_moneyX = imgui.new.int(cfg.positions.moneyX)
local buf_moneyY = imgui.new.int(cfg.positions.moneyY)
local buf_weaponX = imgui.new.int(cfg.positions.weaponX)
local buf_weaponY = imgui.new.int(cfg.positions.weaponY)
local buf_wantedX = imgui.new.int(cfg.positions.wantedX)
local buf_wantedY = imgui.new.int(cfg.positions.wantedY)
local buf_speedX = imgui.new.int(cfg.positions.speedX)
local buf_speedY = imgui.new.int(cfg.positions.speedY)
local buf_fpsX = imgui.new.int(cfg.positions.fpsX)
local buf_fpsY = imgui.new.int(cfg.positions.fpsY)
local buf_zoneX = imgui.new.int(cfg.positions.zoneX)
local buf_zoneY = imgui.new.int(cfg.positions.zoneY)
local buf_timeX = imgui.new.int(cfg.positions.timeX)
local buf_timeY = imgui.new.int(cfg.positions.timeY)

-- Weapon names table (ID 0-46)
local weaponNames = {
    [0] = "Fist",
    [1] = "Brass Knuckles",
    [2] = "Golf Club",
    [3] = "Nightstick",
    [4] = "Knife",
    [5] = "Baseball Bat",
    [6] = "Shovel",
    [7] = "Pool Cue",
    [8] = "Katana",
    [9] = "Chainsaw",
    [10] = "Purple Dildo",
    [11] = "Dildo",
    [12] = "Vibrator",
    [13] = "Silver Vibrator",
    [14] = "Flowers",
    [15] = "Cane",
    [16] = "Grenade",
    [17] = "Tear Gas",
    [18] = "Molotov",
    [22] = "9mm",
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
    [34] = "Sniper",
    [35] = "RPG",
    [36] = "HS Rocket",
    [37] = "Flamethrower",
    [38] = "Minigun",
    [39] = "Satchel",
    [40] = "Detonator",
    [41] = "Spray Can",
    [42] = "Fire Extinguisher",
    [43] = "Camera",
    [44] = "Night Vision",
    [45] = "Thermal",
    [46] = "Parachute",
}

-- GTA V Colors (ABGR format for ImGui)
local COLORS = {
    hpBar       = 0xFF50AF4C,  -- Green (#4CAF50)
    hpBarBg     = 0xCC1A3A18,  -- Dark green background
    armorBar    = 0xFFF39621,  -- Blue (#2196F3)
    armorBarBg  = 0xCC0D3A5E,  -- Dark blue background
    moneyText   = 0xFF50AF4C,  -- Green
    wantedActive   = 0xFF00D7FF,  -- Gold/Yellow (#FFD700)
    wantedInactive = 0xFF444444,  -- Dark gray
    background  = 0xCC111111,  -- Semi-transparent dark
    text        = 0xFFFFFFFF,  -- White
    textShadow  = 0xFF000000,  -- Black shadow
}

-- Helper: get screen resolution
local function getScreenSize()
    local resX, resY = 0, 0
    local ok = pcall(function()
        resX, resY = getScreenResolution()
    end)
    if not ok or resX == 0 then
        resX, resY = 1280, 720
    end
    return resX, resY
end

-- Helper: calculate absolute position from config
-- Negative values are relative to right/bottom edge
local function calcPos(cfgX, cfgY, screenW, screenH)
    local x = cfgX
    local y = cfgY
    if x < 0 then x = screenW + x end
    if y < 0 then y = screenH + y end
    return x, y
end

-- Helper: format money with commas
local function formatMoney(amount)
    local formatted = tostring(math.abs(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    if amount < 0 then
        return "-$" .. formatted
    else
        return "$" .. formatted
    end
end

-- Helper: get weapon name from ID
local function getWeaponName(id)
    return weaponNames[id] or ("Weapon " .. tostring(id))
end

-- Command handler for /chud
function cmd_chud()
    configWindow[0] = not configWindow[0]
end

-- Register command
sampRegisterChatCommand("chud", cmd_chud)

-- Data update function (called every 100ms in main loop)
local function updateHudData()
    -- Health
    pcall(function()
        hudData.health = getCharHealth(PLAYER_PED)
    end)

    -- Armor
    pcall(function()
        hudData.armor = getCharArmour(PLAYER_PED)
    end)

    -- Money
    pcall(function()
        local playerHandle = playerPed or PLAYER_PED
        local ok2, handle = pcall(playerHandleToId or function() return 0 end)
        if not ok2 then handle = 0 end
        hudData.money = getPlayerMoney(handle)
    end)

    -- Weapon
    pcall(function()
        hudData.weaponId = getCurrentCharWeapon(PLAYER_PED)
    end)

    -- Ammo
    pcall(function()
        if hudData.weaponId and hudData.weaponId > 0 then
            hudData.ammoTotal = getAmmoInCharWeapon(PLAYER_PED, hudData.weaponId)
            local clipOk, clipAmmo = pcall(getAmmoInClip, PLAYER_PED, hudData.weaponId)
            if clipOk then
                hudData.ammoClip = clipAmmo
            else
                hudData.ammoClip = 0
            end
        else
            hudData.ammoTotal = 0
            hudData.ammoClip = 0
        end
    end)

    -- Vehicle and speed
    pcall(function()
        hudData.inVehicle = isCharInAnyCar(PLAYER_PED)
        if hudData.inVehicle then
            local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
            if vehicle then
                local speedMs = getCarSpeed(vehicle)
                hudData.speed = math.floor(speedMs * 3.6) -- m/s to km/h
            end
        else
            hudData.speed = 0
        end
    end)

    -- Wanted level
    pcall(function()
        if getPlayerWantedLevel then
            hudData.wantedLevel = getPlayerWantedLevel(playerHandleToId(PLAYER_PED) or 0)
        else
            hudData.wantedLevel = 0
        end
    end)

    -- FPS
    fpsCounter = fpsCounter + 1
    local currentTime = os.clock()
    if currentTime - fpsLastTime >= 1.0 then
        fpsValue = fpsCounter
        fpsCounter = 0
        fpsLastTime = currentTime
    end
    hudData.fps = fpsValue

    -- Server time (from game clock)
    pcall(function()
        if getTimeOfDay then
            local hours, minutes = getTimeOfDay()
            hudData.serverTime = string.format("%02d:%02d", hours, minutes)
        end
    end)

    -- Zone name
    pcall(function()
        if getNameOfZone then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            hudData.zoneName = getNameOfZone(x, y, z) or "Unknown"
        end
    end)
end

-- Main rendering via imgui.OnFrame (background draw list)
imgui.OnFrame(
    function() return true end,
    function(player)
        -- Check if chat is active (hide HUD while typing)
        local chatActive = false
        pcall(function()
            if sampIsChatInputActive then
                chatActive = sampIsChatInputActive()
            end
        end)
        if chatActive then return end

        -- Get draw list and screen size
        local dl = imgui.GetBackgroundDrawList()
        local screenW, screenH = getScreenSize()
        local scale = cfg.general.globalScale
        local opacity = cfg.general.globalOpacity

        -- Apply opacity to color
        local function applyOpacity(color)
            local a = math.floor(((color >> 24) & 0xFF) * opacity)
            return (a << 24) | (color & 0x00FFFFFF)
        end

        -- Helper: draw text with shadow
        local function drawText(x, y, color, text, fontSize)
            fontSize = fontSize or (16 * scale)
            local shadowColor = applyOpacity(COLORS.textShadow)
            local textColor = applyOpacity(color)
            dl:AddText(nil, fontSize, imgui.ImVec2(x + 1, y + 1), shadowColor, text)
            dl:AddText(nil, fontSize, imgui.ImVec2(x, y), textColor, text)
        end

        -- Helper: draw bar
        local function drawBar(x, y, width, height, value, maxValue, fgColor, bgColor)
            local barW = width * scale
            local barH = height * scale
            local fillW = barW * (math.min(value, maxValue) / maxValue)
            -- Background
            dl:AddRectFilled(
                imgui.ImVec2(x, y),
                imgui.ImVec2(x + barW, y + barH),
                applyOpacity(bgColor),
                4.0
            )
            -- Foreground (filled portion)
            if fillW > 0 then
                dl:AddRectFilled(
                    imgui.ImVec2(x, y),
                    imgui.ImVec2(x + fillW, y + barH),
                    applyOpacity(fgColor),
                    4.0
                )
            end
            -- Border
            dl:AddRect(
                imgui.ImVec2(x, y),
                imgui.ImVec2(x + barW, y + barH),
                applyOpacity(0x66FFFFFF),
                4.0
            )
        end

        -- 1. FPS Counter (top-left)
        if cfg.elements.showFPS then
            local fx, fy = calcPos(cfg.positions.fpsX, cfg.positions.fpsY, screenW, screenH)
            -- Background box
            local fpsText = "FPS: " .. tostring(hudData.fps)
            dl:AddRectFilled(
                imgui.ImVec2(fx - 5, fy - 3),
                imgui.ImVec2(fx + 75 * scale, fy + 18 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(fx, fy, COLORS.text, fpsText, 14 * scale)
        end

        -- 2. Server Time (top-left, below FPS)
        if cfg.elements.showTime then
            local tx, ty = calcPos(cfg.positions.timeX, cfg.positions.timeY, screenW, screenH)
            local timeText = hudData.serverTime
            dl:AddRectFilled(
                imgui.ImVec2(tx - 5, ty - 3),
                imgui.ImVec2(tx + 65 * scale, ty + 18 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(tx, ty, COLORS.text, timeText, 14 * scale)
        end

        -- 3. HP Bar (bottom-left)
        if cfg.elements.showHP then
            local hx, hy = calcPos(cfg.positions.hpX, cfg.positions.hpY, screenW, screenH)
            local barWidth = 200
            local barHeight = 20
            -- Background panel
            dl:AddRectFilled(
                imgui.ImVec2(hx - 5, hy - 3),
                imgui.ImVec2(hx + (barWidth + 55) * scale, hy + barHeight * scale + 3),
                applyOpacity(COLORS.background),
                4.0
            )
            -- HP Bar
            drawBar(hx, hy, barWidth, barHeight, hudData.health, 100, COLORS.hpBar, COLORS.hpBarBg)
            -- HP Value text
            local hpStr = tostring(math.floor(hudData.health))
            drawText(hx + (barWidth + 8) * scale, hy + 2 * scale, COLORS.hpBar, hpStr, 14 * scale)
        end

        -- 4. Armor Bar (bottom-left, below HP)
        if cfg.elements.showArmor and hudData.armor > 0 then
            local ax, ay = calcPos(cfg.positions.armorX, cfg.positions.armorY, screenW, screenH)
            local barWidth = 200
            local barHeight = 20
            -- Background panel
            dl:AddRectFilled(
                imgui.ImVec2(ax - 5, ay - 3),
                imgui.ImVec2(ax + (barWidth + 55) * scale, ay + barHeight * scale + 3),
                applyOpacity(COLORS.background),
                4.0
            )
            -- Armor Bar
            drawBar(ax, ay, barWidth, barHeight, hudData.armor, 100, COLORS.armorBar, COLORS.armorBarBg)
            -- Armor Value text
            local armorStr = tostring(math.floor(hudData.armor))
            drawText(ax + (barWidth + 8) * scale, ay + 2 * scale, COLORS.armorBar, armorStr, 14 * scale)
        end

        -- 5. Zone Name (bottom-left, below armor)
        if cfg.elements.showZone then
            local zx, zy = calcPos(cfg.positions.zoneX, cfg.positions.zoneY, screenW, screenH)
            local zoneText = hudData.zoneName
            dl:AddRectFilled(
                imgui.ImVec2(zx - 5, zy - 3),
                imgui.ImVec2(zx + 180 * scale, zy + 18 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(zx, zy, COLORS.text, zoneText, 14 * scale)
        end

        -- 6. Money (top-right)
        if cfg.elements.showMoney then
            local mx, my = calcPos(cfg.positions.moneyX, cfg.positions.moneyY, screenW, screenH)
            local moneyText = formatMoney(hudData.money)
            local textWidth = #moneyText * 10 * scale
            dl:AddRectFilled(
                imgui.ImVec2(mx - 5, my - 3),
                imgui.ImVec2(mx + textWidth + 10, my + 22 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(mx, my, COLORS.moneyText, moneyText, 18 * scale)
        end

        -- 7. Wanted Stars (top-right, below money)
        if cfg.elements.showWanted then
            local wx, wy = calcPos(cfg.positions.wantedX, cfg.positions.wantedY, screenW, screenH)
            local starSize = 14 * scale
            local starSpacing = 18 * scale
            -- Background
            dl:AddRectFilled(
                imgui.ImVec2(wx - 5, wy - 3),
                imgui.ImVec2(wx + 6 * starSpacing + 5, wy + starSize + 6),
                applyOpacity(COLORS.background),
                4.0
            )
            for i = 1, 6 do
                local starX = wx + (i - 1) * starSpacing
                local starColor
                if i <= hudData.wantedLevel then
                    starColor = applyOpacity(COLORS.wantedActive)
                else
                    starColor = applyOpacity(COLORS.wantedInactive)
                end
                -- Draw star as filled circle (simplified star shape)
                dl:AddCircleFilled(
                    imgui.ImVec2(starX + starSize / 2, wy + starSize / 2),
                    starSize / 2.5,
                    starColor,
                    5  -- 5 segments for star-like shape
                )
            end
        end

        -- 8. Weapon + Ammo (bottom-right)
        if cfg.elements.showWeapon then
            local wpx, wpy = calcPos(cfg.positions.weaponX, cfg.positions.weaponY, screenW, screenH)
            local weaponName = getWeaponName(hudData.weaponId)
            local ammoText
            if hudData.weaponId == 0 then
                ammoText = weaponName
            else
                ammoText = weaponName .. " | " .. tostring(hudData.ammoClip) .. "/" .. tostring(hudData.ammoTotal)
            end
            local textWidth = #ammoText * 8 * scale
            dl:AddRectFilled(
                imgui.ImVec2(wpx - 5, wpy - 3),
                imgui.ImVec2(wpx + textWidth + 10, wpy + 20 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(wpx, wpy, COLORS.text, ammoText, 14 * scale)
        end

        -- 9. Vehicle Speed (bottom-right, below weapon)
        if cfg.elements.showSpeed and hudData.inVehicle then
            local sx, sy = calcPos(cfg.positions.speedX, cfg.positions.speedY, screenW, screenH)
            local speedText = tostring(hudData.speed) .. " km/h"
            local textWidth = #speedText * 9 * scale
            dl:AddRectFilled(
                imgui.ImVec2(sx - 5, sy - 3),
                imgui.ImVec2(sx + textWidth + 10, sy + 20 * scale),
                applyOpacity(COLORS.background),
                4.0
            )
            drawText(sx, sy, COLORS.text, speedText, 16 * scale)
        end
    end
)

-- Config Window rendering
imgui.OnFrame(
    function() return configWindow[0] end,
    function(player)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 600), imgui.Cond.FirstUseEver)
        imgui.Begin("Custom HUD Settings", configWindow)

        -- General section
        if imgui.CollapsingHeader("General") then
            if imgui.Checkbox("Hide Default HUD", buf_hideDefaultHud) then
                cfg.general.hideDefaultHud = buf_hideDefaultHud[0]
            end
            if imgui.Checkbox("Hide Default Radar", buf_hideDefaultRadar) then
                cfg.general.hideDefaultRadar = buf_hideDefaultRadar[0]
            end
            if imgui.SliderFloat("Global Opacity", buf_globalOpacity, 0.1, 1.0) then
                cfg.general.globalOpacity = buf_globalOpacity[0]
            end
            if imgui.SliderFloat("Global Scale", buf_globalScale, 0.5, 2.0) then
                cfg.general.globalScale = buf_globalScale[0]
            end
        end

        imgui.Separator()

        -- Elements toggles
        if imgui.CollapsingHeader("Show/Hide Elements") then
            if imgui.Checkbox("HP Bar", buf_showHP) then
                cfg.elements.showHP = buf_showHP[0]
            end
            if imgui.Checkbox("Armor Bar", buf_showArmor) then
                cfg.elements.showArmor = buf_showArmor[0]
            end
            if imgui.Checkbox("Money", buf_showMoney) then
                cfg.elements.showMoney = buf_showMoney[0]
            end
            if imgui.Checkbox("Weapon + Ammo", buf_showWeapon) then
                cfg.elements.showWeapon = buf_showWeapon[0]
            end
            if imgui.Checkbox("Wanted Stars", buf_showWanted) then
                cfg.elements.showWanted = buf_showWanted[0]
            end
            if imgui.Checkbox("Vehicle Speed", buf_showSpeed) then
                cfg.elements.showSpeed = buf_showSpeed[0]
            end
            if imgui.Checkbox("FPS Counter", buf_showFPS) then
                cfg.elements.showFPS = buf_showFPS[0]
            end
            if imgui.Checkbox("Zone Name", buf_showZone) then
                cfg.elements.showZone = buf_showZone[0]
            end
            if imgui.Checkbox("Server Time", buf_showTime) then
                cfg.elements.showTime = buf_showTime[0]
            end
        end

        imgui.Separator()

        -- Position sliders
        if imgui.CollapsingHeader("Positions") then
            imgui.Text("HP Bar:")
            if imgui.SliderInt("HP X", buf_hpX, -1280, 1280) then
                cfg.positions.hpX = buf_hpX[0]
            end
            if imgui.SliderInt("HP Y", buf_hpY, -720, 720) then
                cfg.positions.hpY = buf_hpY[0]
            end

            imgui.Spacing()
            imgui.Text("Armor Bar:")
            if imgui.SliderInt("Armor X", buf_armorX, -1280, 1280) then
                cfg.positions.armorX = buf_armorX[0]
            end
            if imgui.SliderInt("Armor Y", buf_armorY, -720, 720) then
                cfg.positions.armorY = buf_armorY[0]
            end

            imgui.Spacing()
            imgui.Text("Money:")
            if imgui.SliderInt("Money X", buf_moneyX, -1280, 1280) then
                cfg.positions.moneyX = buf_moneyX[0]
            end
            if imgui.SliderInt("Money Y", buf_moneyY, -720, 720) then
                cfg.positions.moneyY = buf_moneyY[0]
            end

            imgui.Spacing()
            imgui.Text("Weapon + Ammo:")
            if imgui.SliderInt("Weapon X", buf_weaponX, -1280, 1280) then
                cfg.positions.weaponX = buf_weaponX[0]
            end
            if imgui.SliderInt("Weapon Y", buf_weaponY, -720, 720) then
                cfg.positions.weaponY = buf_weaponY[0]
            end

            imgui.Spacing()
            imgui.Text("Wanted Stars:")
            if imgui.SliderInt("Wanted X", buf_wantedX, -1280, 1280) then
                cfg.positions.wantedX = buf_wantedX[0]
            end
            if imgui.SliderInt("Wanted Y", buf_wantedY, -720, 720) then
                cfg.positions.wantedY = buf_wantedY[0]
            end

            imgui.Spacing()
            imgui.Text("Vehicle Speed:")
            if imgui.SliderInt("Speed X", buf_speedX, -1280, 1280) then
                cfg.positions.speedX = buf_speedX[0]
            end
            if imgui.SliderInt("Speed Y", buf_speedY, -720, 720) then
                cfg.positions.speedY = buf_speedY[0]
            end

            imgui.Spacing()
            imgui.Text("FPS Counter:")
            if imgui.SliderInt("FPS X", buf_fpsX, -1280, 1280) then
                cfg.positions.fpsX = buf_fpsX[0]
            end
            if imgui.SliderInt("FPS Y", buf_fpsY, -720, 720) then
                cfg.positions.fpsY = buf_fpsY[0]
            end

            imgui.Spacing()
            imgui.Text("Zone Name:")
            if imgui.SliderInt("Zone X", buf_zoneX, -1280, 1280) then
                cfg.positions.zoneX = buf_zoneX[0]
            end
            if imgui.SliderInt("Zone Y", buf_zoneY, -720, 720) then
                cfg.positions.zoneY = buf_zoneY[0]
            end

            imgui.Spacing()
            imgui.Text("Server Time:")
            if imgui.SliderInt("Time X", buf_timeX, -1280, 1280) then
                cfg.positions.timeX = buf_timeX[0]
            end
            if imgui.SliderInt("Time Y", buf_timeY, -720, 720) then
                cfg.positions.timeY = buf_timeY[0]
            end
        end

        imgui.Separator()
        imgui.Spacing()

        -- Save button
        if imgui.Button("SAVE ALL", imgui.ImVec2(imgui.GetContentRegionAvail().x, 40)) then
            inicfg.save(cfg, configFile)
            sampAddChatMessage("{4CAF50}[CustomHUD]{FFFFFF} Settings saved!", 0xFFFFFFFF)
        end

        imgui.End()
    end
)

-- Main loop
function main()
    -- Wait for SAMP to initialize
    if not isSampLoaded or not isSampLoaded() then
        return
    end

    while not isSampAvailable() do
        wait(100)
    end

    sampAddChatMessage("{4CAF50}[CustomHUD]{FFFFFF} GTA V Style HUD loaded! Use /chud to configure.", 0xFFFFFFFF)

    -- Main data update loop
    while true do
        wait(100)

        -- Hide default HUD/radar based on config
        if cfg.general.hideDefaultHud then
            pcall(displayHud, false)
        else
            pcall(displayHud, true)
        end

        if cfg.general.hideDefaultRadar then
            pcall(displayRadar, false)
        else
            pcall(displayRadar, true)
        end

        -- Update HUD data
        updateHudData()
    end
end
