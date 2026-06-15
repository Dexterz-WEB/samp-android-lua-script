-- ============================================================================
-- VEHICLE HUD v1.0
-- Speedometer gauge with vehicle info display for SA-MP Android (MonetLoader)
-- Author: OnlyDexterZ
-- ============================================================================

script_name("VehicleHUD")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local jsoncfg = require 'jsoncfg'
local vhud_lib = require 'vehiclehud_lib'

-- ============================================================================
-- DPI SCALING
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0

-- ============================================================================
-- CONFIG
-- ============================================================================
local defaultConfig = {
    enabled = true,
    style = 1,
    unit = "kmh",
    scale = 1.0,
    opacity = 0.85,
    posX = nil,
    posY = nil,
}

local config = jsoncfg.load(defaultConfig, "VehicleHUD")

local function saveConfig()
    jsoncfg.save(config, "VehicleHUD")
end

-- ============================================================================
-- STATE MACHINE
-- States: HIDDEN, FADE_IN, VISIBLE, FADE_OUT
-- ============================================================================
local currentState = "HIDDEN"
local fadeAlpha = 0.0
local fadeSpeed = 0.08

-- ============================================================================
-- VEHICLE DATA CACHE (updated outside render)
-- ============================================================================
local cachedSpeed = 0
local cachedHealth = 1.0
local cachedModel = 0
local cachedHeading = 0
local cachedEngineOn = false
local cachedVehicleName = "Unknown"
local cachedVehicleType = "Car"
local cachedMaxSpeed = 240
local cachedGear = 1
local cachedDirection = "N"
local frameCounter = 0
local inVehicle = false

-- Smooth display values (interpolated every render frame)
local displaySpeed = 0

-- Drag state
local isDragging = false
local dragOffsetX = 0
local dragOffsetY = 0

-- Config window state
local showConfigWindow = false

-- Config window imgui float buffers
local cfgScaleFloat = imgui.new.float(config.scale)
local cfgOpacityFloat = imgui.new.float(config.opacity)

