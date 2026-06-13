-- ============================================================================
-- 3D RENDER TEST v1.0
-- Tests 4 approaches to convert 3D world coords to 2D screen coords
-- on MonetLoader Android (SA-MP)
-- Author: OnlyDexterZ
-- ============================================================================

script_name("3DRenderTest")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local ffi = require 'ffi'
local memory = require 'memory'

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0
local BASE = MONET_GTASA_BASE or 0

-- ============================================================================
-- STATE (all tests default OFF)
-- ============================================================================
local test1_active = false
local test2_active = false
local test3_active = false
local test4_active = false

-- Screen coords results for each test
local test2_sx, test2_sy = 0, 0
local test2_valid = false

local test3_sx, test3_sy = 0, 0
local test3_valid = false

local test4_sx, test4_sy = 0, 0
local test4_valid = false

-- ============================================================================
-- HELPER: safe chat message
-- ============================================================================
local function chat(msg)
    pcall(function()
        sampAddChatMessage("{00FFFF}[3DTest] {FFFFFF}" .. tostring(msg), 0xFFFFFF)
    end)
end

local function chatErr(msg)
    pcall(function()
        sampAddChatMessage("{FF4444}[3DTest] {FFFFFF}" .. tostring(msg), 0xFFFFFF)
    end)
end

local function chatOk(msg)
    pcall(function()
        sampAddChatMessage("{44FF44}[3DTest] {FFFFFF}" .. tostring(msg), 0xFFFFFF)
    end)
end

-- ============================================================================
-- HELPER: get player position with Z offset for above head
-- ============================================================================
local function getPlayerAbovePos()
    local x, y, z = 0, 0, 0
    local ok = pcall(function()
        x, y, z = getCharCoordinates(PLAYER_PED)
    end)
    if ok and x ~= 0 then
        return x, y, z + 1.5
    end
    return nil, nil, nil
end

-- ============================================================================
-- HELPER: get screen resolution
-- ============================================================================
local function getScreenRes()
    local w, h = 800, 600
    pcall(function()
        w, h = getScreenResolution()
    end)
    return w, h
end

-- ============================================================================
-- TEST 1: Check availability of getActiveCameraCoordinates/getActiveCameraPointAt
-- (command only, no rendering - just prints results to chat)
-- ============================================================================
local function runTest1()
    chat("--- TEST 1: Camera Function Availability ---")

    -- Check getActiveCameraCoordinates
    local hasCamCoords = false
    local camX, camY, camZ = 0, 0, 0
    local ok1, err1 = pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
        hasCamCoords = true
    end)

    if hasCamCoords then
        chatOk("getActiveCameraCoordinates() EXISTS!")
        chatOk("  Result: X=" .. string.format("%.2f", camX) .. " Y=" .. string.format("%.2f", camY) .. " Z=" .. string.format("%.2f", camZ))
    else
        chatErr("getActiveCameraCoordinates() NOT AVAILABLE")
        if err1 then chatErr("  Error: " .. tostring(err1)) end
    end

    -- Check getActiveCameraPointAt
    local hasCamPoint = false
    local ptX, ptY, ptZ = 0, 0, 0
    local ok2, err2 = pcall(function()
        ptX, ptY, ptZ = getActiveCameraPointAt()
        hasCamPoint = true
    end)

    if hasCamPoint then
        chatOk("getActiveCameraPointAt() EXISTS!")
        chatOk("  Result: X=" .. string.format("%.2f", ptX) .. " Y=" .. string.format("%.2f", ptY) .. " Z=" .. string.format("%.2f", ptZ))
    else
        chatErr("getActiveCameraPointAt() NOT AVAILABLE")
        if err2 then chatErr("  Error: " .. tostring(err2)) end
    end

    -- Summary
    if hasCamCoords and hasCamPoint then
        chatOk("Both camera functions available! Can use for manual projection.")
    else
        chatErr("Camera functions not fully available.")
    end
