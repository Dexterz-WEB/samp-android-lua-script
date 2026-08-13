-- ============================================================================
-- RACING DASH ALPHA
-- GTA SA Android / MonetLoader
--
-- Uses only automobile telemetry verified by DashboardTelemetryProbe.
-- Fuel is intentionally omitted because no generic native fuel level is proven.
-- ============================================================================

script_name("RacingDash")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local ffi = require 'ffi'
local shared = require 'SAMemory.shared'

-- ============================================================================
-- SAFE SAMEMORY STRUCTURE LOADING
-- ============================================================================
local cvVehicleReady = false
local cAutomobileReady = false
local structureError = ""

do
    local okVehicle, errVehicle = pcall(function()
        shared.require 'CVehicle'
    end)
    cvVehicleReady = okVehicle

    local okAutomobile, errAutomobile = pcall(function()
        shared.require 'CAutomobile'
    end)
    cAutomobileReady = okAutomobile

    if not okVehicle then
        structureError = "CVehicle: " .. tostring(errVehicle)
    elseif not okAutomobile then
        structureError = "CAutomobile: " .. tostring(errAutomobile)
    end
end

-- ============================================================================
-- LIVE ALPHA TELEMETRY
-- Gear is rendered directly from native nCurrentGear; no speed estimation.
-- field_804 remains visible as raw data in /rddebug for final RPM calibration.
-- ============================================================================
local live = {
    visible = false,
    vehicleHandle = 0,
    vehiclePointer = 0,
    speedKmh = 0.0,
    throttle = 0.0,
    brake = 0.0,
    gear = 0,
    health = 0.0,
    engineOn = false,
    engineRevsRaw = 0.0,
    rpmRatio = 0.0,
    error = "",
}

local showDebugWindow = imgui.new.bool(false)

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function safeNumber(callback, fallback)
    local ok, value = pcall(callback)
    local number = ok and tonumber(value) or nil
    if number ~= nil and number == number and number ~= math.huge and number ~= -math.huge then
        return number
    end
    return fallback
end

local function updateLiveTelemetry()
    live.visible = false
    live.error = ""

    if not cvVehicleReady then
        live.error = structureError ~= "" and structureError or "CVehicle unavailable"
        return
    end

    local inCar = false
    local okInCar, resultInCar = pcall(isCharInAnyCar, PLAYER_PED)
    if okInCar and resultInCar then inCar = true end
    if not inCar then return end

    local vehicleHandle = safeNumber(function()
        return storeCarCharIsInNoSave(PLAYER_PED)
    end, 0)
    if vehicleHandle <= 0 then
        live.error = "Vehicle handle unavailable"
        return
    end

    local vehiclePointer = safeNumber(function()
        return getCarPointer(vehicleHandle)
    end, 0)
    if vehiclePointer <= 0 then
        live.error = "Vehicle pointer unavailable"
        return
    end

    local vehicleDataOk, vehicleData = pcall(function()
        return ffi.cast('struct CVehicle*', vehiclePointer)
    end)
    if not vehicleDataOk or vehicleData == nil then
        live.error = "CVehicle cast failed"
        return
    end

    live.vehicleHandle = vehicleHandle
    live.vehiclePointer = vehiclePointer
    live.speedKmh = math.max(0.0, safeNumber(function()
        return getCarSpeed(vehicleHandle) * 3.6
    end, 0.0))
    live.health = safeNumber(function()
        return getCarHealth(vehicleHandle)
    end, 0.0)
    live.engineOn = safeNumber(function()
        return isCarEngineOn(vehicleHandle) and 1 or 0
    end, 0) == 1
    live.throttle = clamp(safeNumber(function()
        return tonumber(vehicleData.fGasPedal)
    end, 0.0), 0.0, 1.0)
    live.brake = clamp(safeNumber(function()
        return tonumber(vehicleData.fBreakPedal)
    end, 0.0), 0.0, 1.0)
    live.gear = math.floor(safeNumber(function()
        return tonumber(vehicleData.nCurrentGear)
    end, 0))

    live.engineRevsRaw = 0.0
    if cAutomobileReady then
        local automobileDataOk, automobileData = pcall(function()
            return ffi.cast('struct CAutomobile*', vehiclePointer)
        end)
        if automobileDataOk and automobileData ~= nil then
            live.engineRevsRaw = safeNumber(function()
                return tonumber(automobileData.field_804)
            end, 0.0)
        end
    end

    -- Alpha calibration: fEngineRevs is clamped as a 0.0-1.0 tachometer ratio.
    live.rpmRatio = clamp(live.engineRevsRaw, 0.0, 1.0)
    live.visible = true