-- ============================================================================
-- COLORS
-- ============================================================================
local COLORS = {
    bg = 0xCC1A1A2E,
    text = 0xFFEEEEEE,
    textDim = 0xFF999999,
    accent = 0xFF00FFAA,
    needle = 0xFFFF3333,
    gaugeGreen = 0xFF33FF66,
    gaugeYellow = 0xFFFFCC33,
    gaugeRed = 0xFFFF3333,
    healthGreen = 0xFF33CC33,
    healthYellow = 0xFFCCCC33,
    healthRed = 0xFFCC3333,
    speedText = 0xFFFFFFFF,
    engineOn = 0xFF33FF66,
    engineOff = 0xFFFF3333,
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local bit = require 'bit'

local function applyAlpha(color, alpha)
    local a = math.floor(bit.band(bit.rshift(color, 24), 0xFF) * alpha)
    return bit.bor(bit.lshift(a, 24), bit.band(color, 0x00FFFFFF))
end

local function getHudSize()
    local s = config.scale * DPI
    if config.style == 1 then
        return 220 * s, 260 * s
    elseif config.style == 2 then
        return 200 * s, 180 * s
    else
        return 180 * s, 50 * s
    end
end

local function getDefaultPos(screenW, screenH)
    local w, h = getHudSize()
    local padding = 20 * DPI
    return screenW - w - padding, screenH - h - padding
end

-- ============================================================================
-- VEHICLE DETECTION (pcall outside render)
-- ============================================================================
local function isPlayerInVehicle()
    local result = false
    pcall(function()
        result = isCharInAnyCar(PLAYER_PED)
    end)
    return result
end

-- ============================================================================
-- DATA UPDATE (called from main loop via frame counter, NOT inside render)
-- ============================================================================
local function updateVehicleData()
    local veh = nil
    local ok, handle = pcall(storeCarCharIsInNoSave, PLAYER_PED)
    if ok and handle then
        veh = handle
    end

    if not veh then return end

    -- Speed
    pcall(function()
        local rawSpeed = getCarSpeed(veh)
        if config.unit == "kmh" then
            cachedSpeed = rawSpeed * 3.6
        else
            cachedSpeed = rawSpeed * 2.237
        end
    end)

    -- Health
    pcall(function()
        cachedHealth = getCarHealth(veh) / 1000.0
        if cachedHealth > 1.0 then cachedHealth = 1.0 end
        if cachedHealth < 0.0 then cachedHealth = 0.0 end
    end)

    -- Model
    pcall(function()
        cachedModel = getCarModel(veh)
    end)

    -- Heading
    pcall(function()
        cachedHeading = getCarHeading(veh)
    end)

    -- Engine
    pcall(function()
        cachedEngineOn = isCarEngineOn(veh)
    end)

    -- Derived data from lib
    cachedVehicleName = vhud_lib.getVehicleName(cachedModel)
    cachedVehicleType = vhud_lib.getVehicleType(cachedModel)
    cachedMaxSpeed = vhud_lib.getMaxSpeed(cachedModel)
    cachedGear = vhud_lib.getGearFromSpeed(
        config.unit == "kmh" and cachedSpeed or (cachedSpeed / 2.237 * 3.6),
        cachedVehicleType
    )
    cachedDirection = vhud_lib.getHeadingDirection(cachedHeading)
end

-- ============================================================================
-- STATE MACHINE UPDATE (called from main loop, NOT inside render)
-- ============================================================================
local function updateStateMachine()
    local nowInVehicle = isPlayerInVehicle()

    -- State transitions
    if nowInVehicle and not inVehicle then
        -- Just entered vehicle
        if currentState == "HIDDEN" or currentState == "FADE_OUT" then
            currentState = "FADE_IN"
        end
    elseif not nowInVehicle and inVehicle then
        -- Just exited vehicle
        if currentState == "VISIBLE" or currentState == "FADE_IN" then
            currentState = "FADE_OUT"
        end
    end

    inVehicle = nowInVehicle
end

-- Fade-only update (safe to call from render, no pcall)
local function updateFade()
    if currentState == "FADE_IN" then
        fadeAlpha = fadeAlpha + fadeSpeed
        if fadeAlpha >= 1.0 then
            fadeAlpha = 1.0
            currentState = "VISIBLE"
        end
    elseif currentState == "FADE_OUT" then
        fadeAlpha = fadeAlpha - fadeSpeed
        if fadeAlpha <= 0.0 then
            fadeAlpha = 0.0
            currentState = "HIDDEN"
            displaySpeed = 0
        end
    end
end

-- ============================================================================
-- STYLE 1: Classic Gauge (semicircle arc speedometer)
-- ============================================================================
local function renderStyleClassic(dl, posX, posY, alpha)
    local s = config.scale * DPI
    local w = 220 * s
    local h = 260 * s

    -- Background panel
    local bgColor = applyAlpha(COLORS.bg, alpha * (config.opacity or 0.85))
    dl:AddRectFilled(
        imgui.ImVec2(posX, posY),
        imgui.ImVec2(posX + w, posY + h),
        bgColor, 10 * s
    )

    -- Arc gauge center
    local cx = posX + w * 0.5
    local cy = posY + 120 * s
    local radius = 80 * s
    local minAngle = math.rad(-225)
    local maxAngle = math.rad(45)

    -- Draw arc gauge background
    vhud_lib.drawArcGauge(dl, cx, cy, radius, minAngle, maxAngle, displaySpeed, cachedMaxSpeed, {
        thickness = 6 * s,
        bgColor = applyAlpha(0xFF333344, alpha),
        fgColor = applyAlpha(COLORS.accent, alpha),
        segments = 60,
    })

    -- Draw tick marks with color zones
    vhud_lib.drawTickMarks(dl, cx, cy, radius, 27, {
        minAngle = minAngle,
        maxAngle = maxAngle,
        innerRadius = radius - 12 * s,
        outerRadius = radius - 4 * s,
        color = applyAlpha(0xFFAAAAAA, alpha),
        majorEvery = 3,
        colorZones = {
            { startTick = 0, endTick = 15, color = applyAlpha(COLORS.gaugeGreen, alpha) },
            { startTick = 15, endTick = 21, color = applyAlpha(COLORS.gaugeYellow, alpha) },
            { startTick = 21, endTick = 27, color = applyAlpha(COLORS.gaugeRed, alpha) },
        },
    })

    -- Draw speed numbers along arc
    local interval = 20
    if cachedMaxSpeed > 200 then interval = 40
    elseif cachedMaxSpeed > 100 then interval = 20
    else interval = 10 end

    vhud_lib.drawSpeedNumbers(dl, cx, cy, radius, cachedMaxSpeed, interval, nil, {
        minAngle = minAngle,
        maxAngle = maxAngle,
        color = applyAlpha(COLORS.textDim, alpha),
    })

    -- Draw needle
    local needleAngle = vhud_lib.angleForValue(displaySpeed, cachedMaxSpeed, minAngle, maxAngle)
    vhud_lib.drawNeedle(dl, cx, cy, radius - 16 * s, needleAngle, {
        color = applyAlpha(COLORS.needle, alpha),
        thickness = 2.5 * s,
        length = radius - 20 * s,
    })

    -- Center dot
    dl:AddCircleFilled(imgui.ImVec2(cx, cy), 5 * s, applyAlpha(0xFFDDDDDD, alpha))

    -- Digital speed display below gauge
    local speedStr = tostring(math.floor(displaySpeed))
    local unitStr = config.unit == "kmh" and "km/h" or "mph"
    dl:AddText(imgui.ImVec2(cx - 20 * s, cy + 20 * s), applyAlpha(COLORS.speedText, alpha), speedStr)
    dl:AddText(imgui.ImVec2(cx - 12 * s, cy + 36 * s), applyAlpha(COLORS.textDim, alpha), unitStr)

    -- Vehicle info below
    local infoY = posY + 180 * s

    -- Vehicle name
    dl:AddText(imgui.ImVec2(posX + 10 * s, infoY), applyAlpha(COLORS.text, alpha), cachedVehicleName)

    -- Gear
    local gearStr = "Gear: " .. tostring(cachedGear)
    dl:AddText(imgui.ImVec2(posX + 10 * s, infoY + 16 * s), applyAlpha(COLORS.textDim, alpha), gearStr)

    -- Engine status
    local engineStr = "ENG: " .. (cachedEngineOn and "ON" or "OFF")
    local engineColor = cachedEngineOn and COLORS.engineOn or COLORS.engineOff
    dl:AddText(imgui.ImVec2(posX + 10 * s, infoY + 32 * s), applyAlpha(engineColor, alpha), engineStr)

    -- Direction/heading
    local dirStr = cachedDirection .. " (" .. tostring(math.floor(cachedHeading)) .. ")"
    dl:AddText(imgui.ImVec2(posX + w - 80 * s, infoY + 16 * s), applyAlpha(COLORS.textDim, alpha), dirStr)

    -- Health bar at bottom
    vhud_lib.drawHealthBar(dl, posX + 10 * s, posY + h - 22 * s, w - 20 * s, 12 * s, cachedHealth, {
        bgColor = applyAlpha(0xFF222233, alpha),
        rounding = 4 * s,
    })
end

-- ============================================================================
-- STYLE 2: Flat Digital
-- ============================================================================
local function renderStyleDigital(dl, posX, posY, alpha)
    local s = config.scale * DPI
    local w = 200 * s
    local h = 180 * s

    -- Background panel
    local bgColor = applyAlpha(COLORS.bg, alpha * (config.opacity or 0.85))
    dl:AddRectFilled(
        imgui.ImVec2(posX, posY),
        imgui.ImVec2(posX + w, posY + h),
        bgColor, 8 * s
    )

    -- Large digital speed centered
    local speedStr = tostring(math.floor(displaySpeed))
    local unitStr = config.unit == "kmh" and "km/h" or "mph"
    dl:AddText(imgui.ImVec2(posX + w * 0.5 - 20 * s, posY + 15 * s), applyAlpha(COLORS.speedText, alpha), speedStr)
    dl:AddText(imgui.ImVec2(posX + w * 0.5 - 10 * s, posY + 35 * s), applyAlpha(COLORS.textDim, alpha), unitStr)

    -- Horizontal speed bar
    local barX = posX + 10 * s
    local barY = posY + 58 * s
    local barW = w - 20 * s
    local barH = 8 * s
    local speedPercent = cachedMaxSpeed > 0 and math.min(displaySpeed / cachedMaxSpeed, 1.0) or 0

    -- Bar background
    dl:AddRectFilled(
        imgui.ImVec2(barX, barY),
        imgui.ImVec2(barX + barW, barY + barH),
        applyAlpha(0xFF222233, alpha), 3 * s
    )
    -- Bar fill
    local barColor = COLORS.gaugeGreen
    if speedPercent > 0.8 then barColor = COLORS.gaugeRed
    elseif speedPercent > 0.6 then barColor = COLORS.gaugeYellow end

    if speedPercent > 0 then
        dl:AddRectFilled(
            imgui.ImVec2(barX, barY),
            imgui.ImVec2(barX + barW * speedPercent, barY + barH),
            applyAlpha(barColor, alpha), 3 * s
        )
    end

    -- Vehicle name and info
    local infoY = posY + 78 * s
    dl:AddText(imgui.ImVec2(posX + 10 * s, infoY), applyAlpha(COLORS.text, alpha), cachedVehicleName)

    -- Gear and direction on same line
    local gearStr = "G" .. tostring(cachedGear)
    dl:AddText(imgui.ImVec2(posX + 10 * s, infoY + 18 * s), applyAlpha(COLORS.textDim, alpha), gearStr)

    local dirStr = cachedDirection
    dl:AddText(imgui.ImVec2(posX + 50 * s, infoY + 18 * s), applyAlpha(COLORS.textDim, alpha), dirStr)

    -- Engine status
    local engineStr = cachedEngineOn and "ENG ON" or "ENG OFF"
    local engineColor = cachedEngineOn and COLORS.engineOn or COLORS.engineOff
    dl:AddText(imgui.ImVec2(posX + w - 70 * s, infoY + 18 * s), applyAlpha(engineColor, alpha), engineStr)

    -- Health bar
    vhud_lib.drawHealthBar(dl, posX + 10 * s, posY + h - 22 * s, w - 20 * s, 10 * s, cachedHealth, {
        bgColor = applyAlpha(0xFF222233, alpha),
        rounding = 3 * s,
    })
end

-- ============================================================================
-- STYLE 3: Minimal Bar
-- ============================================================================
local function renderStyleMinimal(dl, posX, posY, alpha)
    local s = config.scale * DPI
    local w = 180 * s
    local h = 50 * s

    -- Background
    local bgColor = applyAlpha(COLORS.bg, alpha * (config.opacity or 0.85))
    dl:AddRectFilled(
        imgui.ImVec2(posX, posY),
        imgui.ImVec2(posX + w, posY + h),
        bgColor, 6 * s
    )

    -- Speed number left
    local speedStr = tostring(math.floor(displaySpeed)) .. " " .. (config.unit == "kmh" and "km/h" or "mph")
    dl:AddText(imgui.ImVec2(posX + 8 * s, posY + 6 * s), applyAlpha(COLORS.speedText, alpha), speedStr)

    -- Vehicle name small
    local nameStr = cachedVehicleName
    if #nameStr > 12 then nameStr = nameStr:sub(1, 11) .. "." end
    dl:AddText(imgui.ImVec2(posX + 8 * s, posY + 22 * s), applyAlpha(COLORS.textDim, alpha), nameStr)

    -- Gear indicator right
    local gearStr = "G" .. tostring(cachedGear)
    dl:AddText(imgui.ImVec2(posX + w - 30 * s, posY + 6 * s), applyAlpha(COLORS.textDim, alpha), gearStr)

    -- Minimal health bar at bottom
    local barX = posX + 8 * s
    local barY = posY + h - 10 * s
    local barW = w - 16 * s
    local barH = 4 * s

    dl:AddRectFilled(
        imgui.ImVec2(barX, barY),
        imgui.ImVec2(barX + barW, barY + barH),
        applyAlpha(0xFF222233, alpha), 2 * s
    )

    local healthColor = COLORS.healthGreen
    if cachedHealth < 0.3 then healthColor = COLORS.healthRed
    elseif cachedHealth < 0.6 then healthColor = COLORS.healthYellow end

    if cachedHealth > 0 then
        dl:AddRectFilled(
            imgui.ImVec2(barX, barY),
            imgui.ImVec2(barX + barW * cachedHealth, barY + barH),
            applyAlpha(healthColor, alpha), 2 * s
        )
    end
end

-- ============================================================================
-- IMGUI RENDERING - Drag Window (separate interactable window for drag)
-- ============================================================================
imgui.OnFrame(
    function() return config.enabled and currentState ~= "HIDDEN" end,
    function(self)
        -- Smooth needle interpolation every render frame
        displaySpeed = displaySpeed + (cachedSpeed - displaySpeed) * 0.12

        -- Update fade alpha (safe, no pcall)
        updateFade()

        -- Determine position
        local screenW = imgui.GetIO().DisplaySize.x
        local screenH = imgui.GetIO().DisplaySize.y
        local hudW, hudH = getHudSize()

        local posX = config.posX
        local posY = config.posY
        if posX == nil or posY == nil then
            posX, posY = getDefaultPos(screenW, screenH)
        end

        -- Hide cursor unless dragging or config window is open
        self.HideCursor = not isDragging and not showConfigWindow

        -- Drag window - separate small window for input handling
        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY))
        imgui.SetNextWindowSize(imgui.ImVec2(hudW, hudH))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))

        if imgui.Begin("##VehicleHUDDrag", nil,
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoBackground +
            imgui.WindowFlags.NoSavedSettings) then

            -- Invisible button for drag detection
            imgui.InvisibleButton("##vhud_drag", imgui.ImVec2(hudW, hudH))
            local dragActive = imgui.IsItemActive()

            if dragActive then
                local mousePos = imgui.GetIO().MousePos
                if not isDragging then
                    -- Starting drag - calculate offset
                    isDragging = true
                    dragOffsetX = mousePos.x - posX
                    dragOffsetY = mousePos.y - posY
                end
                -- Update position while dragging
                local newX = mousePos.x - dragOffsetX
                local newY = mousePos.y - dragOffsetY
                -- Clamp to screen
                if newX < 0 then newX = 0 end
                if newY < 0 then newY = 0 end
                if newX + hudW > screenW then newX = screenW - hudW end
                if newY + hudH > screenH then newY = screenH - hudH end
                config.posX = newX
                config.posY = newY
            else
                if isDragging then
                    -- Drag ended - save config
                    isDragging = false
                    saveConfig()
                end
            end
        end
        imgui.End()
        imgui.PopStyleVar(2)

        -- Recalculate position after possible drag update
        posX = config.posX
        posY = config.posY
        if posX == nil or posY == nil then
            posX, posY = getDefaultPos(screenW, screenH)
        end

        -- Draw HUD on background draw list
        local dl = imgui.GetBackgroundDrawList()

        if config.style == 1 then
            renderStyleClassic(dl, posX, posY, fadeAlpha)
        elseif config.style == 2 then
            renderStyleDigital(dl, posX, posY, fadeAlpha)
        else
            renderStyleMinimal(dl, posX, posY, fadeAlpha)
        end
    end
)

