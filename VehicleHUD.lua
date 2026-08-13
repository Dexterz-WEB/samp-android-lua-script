-- ============================================================================
-- VEHICLE HUD v2.0 (Restyle - SA reference)
-- for SA-MP Android (MonetLoader)
-- Author: OnlyDexterZ (restyle by request)
-- ============================================================================

script_name("VehicleHUD")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local jsoncfg = require 'jsoncfg'
local vhud_lib = require 'lib.vehiclehud_lib'
-- SAMemory di-handle di dalam vehiclehud_lib (getVehicleData)

-- ============================================================================
-- DPI / AUTO-SCALE
-- Mode "B": auto-scale berbasis imgui DisplaySize (bukan getScreenResolution)
-- Tujuan: hindari double-scaling yang bikin HUD offset pas scale besar.
-- ============================================================================
local DPI = 1.0

local function calcAutoScale(screenW, screenH)
    -- Baseline landscape 1920x1080
    -- Pakai min supaya aman di aspect ratio beda-beda
    local scale = math.min(screenW / 1920.0, screenH / 1080.0)
    if scale < 0.6 then scale = 0.6 end
    if scale > 2.5 then scale = 2.5 end
    return scale
end

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
-- fadeSpeed dihapus — diganti dt-based (2.4 unit/detik = 0.08/frame * 30fps baseline)
local inVehicle = false

-- ============================================================================
-- DELTA TIME (frame-rate independent animation)
-- Baseline: 30 FPS. Behaviour pada 30 FPS identik dengan implementasi lama.
-- os.clock() dipakai karena getFrameTime() tidak tersedia di MonetLoader Android.
-- ============================================================================
local lastFrameTime = os.clock()

-- ============================================================================
-- VEHICLE DATA CACHE (updated outside render)
-- ============================================================================
local cachedSpeed = 0
local cachedSpeedKmh = 0
local cachedHealth = 1.0
local cachedModel = 0
local cachedHeading = 0
local cachedEngineOn = false
local cachedLocked = false
local cachedLightsOn = false
local cachedVehicleName = "Unknown"
local cachedVehicleType = "Car"
local cachedMaxSpeed = 240
local cachedGear = 1
local cachedRpmRatio = 0.0
local cachedDirection = "N"
local cachedVehHandle = 0
local nativeRpm = 0.0
local frameCounter = 0

-- Smooth display values (interpolated every render frame)
local displaySpeed = 0
local displayRpmRatio = 0.0
local displayNeedleRatio = 0.0
local lastDisplayedGear = nil
local gearShiftShake = 0.0

-- Smooth display values for Throttle and Brake (F1 Style)
local cachedThrottle = 0.0
local cachedBrake = 0.0
local displayThrottle = 0.0
local displayBrake = 0.0


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
        tickWhite = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.95, 0.95, 0.95, a)),
        tickRed = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.55, 0.10, 0.10, a)),
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
    return 240 * s, 260 * s
end

local function getDefaultPos(screenW, screenH)
    local w, h = getHudSize()
    local padding = 20 * DPI
    return screenW - w - padding, screenH - h - padding
end

local function clampHudPos(posX, posY, screenW, screenH)
    local w, h = getHudSize()
    local maxX = math.max(0, screenW - w)
    local maxY = math.max(0, screenH - h)
    if posX < 0 then posX = 0 end
    if posY < 0 then posY = 0 end
    if posX > maxX then posX = maxX end
    if posY > maxY then posY = maxY end
    return posX, posY
end

-- ============================================================================
-- VEHICLE DETECTION (pcall outside render)
-- ============================================================================
local function isPlayerInVehicle()
    -- MonetLoader: beberapa build membedakan "car" vs "bike/boat/plane".
    -- Kalau cuma cek isCharInAnyCar, HUD bisa hilang pas ganti ke motor/heli/boat.
    local function safeBoolCall(fn, ...)
        if type(fn) ~= "function" then return false end
        local ok, res = pcall(fn, ...)
        return ok and (res and true or false)
    end

    return safeBoolCall(isCharInAnyCar, PLAYER_PED)
        or safeBoolCall(isCharOnAnyBike, PLAYER_PED)
        or safeBoolCall(isCharInAnyBoat, PLAYER_PED)
        or safeBoolCall(isCharInAnyPlane, PLAYER_PED)
        or safeBoolCall(isCharInAnyHeli, PLAYER_PED)
        or safeBoolCall(isCharInAnyHelicopter, PLAYER_PED)
end

