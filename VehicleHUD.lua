-- ============================================================================
-- VEHICLE HUD v2.0
-- SA-Styled Speedometer with proper colors and fixed state machine
-- for SA-MP Android (MonetLoader)
-- Author: OnlyDexterZ
-- ============================================================================

script_name("VehicleHUD")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local jsoncfg = require 'jsoncfg'
local vhud_lib = require 'lib.vehiclehud_lib'

-- ============================================================================
-- DPI SCALING (auto-scale based on screen resolution)
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0

-- ============================================================================
-- CONFIG
-- ============================================================================
local defaultConfig = {
    enabled = true,
    unit = "kmh",
    scale = 1.0,
    opacity = 0.85,
    posX = nil,
    posY = nil,
    devMode = false,
}

local config = jsoncfg.load(defaultConfig, "VehicleHUD")

local function saveConfig()
    jsoncfg.save(config, "VehicleHUD")
end

-- ============================================================================
-- FADE SYSTEM (simple direction-based, no complex state machine)
-- fadeDirection: -1 = fading out, 0 = idle, 1 = fading in
-- ============================================================================
local fadeAlpha = 0.0
local fadeDirection = 0
local fadeSpeed = 0.08
local inVehicle = false

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
local cachedVehHandle = 0
local frameCounter = 0

-- Smooth display values (interpolated every render frame)
local displaySpeed = 0

-- Config window state
local showConfigWindow = false
local showDebugWindow = imgui.new.bool(config.devMode or false)

-- Config window imgui buffers
local cfgScaleFloat = imgui.new.float(config.scale)
local cfgOpacityFloat = imgui.new.float(config.opacity)
local cfgPosXFloat = imgui.new.float(config.posX or 0)
local cfgPosYFloat = imgui.new.float(config.posY or 0)
local cfgDevModeBool = imgui.new.bool(config.devMode or false)

-- ============================================================================
-- COLOR HELPER - must be called INSIDE imgui.OnFrame callback only
-- Uses imgui.ColorConvertFloat4ToU32 for platform-correct color conversion
-- ============================================================================
local function getColors(alpha)
    local a = alpha
    return {
        needle = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.93, 0.07, 0.07, a)),
        text = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.93, 0.93, 0.93, a)),
        textDim = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.67, 0.67, 0.67, a)),
        tickWhite = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.87, 0.87, 0.87, a)),
        tickRed = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.8, 0.27, 0.27, a)),
        speedText = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, a)),
        engineOn = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 1.0, 0.4, a)),
        engineOff = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.2, 0.2, a)),
        pivotCenter = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.8, 0.8, 0.8, a)),
        healthGreen = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.27, 0.8, 0.27, a)),
        healthYellow = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.8, 0.8, 0.27, a)),
        healthRed = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.8, 0.27, 0.27, a)),
        bgDark = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.1, 0.12, 0.8 * a)),
        barBg = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.13, 0.13, 0.18, 0.6 * a)),
    }
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function getHudSize()
    local s = config.scale * DPI
    return 360 * s, 200 * s
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
-- FADE UPDATE (safe to call from render, no pcall)
-- ============================================================================
local function updateFade()
    if fadeDirection == 1 then
        fadeAlpha = fadeAlpha + fadeSpeed
        if fadeAlpha >= 1.0 then
            fadeAlpha = 1.0
            fadeDirection = 0
        end
    elseif fadeDirection == -1 then
        fadeAlpha = fadeAlpha - fadeSpeed
        if fadeAlpha <= 0 then
            fadeAlpha = 0
            fadeDirection = 0
            displaySpeed = 0
        end
    end
end