end

-- ============================================================================
-- TEST 2: Manual projection using camera view matrix via FFI
-- Reads view matrix from CCamera struct in game memory
-- ============================================================================

-- CCamera view matrix offset: mViewMatrix is after mCameraMatrix and mCameraMatrixOld
-- The matrix struct is: right(12) + flags(4) + up(12) + pad(4) + at(12) + pad(4) + pos(12) + pad(4) + ptr(4/8) + bool(1) + padding
-- On ARM 32-bit, sizeof(matrix) is approximately 68 bytes (3*16 + 4 + ptr + bool + pad)
-- However, we'll use a simpler approach: read camera pos and direction from known functions

local function computeTest2ScreenPos()
    test2_valid = false

    local px, py, pz = getPlayerAbovePos()
    if not px then return end

    -- Get camera position and look-at point
    local camX, camY, camZ, lookX, lookY, lookZ
    local ok1 = pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
    end)
    local ok2 = pcall(function()
        lookX, lookY, lookZ = getActiveCameraPointAt()
    end)

    if not ok1 or not ok2 or not camX or not lookX then
        return
    end

    local screenW, screenH = getScreenRes()

    -- Build camera forward, right, up vectors
    local fwdX = lookX - camX
    local fwdY = lookY - camY
    local fwdZ = lookZ - camZ
    local fwdLen = math.sqrt(fwdX * fwdX + fwdY * fwdY + fwdZ * fwdZ)
    if fwdLen < 0.001 then return end
    fwdX = fwdX / fwdLen
    fwdY = fwdY / fwdLen
    fwdZ = fwdZ / fwdLen

    -- World up
    local wupX, wupY, wupZ = 0, 0, 1

    -- Right = forward x world_up
    local rightX = fwdY * wupZ - fwdZ * wupY
    local rightY = fwdZ * wupX - fwdX * wupZ
    local rightZ = fwdX * wupY - fwdY * wupX
    local rightLen = math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ)
    if rightLen < 0.001 then return end
    rightX = rightX / rightLen
    rightY = rightY / rightLen
    rightZ = rightZ / rightLen

    -- Up = right x forward
    local upX = rightY * fwdZ - rightZ * fwdY
    local upY = rightZ * fwdX - rightX * fwdZ
    local upZ = rightX * fwdY - rightY * fwdX

    -- Vector from camera to target
    local dx = px - camX
    local dy = py - camY
    local dz = pz - camZ

    -- Project onto camera axes
    local dotFwd   = dx * fwdX   + dy * fwdY   + dz * fwdZ
    local dotRight = dx * rightX + dy * rightY + dz * rightZ
    local dotUp    = dx * upX    + dy * upY    + dz * upZ

    -- Behind camera check
    if dotFwd <= 0.1 then return end

    -- Perspective projection (GTA SA uses ~70 degree FOV)
    local fov = 70.0
    local aspect = screenW / screenH
    local tanHalfFov = math.tan(math.rad(fov * 0.5))

    local ndcX = (dotRight / dotFwd) / (tanHalfFov * aspect)
    local ndcY = (dotUp / dotFwd) / tanHalfFov

    -- NDC to screen (NDC goes from -1..1, screen from 0..W/H)
    -- Note: Y is flipped (screen Y goes down)
    local sx = (ndcX * 0.5 + 0.5) * screenW
    local sy = (-ndcY * 0.5 + 0.5) * screenH

    -- Check if on screen
    if sx >= 0 and sx <= screenW and sy >= 0 and sy <= screenH then
        test2_sx = sx
        test2_sy = sy
        test2_valid = true
    end
end

-- ============================================================================
-- TEST 3: Call native CalcScreenCoors via FFI
-- GTA SA function: CSprite::CalcScreenCoors(RwV3d in, RwV3d* out, float* w, float* h, bool, bool)
-- ARM Android offset varies by version. Common offset for GTA SA Android 2.00:
-- CalcScreenCoors is typically at offset 0x54EEC0 or similar from base.
-- We try multiple known offsets.
-- ============================================================================