-- ============================================================================
-- FADE UPDATE (safe to call from render, no pcall)
-- ============================================================================
local function updateFade(dt)
    -- 2.4/detik = 0.08/frame * 30fps baseline → identik di 30fps
    local fadeStep = dt * 2.4
    if fadeDirection == 1 then
        fadeAlpha = fadeAlpha + fadeStep
        if fadeAlpha >= 1.0 then
            fadeAlpha = 1.0
            fadeDirection = 0
        end
    elseif fadeDirection == -1 then
        fadeAlpha = fadeAlpha - fadeStep
        if fadeAlpha <= 0 then
            fadeAlpha = 0
            fadeDirection = 0
            displaySpeed = 0
            displayRpmRatio = 0
            displayNeedleRatio = 0
            gearShiftShake = 0
            lastDisplayedGear = nil
            cachedThrottle = 0
            cachedBrake = 0
            displayThrottle = 0
            displayBrake = 0
        end
    end
end

-- ============================================================================
-- STATE MACHINE UPDATE (called from main loop, NOT inside render)
-- ============================================================================
local function updateStateMachine()
    local nowInVehicle = isPlayerInVehicle()
    if nowInVehicle and not inVehicle then
        fadeDirection = 1
    elseif not nowInVehicle and inVehicle then
        fadeDirection = -1
    elseif nowInVehicle and fadeAlpha < 1.0 and fadeDirection ~= 1 then
        fadeDirection = 1
    elseif not nowInVehicle and fadeAlpha > 0 and fadeDirection ~= -1 then
        fadeDirection = -1
    end
    inVehicle = nowInVehicle
end