-- ============================================================================
-- STATE MACHINE UPDATE (called from main loop, NOT inside render)
-- Simple fade direction approach - no complex state enum
-- ============================================================================
local function updateStateMachine()
    local nowInVehicle = isPlayerInVehicle()
    if nowInVehicle and not inVehicle then
        -- Just entered vehicle
        fadeDirection = 1
    elseif not nowInVehicle and inVehicle then
        -- Just exited vehicle
        fadeDirection = -1
    elseif nowInVehicle and fadeAlpha < 1.0 and fadeDirection ~= 1 then
        -- Still in vehicle but not fully visible (recovery)
        fadeDirection = 1
    elseif not nowInVehicle and fadeAlpha > 0 and fadeDirection ~= -1 then
        -- Not in vehicle but still showing (recovery)
        fadeDirection = -1
    end
    inVehicle = nowInVehicle
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

    cachedVehHandle = veh or 0
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
-- STYLE 1: Classic SA Gauge (semicircle, SA reference styling)
-- Dark semicircle background shape, red needle, white ticks, speed numbers
-- ============================================================================
local function renderStyleClassic(dl, posX, posY, colors)
    local s = config.scale * DPI
    local w = 360 * s
    local h = 200 * s

    -- Arc gauge center
    local cx = posX + w * 0.5
    local cy = posY + h * 0.55
    local radius = 90 * s

    -- 180-degree semicircle: from left (-180 deg) to right (0 deg)
    -- Using standard math angles: -pi = left, 0 = right, top half
    local minAngle = math.rad(-180)
    local maxAngle = math.rad(0)

    -- Draw dark semicircle background shape (pie/fan)
    vhud_lib.drawSemicircleBackground(dl, cx, cy, radius + 18 * s, colors.bgDark, 80)

    -- Draw tick marks - white with subtle red at end (last 18%)
    local tickCount = 27
    vhud_lib.drawTickMarks(dl, cx, cy, radius, tickCount, {
        minAngle = minAngle,
        maxAngle = maxAngle,
        innerRadius = radius - 14 * s,
        outerRadius = radius - 2 * s,
        color = colors.tickWhite,
        majorEvery = 3,
        thickness = 1.5 * s,
        redZoneColor = colors.tickRed,
        redZoneStart = 0.82,
    })

    -- Draw speed numbers along arc (outside)
    local interval = 20
    if cachedMaxSpeed >= 300 then interval = 50
    elseif cachedMaxSpeed >= 200 then interval = 40
    elseif cachedMaxSpeed >= 150 then interval = 20
    elseif cachedMaxSpeed >= 80 then interval = 20
    else interval = 10 end

    vhud_lib.drawSpeedNumbers(dl, cx, cy, radius, cachedMaxSpeed, interval, {
        minAngle = minAngle,
        maxAngle = maxAngle,
        color = colors.text,
        offset = 12 * s,
    })

    -- Draw needle - bright red, thick, prominent
    local needleAngle = vhud_lib.angleForValue(displaySpeed, cachedMaxSpeed, minAngle, maxAngle)
    vhud_lib.drawNeedle(dl, cx, cy, radius - 18 * s, needleAngle, {
        color = colors.needle,
        thickness = 3.0 * s,
    })

    -- Center pivot hub
    dl:AddCircleFilled(imgui.ImVec2(cx, cy), 7 * s, colors.pivotCenter)
    dl:AddCircleFilled(imgui.ImVec2(cx, cy), 3.5 * s, colors.needle)

    -- Digital speed + unit INSIDE semicircle (above center, centered)
    local speedStr = tostring(math.floor(displaySpeed))
    local unitStr = config.unit == "kmh" and "km/h" or "mph"
    local speedTextW = #speedStr * 7 * s
    dl:AddText(imgui.ImVec2(cx - speedTextW * 0.5, cy - 38 * s), colors.speedText, speedStr)
    local unitTextW = #unitStr * 5.5 * s
    dl:AddText(imgui.ImVec2(cx - unitTextW * 0.5, cy - 22 * s), colors.textDim, unitStr)

    -- Health bar directly below semicircle (at center line)
    local healthColor = colors.healthGreen
    if cachedHealth < 0.3 then
        healthColor = colors.healthRed
    elseif cachedHealth < 0.6 then
        healthColor = colors.healthYellow
    end

    local healthBarY = cy + 3 * s
    local healthBarW = radius * 1.8
    local healthBarX = cx - healthBarW * 0.5
    vhud_lib.drawHealthBar(dl, healthBarX, healthBarY, healthBarW, 7 * s, cachedHealth, {
        bgColor = colors.barBg,
        fillColor = healthColor,
        rounding = 3 * s,
    })

    -- Vehicle info to the RIGHT of semicircle
    local infoX = cx + radius + 25 * s
    local infoStartY = cy - 70 * s

    -- Background for right-side info text (readable)
    local infoBgPadding = 6 * s
    local infoBgW = 90 * s
    local infoBgH = 68 * s
    dl:AddRectFilled(
        imgui.ImVec2(infoX - infoBgPadding, infoStartY - infoBgPadding),
        imgui.ImVec2(infoX + infoBgW, infoStartY + infoBgH),
        colors.bgDark, 6 * s
    )

    -- Direction/heading (at top)
    local dirStr = cachedDirection .. " " .. tostring(math.floor(cachedHeading))
    dl:AddText(imgui.ImVec2(infoX, infoStartY), colors.textDim, dirStr)

    -- Vehicle name
    dl:AddText(imgui.ImVec2(infoX, infoStartY + 16 * s), colors.text, cachedVehicleName)

    -- Engine status
    local engineStr = cachedEngineOn and "ENG ON" or "ENG OFF"
    local engineColor = cachedEngineOn and colors.engineOn or colors.engineOff
    dl:AddText(imgui.ImVec2(infoX, infoStartY + 32 * s), engineColor, engineStr)

    -- Gear
    local gearStr = "G" .. tostring(cachedGear)
    dl:AddText(imgui.ImVec2(infoX, infoStartY + 48 * s), colors.textDim, gearStr)