end

-- ============================================================================
-- DRAW HELPERS
-- ============================================================================
local function color(r, g, b, a)
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a))
end

local function drawArc(drawList, cx, cy, radius, startAngle, endAngle, arcColor, thickness, segments)
    segments = segments or 64
    local sweep = endAngle - startAngle
    local step = sweep / segments

    for index = 0, segments - 1 do
        local angleA = startAngle + step * index
        local angleB = angleA + step
        drawList:AddLine(
            imgui.ImVec2(cx + math.cos(angleA) * radius, cy + math.sin(angleA) * radius),
            imgui.ImVec2(cx + math.cos(angleB) * radius, cy + math.sin(angleB) * radius),
            arcColor,
            thickness
        )
    end
end

local function drawSegmentedArc(drawList, cx, cy, radius, startAngle, endAngle, count, activeCount, normalColor, activeColor, redZoneColor, redZoneStart, thickness)
    local sweep = endAngle - startAngle
    local segmentSweep = sweep / count
    local gap = math.rad(1.8)

    for index = 1, count do
        local segmentStart = startAngle + segmentSweep * (index - 1) + gap * 0.5
        local segmentEnd = startAngle + segmentSweep * index - gap * 0.5
        local segmentColor = normalColor

        if index <= activeCount then
            if index >= redZoneStart then
                segmentColor = redZoneColor
            else
                segmentColor = activeColor
            end
        elseif index >= redZoneStart then
            segmentColor = color(0.34, 0.05, 0.05, 0.75)
        end

        drawArc(drawList, cx, cy, radius, segmentStart, segmentEnd, segmentColor, thickness, 5)
    end
end

-- Draw-list AddText does not apply io.FontGlobalScale reliably on MonetLoader.
-- Use ImDrawList:AddTextFontPtr so every label receives an explicit pixel size.
local function drawTextAt(drawList, text, x, y, textColor, fontSize)
    local font = imgui.GetFont()
    drawList:AddTextFontPtr(font, fontSize, imgui.ImVec2(x, y), textColor, text, nil, 0, nil)
end

local function drawCenteredText(drawList, text, centerX, y, textColor, fontSize)
    local font = imgui.GetFont()
    local size = font:CalcTextSizeA(fontSize, 10000, 0, text)
    drawTextAt(drawList, text, centerX - size.x * 0.5, y, textColor, fontSize)
end

local function drawOutlinedCenteredText(drawList, text, centerX, y, textColor, fontSize, outlineColor)
    local font = imgui.GetFont()
    local size = font:CalcTextSizeA(fontSize, 10000, 0, text)
    local x = centerX - size.x * 0.5
    local offset = math.max(1.0, fontSize * 0.055)

    drawTextAt(drawList, text, x - offset, y, outlineColor, fontSize)
    drawTextAt(drawList, text, x + offset, y, outlineColor, fontSize)
    drawTextAt(drawList, text, x, y - offset, outlineColor, fontSize)
    drawTextAt(drawList, text, x, y + offset, outlineColor, fontSize)
    drawTextAt(drawList, text, x, y, textColor, fontSize)
end

local function drawNeedle(drawList, cx, cy, angle, length, needleColor, hubColor, thickness)
    local endX = cx + math.cos(angle) * length
    local endY = cy + math.sin(angle) * length

    drawList:AddLine(imgui.ImVec2(cx, cy), imgui.ImVec2(endX, endY), needleColor, thickness)
    drawList:AddCircleFilled(imgui.ImVec2(cx, cy), thickness * 1.8, hubColor, 18)
    drawList:AddCircle(imgui.ImVec2(cx, cy), thickness * 1.8, color(0.03, 0.03, 0.04, 1.0), 18, 1.0)
end