-- ============================================================================
-- CONFIG WINDOW (separate imgui.OnFrame)
-- ============================================================================
imgui.OnFrame(
    function() return showConfigWindow end,
    function(self)
        self.HideCursor = false

        local io = imgui.GetIO()
        local screenW = io.DisplaySize.x
        local screenH = io.DisplaySize.y
        local winW = 340
        local winH = 460

        -- Push dark theme styles
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2((screenW - winW) / 2, (screenH - winH) / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        if imgui.Begin("VehicleHUD Config", nil,
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoCollapse +
            imgui.WindowFlags.NoSavedSettings) then

            -- Title
            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.67, 1.0), "VEHICLE HUD")
            imgui.SameLine()
            imgui.TextDisabled("v1.0")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Enable/Disable Toggle (Button-based, no Checkbox)
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "GENERAL")
            imgui.Spacing()

            if config.enabled then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1, 0.6, 0.3, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.7, 0.4, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.5, 0.25, 1.0))
                if imgui.Button("HUD: ENABLED", imgui.ImVec2(-1, 30)) then
                    config.enabled = false
                    saveConfig()
                end
                imgui.PopStyleColor(3)
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.6, 0.15, 0.15, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.7, 0.2, 0.2, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0.1, 0.1, 1.0))
                if imgui.Button("HUD: DISABLED", imgui.ImVec2(-1, 30)) then
                    config.enabled = true
                    saveConfig()
                end
                imgui.PopStyleColor(3)
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Style Selector
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "STYLE")
            imgui.Spacing()

            local styleNames = { "Classic", "Digital", "Minimal" }
            local btnWidth = (imgui.GetContentRegionAvail().x - 16) / 3

            for i = 1, 3 do
                if i > 1 then imgui.SameLine() end
                if config.style == i then
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.5, 0.9, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.35, 0.7, 1.0))
                    if imgui.Button(styleNames[i], imgui.ImVec2(btnWidth, 28)) then end
                    imgui.PopStyleColor(3)
                else
                    if imgui.Button(styleNames[i], imgui.ImVec2(btnWidth, 28)) then
                        config.style = i
                        saveConfig()
                    end
                end
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Unit Selector
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "UNIT")
            imgui.Spacing()

            local unitBtnWidth = (imgui.GetContentRegionAvail().x - 8) / 2

            -- km/h button
            if config.unit == "kmh" then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.5, 0.9, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.35, 0.7, 1.0))
                if imgui.Button("km/h", imgui.ImVec2(unitBtnWidth, 28)) then end
                imgui.PopStyleColor(3)
            else
                if imgui.Button("km/h", imgui.ImVec2(unitBtnWidth, 28)) then
                    config.unit = "kmh"
                    saveConfig()
                end
            end

            imgui.SameLine()

            -- mph button
            if config.unit == "mph" then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.5, 0.9, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.35, 0.7, 1.0))
                if imgui.Button("mph", imgui.ImVec2(unitBtnWidth, 28)) then end
                imgui.PopStyleColor(3)
            else
                if imgui.Button("mph", imgui.ImVec2(unitBtnWidth, 28)) then
                    config.unit = "mph"
                    saveConfig()
                end
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Scale Slider
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "SCALE & OPACITY")
            imgui.Spacing()

            imgui.Text("Scale:")
            imgui.SetNextItemWidth(-1)
            cfgScaleFloat[0] = config.scale
            if imgui.SliderFloat("##scale", cfgScaleFloat, 0.5, 2.0, "%.2f") then
                config.scale = cfgScaleFloat[0]
            end

            imgui.Text("Opacity:")
            imgui.SetNextItemWidth(-1)
            cfgOpacityFloat[0] = config.opacity
            if imgui.SliderFloat("##opacity", cfgOpacityFloat, 0.3, 1.0, "%.2f") then
                config.opacity = cfgOpacityFloat[0]
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Reset buttons
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "RESET")
            imgui.Spacing()

            local resetBtnWidth = (imgui.GetContentRegionAvail().x - 8) / 2

            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.3, 0.1, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.6, 0.4, 0.15, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.4, 0.25, 0.08, 1.0))
            if imgui.Button("Reset Position", imgui.ImVec2(resetBtnWidth, 28)) then
                config.posX = nil
                config.posY = nil
                saveConfig()
                sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Position reset", 0xFFFFFF)
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()

            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.6, 0.15, 0.15, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.7, 0.2, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0.1, 0.1, 1.0))
            if imgui.Button("Reset All", imgui.ImVec2(resetBtnWidth, 28)) then
                config.enabled = defaultConfig.enabled
                config.style = defaultConfig.style
                config.unit = defaultConfig.unit
                config.scale = defaultConfig.scale
                config.opacity = defaultConfig.opacity
                config.posX = nil
                config.posY = nil
                saveConfig()
                sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} All settings reset to defaults", 0xFFFFFF)
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Close / Save button
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1, 0.5, 0.3, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.6, 0.4, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.08, 0.4, 0.25, 1.0))
            if imgui.Button("SAVE & CLOSE", imgui.ImVec2(-1, 35)) then
                saveConfig()
                showConfigWindow = false
            end
            imgui.PopStyleColor(3)
        end
        imgui.End()
        imgui.PopStyleColor(7)
        imgui.PopStyleVar(4)
    end
)

