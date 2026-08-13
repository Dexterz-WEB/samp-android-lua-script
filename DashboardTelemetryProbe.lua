-- ============================================================================
-- DASHBOARD TELEMETRY PROBE
-- GTA SA Android / MonetLoader
--
-- Purpose:
--   Verify raw automobile telemetry before connecting it to RacingDashboardMockup.
--
-- Scope:
--   - No dashboard rendering.
--   - No hard-coded memory offsets.
--   - No fuel implementation.
--   - No widget press-state API.
-- ============================================================================

script_name("DashboardTelemetryProbe")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local ffi = require 'ffi'
local shared = require 'SAMemory.shared'

-- ============================================================================
-- SAFE STRUCTURE LOADING
-- ============================================================================
local cvVehicleReady = false
local cAutomobileReady = false
local structureError = ""

local function loadStructures()
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
    else
        structureError = ""
    end
end

loadStructures()

-- ============================================================================
-- PROBE STATE
-- ============================================================================
local showWindow = imgui.new.bool(true)
local sampReady = false
local lastRefresh = 0

local probe = {
    context = "Waiting for SA-MP...",
    vehicleHandle = nil,
    vehiclePointer = nil,
    modelId = nil,
    speedKmh = nil,
    health = nil,
    engineOn = nil,
    gasPedal = nil,
    brakePedal = nil,
    currentGear = nil,
    engineRevs = nil,
    state = {},
    error = {},
}

local function resetProbe(context)
    probe.context = context or "No automobile detected"
    probe.vehicleHandle = nil
    probe.vehiclePointer = nil
    probe.modelId = nil
    probe.speedKmh = nil
    probe.health = nil
    probe.engineOn = nil
    probe.gasPedal = nil
    probe.brakePedal = nil
    probe.currentGear = nil
    probe.engineRevs = nil
    probe.state = {}
    probe.error = {}
end

local function trimError(value)
    local text = tostring(value)
    if #text > 72 then
        return text:sub(1, 69) .. "..."
    end
    return text
end

local function readField(key, callback)
    local ok, value = pcall(callback)
    if ok then
        probe.state[key] = "OK"
        probe.error[key] = nil
        return value
    end

    probe.state[key] = "ERROR"
    probe.error[key] = trimError(value)
    return nil
end

local function runProbe()
    if not sampReady then
        resetProbe("Waiting for SA-MP...")
        return
    end

    if not cvVehicleReady then
        resetProbe("CVehicle structure unavailable")
        probe.error.structure = structureError
        return
    end

    local inCar = readField("inCar", function()
        return isCharInAnyCar(PLAYER_PED)
    end)

    if not inCar then
        resetProbe("Enter an automobile to begin testing")
        probe.state.inCar = "NO"
        return
    end

    local handle = readField("vehicleHandle", function()
        return storeCarCharIsInNoSave(PLAYER_PED)
    end)

    if type(handle) ~= "number" or handle <= 0 then
        resetProbe("Vehicle handle is invalid")
        probe.state.vehicleHandle = "ERROR"
        probe.error.vehicleHandle = "storeCarCharIsInNoSave returned no valid handle"
        return
    end

    probe.context = "Automobile detected: live raw values"
    probe.vehicleHandle = handle

    local exists = readField("vehicleExists", function()
        return doesVehicleExist(handle)
    end)
    if not exists then
        resetProbe("Vehicle no longer exists")
        probe.state.vehicleExists = "ERROR"
        probe.error.vehicleExists = "doesVehicleExist returned false"
        return
    end

    local carPtr = readField("vehiclePointer", function()
        return getCarPointer(handle)
    end)

    if type(carPtr) ~= "number" or carPtr == 0 then
        resetProbe("Vehicle pointer is invalid")
        probe.state.vehiclePointer = "ERROR"
        probe.error.vehiclePointer = "getCarPointer returned no valid pointer"
        return
    end

    probe.vehiclePointer = carPtr
    probe.modelId = readField("modelId", function()
        return getCarModel(handle)
    end)
    probe.speedKmh = readField("speedKmh", function()
        return getCarSpeed(handle) * 3.6
    end)
    probe.health = readField("health", function()
        return getCarHealth(handle)
    end)
    probe.engineOn = readField("engineOn", function()
        return isCarEngineOn(handle)
    end)

    local vehicleData = readField("cvVehicleCast", function()
        return ffi.cast('struct CVehicle*', carPtr)
    end)

    if vehicleData == nil then
        probe.context = "CVehicle cast failed"
        return
    end

    probe.gasPedal = readField("gasPedal", function()
        return tonumber(vehicleData.fGasPedal)
    end)
    probe.brakePedal = readField("brakePedal", function()
        return tonumber(vehicleData.fBreakPedal)
    end)
    probe.currentGear = readField("currentGear", function()
        return tonumber(vehicleData.nCurrentGear)
    end)

    -- Candidate only: this is a named SAMemory CAutomobile field, but its
    -- runtime behavior/range must be confirmed on the target device.
    if cAutomobileReady then
        local automobileData = readField("cAutomobileCast", function()
            return ffi.cast('struct CAutomobile*', carPtr)
        end)

        if automobileData ~= nil then
            probe.engineRevs = readField("engineRevs", function()
                return tonumber(automobileData.field_804)
            end)
        end
    else
        probe.state.engineRevs = "UNAVAILABLE"
        probe.error.engineRevs = "CAutomobile structure could not be loaded"
    end