end

-- ============================================================================
-- IMGUI RENDERING - Direct BackgroundDrawList (no window, non-interactive)
-- CRITICAL FIX: condition is ONLY config.enabled - NO state check!
-- This ensures the render callback always runs and can respond to state changes
-- ============================================================================
imgui.OnFrame(
    function() return config.enabled end,
    function(self)
        self.HideCursor = true

        -- Update fade (safe, no pcall)
        updateFade()

        -- Skip rendering if fully hidden
        if fadeAlpha <= 0 and not inVehicle then return end

        -- Smooth needle interpolation every render frame
        displaySpeed = displaySpeed + (cachedSpeed - displaySpeed) * 0.12

        -- Generate colors inside render callback (platform-correct conversion)
        -- Caller controls overall visibility: fadeAlpha * config.opacity
        local colors = getColors(fadeAlpha * (config.opacity or 0.85))

        -- Determine position
        local screenW = imgui.GetIO().DisplaySize.x
        local screenH = imgui.GetIO().DisplaySize.y

        local posX = config.posX
        local posY = config.posY
        if posX == nil or posY == nil then
            posX, posY = getDefaultPos(screenW, screenH)
        end

        -- Draw HUD directly on background draw list
        local dl = imgui.GetBackgroundDrawList()

        renderStyleClassic(dl, posX, posY, colors)
    end
)