-- ============================================================================
-- COMMAND HANDLER
-- ============================================================================
local function handleCommand(args)
    if args == "" then
        -- Toggle config window open/close
        showConfigWindow = not showConfigWindow
        return
    end

    -- Parse subcommand
    local cmd, val = args:match("^(%S+)%s*(.*)$")
    if not cmd then return end
    cmd = cmd:lower()

    if cmd == "toggle" then
        -- Quick enable/disable without opening window
        config.enabled = not config.enabled
        saveConfig()
        local state = config.enabled and "ON" or "OFF"
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} HUD " .. state, 0xFFFFFF)

    elseif cmd == "style" then
        local n = tonumber(val)
        if n and n >= 1 and n <= 3 then
            config.style = math.floor(n)
            saveConfig()
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Style set to " .. tostring(config.style), 0xFFFFFF)
        else
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Usage: /vhud style 1|2|3", 0xFFFFFF)
        end

    elseif cmd == "unit" then
        val = val:lower()
        if val == "kmh" or val == "mph" then
            config.unit = val
            saveConfig()
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Unit set to " .. val, 0xFFFFFF)
        else
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Usage: /vhud unit kmh|mph", 0xFFFFFF)
        end

    elseif cmd == "scale" then
        local n = tonumber(val)
        if n and n >= 0.5 and n <= 2.0 then
            config.scale = n
            saveConfig()
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Scale set to " .. tostring(n), 0xFFFFFF)
        else
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Usage: /vhud scale 0.5-2.0", 0xFFFFFF)
        end

    elseif cmd == "opacity" then
        local n = tonumber(val)
        if n and n >= 0.3 and n <= 1.0 then
            config.opacity = n
            saveConfig()
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Opacity set to " .. tostring(n), 0xFFFFFF)
        else
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Usage: /vhud opacity 0.3-1.0", 0xFFFFFF)
        end

    elseif cmd == "reset" then
        config.enabled = defaultConfig.enabled
        config.style = defaultConfig.style
        config.unit = defaultConfig.unit
        config.scale = defaultConfig.scale
        config.opacity = defaultConfig.opacity
        config.posX = nil
        config.posY = nil
        saveConfig()
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Settings reset to defaults", 0xFFFFFF)

    else
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Commands: /vhud [toggle|style|unit|scale|opacity|reset]", 0xFFFFFF)
    end
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    -- Wait for SA-MP to be available
    while not isSampAvailable() do wait(100) end

    -- Register chat command
    sampRegisterChatCommand("vhud", handleCommand)

    -- Load message
    sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Loaded! Use /vhud to open config", 0xFFFFFF)

    -- Main loop: update data outside render
    while true do
        wait(0)
        frameCounter = frameCounter + 1

        -- Update state machine every frame
        updateStateMachine()

        -- Update vehicle data every 3 frames (performance)
        if currentState ~= "HIDDEN" and frameCounter % 3 == 0 then
            updateVehicleData()
        end
    end
end