local function drawGaugeTicks(drawList, cx, cy, innerRadius, outerRadius, startAngle, endAngle, count, majorEvery, normalColor, redColor, redStart, scale)
    for index = 0, count do
        local ratio = index / count
        local angle = startAngle + (endAngle - startAngle) * ratio
        local isMajor = (index % majorEvery == 0)
        local currentInner = isMajor and innerRadius or (innerRadius + 8 * scale)
        local thickness = isMajor and 2.0 * scale or 1.0 * scale
        local tickColor = ratio >= redStart and redColor or normalColor

        drawList:AddLine(
            imgui.ImVec2(cx + math.cos(angle) * currentInner, cy + math.sin(angle) * currentInner),
            imgui.ImVec2(cx + math.cos(angle) * outerRadius, cy + math.sin(angle) * outerRadius),
            tickColor,
            thickness
        )
    end
end

local function drawSpeedometer(drawList, cx, cy, scale, value)
    local startAngle = math.rad(135)
    local endAngle = math.rad(405)
    local valueRatio = clamp(value / 280.0, 0.0, 1.0)
    local outerRadius = 110 * scale
    local white = color(0.94, 0.94, 0.94, 1.0)
    local muted = color(0.48, 0.50, 0.54, 1.0)
    local black = color(0.02, 0.02, 0.025, 0.96)
    local dial = color(0.06, 0.07, 0.085, 0.94)
    local cyan = color(0.16, 0.72, 1.0, 1.0)
    local red = color(0.95, 0.12, 0.13, 1.0)

    drawList:AddCircleFilled(imgui.ImVec2(cx, cy), outerRadius, black, 72)
    drawList:AddCircle(imgui.ImVec2(cx, cy), outerRadius - 3 * scale, color(0.78, 0.80, 0.86, 0.9), 72, 2.0 * scale)
    drawList:AddCircleFilled(imgui.ImVec2(cx, cy), outerRadius - 8 * scale, dial, 72)

    drawSegmentedArc(drawList, cx, cy, outerRadius - 15 * scale, startAngle, endAngle, 34, math.floor(valueRatio * 34 + 0.5), muted, cyan, red, 31, 5.0 * scale)
    drawGaugeTicks(drawList, cx, cy, 74 * scale, 88 * scale, startAngle, endAngle, 28, 4, white, red, 0.86, scale)

    for speed = 0, 280, 40 do
        local ratio = speed / 280.0
        local angle = startAngle + (endAngle - startAngle) * ratio
        -- Keep scale labels outside the fuel sub-gauge and below the tick ring.
        local labelRadius = 69 * scale
        local labelX = cx + math.cos(angle) * labelRadius
        local labelY = cy + math.sin(angle) * labelRadius - 4 * scale
        drawCenteredText(drawList, tostring(speed), labelX, labelY, white, 17 * scale)
    end

    local needleAngle = startAngle + (endAngle - startAngle) * valueRatio
    drawNeedle(drawList, cx, cy, needleAngle, 70 * scale, white, red, 2.5 * scale)

    -- Fuel is intentionally not faked in alpha: no verified generic GTA fuel field.
    local fuelStart = math.rad(150)
    local fuelEnd = math.rad(390)
    local fuelCy = cy + 23 * scale
    drawArc(drawList, cx, fuelCy, 25 * scale, fuelStart, fuelEnd, muted, 2.5 * scale, 24)
    drawCenteredText(drawList, "FUEL", cx, cy + 12 * scale, white, 14 * scale)
    drawCenteredText(drawList, "N/A", cx, cy + 29 * scale, muted, 13 * scale)
end