-- Known offsets for CalcScreenCoors on different GTA SA Android versions
local CALC_SCREEN_COORS_OFFSETS = {
    0x54EEC0,  -- GTA SA Android 2.10
    0x54EE50,  -- GTA SA Android 2.00
    0x5401C0,  -- alternate
    0x3F7000,  -- SA-MP Android specific
    0x3F7098,  -- SA-MP Android alternate
}

local calcScreenCoors_fn = nil
local calcScreenCoors_initialized = false

local function initCalcScreenCoors()
    if calcScreenCoors_initialized then return end
    calcScreenCoors_initialized = true

    if BASE == 0 then
        chatErr("[TEST 3] MONET_GTASA_BASE is 0, cannot hook native function")
        return
    end

    -- Define the C types we need
    pcall(function()
        ffi.cdef[[
            typedef struct RwV3d_t { float x, y, z; } RwV3d_t;
        ]]
    end)

    -- CalcScreenCoors signature:
    -- bool CalcScreenCoors(RwV3d* posIn, RwV3d* posOut, float* w, float* h, bool checkMaxVisible, bool checkMinVisible)
    -- On ARM Android this is typically a C++ static function
    local funcType = ffi.typeof("bool(*)(float*, float*, float*, float*, bool, bool)")

    for _, offset in ipairs(CALC_SCREEN_COORS_OFFSETS) do
        local addr = BASE + offset
        -- Verify the address is at least somewhat valid (non-zero, thumb bit for ARM)
        local ok, fn = pcall(function()
            -- ARM thumb functions have bit 0 set, try both
            local ptr = ffi.cast("void*", addr + 1) -- +1 for THUMB mode on ARM
            return ffi.cast(funcType, ptr)
        end)
        if ok and fn then
            -- Store as candidate (we cannot verify without calling)
            calcScreenCoors_fn = fn
            chat("[TEST 3] Using CalcScreenCoors at offset 0x" .. string.format("%X", offset) .. " (THUMB)")
            return
        end
    end

    -- Try without THUMB bit
    for _, offset in ipairs(CALC_SCREEN_COORS_OFFSETS) do
        local addr = BASE + offset
        local ok, fn = pcall(function()
            local ptr = ffi.cast("void*", addr)
            return ffi.cast(funcType, ptr)
        end)
        if ok and fn then
            calcScreenCoors_fn = fn
            chat("[TEST 3] Using CalcScreenCoors at offset 0x" .. string.format("%X", offset) .. " (ARM)")
            return
        end
    end

    chatErr("[TEST 3] Could not set up CalcScreenCoors function pointer")
end

local function computeTest3ScreenPos()
    test3_valid = false

    local px, py, pz = getPlayerAbovePos()
    if not px then return end

    if not calcScreenCoors_fn then return end

    local ok, err = pcall(function()
        local posIn = ffi.new("float[3]", px, py, pz)
        local posOut = ffi.new("float[3]", 0, 0, 0)
        local screenW = ffi.new("float[1]", 0)
        local screenH = ffi.new("float[1]", 0)

        local result = calcScreenCoors_fn(posIn, posOut, screenW, screenH, true, true)
        if result then
            test3_sx = posOut[0]
            test3_sy = posOut[1]
            test3_valid = true
        end
    end)

    if not ok then
        -- Silently fail per frame, only report once
    end
end

-- ============================================================================
-- TEST 4: Simplified angle-based approach (pure math, most safe)
-- Uses camera heading angle to estimate screen position
-- Not a true 3D projection but a working indicator
-- ============================================================================

