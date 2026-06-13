-- ============================================================================
-- DevBox3D v2.0
-- Floating 3D box (background rectangle + text) above player head
-- Uses manual camera projection (Test 2 approach - confirmed working)
-- Config via mimgui panel (/devbox to toggle config window)
-- Author: OnlyDexterZ
-- ============================================================================

script_name("DevBox3D")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0

local PRESET_TEXTS = {
    "DevBox Test",
    "Hello World",
    "Testing 3D",
    "Custom Box",
    "SA-MP Android"
}

-- ============================================================================
-- STATE
-- ============================================================================
local devbox = {
    enabled = true,
    text = "DevBox Test",
    textIndex = 1,
    offsetX = 0,
    offsetY = 0,
    zOffset = 1.5,
    maxTiltAngle = 30,
    padding = 8,
    cornerRounding = 4
}

-- imgui state variables (float pointers for sliders, bool for window)
local showConfigWindow = imgui.new.bool(false)
local sliderOffsetX = imgui.new.float(0)
local sliderOffsetY = imgui.new.float(0)
local sliderZOffset = imgui.new.float(1.5)
local sliderMaxTilt = imgui.new.float(30)

-- Projection result
local screen_x, screen_y = 0, 0
local screen_valid = false

-- ============================================================================
-- HELPER: safe chat message
-- ============================================================================
local function chat(msg)
    pcall(function()
        sampAddChatMessage("{00FFCC}[DevBox3D] {FFFFFF}" .. tostring(msg), 0xFFFFFF)
    end)
end

-- ============================================================================
-- HELPER: get player position with Z offset
-- ============================================================================
local function getPlayerAbovePos()
    local x, y, z = 0, 0, 0
    local ok = pcall(function()
        x, y, z = getCharCoordinates(PLAYER_PED)
    end)
    if ok and x ~= 0 then
        return x, y, z + devbox.zOffset
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
-- PROJECTION: Manual camera projection (Test 2 approach)
-- Returns screen position and camera pitch angle (in degrees)
-- ============================================================================
local function computeScreenPos()
    screen_valid = false

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

    -- Build camera forward vector
    local fwdX = lookX - camX
    local fwdY = lookY - camY
    local fwdZ = lookZ - camZ
    local fwdLen = math.sqrt(fwdX * fwdX + fwdY * fwdY + fwdZ * fwdZ)
    if fwdLen < 0.001 then return end
    fwdX = fwdX / fwdLen
    fwdY = fwdY / fwdLen
    fwdZ = fwdZ / fwdLen

    -- Calculate camera pitch angle
    local fwdLen2D = math.sqrt(fwdX * fwdX + fwdY * fwdY)
    local camPitch = math.deg(math.atan2(fwdZ, fwdLen2D))

    -- Tilt angle limit: if abs(pitch) exceeds max, hide the box
    if math.abs(camPitch) > devbox.maxTiltAngle then
        return
    end

    -- World up
    local wupX, wupY, wupZ = 0, 0, 1

    -- Right = forward x world_up (normalize)
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

    -- NDC to screen (Y is flipped - screen Y goes down)
    local sx = (ndcX * 0.5 + 0.5) * screenW
    local sy = (-ndcY * 0.5 + 0.5) * screenH

    -- Apply pixel offsets
    sx = sx + devbox.offsetX
    sy = sy + devbox.offsetY

    -- Check if on screen (with margin for box size)
    if sx >= -200 and sx <= screenW + 200 and sy >= -200 and sy <= screenH + 200 then
        screen_x = sx
        screen_y = sy
        screen_valid = true
    end
end

