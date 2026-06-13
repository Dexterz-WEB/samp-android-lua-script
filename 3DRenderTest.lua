-- ============================================================================
-- DevBox3D v1.0
-- Floating 3D box (background rectangle + text) above player head
-- Uses manual camera projection (Test 2 approach - confirmed working)
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

-- ============================================================================
-- STATE
-- ============================================================================
local devbox = {
    enabled = true,
    text = "DevBox Test",
    offsetX = 0,       -- screen pixel offset X
    offsetY = 0,       -- screen pixel offset Y
    zOffset = 1.5,     -- world Z offset above head
    padding = 8,       -- padding inside box (px)
    cornerRounding = 4 -- rounded corners radius
}

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
-- IMGUI RENDERING FRAME
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
-- COMMAND: /devbox
-- ============================================================================
sampRegisterChatCommand("devbox", function(args)
    args = args or ""

    -- No argument = toggle
    if args == "" then
        devbox.enabled = not devbox.enabled
        if devbox.enabled then
            chat("Enabled")
        else
            chat("Disabled")
        end
        return
    end

    -- Parse subcommand
    local cmd, value = args:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or ""

    if cmd == "text" then
        if value == "" then
            chat("Current text: \"" .. devbox.text .. "\"")
        else
            devbox.text = value
            chat("Text set to: \"" .. value .. "\"")
        end

    elseif cmd == "x" then
        local num = tonumber(value)
        if num then
            devbox.offsetX = num
            chat("Offset X set to: " .. num .. " px")
        else
            chat("Current offset X: " .. devbox.offsetX .. " px")
        end

    elseif cmd == "y" then
        local num = tonumber(value)
        if num then
            devbox.offsetY = num
            chat("Offset Y set to: " .. num .. " px")
        else
            chat("Current offset Y: " .. devbox.offsetY .. " px")
        end

    elseif cmd == "z" then
        local num = tonumber(value)
        if num then
            devbox.zOffset = num
            chat("Z world offset set to: " .. num)
        else
            chat("Current Z offset: " .. devbox.zOffset)
        end

    elseif cmd == "reset" then
        devbox.offsetX = 0
        devbox.offsetY = 0
        devbox.zOffset = 1.5
        devbox.text = "DevBox Test"
        devbox.padding = 8
        devbox.cornerRounding = 4
        chat("All settings reset to defaults")

    else
        chat("Usage:")
        chat("  /devbox - toggle on/off")
        chat("  /devbox text <text> - set display text")
        chat("  /devbox x <pixels> - set X pixel offset")
        chat("  /devbox y <pixels> - set Y pixel offset")
        chat("  /devbox z <value> - set Z world offset")
        chat("  /devbox reset - reset all to defaults")
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
chat("Loaded! Default: ON, text=\"DevBox Test\"")
chat("  /devbox - toggle | /devbox text <msg> | /devbox reset")