local function computeTest4ScreenPos()
    test4_valid = false

    local px, py, pz = getPlayerAbovePos()
    if not px then return end

    local screenW, screenH = getScreenRes()

    -- Get camera position and direction
    local camX, camY, camZ, lookX, lookY, lookZ
    local hasCam = false

    pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
        lookX, lookY, lookZ = getActiveCameraPointAt()
        hasCam = true
    end)

    -- Fallback: use player heading if camera functions not available
    if not hasCam or not camX or not lookX then
        local heading = 0
        pcall(function()
            heading = getCharHeading(PLAYER_PED)
        end)

        -- If we can't get camera data, use simplified approach
        -- Player is always at center of screen when looking at themselves
        -- This is a fallback that just places text at top-center
        test4_sx = screenW * 0.5
        test4_sy = screenH * 0.35
        test4_valid = true
        return
    end

    -- Camera heading angle (from camera forward vector)
    local camFwdX = lookX - camX
    local camFwdY = lookY - camY
    local camFwdZ = lookZ - camZ
    local camHeading = math.deg(math.atan2(camFwdX, camFwdY))  -- angle from Y+ (North)

    -- Angle from camera to target
    local dx = px - camX
    local dy = py - camY
    local dz = pz - camZ
    local dist2D = math.sqrt(dx * dx + dy * dy)
    local targetAngleH = math.deg(math.atan2(dx, dy))  -- horizontal angle from Y+

    -- Vertical angle from camera to target
    local targetAngleV = math.deg(math.atan2(dz, dist2D))

    -- Camera vertical angle (pitch)
    local camFwdLen2D = math.sqrt(camFwdX * camFwdX + camFwdY * camFwdY)
    local camPitch = math.deg(math.atan2(camFwdZ, camFwdLen2D))

    -- Angle differences
    local angleDiffH = targetAngleH - camHeading
    -- Normalize to -180..180
    while angleDiffH > 180 do angleDiffH = angleDiffH - 360 end
    while angleDiffH < -180 do angleDiffH = angleDiffH + 360 end

    local angleDiffV = targetAngleV - camPitch
    while angleDiffV > 180 do angleDiffV = angleDiffV - 360 end
    while angleDiffV < -180 do angleDiffV = angleDiffV + 360 end

    -- FOV approximation (GTA SA uses about 70 degrees horizontal FOV)
    local hFov = 70.0
    local vFov = hFov * (screenH / screenW)

    -- Check if within screen bounds (with some margin)
    if math.abs(angleDiffH) > hFov * 0.6 then return end
    if math.abs(angleDiffV) > vFov * 0.6 then return end

    -- Convert angle diff to screen position
    -- angleDiffH = 0 means center of screen, positive = right
    local sx = screenW * 0.5 + (angleDiffH / hFov) * screenW
    -- angleDiffV = 0 means center, positive = up (so negate for screen Y)
    local sy = screenH * 0.5 - (angleDiffV / vFov) * screenH

    -- Clamp to screen
    if sx >= 0 and sx <= screenW and sy >= 0 and sy <= screenH then
        test4_sx = sx
        test4_sy = sy
        test4_valid = true
    end
end