local function drawTachometer(drawList, cx, cy, scale, rpmX1000)
    local startAngle = math.rad(135)
    local endAngle = math.rad(405)
    local valueRatio = clamp(rpmX1000 / 8.0, 0.0, 1.0)
    local outerRadius = 110 * scale
    local white = color(0.94, 0.94, 0.94, 1.0)
    local muted = color(0.48, 0.50, 0.54, 1.0)
    local black = color(0.02, 0.02, 0.025, 0.96)
    local dial = color(0.06, 0.07, 0.085, 0.94)
    local orange = color(1.0, 0.62, 0.08, 1.0)
    local red = color(0.95, 0.12, 0.13, 1.0)

    drawList:AddCircleFilled(imgui.ImVec2(cx, cy), outerRadius, black, 72)
    drawList:AddCircle(imgui.ImVec2(cx, cy), outerRadius - 3 * scale, color(0.78, 0.80, 0.86, 0.9), 72, 2.0 * scale)
    drawList:AddCircleFilled(imgui.ImVec2(cx, cy), outerRadius - 8 * scale, dial, 72)

    drawSegmentedArc(drawList, cx, cy, outerRadius - 15 * scale, startAngle, endAngle, 32, math.floor(valueRatio * 32 + 0.5), muted, white, red, 27, 5.0 * scale)
    drawGaugeTicks(drawList, cx, cy, 74 * scale, 88 * scale, startAngle, endAngle, 32, 4, white, red, 0.80, scale)

    for rpm = 0, 8 do
        local ratio = rpm / 8.0
        local angle = startAngle + (endAngle - startAngle) * ratio
        local labelRadius = 69 * scale
        local labelX = cx + math.cos(angle) * labelRadius
        local labelY = cy + math.sin(angle) * labelRadius - 4 * scale
        local labelColor = rpm >= 7 and red or white
        drawCenteredText(drawList, tostring(rpm), labelX, labelY, labelColor, 17 * scale)
    end

    local needleAngle = startAngle + (endAngle - startAngle) * valueRatio
    drawNeedle(drawList, cx, cy, needleAngle, 70 * scale, orange, red, 2.5 * scale)
    drawCenteredText(drawList, "x1000 rpm", cx, cy + 34 * scale, white, 14 * scale)
end

local function drawTelemetryBar(drawList, x, y, width, height, label, ratio, backgroundColor, fillColor, textColor, scale)
    local border = color(0.02, 0.02, 0.025, 0.95)
    local ratioClamped = clamp(ratio, 0.0, 1.0)

    local barStartX = x + 96 * scale
    drawOutlinedCenteredText(drawList, label, x + 44 * scale, y - 3 * scale, textColor, 14 * scale, border)
    drawList:AddRectFilled(imgui.ImVec2(barStartX, y), imgui.ImVec2(x + width, y + height), backgroundColor, 2.0 * scale)
    drawList:AddRect(imgui.ImVec2(barStartX, y), imgui.ImVec2(x + width, y + height), border, 2.0 * scale, 0, 1.0 * scale)

    local fillEnd = barStartX + (x + width - barStartX) * ratioClamped
    if fillEnd > barStartX then
        drawList:AddRectFilled(imgui.ImVec2(barStartX, y), imgui.ImVec2(fillEnd, y + height), fillColor, 2.0 * scale)
    end
end