-- ============================================================================
-- IMGUI FRAME: 3D Box Rendering (background draw list)
-- ============================================================================
imgui.OnFrame(
    function()
        return devbox.enabled
    end,
    function(self)
        self.HideCursor = true

        -- Compute 3D projection
        pcall(computeScreenPos)

        if not screen_valid then return end

        local dl = imgui.GetBackgroundDrawList()
        local scale = DPI

        -- Colors
        local colorBg = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.0, 0.0, 0.85))
        local colorWhite = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        local colorShadow = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.0, 0.0, 1.0))

        -- Calculate text size
        local text = devbox.text
        local textSize = imgui.CalcTextSize(text)
        local textW = textSize.x
        local textH = textSize.y

        -- Padding scaled
        local pad = devbox.padding * scale

        -- Box dimensions
        local boxW = textW + pad * 2
        local boxH = textH + pad * 2

        -- Box position (centered on projected point)
        local boxX = screen_x - boxW * 0.5
        local boxY = screen_y - boxH * 0.5

        -- Draw background rectangle (rounded corners)
        local boxMin = imgui.ImVec2(boxX, boxY)
        local boxMax = imgui.ImVec2(boxX + boxW, boxY + boxH)
        local rounding = devbox.cornerRounding * scale
        dl:AddRectFilled(boxMin, boxMax, colorBg, rounding)

        -- Text position (centered inside box)
        local textX = boxX + pad
        local textY = boxY + pad

        -- Draw text shadow/outline (+1px offsets)
        local ox = 1.0 * scale
        dl:AddText(imgui.ImVec2(textX - ox, textY), colorShadow, text)
        dl:AddText(imgui.ImVec2(textX + ox, textY), colorShadow, text)
        dl:AddText(imgui.ImVec2(textX, textY - ox), colorShadow, text)
        dl:AddText(imgui.ImVec2(textX, textY + ox), colorShadow, text)

        -- Draw main text (white)
        dl:AddText(imgui.ImVec2(textX, textY), colorWhite, text)
    end
)

-- ============================================================================
-- IMGUI FRAME: Config Window
-- ============================================================================
imgui.OnFrame(
    function()
        return showConfigWindow[0]
    end,
    function(self)
        self.HideCursor = false

        local sw, sh = getScreenRes()
        local winW = 360 * DPI
        local winH = 420 * DPI

        -- Dark blue-grey theme (same as ChatEngine)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12 * DPI)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6 * DPI)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15 * DPI, 12 * DPI))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8 * DPI, 6 * DPI))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        imgui.Begin("DevBox3D Settings", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

        -- Title
        imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.6, 1), "DEVBOX3D SETTINGS")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "v2.0")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Toggle ON/OFF (Button, NOT Checkbox)
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "GENERAL")
        imgui.Spacing()

        local enableLabel = devbox.enabled and "[ON] DevBox3D" or "[OFF] DevBox3D"
        if imgui.Button(enableLabel, imgui.ImVec2(-1, 30 * DPI)) then
            devbox.enabled = not devbox.enabled
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Text display + Change Text button
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "TEXT")
        imgui.Spacing()

        imgui.Text("Current: \"" .. devbox.text .. "\"")
        imgui.Spacing()

        if imgui.Button("Change Text", imgui.ImVec2(-1, 30 * DPI)) then
            devbox.textIndex = devbox.textIndex + 1
            if devbox.textIndex > #PRESET_TEXTS then
                devbox.textIndex = 1
            end
            devbox.text = PRESET_TEXTS[devbox.textIndex]
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Sliders
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "POSITION & LIMITS")
        imgui.Spacing()

        imgui.Text("Offset X:")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##offsetX", sliderOffsetX, -200.0, 200.0, "%.0f")
        devbox.offsetX = sliderOffsetX[0]

        imgui.Spacing()

        imgui.Text("Offset Y:")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##offsetY", sliderOffsetY, -200.0, 200.0, "%.0f")
        devbox.offsetY = sliderOffsetY[0]

        imgui.Spacing()

        imgui.Text("Z World Offset:")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##zOffset", sliderZOffset, 0.5, 5.0, "%.1f")
        devbox.zOffset = sliderZOffset[0]

        imgui.Spacing()

        imgui.Text("Max Tilt Angle:")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##maxTilt", sliderMaxTilt, 10.0, 80.0, "%.0f")
        devbox.maxTiltAngle = sliderMaxTilt[0]

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- RESET ALL button
        if imgui.Button("RESET ALL", imgui.ImVec2(-1, 35 * DPI)) then
            devbox.enabled = true
            devbox.text = "DevBox Test"
            devbox.textIndex = 1
            devbox.offsetX = 0
            devbox.offsetY = 0
            devbox.zOffset = 1.5
            devbox.maxTiltAngle = 30
            sliderOffsetX[0] = 0
            sliderOffsetY[0] = 0
            sliderZOffset[0] = 1.5
            sliderMaxTilt[0] = 30
        end

        imgui.End()
        imgui.PopStyleColor(7)
        imgui.PopStyleVar(4)
    end
)

-- ============================================================================
-- COMMAND: /devbox - toggle config window open/close
-- ============================================================================
sampRegisterChatCommand("devbox", function()
    showConfigWindow[0] = not showConfigWindow[0]
    if showConfigWindow[0] then
        chat("Config window opened")
    else
        chat("Config window closed")
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
chat("v2.0 Loaded! Type /devbox to open settings")