end

-- ============================================================================
-- UI HELPERS
-- ============================================================================
local function statusColor(status)
    if status == "OK" then
        return imgui.ImVec4(0.20, 0.95, 0.45, 1.0)
    elseif status == "NO" or status == "UNAVAILABLE" then
        return imgui.ImVec4(1.0, 0.75, 0.20, 1.0)
    end
    return imgui.ImVec4(1.0, 0.28, 0.25, 1.0)
end

local function displayValue(value, decimals)
    if value == nil then return "-" end
    if type(value) == "number" then
        return string.format("%." .. tostring(decimals or 3) .. "f", value)
    end
    return tostring(value)
end

local function drawRow(label, key, value, decimals)
    local status = probe.state[key] or "-"

    imgui.Text(label)
    imgui.SameLine(185)
    imgui.Text(displayValue(value, decimals))
    imgui.SameLine(320)
    imgui.TextColored(statusColor(status), status)

    if probe.error[key] then
        imgui.TextColored(imgui.ImVec4(1.0, 0.35, 0.30, 1.0), "  " .. probe.error[key])
    end
end

-- ============================================================================
-- PROBE WINDOW
-- ============================================================================
imgui.OnFrame(
    function() return showWindow[0] end,
    function(self)
        self.HideCursor = false

        imgui.SetNextWindowSize(imgui.ImVec2(520, 520), imgui.Cond.FirstUseEver)
        imgui.Begin("Dashboard Telemetry Probe", showWindow)

        imgui.TextColored(imgui.ImVec4(0.25, 0.80, 1.0, 1.0), "STATIC DATA-SOURCE TEST")
        imgui.TextWrapped("This script only reads and displays raw values. It does not modify the vehicle or RacingDashboardMockup.")
        imgui.Separator()

        imgui.Text("Context: " .. probe.context)
        if structureError ~= "" then
            imgui.TextColored(imgui.ImVec4(1.0, 0.35, 0.30, 1.0), structureError)
        end
        imgui.Separator()

        if imgui.CollapsingHeader("Vehicle / Opcode Data", imgui.TreeNodeFlags.DefaultOpen) then
            drawRow("Vehicle handle", "vehicleHandle", probe.vehicleHandle, 0)
            drawRow("Vehicle pointer", "vehiclePointer", probe.vehiclePointer, 0)
            drawRow("Model ID", "modelId", probe.modelId, 0)
            drawRow("Speed (km/h)", "speedKmh", probe.speedKmh, 3)
            drawRow("Health", "health", probe.health, 3)
            drawRow("Engine on", "engineOn", probe.engineOn, 0)
        end

        if imgui.CollapsingHeader("CVehicle Raw Fields", imgui.TreeNodeFlags.DefaultOpen) then
            drawRow("fGasPedal", "gasPedal", probe.gasPedal, 6)
            drawRow("fBreakPedal", "brakePedal", probe.brakePedal, 6)
            drawRow("nCurrentGear", "currentGear", probe.currentGear, 0)
        end

        if imgui.CollapsingHeader("CAutomobile Candidate", imgui.TreeNodeFlags.DefaultOpen) then
            drawRow("field_804 (m_fEngineRevs)", "engineRevs", probe.engineRevs, 6)
            imgui.TextWrapped("Expected test: compare this raw value while idle, accelerating, braking, reversing, and shifting. Do not treat it as dashboard RPM until its behavior is confirmed.")
        end

        if imgui.CollapsingHeader("Excluded / Not Available") then
            imgui.TextDisabled("Fuel: no generic fuel-level source was found in the audited structures.")
            imgui.TextDisabled("Widget press state: IDs exist, but a press-state API was not verified.")
            imgui.TextDisabled("Hard-coded pointer offsets are intentionally not used.")
        end

        imgui.Separator()
        imgui.TextDisabled("Command: /tdprobe toggles this draggable window.")
        imgui.End()
    end
)

-- ============================================================================
-- ENTRY POINT
-- ============================================================================
function main()
    while not isSampAvailable() do
        wait(100)
    end

    sampReady = true
    sampRegisterChatCommand("tdprobe", function()
        showWindow[0] = not showWindow[0]
    end)

    sampAddChatMessage("{33CCFF}[Telemetry Probe]{FFFFFF} Loaded. Enter an automobile, then use /tdprobe.", -1)

    while true do
        wait(100)
        runProbe()
    end
end