local function renderDashboard()
    local drawList = imgui.GetBackgroundDrawList()
    local io = imgui.GetIO()
    local screenW = io.DisplaySize.x
    local screenH = io.DisplaySize.y

    if screenW <= 0 or screenH <= 0 then return end

    local scale = math.min(screenW / 1920.0, screenH / 1080.0)
    if scale < 0.55 then scale = 0.55 end
    if scale > 1.35 then scale = 1.35 end

    local dashboardW = 930 * scale
    local dashboardH = 292 * scale
    local baseX = (screenW - dashboardW) * 0.5
    local baseY = screenH - dashboardH - 22 * scale

    local black = color(0.02, 0.02, 0.025, 0.84)
    local panel = color(0.08, 0.09, 0.11, 0.94)
    local panelEdge = color(0.48, 0.50, 0.56, 0.88)
    local white = color(0.94, 0.94, 0.94, 1.0)
    local muted = color(0.55, 0.57, 0.63, 1.0)
    local blue = color(0.15, 0.65, 1.0, 1.0)
    local green = color(0.15, 0.95, 0.48, 1.0)
    local red = color(0.95, 0.12, 0.13, 1.0)

    local speedCx = baseX + 145 * scale
    local tachCx = baseX + 785 * scale
    local gaugeCy = baseY + 140 * scale

    -- Central instrument body
    local centerX = baseX + 306 * scale
    local centerY = baseY + 58 * scale
    local centerW = 318 * scale
    local centerH = 210 * scale
    drawList:AddRectFilled(imgui.ImVec2(centerX, centerY), imgui.ImVec2(centerX + centerW, centerY + centerH), black, 12 * scale)
    drawList:AddRectFilled(imgui.ImVec2(centerX + 3 * scale, centerY + 3 * scale), imgui.ImVec2(centerX + centerW - 3 * scale, centerY + centerH - 3 * scale), panel, 10 * scale)
    drawList:AddRect(imgui.ImVec2(centerX, centerY), imgui.ImVec2(centerX + centerW, centerY + centerH), panelEdge, 12 * scale, 0, 1.5 * scale)

    drawSpeedometer(drawList, speedCx, gaugeCy, scale, live.speedKmh)
    drawTachometer(drawList, tachCx, gaugeCy, scale, live.rpmRatio * 8.0)

    -- Center display
    drawCenteredText(drawList, "RACING DASH • ALPHA", centerX + centerW * 0.5, centerY + 15 * scale, muted, 16 * scale)
    drawOutlinedCenteredText(drawList, tostring(math.floor(live.speedKmh + 0.5)), centerX + 110 * scale, centerY + 45 * scale, white, 52 * scale, black)
    drawCenteredText(drawList, "km/h", centerX + 110 * scale, centerY + 104 * scale, muted, 16 * scale)

    local gearBoxX = centerX + 212 * scale
    local gearBoxY = centerY + 42 * scale
    local gearBoxW = 76 * scale
    local gearBoxH = 86 * scale
    drawList:AddRectFilled(imgui.ImVec2(gearBoxX, gearBoxY), imgui.ImVec2(gearBoxX + gearBoxW, gearBoxY + gearBoxH), color(0.025, 0.03, 0.04, 1.0), 7 * scale)
    drawList:AddRect(imgui.ImVec2(gearBoxX, gearBoxY), imgui.ImVec2(gearBoxX + gearBoxW, gearBoxY + gearBoxH), blue, 7 * scale, 0, 1.5 * scale)
    -- Gear is rendered from the native nCurrentGear value without speed estimation.
    drawOutlinedCenteredText(drawList, tostring(live.gear), gearBoxX + gearBoxW * 0.5, gearBoxY + 7 * scale, white, 48 * scale, black)
    drawCenteredText(drawList, "GEAR", gearBoxX + gearBoxW * 0.5, gearBoxY + 65 * scale, muted, 14 * scale)

    drawTelemetryBar(drawList, centerX + 18 * scale, centerY + 150 * scale, centerW - 36 * scale, 10 * scale, "THROTTLE", live.throttle, color(0.04, 0.12, 0.22, 1.0), green, white, scale)
    drawTelemetryBar(drawList, centerX + 18 * scale, centerY + 178 * scale, centerW - 36 * scale, 10 * scale, "BRAKE", live.brake, color(0.22, 0.04, 0.04, 1.0), red, white, scale)
end

-- ============================================================================
-- LIVE IMGUI RENDER LOOP
-- ============================================================================
imgui.OnFrame(
    function() return live.visible end,
    function(self)
        self.HideCursor = true
        renderDashboard()
    end
)

-- Optional alpha diagnostic: confirms the values currently driving the dashboard.
imgui.OnFrame(
    function() return showDebugWindow[0] end,
    function(self)
        self.HideCursor = false
        imgui.SetNextWindowSize(imgui.ImVec2(330, 285), imgui.Cond.FirstUseEver)
        imgui.Begin("RacingDash Alpha Debug", showDebugWindow)
        imgui.Text("Status: " .. (live.visible and "LIVE" or "WAITING"))
        if live.error ~= "" then
            imgui.TextColored(imgui.ImVec4(1.0, 0.35, 0.30, 1.0), live.error)
        end
        imgui.Separator()
        imgui.Text(string.format("Speed: %.3f km/h", live.speedKmh))
        imgui.Text("Native gear: " .. tostring(live.gear))
        imgui.Text(string.format("Throttle: %.6f", live.throttle))
        imgui.Text(string.format("Brake: %.6f", live.brake))
        imgui.Text(string.format("Health: %.3f", live.health))
        imgui.Text("Engine: " .. (live.engineOn and "ON" or "OFF"))
        imgui.Text(string.format("field_804 raw: %.6f", live.engineRevsRaw))
        imgui.Text(string.format("RPM gauge ratio: %.6f", live.rpmRatio))
        imgui.Separator()
        imgui.TextDisabled("/rddebug toggles this window")
        imgui.End()
    end
)

function main()
    while not isSampAvailable() do
        wait(100)
    end

    sampRegisterChatCommand("rddebug", function()
        showDebugWindow[0] = not showDebugWindow[0]
    end)
    sampAddChatMessage("{33CCFF}[RacingDash]{FFFFFF} Alpha loaded. /rddebug for raw telemetry.", -1)

    while true do
        wait(0)
        updateLiveTelemetry()
    end
end

-- ============================================================================
-- END OF RACING DASH ALPHA
-- ============================================================================