-- ============================================================================
-- DATA UPDATE (called from main loop via frame counter, NOT inside render)
-- ============================================================================
local function updateVehicleData()
    local function sanitizeNumber(n, fallback)
        if type(n) ~= "number" then return fallback end
        -- NaN check: NaN ~= NaN
        if n ~= n then return fallback end
        if n == math.huge or n == -math.huge then return fallback end
        return n
    end

    -- Ambil handle kendaraan secara aman untuk berbagai tipe (car/bike/boat/plane/heli).
    -- Catatan: di beberapa build, storeCarCharIsInNoSave bisa ngasih 0 saat player bukan di kendaraan.
    local function getVehicleHandle()
        local ok, h = pcall(storeCarCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        ok, h = pcall(storeBikeCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        ok, h = pcall(storeBoatCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        ok, h = pcall(storePlaneCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        ok, h = pcall(storeHeliCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        ok, h = pcall(storeHelicopterCharIsInNoSave, PLAYER_PED)
        if ok and type(h) == "number" and h > 0 then return h end
        return nil
    end

    local veh = getVehicleHandle()

    if not veh then return end

    -- Speed
    pcall(function()
        -- MonetLoader: beberapa build tetap pakai getCarSpeed untuk semua kendaraan,
        -- tapi ada saat transisi (turun/naik) nilainya bisa invalid. Kita sanitize.
        local rawSpeed = sanitizeNumber(getCarSpeed(veh), 0.0)
        cachedSpeedKmh = sanitizeNumber(rawSpeed * 3.6, 0.0)
        if config.unit == "kmh" then
            cachedSpeed = cachedSpeedKmh
        else
            cachedSpeed = sanitizeNumber(rawSpeed * 2.237, 0.0)
        end
        cachedSpeed = sanitizeNumber(cachedSpeed, 0.0)
    end)

    -- Model
    pcall(function()
        cachedModel = getCarModel(veh)
    end)

    -- Heading
    pcall(function()
        cachedHeading = getCarHeading(veh)
    end)

    -- Derived data (partially needed like name and type)
    cachedVehicleName = vhud_lib.getVehicleName(cachedModel)
    cachedVehicleType = vhud_lib.getVehicleType(cachedModel)
    cachedMaxSpeed = vhud_lib.getMaxSpeed(cachedModel)

    -- Engine status
    pcall(function()
        cachedEngineOn = isCarEngineOn(veh)
    end)

    -- Health
    pcall(function()
        local rawHealth = sanitizeNumber(getCarHealth(veh), 1000.0)
        cachedHealth = rawHealth / 1000.0
        if cachedHealth > 1.0 then cachedHealth = 1.0 end
        if cachedHealth < 0.0 then cachedHealth = 0.0 end
    end)

    -- Throttle & Brake via widget (mobile touch buttons)
    local rawThrottle = 0.0
    local rawBrake    = 0.0
    pcall(function()
        if isWidgetPressed then
            if isWidgetPressed(0x2) then rawThrottle = 1.0 end
            if isWidgetPressed(0x3) then rawBrake    = 1.0 end
            if isWidgetPressed(0x4) then rawBrake    = 1.0 end
        end
    end)
    cachedThrottle = rawThrottle
    cachedBrake    = rawBrake

    -- RPM + Gear via SAMemory (getVehicleData di lib)
    local carPtr = nil
    pcall(function() carPtr = getCarPointer(veh) end)

    local rpmInt, gearFromMem = vhud_lib.getVehicleData(veh, carPtr, cachedEngineOn, cachedSpeedKmh)

    cachedRpmRatio = rpmInt / 7000.0
    if cachedRpmRatio < 0.0 then cachedRpmRatio = 0.0 end
    if cachedRpmRatio > 1.0 then cachedRpmRatio = 1.0 end

    cachedGear = gearFromMem

    -- Gear shift shake + RPM drop saat pindah gigi
    if cachedEngineOn then
        if lastDisplayedGear ~= nil and cachedGear ~= lastDisplayedGear then
            gearShiftShake = 1.0
            -- Drop RPM display langsung saat ganti gigi, lalu interpolasi naik balik natural
            displayRpmRatio = displayRpmRatio - 0.28
            if displayRpmRatio < 0.0 then displayRpmRatio = 0.0 end
        end
        lastDisplayedGear = cachedGear
    else
        lastDisplayedGear = nil
    end

    cachedDirection = vhud_lib.getHeadingDirection(cachedHeading)
    cachedVehHandle = veh or 0

    -- Native RPM via SAMemory (offset 0x420)
    pcall(function()
        if carPtr and carPtr ~= 0 then
            -- fCurrentEngineRpm is a float at offset 0x420 in CVehicle
            nativeRpm = memory.getfloat(carPtr + 0x420, true)
        else
            nativeRpm = 0.0
        end
    end)
end

-- ============================================================================
-- STYLE: closer to PC CLEO speedometer from source ZIP
-- ============================================================================
local function renderStyleClassic(dl, posX, posY, colors)
    local s = config.scale * DPI
    local w = 240 * s
    local h = 260 * s

    -- Center tepat di tengah window, ada margin 20*s di semua sisi
    local cx = posX + w * 0.5
    local cy = posY + h * 0.5

    -- ============================================================
    -- RADIUS TABLE (semua proporsional, gauge muat dalam window)
    -- gaugeOuter (100*s) < cx (120*s) -> margin 20*s aman di semua sisi
    -- label (91*s) di antara spdTickOuter (88*s) dan chrome (97*s)
    -- ============================================================
    local gaugeOuter   = 100 * s  -- filled circle paling luar (shadow)
    local chromeR1     = 99  * s  -- chrome bright
    local chromeR2     = 97  * s  -- chrome dim
    local dialOuter    = 94  * s  -- background dial filled
    local spdTickOuter = 88  * s  -- ujung luar tick (dikembalikan panjang dan elegan)
    local spdTickInner = 76  * s  -- ujung dalam tick major
    local spdTickMinor = 83  * s  -- ujung dalam tick minor
    local spdLabelR    = 91  * s  -- label angka (radius cadangan)

    local rpmOuter     = 62  * s
    local rpmInner     = 47  * s

    local arcStart  = math.rad(120)
    local fullSweep = math.rad(300)
    local arcEnd    = arcStart + fullSweep

    local TOTAL_SEGS = 240
    local function segsFor(sweep)
        return math.max(6, math.ceil(TOTAL_SEGS * math.abs(sweep) / fullSweep))
    end

    local a = fadeAlpha * (config.opacity or 0.85)

    local colBorder     = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0,  0.0,  0.0,  a))
    local colTrackDark  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.03, 0.03, 0.04, a * 0.99))
    local colTrackMid   = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.10, a * 0.97))
    local colTrackInner = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.02, 0.02, 0.03, a * 0.95))
    local colChrome     = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.72, 0.74, 0.78, a * 0.90))
    local colChromeDim  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.45, 0.47, 0.52, a * 0.70))
    local colInactive   = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.38, 0.38, 0.40, a * 0.50))
    local colTickDim    = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.75, 0.75, 0.75, a * 0.85))
    local colTickRed    = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.80, 0.15, 0.15, a))
    local colNeedle     = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.96, 0.96, 0.96, a))
    local colNeedleTip  = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.93, 0.07, 0.07, a))
    local colPivot      = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.82, 0.82, 0.82, a))

    -- Colors for Throttle (Blue) and Brake (Red)
    local colThrottleBg = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.04, 0.12, 0.22, a * 0.45))
    local colThrottle   = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.20, 0.60, 1.00, a))
    local colBrakeBg    = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.22, 0.04, 0.04, a * 0.45))
    local colBrake      = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.18, 0.18, a))

    local function arcBand(r1, r2, angleFr, sw, col)
        if sw == 0 then return end
        local n = segsFor(sw)
        local step = sw / n
        for i = 0, n - 1 do
            local a1 = angleFr + step * i
            local a2 = a1 + step
            local c1, s1 = math.cos(a1), math.sin(a1)
            local c2, s2 = math.cos(a2), math.sin(a2)
            local p1 = imgui.ImVec2(cx + r2 * c1, cy + r2 * s1)
            local p2 = imgui.ImVec2(cx + r2 * c2, cy + r2 * s2)
            local p3 = imgui.ImVec2(cx + r1 * c2, cy + r1 * s2)
            local p4 = imgui.ImVec2(cx + r1 * c1, cy + r1 * s1)
            if dl.AddQuadFilled then
                dl:AddQuadFilled(p1, p2, p3, p4, col)
            elseif dl.AddTriangleFilled then
                dl:AddTriangleFilled(p1, p2, p3, col)
                dl:AddTriangleFilled(p1, p3, p4, col)
            end
        end
    end

    local function arcLine(r, angleFr, sw, col, thick)
        if sw == 0 then return end
        local n = segsFor(sw)
        local step = sw / n
        for i = 0, n - 1 do
            local a1 = angleFr + step * i
            local a2 = a1 + step
            dl:AddLine(
                imgui.ImVec2(cx + r * math.cos(a1), cy + r * math.sin(a1)),
                imgui.ImVec2(cx + r * math.cos(a2), cy + r * math.sin(a2)),
                col, thick
            )
        end
    end

    local function filledCircle(radius, col, segments)
        if dl.AddCircleFilled then
            dl:AddCircleFilled(imgui.ImVec2(cx, cy), radius, col, segments or 64)
        end
    end

    local io = imgui.GetIO()
    local function drawOutlined(text, x, y, col, outlineMul)
        local mul = outlineMul or 1.0
        local o = math.max(1.0, 1.35 * s * mul)
        dl:AddText(imgui.ImVec2(x - o, y), colBorder, text)
        dl:AddText(imgui.ImVec2(x + o, y), colBorder, text)
        dl:AddText(imgui.ImVec2(x, y - o), colBorder, text)
        dl:AddText(imgui.ImVec2(x, y + o), colBorder, text)
        dl:AddText(imgui.ImVec2(x - o, y - o), colBorder, text)
        dl:AddText(imgui.ImVec2(x + o, y - o), colBorder, text)
        dl:AddText(imgui.ImVec2(x - o, y + o), colBorder, text)
        dl:AddText(imgui.ImVec2(x + o, y + o), colBorder, text)
        dl:AddText(imgui.ImVec2(x, y), col, text)
    end

    local function drawOutlinedCentered(text, centerX, y, fontScale, col, outlineMul)
        local old = io.FontGlobalScale
        io.FontGlobalScale = old * (fontScale or 1.0)
        local ts = imgui.CalcTextSize(text)
        drawOutlined(text, centerX - ts.x * 0.5, y, col, (outlineMul or 1.0) * (fontScale or 1.0))
        io.FontGlobalScale = old
    end

    local rpmRatio = displayRpmRatio
    if rpmRatio < 0.0 then rpmRatio = 0.0 end
    if rpmRatio > 1.0 then rpmRatio = 1.0 end

    local barCount     = 30
    local redZoneBars  = 3
    local barGap       = math.rad(2.2)
    local barSweep     = (fullSweep / barCount) - barGap
    if barSweep < math.rad(1.5) then barSweep = math.rad(1.5) end

    local activeBars = math.floor(rpmRatio * barCount + 0.999)
    if cachedEngineOn and activeBars < 1 then activeBars = 1 end
    if activeBars > barCount then activeBars = barCount end
    local redZoneStartRatio = (barCount - redZoneBars) / barCount

    local maxSpd = cachedMaxSpeed
    if not maxSpd or maxSpd <= 0 then maxSpd = 180 end

    -- maxSpd database selalu KMH; kalau unit MPH, konversi supaya mapping konsisten
    local maxSpdDisp = maxSpd
    if config.unit ~= "kmh" then
        maxSpdDisp = maxSpd * 0.621371
    end

    local speedRatio = displaySpeed / maxSpdDisp
    if speedRatio < 0.0 then speedRatio = 0.0 end
    if speedRatio > 1.0 then speedRatio = 1.0 end

    -- =========================================================================
    -- ANCHORED SCALE (biar beda kelas kendaraan beda "rasa" speedo)
    -- Slow  : maxSpd < 100 km/h  -> anchor adaptif (sekitar 65% max)
    -- Medium: 100-189 km/h       -> anchor fixed 100 km/h (atau 60 mph)
    -- Fast  : >= 190 km/h        -> anchor fixed 140 km/h (atau 80 mph)
    -- Semua elemen (needle/tick/angka) harus pakai mapping yang sama.
    -- =========================================================================
    local interval = (config.unit == "kmh") and 20 or 10

    local function roundDown(v, step)
        if not step or step <= 0 then return v end
        return math.floor(v / step) * step
    end

    local anchor = nil
    if maxSpd >= 190 then
        anchor = (config.unit == "kmh") and 140 or 80
    elseif maxSpd >= 100 then
        anchor = (config.unit == "kmh") and 100 or 60
    else
        anchor = roundDown(maxSpdDisp * 0.65, interval)
        local minA = (config.unit == "kmh") and 40 or 20
        if anchor < minA then anchor = minA end
    end

    local useAnchor = false -- Force symmetrical layout (0 KMH starts at 7 o'clock)

    -- IMPORTANT:
    -- Mapping piecewise bikin jarak antar angka tidak rata (contoh 120-160 keliatan jauh).
    -- Solusi: mapping tetap LINEAR (biar spacing rata), tapi seluruh skala "dirotasi"
    -- sehingga anchor selalu jatuh di tengah arc.
    local arcStartEff = arcStart
    local arcEndEff = arcEnd
    if useAnchor then
        local arcMid = arcStart + (arcEnd - arcStart) * 0.5
        local anchorAngleLinear = vhud_lib.angleForValue(anchor, maxSpdDisp, arcStart, arcEnd)
        local angleOffset = arcMid - anchorAngleLinear
        arcStartEff = arcStart + angleOffset
        arcEndEff = arcEnd + angleOffset
    end

    local function mapSpeedToAngle(v)
        return vhud_lib.angleForValue(v, maxSpdDisp, arcStartEff, arcEndEff)
    end

    local speedAngle = mapSpeedToAngle(displaySpeed)

    local shakeTime = os.clock()
    local redlineIntensity = 0.0
    if rpmRatio > redZoneStartRatio then
        redlineIntensity = (rpmRatio - redZoneStartRatio) / (1.0 - redZoneStartRatio)
        if redlineIntensity < 0.0 then redlineIntensity = 0.0 end
        if redlineIntensity > 1.0 then redlineIntensity = 1.0 end
    end

    local shiftShakeAngle = 0.0
    if gearShiftShake > 0 then
        local knockback = -math.rad(4.0) * gearShiftShake
        local overshoot = math.sin(shakeTime * 40.0) * math.rad(1.5) * gearShiftShake
        shiftShakeAngle = knockback + overshoot
    end

    -- Needle vibrate saat mendekati redline (mulai dari rpmRatio > 0.75)
    local rpmVibrateAngle = 0.0
    if rpmRatio > 0.75 then
        local vibrateIntensity = (rpmRatio - 0.75) / 0.25
        if vibrateIntensity > 1.0 then vibrateIntensity = 1.0 end
        rpmVibrateAngle =
            (math.sin(shakeTime * 85.0) * math.rad(1.2) +
             math.sin(shakeTime * 47.0) * math.rad(0.6)) * vibrateIntensity
    end

    speedAngle = speedAngle + shiftShakeAngle + rpmVibrateAngle

    -- ============================================================
    -- [LAYER 1] BACKGROUND
    -- ============================================================
    filledCircle(gaugeOuter, colBorder, 80)
    filledCircle(dialOuter,  colTrackDark, 80)
    arcBand(rpmOuter + 2 * s, spdTickInner - 1 * s, arcStartEff, fullSweep, colTrackMid)
    filledCircle(rpmInner - 2 * s, colTrackInner, 72)

    -- ============================================================
    -- [LAYER 2] CHROME BORDER
    -- ============================================================
    arcLine(chromeR1, arcStartEff, fullSweep, colChrome,    2.0 * s)
    arcLine(chromeR2, arcStartEff, fullSweep, colChromeDim, 1.2 * s)

    -- ============================================================
    -- [LAYER 2.5] F1 STYLE THROTTLE & BRAKE TELEMETRY
    -- Bar diperbesar 2.5x: lebar 4*s -> 10*s, sweep 90° -> 110°
    -- ============================================================
    local tbR1      = 101.5 * s  -- radius dalam (sama, nempel di luar chrome)
    local tbR2      = 111.5 * s  -- radius luar (lebar 10*s, naik dari 105.5)
    local tbSweep   = math.rad(110) -- sweep diperlebar dari 90° ke 110°

    -- Throttle: Left side, bottom to top
    arcBand(tbR1, tbR2, math.rad(125), tbSweep, colThrottleBg)
    arcBand(tbR1, tbR2, math.rad(125), tbSweep * displayThrottle, colThrottle)

    -- Brake: Right side, bottom to top
    arcBand(tbR1, tbR2, math.rad(55), -tbSweep, colBrakeBg)
    arcBand(tbR1, tbR2, math.rad(55), -tbSweep * displayBrake, colBrake)

    -- ============================================================
    -- [LAYER 3] RPM BAR
    -- ============================================================
    arcBand(rpmInner, rpmOuter, arcStartEff, fullSweep, colTrackMid)

    for i = 0, barCount - 1 do
        local barAngle  = arcStartEff + (fullSweep / barCount) * i + barGap * 0.5
        local isRedZone = i >= (barCount - redZoneBars)
        local col       = colInactive

        if i < activeBars then
            if isRedZone then
                local glow = redlineIntensity
                -- Flash: brightness pulse pakai sin, makin cepat makin tinggi redlineIntensity
                local flashFreq = 6.0 + redlineIntensity * 10.0
                local flashPulse = 0.55 + 0.45 * math.abs(math.sin(shakeTime * flashFreq))
                col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
                    (0.90 + 0.10 * glow) * flashPulse,
                    (0.10 - 0.10 * glow) * flashPulse,
                    (0.10 - 0.10 * glow) * flashPulse,
                    a
                ))
            else
                col = colors.tickWhite
            end
        elseif isRedZone then
            col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.35, 0.08, 0.08, a * 0.55))
        end

        arcBand(rpmInner + 3 * s, rpmOuter - 3 * s, barAngle, barSweep, col)
    end

    arcLine(rpmOuter, arcStartEff, fullSweep, colBorder, 2.5 * s)
    arcLine(rpmInner, arcStartEff, fullSweep, colBorder, 2.0 * s)

    -- ============================================================
    -- [LAYER 4] TICK MARKS
    -- Major: lebih panjang (dari spdTickInner - 5*s) dan tebal (2.5*s)
    -- Minor: lebih pendek (dari spdTickMinor + 2*s) dan tipis (max 1.0*s)
    -- ============================================================
    local tickStep = 5
    local majorEvery = math.max(1, math.floor(interval / tickStep + 0.5))
    local thickMinor = math.max(0.8, 1.0 * s)

    local v = 0
    local idx = 0
    while v <= maxSpdDisp + 0.001 do
        local angle = mapSpeedToAngle(v)
        local isMajor = (idx % majorEvery == 0)
        local ratio = (maxSpdDisp > 0) and (v / maxSpdDisp) or 0
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        local isRed = ratio >= 0.85
        local col2 = isRed and colTickRed or colTickDim

        local inner, thick
        if isMajor then
            inner = spdTickInner - 5 * s   -- lebih panjang ke dalam
            thick = math.max(2.0, 2.8 * s) -- lebih tebal
        else
            inner = spdTickMinor + 2 * s   -- lebih pendek
            thick = thickMinor             -- tipis
        end
        dl:AddLine(
            imgui.ImVec2(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
            imgui.ImVec2(cx + spdTickOuter * math.cos(angle), cy + spdTickOuter * math.sin(angle)),
            col2, thick
        )
        v = v + tickStep
        idx = idx + 1
    end
    -- ============================================================
    -- [LAYER 6] NEEDLE
    -- ============================================================
    local needleLen   = spdTickInner - 2 * s  -- 74*s
    local needleTail  = 10 * s

    -- Needle tapered: base lebar, ujung meruncing
    -- Pakai 2 segmen quad: tail-to-mid (lebar penuh) + mid-to-tip (mengecil)
    do
        local ca, sa = math.cos(speedAngle), math.sin(speedAngle)
        local cp, sp = -sa, ca  -- perpendicular

        local baseW   = 3.0 * s   -- lebar di pusat/tail
        local midW    = 2.2 * s   -- lebar di 60% needle
        local tipW    = 0.4 * s   -- lebar di ujung (sangat runcing)
        local midDist = needleLen * 0.60

        -- Titik-titik quad (dari tail ke mid, tebal)
        local t = imgui.ImVec2(cx - needleTail * ca, cy - needleTail * sa)
        local m = imgui.ImVec2(cx + midDist  * ca,   cy + midDist  * sa)
        local e = imgui.ImVec2(cx + needleLen * ca,  cy + needleLen * sa)

        local t1 = imgui.ImVec2(t.x + cp * baseW, t.y + sp * baseW)
        local t2 = imgui.ImVec2(t.x - cp * baseW, t.y - sp * baseW)
        local m1 = imgui.ImVec2(m.x + cp * midW,  m.y + sp * midW)
        local m2 = imgui.ImVec2(m.x - cp * midW,  m.y - sp * midW)
        local e1 = imgui.ImVec2(e.x + cp * tipW,  e.y + sp * tipW)
        local e2 = imgui.ImVec2(e.x - cp * tipW,  e.y - sp * tipW)

        -- Shadow/border pass (lebih lebar sedikit)
        local bW = baseW + 1.2 * s
        local bt1 = imgui.ImVec2(t.x + cp * bW, t.y + sp * bW)
        local bt2 = imgui.ImVec2(t.x - cp * bW, t.y - sp * bW)
        local bm1 = imgui.ImVec2(m.x + cp * (midW + 1.0 * s), m.y + sp * (midW + 1.0 * s))
        local bm2 = imgui.ImVec2(m.x - cp * (midW + 1.0 * s), m.y - sp * (midW + 1.0 * s))
        local be1 = imgui.ImVec2(e.x + cp * (tipW + 0.5 * s), e.y + sp * (tipW + 0.5 * s))
        local be2 = imgui.ImVec2(e.x - cp * (tipW + 0.5 * s), e.y - sp * (tipW + 0.5 * s))

        -- Draw shadow quad (hitam)
        dl:AddTriangleFilled(bt1, bt2, bm2, colBorder)
        dl:AddTriangleFilled(bt1, bm2, bm1, colBorder)
        dl:AddTriangleFilled(bm1, bm2, be2, colBorder)
        dl:AddTriangleFilled(bm1, be2, be1, colBorder)

        -- Body needle: putih/abu dari tail ke mid
        dl:AddTriangleFilled(t1, t2, m2, colNeedle)
        dl:AddTriangleFilled(t1, m2, m1, colNeedle)
        -- Tip merah dari mid ke ujung
        dl:AddTriangleFilled(m1, m2, e2, colNeedleTip)
        dl:AddTriangleFilled(m1, e2, e1, colNeedleTip)
    end

    -- ============================================================
    -- [LAYER 7] CENTER HUB
    -- ============================================================
    if dl.AddCircleFilled then
        dl:AddCircleFilled(imgui.ImVec2(cx, cy), 8.5 * s, colBorder,    24)
        dl:AddCircleFilled(imgui.ImVec2(cx, cy), 7.0 * s, colChrome,    20)
        dl:AddCircleFilled(imgui.ImVec2(cx, cy), 5.5 * s,
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.85, 0.05, 0.05, a)), 18)
        dl:AddCircleFilled(imgui.ImVec2(cx, cy), 2.0 * s, colTrackInner, 12)
    end

    -- ============================================================
    -- [LAYER 8] CENTER TEXT (gear, speed number, unit)
    -- ============================================================
    local colorTxt = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, a))
    local gearStr  = vhud_lib.getGearLabel(cachedGear, cachedEngineOn, cachedSpeedKmh)
    local gearCol  = rpmRatio >= 0.9
        and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.25, 0.25, a))
        or colorTxt

    drawOutlinedCentered(gearStr, cx, cy - 38 * s, 1.5, gearCol, 1.0)
    local spdStr = tostring(math.floor(displaySpeed + 0.5))
    drawOutlinedCentered(spdStr, cx, cy - 24 * s, 1.6, colorTxt, 1.0)
    local unitStr = config.unit == "kmh" and "KMH" or "MPH"
    drawOutlinedCentered(unitStr, cx, cy + 14 * s, 0.80, colorTxt, 1.0)