-- ============================================================================
-- DEBUG WINDOW (Developer Mode)
-- ============================================================================
imgui.OnFrame(
    function() return showDebugWindow[0] end,
    function(self)
        self.HideCursor = false
        imgui.SetNextWindowSize(imgui.ImVec2(300, 400), imgui.Cond.FirstUseEver)
        imgui.Begin("VehicleHUD Developer Mode", showDebugWindow)
        
        if imgui.CollapsingHeader("Vehicle Data") then
            imgui.Text("Handle: " .. tostring(cachedVehHandle))
            imgui.Text("Model ID: " .. tostring(cachedModel))
            imgui.Text("Name: " .. cachedVehicleName)
            imgui.Text("Type: " .. cachedVehicleType)
            imgui.Separator()
            imgui.Text("Speed (Cached): %.2f", cachedSpeed)
            imgui.Text("Speed (Display): %.2f", displaySpeed)
            imgui.Text("Max Speed: %d", cachedMaxSpeed)
            imgui.Text("Health: %.2f (%.1f%%)", cachedHealth, cachedHealth * 100)
            imgui.Text("Heading: %.2f (%s)", cachedHeading, cachedDirection)
            imgui.Text("Engine: " .. (cachedEngineOn and "ON" or "OFF"))
            imgui.Text("Gear: " .. tostring(cachedGear))
        end

        if imgui.CollapsingHeader("HUD State") then
            imgui.Text("In Vehicle: " .. tostring(inVehicle))
            imgui.Text("Fade Alpha: %.2f", fadeAlpha)
            imgui.Text("Fade Direction: " .. tostring(fadeDirection))
            imgui.Text("DPI Scale: %.2f", DPI)
            imgui.Text("Config Scale: %.2f", config.scale)
        end

        if imgui.CollapsingHeader("Performance") then
            imgui.Text("Frame Counter: " .. tostring(frameCounter))
            imgui.Text("FPS: %.1f", imgui.GetIO().Framerate)
        end

        imgui.End()
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
        local winH = 520

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
            imgui.TextDisabled("v2.0 SA-Style")
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

            -- Scale & Opacity Sliders
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
            imgui.TextColored(imgui.ImVec4(0.8, 0.4, 0.0, 1.0), "DEVELOPER TOOLS")
            imgui.Separator()
            imgui.Spacing()

            if imgui.Checkbox("Developer Mode", cfgDevModeBool) then
                config.devMode = cfgDevModeBool[0]
                showDebugWindow[0] = cfgDevModeBool[0]
                saveConfig()
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- Position Sliders
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "POSITION")
            imgui.Spacing()

            -- Initialize position float buffers with current values
            local curPosX = config.posX
            local curPosY = config.posY
            if curPosX == nil or curPosY == nil then
                curPosX, curPosY = getDefaultPos(screenW, screenH)
            end

            imgui.Text("Position X:")
            imgui.SetNextItemWidth(-1)
            cfgPosXFloat[0] = curPosX
            if imgui.SliderFloat("##posX", cfgPosXFloat, 0, screenW, "%.0f") then
                config.posX = cfgPosXFloat[0]
            end

            imgui.Text("Position Y:")
            imgui.SetNextItemWidth(-1)
            cfgPosYFloat[0] = curPosY
            if imgui.SliderFloat("##posY", cfgPosYFloat, 0, screenH, "%.0f") then
                config.posY = cfgPosYFloat[0]
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
                config.unit = defaultConfig.unit
                config.scale = defaultConfig.scale
                config.opacity = defaultConfig.opacity
                config.posX = nil
                config.posY = nil
                config.devMode = false
                cfgDevModeBool[0] = false
                showDebugWindow[0] = false
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
        config.enabled = not config.enabled
        saveConfig()
        local state = config.enabled and "ON" or "OFF"
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} HUD " .. state, 0xFFFFFF)

    elseif cmd == "debug" or cmd == "dev" then
        config.devMode = not config.devMode
        showDebugWindow[0] = config.devMode
        cfgDevModeBool[0] = config.devMode
        saveConfig()
        local state = config.devMode and "ENABLED" or "DISABLED"
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Developer Mode " .. state, 0xFFFFFF)

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

    elseif cmd == "pos" then
        local x, y = val:match("^(%S+)%s+(%S+)$")
        x = tonumber(x)
        y = tonumber(y)
        if x and y then
            config.posX = x
            config.posY = y
            saveConfig()
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Position set to " .. tostring(math.floor(x)) .. ", " .. tostring(math.floor(y)), 0xFFFFFF)
        else
            sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Usage: /vhud pos <x> <y>", 0xFFFFFF)
        end

        elseif cmd == "reset" then
        config.enabled = defaultConfig.enabled
        config.unit = defaultConfig.unit
        config.scale = defaultConfig.scale
        config.opacity = defaultConfig.opacity
        config.posX = nil
        config.posY = nil
        config.devMode = false
        saveConfig()
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Settings reset to defaults", 0xFFFFFF)
    else
        sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} Commands: /vhud [toggle|dev|unit|scale|opacity|pos|reset]", 0xFFFFFF)
    end
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    -- Wait for SA-MP to be available
    while not isSampAvailable() do wait(100) end

    -- Auto-adjust DPI based on screen resolution
    local screenW, screenH = 800, 600
    pcall(function()
        screenW, screenH = getScreenResolution()
    end)
    -- Base design for 1080px width. Scale proportionally.
    local autoScale = screenW / 1080.0
    if autoScale < 0.6 then autoScale = 0.6 end
    if autoScale > 2.5 then autoScale = 2.5 end
    DPI = (MONET_DPI_SCALE or 1.0) * autoScale

    -- Register chat command
    sampRegisterChatCommand("vhud", handleCommand)

    -- Load message
    sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} v2.1 Loaded with Developer Mode! Use /vhud to open config", 0xFFFFFF)

    -- Main loop: update data outside render
    while true do
        wait(0)
        frameCounter = frameCounter + 1

        -- Update state machine every frame (sets fadeDirection)
        updateStateMachine()

        -- Update vehicle data every 3 frames when visible or fading
        if (fadeAlpha > 0 or inVehicle) and frameCounter % 3 == 0 then
            updateVehicleData()
        end
    end
end