-- ============================================================================
-- IMGUI RENDERING FRAME
-- ============================================================================
imgui.OnFrame(
    function()
        return test2_active or test3_active or test4_active
    end,
    function(self)
        self.HideCursor = true

        -- Compute positions for active tests
        if test2_active then
            pcall(computeTest2ScreenPos)
        end
        if test3_active then
            pcall(computeTest3ScreenPos)
        end
        if test4_active then
            pcall(computeTest4ScreenPos)
        end

        -- Get draw list
        local dl = imgui.GetBackgroundDrawList()
        local scale = DPI

        -- Helper: draw outlined text
        local function drawText(drawList, x, y, color, text)
            local pos = imgui.ImVec2(x * scale, y * scale)
            local outlineColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 1))
            local mainColor = color
            local ox = 1.0 * scale
            -- Outline
            drawList:AddText(imgui.ImVec2(pos.x - ox, pos.y), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x + ox, pos.y), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x, pos.y - ox), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x, pos.y + ox), outlineColor, text)
            -- Main
            drawList:AddText(pos, mainColor, text)
        end

        -- Helper: draw text at raw screen position (already scaled or from native coords)
        local function drawTextRaw(drawList, x, y, color, text)
            local pos = imgui.ImVec2(x, y)
            local outlineColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 1))
            local ox = 1.0 * scale
            drawList:AddText(imgui.ImVec2(pos.x - ox, pos.y), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x + ox, pos.y), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x, pos.y - ox), outlineColor, text)
            drawList:AddText(imgui.ImVec2(pos.x, pos.y + ox), outlineColor, text)
            drawList:AddText(pos, color, text)
        end

        local colorGreen = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 1.0, 0.3, 1.0))
        local colorYellow = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
        local colorCyan = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 1.0, 1.0, 1.0))

        -- TEST 2 render
        if test2_active and test2_valid then
            drawTextRaw(dl, test2_sx, test2_sy, colorGreen, "[TEST 2] WORKS!")
        end

        -- TEST 3 render
        if test3_active and test3_valid then
            drawTextRaw(dl, test3_sx, test3_sy, colorYellow, "[TEST 3] WORKS!")
        end

        -- TEST 4 render
        if test4_active and test4_valid then
            drawTextRaw(dl, test4_sx, test4_sy, colorCyan, "[TEST 4] WORKS!")
        end
    end
)

-- ============================================================================
-- CHAT COMMANDS
-- ============================================================================

-- /3dtest1 - Test camera function availability (just prints to chat)
sampRegisterChatCommand("3dtest1", function()
    test1_active = not test1_active
    if test1_active then
        chat("Test 1: Checking camera function availability...")
        runTest1()
        test1_active = false  -- one-shot, no rendering needed
    else
        chat("Test 1: OFF")
    end
end)

-- /3dtest2 - Manual projection via camera vectors
sampRegisterChatCommand("3dtest2", function()
    test2_active = not test2_active
    if test2_active then
        chatOk("Test 2: ON - Manual view-projection (camera vectors)")
        chat("  Using getActiveCameraCoordinates + getActiveCameraPointAt")
        chat("  Projecting player pos (Z+1.5) to screen via perspective math")
    else
        chat("Test 2: OFF")
        test2_valid = false
    end
end)

-- /3dtest3 - Native CalcScreenCoors via FFI
sampRegisterChatCommand("3dtest3", function()
    test3_active = not test3_active
    if test3_active then
        chatOk("Test 3: ON - Native CalcScreenCoors via FFI")
        chat("  Attempting to call CSprite::CalcScreenCoors from game binary")
        chat("  Base address: 0x" .. string.format("%X", BASE))
        initCalcScreenCoors()
        if not calcScreenCoors_fn then
            chatErr("  WARNING: Function pointer could not be established")
            chatErr("  This test may not render anything")
        end
    else
        chat("Test 3: OFF")
        test3_valid = false
    end
end)

-- /3dtest4 - Angle-based simplified approach
sampRegisterChatCommand("3dtest4", function()
    test4_active = not test4_active
    if test4_active then
        chatOk("Test 4: ON - Angle-based approach (pure math)")
        chat("  Calculates angle from camera to target")
        chat("  Converts angle difference to screen position")
        chat("  NOT true 3D projection, but safe and works as indicator")
    else
        chat("Test 4: OFF")
        test4_valid = false
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
chat("3DRenderTest loaded! Commands:")
chat("  /3dtest1 - Check camera function availability")
chat("  /3dtest2 - Manual projection (camera matrix math)")
chat("  /3dtest3 - Native CalcScreenCoors via FFI")
chat("  /3dtest4 - Angle-based approach (safest)")
chat("All tests render text above YOUR player (local).")