end

-- ============================================================================
-- IMGUI RENDERING - Direct BackgroundDrawList (no window, non-interactive)
-- ============================================================================
imgui.OnFrame(
    function() return config.enabled end,
    function(self)
        self.HideCursor = true

        -- --------------------------------------------------------
        -- DELTA TIME
        -- Clamp: max 100ms (~10fps) mencegah lag spike merusak animasi.
        -- Fallback: 1/30 jika os.clock stuck atau dt <= 0.
        -- --------------------------------------------------------
        local now = os.clock()
        local dt  = now - lastFrameTime
        lastFrameTime = now
        if dt <= 0 or dt ~= dt then dt = 1 / 30 end
        if dt > 0.1 then dt = 0.1 end

        updateFade(dt)

        if fadeAlpha <= 0 and not inVehicle then return end

        -- Safety: kalau sempat NaN (biasanya pas ganti kendaraan), reset biar nggak nempel terus
        if type(displaySpeed) ~= "number" or displaySpeed ~= displaySpeed then displaySpeed = 0 end
        if type(displayRpmRatio) ~= "number" or displayRpmRatio ~= displayRpmRatio then displayRpmRatio = 0 end
        if type(cachedSpeed) ~= "number" or cachedSpeed ~= cachedSpeed then cachedSpeed = 0 end
        if type(cachedRpmRatio) ~= "number" or cachedRpmRatio ~= cachedRpmRatio then cachedRpmRatio = 0 end

        -- --------------------------------------------------------
        -- FRAME-RATE INDEPENDENT LERP
        -- Formula: factor_dt = 1 - (1 - f)^(dt * 30)
        -- Baseline 30fps → dt=1/30 → factor_dt = f (identik implementasi lama)
        -- --------------------------------------------------------
        local k30 = dt * 30  -- normalized ke 30fps baseline
        local fSpeed    = 1 - (0.90 ^ k30)  -- was * 0.10
        local fTB       = 1 - (0.85 ^ k30)  -- was * 0.15 (throttle & brake)

        -- RPM easing dinamis: makin tinggi RPM display, makin lambat naiknya
        -- Efek: terasa "struggle" mendekati redline, drop tetap responsif
        local rpmDiff = cachedRpmRatio - displayRpmRatio
        local fRpmBase
        if rpmDiff > 0 then
            -- Naik: lambat makin tinggi RPM (0.82 di bawah, turun ke 0.92 di redline)
            local slowdown = displayRpmRatio * 0.10  -- makin tinggi makin lambat
            fRpmBase = 0.82 + slowdown
            if fRpmBase > 0.94 then fRpmBase = 0.94 end
        else
            -- Turun: tetap responsif
            fRpmBase = 0.78
        end
        local fRpm = 1 - (fRpmBase ^ k30)

        displaySpeed    = displaySpeed    + (cachedSpeed    - displaySpeed)    * fSpeed
        displayRpmRatio = displayRpmRatio + (cachedRpmRatio - displayRpmRatio) * fRpm
        displayThrottle = displayThrottle + (cachedThrottle - displayThrottle) * fTB
        displayBrake    = displayBrake    + (cachedBrake    - displayBrake)    * fTB
        if gearShiftShake > 0 then
            -- Linear decay: diperlambat 2.4 → 1.2/detik biar animasi lebih panjang & natural
            gearShiftShake = gearShiftShake - dt * 1.2
            if gearShiftShake < 0 then gearShiftShake = 0 end
        end

        local colors = getColors(fadeAlpha * (config.opacity or 0.85))

        local io = imgui.GetIO()
        local screenW = io.DisplaySize.x
        local screenH = io.DisplaySize.y

        -- Update DPI dari display size (Mode B)
        DPI = calcAutoScale(screenW, screenH)

        local posX = config.posX
        local posY = config.posY
        if posX == nil or posY == nil then
            posX, posY = getDefaultPos(screenW, screenH)
        end
        -- NOTE: posisi tetap bebas diatur via config (X/Y).
        -- Kalau mau paksa selalu on-screen, baru clampHudPos dipakai.

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
            imgui.Separator()
            imgui.Text("Native RPM: %.4f", nativeRpm)
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

        -- Update DPI juga di config window supaya slider sesuai
        DPI = calcAutoScale(screenW, screenH)

        local winW = 340
        local winH = 520

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

            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.67, 1.0), "VEHICLE HUD")
            imgui.SameLine()
            imgui.TextDisabled("v2.0 SA-Style")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

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

            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "UNIT")
            imgui.Spacing()

            local unitBtnWidth = (imgui.GetContentRegionAvail().x - 8) / 2

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

            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "POSITION")
            imgui.Spacing()

            local curPosX = config.posX
            local curPosY = config.posY
            if curPosX == nil or curPosY == nil then
                curPosX, curPosY = getDefaultPos(screenW, screenH)
            end
            -- Jangan di-clamp, biar user bebas set X/Y (termasuk kalau mau sebagian keluar layar)

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
        showConfigWindow = not showConfigWindow
        return
    end

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
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("vhud", handleCommand)
    sampAddChatMessage("{00FFAA}[VehicleHUD]{FFFFFF} v2.1 Loaded with Developer Mode! Use /vhud to open config", 0xFFFFFF)

    while true do
        wait(0)
        frameCounter = frameCounter + 1

        updateStateMachine()

        -- Jangan update data saat lagi fade-out (player sudah turun).
        -- Kalau dipaksa update, handle kendaraan bisa 0/invalid dan bikin NaN lagi.
        if inVehicle and frameCounter % 3 == 0 then
            updateVehicleData()
        end
    end
end
