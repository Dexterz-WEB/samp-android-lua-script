-- ============================================================================
-- CHAT ENGINE v3.0 - Scrollable BeginChild + Auto-hide + Discord Dark Theme
-- Combines v1.0 proven scrollable structure with v2.0 visual improvements
-- Compatible with MonetLoader Android
-- ============================================================================

script_name("ChatEngine")
script_author("OnlyDexterZ")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'
local inicfg = require 'inicfg'

local sampev_loaded, sampev = pcall(require, "samp.events")
if not sampev_loaded then
    print("[ChatEngine] WARNING: samp.events not available!")
end

local chatlib_loaded, chatlib = pcall(require, "lib.chatengine_lib")
if not chatlib_loaded then
    print("[ChatEngine] ERROR: chatengine_lib not found!")
    chatlib = nil
end

-- ============================================================================
-- DPI SCALE (MonetLoader Android)
-- ============================================================================
local DPI_SCALE = MONET_DPI_SCALE or 1.0

-- ============================================================================
-- CONFIG (inicfg)
-- ============================================================================
local defaultConfig = {
    Settings = {
        enabled = true,
        fontSize = 14,
        autoHideDelay = 10,
        showTimestamp = true,
        showAccentBar = true
    }
}

local iniFileName = "ChatEngine.ini"
local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end

-- Ensure all settings exist (backwards compat)
if iniData.Settings.showAccentBar == nil then
    iniData.Settings.showAccentBar = true
end
if iniData.Settings.showTimestamp == nil then
    iniData.Settings.showTimestamp = true
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local chatInterceptEnabled = (iniData.Settings.enabled ~= false)

-- Auto-hide state machine
local STATE_HIDDEN = 0
local STATE_FADE_IN = 1
local STATE_VISIBLE = 2
local STATE_FADE_OUT = 3

local chatState = STATE_HIDDEN
local stateStartTime = os.clock()
local lastInsertionCount = 0

-- Fade durations
local FADE_IN_DURATION = 0.5
local FADE_OUT_DURATION = 2.0

-- Config panel state
local showConfigWindow = imgui.new.bool(false)

-- Config imgui bindings
local cfgFontSize = imgui.new.float(iniData.Settings.fontSize or 14)
local cfgAutoHide = imgui.new.float(iniData.Settings.autoHideDelay or 10)
local cfgEnabled = imgui.new.bool(iniData.Settings.enabled ~= false)
local cfgTimestamp = imgui.new.bool(iniData.Settings.showTimestamp ~= false)
local cfgAccentBar = imgui.new.bool(iniData.Settings.showAccentBar ~= false)

-- Auto-scroll flag
local shouldAutoScroll = false

-- ============================================================================
-- BUBBLE SYSTEM STATE
-- ============================================================================
local activeBubbles = {}           -- Array of active bubble objects
local MAX_BUBBLES_PER_PLAYER = 3
local BUBBLE_MAX_DISTANCE = 10
local BUBBLE_MAX_WIDTH_RATIO = 0.6
local BUBBLE_MAX_LINES = 4

-- ============================================================================
-- CATEGORY COLORS (for accent bars and prefixes)
-- ============================================================================
local categoryColors = {
    PM     = { 0.2, 0.9, 0.4 },
    OOC    = { 0.6, 0.6, 0.6 },
    IC     = { 0.9, 0.9, 1.0 },
    Ad     = { 1.0, 0.85, 0.2 },
    Action = { 0.8, 0.4, 0.9 },
    Server = { 0.3, 0.3, 0.3 }
}

local categoryPrefixes = {
    PM     = "[PM] ",
    OOC    = "[OOC] ",
    IC     = "[IC] ",
    Ad     = "[AD] ",
    Action = "[ACT] "
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- ============================================================================
-- BUBBLE SYSTEM HELPERS
-- ============================================================================

-- 3D distance between two points
local function getDistance3D(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Project world coordinates to screen using manual camera projection
-- Same math as DevBox3D (3DRenderTest.lua) - proven working on MonetLoader
local function projectWorldToScreen(worldX, worldY, worldZ)
    -- Get camera position and look-at point
    local camX, camY, camZ, lookX, lookY, lookZ
    local ok1 = pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
    end)
    local ok2 = pcall(function()
        lookX, lookY, lookZ = getActiveCameraPointAt()
    end)

    if not ok1 or not ok2 or not camX or not lookX then
        return 0, 0, false
    end

    local screenW, screenH = 800, 600
    pcall(function()
        screenW, screenH = getScreenResolution()
    end)

    -- Build camera forward vector
    local fwdX = lookX - camX
    local fwdY = lookY - camY
    local fwdZ = lookZ - camZ
    local fwdLen = math.sqrt(fwdX * fwdX + fwdY * fwdY + fwdZ * fwdZ)
    if fwdLen < 0.001 then return 0, 0, false end
    fwdX = fwdX / fwdLen
    fwdY = fwdY / fwdLen
    fwdZ = fwdZ / fwdLen

    -- Calculate camera pitch angle
    local fwdLen2D = math.sqrt(fwdX * fwdX + fwdY * fwdY)
    local camPitch = math.deg(math.atan2(fwdZ, fwdLen2D))

    -- Tilt angle limit: if abs(pitch) exceeds 30 degrees, hide
    if math.abs(camPitch) > 30 then
        return 0, 0, false
    end

    -- World up
    local wupX, wupY, wupZ = 0, 0, 1

    -- Right = forward x world_up (normalize)
    local rightX = fwdY * wupZ - fwdZ * wupY
    local rightY = fwdZ * wupX - fwdX * wupZ
    local rightZ = fwdX * wupY - fwdY * wupX
    local rightLen = math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ)
    if rightLen < 0.001 then return 0, 0, false end
    rightX = rightX / rightLen
    rightY = rightY / rightLen
    rightZ = rightZ / rightLen

    -- Up = right x forward
    local upX = rightY * fwdZ - rightZ * fwdY
    local upY = rightZ * fwdX - rightX * fwdZ
    local upZ = rightX * fwdY - rightY * fwdX

    -- Vector from camera to target
    local dx = worldX - camX
    local dy = worldY - camY
    local dz = worldZ - camZ

    -- Project onto camera axes
    local dotFwd   = dx * fwdX   + dy * fwdY   + dz * fwdZ
    local dotRight = dx * rightX + dy * rightY + dz * rightZ
    local dotUp    = dx * upX    + dy * upY    + dz * upZ

    -- Behind camera check
    if dotFwd <= 0.1 then return 0, 0, false end

    -- Perspective projection (GTA SA uses ~70 degree FOV)
    local fov = 70.0
    local aspect = screenW / screenH
    local tanHalfFov = math.tan(math.rad(fov * 0.5))

    local ndcX = (dotRight / dotFwd) / (tanHalfFov * aspect)
    local ndcY = (dotUp / dotFwd) / tanHalfFov

    -- NDC to screen (Y is flipped - screen Y goes down)
    local sx = (ndcX * 0.5 + 0.5) * screenW + 9
    local sy = (-ndcY * 0.5 + 0.5) * screenH + 4

    -- Check if on screen (with margin)
    if sx >= -200 and sx <= screenW + 200 and sy >= -200 and sy <= screenH + 200 then
        return sx, sy, true
    end

    return 0, 0, false
end

-- Wrap text to fit within maxWidth pixels, max BUBBLE_MAX_LINES lines
local function wrapBubbleText(text, maxWidth)
    local lines = {}
    local words = {}

    -- Split text into words
    for word in text:gmatch("%S+") do
        words[#words + 1] = word
    end

    if #words == 0 then
        return {""}
    end

    local currentLine = ""
    for i = 1, #words do
        local testLine
        if currentLine == "" then
            testLine = words[i]
        else
            testLine = currentLine .. " " .. words[i]
        end

        local textSize = imgui.CalcTextSize(testLine)
        if textSize.x > maxWidth and currentLine ~= "" then
            -- Current line is full, push it
            lines[#lines + 1] = currentLine
            currentLine = words[i]

            -- Check max lines
            if #lines >= BUBBLE_MAX_LINES then
                -- Truncate last line with "..."
                local lastLine = lines[#lines]
                local truncSize = imgui.CalcTextSize(lastLine .. "...")
                if truncSize.x <= maxWidth then
                    lines[#lines] = lastLine .. "..."
                else
                    -- Try to shorten last line to fit "..."
                    lines[#lines] = lastLine .. "..."
                end
                return lines
            end
        else
            currentLine = testLine
        end
    end

    -- Push remaining line
    if currentLine ~= "" then
        lines[#lines + 1] = currentLine
    end

    -- If over max lines, truncate
    if #lines > BUBBLE_MAX_LINES then
        lines[BUBBLE_MAX_LINES] = lines[BUBBLE_MAX_LINES] .. "..."
        -- Remove extra lines
        for i = #lines, BUBBLE_MAX_LINES + 1, -1 do
            lines[i] = nil
        end
    end

    if #lines == 0 then
        lines[1] = text
    end

    return lines
end

-- Create a new chat bubble for a player
local function createBubble(playerId, playerName, text)
    -- Calculate word count for duration
    local wordCount = 0
    for _ in text:gmatch("%S+") do
        wordCount = wordCount + 1
    end

    -- Duration: word_count * 0.5, clamped [3, 8]
    local duration = wordCount * 0.5
    if duration < 3 then duration = 3 end
    if duration > 8 then duration = 8 end

    -- Create bubble object
    local bubble = {
        playerId = playerId,
        playerName = playerName or ("ID " .. playerId),
        text = text,
        startTime = os.clock(),
        duration = duration,
        alpha = 1.0
    }

    -- Count existing bubbles for this player and enforce max
    local playerBubbleCount = 0
    for i = 1, #activeBubbles do
        if activeBubbles[i].playerId == playerId then
            playerBubbleCount = playerBubbleCount + 1
        end
    end

    -- Remove oldest bubbles for this player if at max
    while playerBubbleCount >= MAX_BUBBLES_PER_PLAYER do
        for i = 1, #activeBubbles do
            if activeBubbles[i].playerId == playerId then
                table.remove(activeBubbles, i)
                playerBubbleCount = playerBubbleCount - 1
                break
            end
        end
    end

    -- Add new bubble
    activeBubbles[#activeBubbles + 1] = bubble
end

local function saveConfig()
    iniData.Settings.enabled = cfgEnabled[0]
    iniData.Settings.fontSize = cfgFontSize[0]
    iniData.Settings.autoHideDelay = cfgAutoHide[0]
    iniData.Settings.showTimestamp = cfgTimestamp[0]
    iniData.Settings.showAccentBar = cfgAccentBar[0]
    chatInterceptEnabled = cfgEnabled[0]
    inicfg.save(iniData, iniFileName)
end

-- Calculate master alpha based on current state
local function getMasterAlpha()
    local now = os.clock()
    local elapsed = now - stateStartTime

    if chatState == STATE_HIDDEN then
        return 0.0
    elseif chatState == STATE_FADE_IN then
        local progress = elapsed / FADE_IN_DURATION
        if progress >= 1.0 then
            progress = 1.0
        end
        return progress
    elseif chatState == STATE_VISIBLE then
        return 1.0
    elseif chatState == STATE_FADE_OUT then
        local progress = elapsed / FADE_OUT_DURATION
        if progress >= 1.0 then
            progress = 1.0
        end
        return 1.0 - progress
    end
    return 0.0
end

-- Update state machine transitions based on time
local function updateStateMachine()
    local now = os.clock()
    local elapsed = now - stateStartTime

    if chatState == STATE_FADE_IN then
        if elapsed >= FADE_IN_DURATION then
            chatState = STATE_VISIBLE
            stateStartTime = now
        end
    elseif chatState == STATE_VISIBLE then
        local hideDelay = cfgAutoHide[0]
        if hideDelay > 0 and elapsed >= hideDelay then
            chatState = STATE_FADE_OUT
            stateStartTime = now
        end
    elseif chatState == STATE_FADE_OUT then
        if elapsed >= FADE_OUT_DURATION then
            chatState = STATE_HIDDEN
            stateStartTime = now
        end
    end
end

-- Handle new message arrival - trigger state transitions
local function onNewMessage()
    local now = os.clock()

    if chatState == STATE_HIDDEN then
        chatState = STATE_FADE_IN
        stateStartTime = now
    elseif chatState == STATE_FADE_OUT then
        -- Cancel fade out, go directly to visible
        chatState = STATE_VISIBLE
        stateStartTime = now
    elseif chatState == STATE_VISIBLE then
        -- Reset visible timer
        stateStartTime = now
    elseif chatState == STATE_FADE_IN then
        -- Already fading in, keep going
    end
end

-- Check for new messages from the library
local function checkNewMessages()
    if not chatlib then return end
    local currentCount = chatlib.getInsertionCount()
    if currentCount > lastInsertionCount then
        lastInsertionCount = currentCount
        shouldAutoScroll = true
        onNewMessage()
    end
end

-- ============================================================================
-- SAMP.EVENTS HOOKS
-- ============================================================================
if sampev_loaded then
    function sampev.onServerMessage(color, text)
        if chatInterceptEnabled and chatlib then
            chatlib.addMessage(text, color)
            return false
        end
    end

    function sampev.onChatMessage(playerId, text)
        if chatInterceptEnabled and chatlib then
            local playerName = nil
            pcall(function()
                playerName = sampGetPlayerNickname(playerId)
            end)
            local formatted = ""
            if playerName then
                formatted = playerName .. " (" .. playerId .. "): " .. text
            else
                formatted = "ID " .. playerId .. ": " .. text
            end
            chatlib.addMessage(formatted, 0xFFFFFFFF, "IC")

            -- Create chat bubble for other players (not self) within distance
            pcall(function()
                -- Get local player ID
                local _, localId = sampGetPlayerIdByCharHandle(PLAYER_PED)
                if localId and playerId ~= localId then
                    -- Check if player is connected
                    if sampIsPlayerConnected(playerId) then
                        -- Get other player's character handle
                        local result, handle = sampGetCharHandleBySampPlayerId(playerId)
                        if result and handle then
                            -- Get positions
                            local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                            local otherX, otherY, otherZ = getCharCoordinates(handle)
                            -- Distance check
                            local dist = getDistance3D(myX, myY, myZ, otherX, otherY, otherZ)
                            if dist <= BUBBLE_MAX_DISTANCE then
                                createBubble(playerId, playerName or ("ID " .. playerId), text)
                            end
                        end
                    end
                end
            end)

            return false
        end
    end
end

-- ============================================================================
-- SHADOW TEXT HELPER
-- Renders black shadow text offset by 1px via DrawList:AddText
-- ============================================================================
local function renderTextWithShadow(drawList, screenX, screenY, text, r, g, b, alpha)
    -- Shadow (black, offset 1px right and down)
    local offsetPx = 1 * DPI_SCALE
    drawList:AddText(
        imgui.ImVec2(screenX + offsetPx, screenY + offsetPx),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, alpha * 0.8)),
        text
    )
end

-- ============================================================================
-- CHAT WINDOW (imgui.OnFrame) - Scrollable BeginChild + Discord Dark Theme
-- ============================================================================
imgui.OnFrame(
    function()
        -- Always run state polling every frame
        checkNewMessages()
        updateStateMachine()
        return true
    end,
    function(self)
        self.HideCursor = true

        -- Short-circuit: skip rendering when disabled or fully transparent
        if not chatInterceptEnabled then return end
        local masterAlpha = getMasterAlpha()
        if masterAlpha <= 0.01 then return end

        -- Position and size
        local posX = 10 * DPI_SCALE
        local posY = 10 * DPI_SCALE
        local sw, sh = getScreenResolution()
        local winW = sw * 0.45
        local winH = sh * 0.35

        -- Push window styles - Discord dark blue-grey theme
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8 * DPI_SCALE)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8 * DPI_SCALE, 8 * DPI_SCALE))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2 * DPI_SCALE, 2 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.09, 0.14, masterAlpha))
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.06, 0.07, 0.11, masterAlpha))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ScrollbarBg, imgui.ImVec4(0.05, 0.05, 0.08, 0.3 * masterAlpha))
        imgui.PushStyleColor(imgui.Col.ScrollbarGrab, imgui.ImVec4(0.2, 0.2, 0.3, 0.4 * masterAlpha))

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        local flags = imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoScrollbar
            + imgui.WindowFlags.NoInputs

        imgui.Begin("##ChatEngineWindow", nil, flags)

        -- Apply font size scaling
        imgui.SetWindowFontScale(cfgFontSize[0] / 14.0)

        -- Header: "Chat Engine" text + separator
        imgui.TextColored(imgui.ImVec4(0.4, 0.7, 1.0, masterAlpha), "Chat Engine")
        imgui.Separator()

        -- Scrollable child region for messages
        imgui.BeginChild("##ChatScroll", imgui.ImVec2(0, -1), false, 0)

        -- Enable text wrapping so long messages don't get cut off
        imgui.PushTextWrapPos(0)

        -- Get messages and render
        if chatlib then
            local allMessages = chatlib.getMessages()
            local totalMessages = #allMessages
            local drawList = imgui.GetWindowDrawList()
            local lineHeight = (cfgFontSize[0] + 4) * DPI_SCALE

            for idx = 1, totalMessages do
                local msg = allMessages[idx]

                -- Gradient opacity: older = floor 0.5, newer = full opacity
                local gradientAlpha = masterAlpha * math.max(0.5, idx / totalMessages)

                -- Get screen position for DrawList operations (accounts for scroll)
                local screenPos = imgui.GetCursorScreenPos()
                local screenX = screenPos.x
                local screenY = screenPos.y

                -- Draw accent bar (thin colored bar 3px on the left)
                if cfgAccentBar[0] and msg.category and msg.category ~= "Server" then
                    local barColor = categoryColors[msg.category]
                    if barColor then
                        local barWidth = 3 * DPI_SCALE
                        local barHeight = lineHeight - 2 * DPI_SCALE
                        drawList:AddRectFilled(
                            imgui.ImVec2(screenX, screenY),
                            imgui.ImVec2(screenX + barWidth, screenY + barHeight),
                            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
                                barColor[1], barColor[2], barColor[3], gradientAlpha
                            ))
                        )
                    end
                end

                -- Offset text after accent bar
                local textOffsetX = 0
                if cfgAccentBar[0] then
                    textOffsetX = 6 * DPI_SCALE
                end
                local cursorPos = imgui.GetCursorPos()
                imgui.SetCursorPosX(cursorPos.x + textOffsetX)

                -- Timestamp [HH:MM]
                if cfgTimestamp[0] and msg.timestamp then
                    local tsScreenPos = imgui.GetCursorScreenPos()
                    renderTextWithShadow(drawList, tsScreenPos.x, tsScreenPos.y, msg.timestamp, 0.5, 0.5, 0.6, gradientAlpha * 0.7)
                    imgui.TextColored(
                        imgui.ImVec4(0.5, 0.5, 0.6, gradientAlpha * 0.7),
                        msg.timestamp
                    )
                    imgui.SameLine(0, 4 * DPI_SCALE)
                end

                -- Category prefix (not for Server)
                if msg.category and msg.category ~= "Server" then
                    local catColor = categoryColors[msg.category]
                    local catPrefix = categoryPrefixes[msg.category]
                    if catColor and catPrefix then
                        local pfxScreenPos = imgui.GetCursorScreenPos()
                        renderTextWithShadow(drawList, pfxScreenPos.x, pfxScreenPos.y, catPrefix, catColor[1], catColor[2], catColor[3], gradientAlpha)
                        imgui.TextColored(
                            imgui.ImVec4(catColor[1], catColor[2], catColor[3], gradientAlpha),
                            catPrefix
                        )
                        imgui.SameLine(0, 0)
                    end
                end

                -- Render message text with color segments (brighter + shadow)
                if msg.parsed_segments and #msg.parsed_segments > 0 then
                    for j = 1, #msg.parsed_segments do
                        local seg = msg.parsed_segments[j]
                        if j > 1 then
                            imgui.SameLine(0, 0)
                        end
                        -- Shadow for message text
                        local segScreenPos = imgui.GetCursorScreenPos()
                        -- Brighten colors by 20%, capped at 1.0
                        local br = math.min(1.0, seg.r * 1.2)
                        local bg = math.min(1.0, seg.g * 1.2)
                        local bb = math.min(1.0, seg.b * 1.2)
                        renderTextWithShadow(drawList, segScreenPos.x, segScreenPos.y, seg.text, br, bg, bb, gradientAlpha)
                        imgui.TextColored(
                            imgui.ImVec4(br, bg, bb, gradientAlpha),
                            seg.text
                        )
                    end
                else
                    -- Fallback: plain text with shadow
                    local fbScreenPos = imgui.GetCursorScreenPos()
                    renderTextWithShadow(drawList, fbScreenPos.x, fbScreenPos.y, msg.text or "", 1, 1, 1, gradientAlpha)
                    imgui.TextColored(
                        imgui.ImVec4(1.0, 1.0, 1.0, gradientAlpha),
                        msg.text or ""
                    )
                end
            end

            -- Auto-scroll to bottom when new messages arrive
            if shouldAutoScroll then
                imgui.SetScrollHereY(1.0)
                shouldAutoScroll = false
            end
        end

        imgui.PopTextWrapPos()
        imgui.EndChild()

        -- Reset font scale
        imgui.SetWindowFontScale(1.0)

        imgui.End()
        imgui.PopStyleColor(5)
        imgui.PopStyleVar(3)
    end
)

-- ============================================================================
-- CONFIG PANEL (imgui.OnFrame)
-- ============================================================================
imgui.OnFrame(
    function() return showConfigWindow[0] end,
    function(self)
        self.HideCursor = false

        local sw, sh = getScreenResolution()
        local winW = 380 * DPI_SCALE
        local winH = 400 * DPI_SCALE

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12 * DPI_SCALE)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6 * DPI_SCALE)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15 * DPI_SCALE, 12 * DPI_SCALE))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8 * DPI_SCALE, 6 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        imgui.Begin("ChatEngine Config", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

        -- Title
        imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.6, 1), "CHATENGINE SETTINGS")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "v3.0")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Toggle enabled (Button, NOT Checkbox)
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "GENERAL")
        imgui.Spacing()

        local enableLabel = cfgEnabled[0] and "[ON] ChatEngine" or "[OFF] ChatEngine"
        if imgui.Button(enableLabel, imgui.ImVec2(-1, 30 * DPI_SCALE)) then
            cfgEnabled[0] = not cfgEnabled[0]
        end

        local tsLabel = cfgTimestamp[0] and "[ON] Timestamps" or "[OFF] Timestamps"
        if imgui.Button(tsLabel, imgui.ImVec2(-1, 30 * DPI_SCALE)) then
            cfgTimestamp[0] = not cfgTimestamp[0]
        end

        local barLabel = cfgAccentBar[0] and "[ON] Accent Bar" or "[OFF] Accent Bar"
        if imgui.Button(barLabel, imgui.ImVec2(-1, 30 * DPI_SCALE)) then
            cfgAccentBar[0] = not cfgAccentBar[0]
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Sliders
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "APPEARANCE")
        imgui.Spacing()

        imgui.Text("Font Size:")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##fontSize", cfgFontSize, 10.0, 24.0, "%.0f")

        imgui.Spacing()

        imgui.Text("Auto-hide Delay (seconds):")
        imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##autoHide", cfgAutoHide, 3.0, 30.0, "%.0f")

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- Save button
        if imgui.Button("SAVE CONFIG", imgui.ImVec2(-1, 35 * DPI_SCALE)) then
            saveConfig()
            showConfigWindow[0] = false
        end

        imgui.End()
        imgui.PopStyleColor(7)
        imgui.PopStyleVar(4)
    end
)

-- ============================================================================
-- BUBBLE RENDERING (imgui.OnFrame) - Separate from chat window
-- Uses GetBackgroundDrawList for overlay rendering
-- ============================================================================
imgui.OnFrame(
    function()
        return true
    end,
    function(self)
        self.HideCursor = true

        -- Skip if no active bubbles
        if #activeBubbles == 0 then return end

        local now = os.clock()

        -- Get screen resolution
        local screenW, screenH = 800, 600
        pcall(function()
            screenW, screenH = getScreenResolution()
        end)

        -- Get local player position
        local myX, myY, myZ = 0, 0, 0
        local gotMyPos = pcall(function()
            myX, myY, myZ = getCharCoordinates(PLAYER_PED)
        end)
        if not gotMyPos then return end

        local drawList = imgui.GetBackgroundDrawList()

        -- Track cumulative Y offset per player for stacking
        local playerStackOffset = {}

        -- Remove expired bubbles (iterate backward for safe removal)
        local i = #activeBubbles
        while i >= 1 do
            local bubble = activeBubbles[i]
            local elapsed = now - bubble.startTime
            if elapsed >= bubble.duration then
                table.remove(activeBubbles, i)
            end
            i = i - 1
        end

        -- Render bubbles (newer bubbles are at end of array, render them first at bottom)
        -- Iterate from newest to oldest so newer bubbles are at anchor, older ones stack above
        for idx = #activeBubbles, 1, -1 do
            local bubble = activeBubbles[idx]
            local elapsed = now - bubble.startTime

            -- Calculate alpha with fade out in last 1 second
            local bubbleAlpha = 1.0
            local timeRemaining = bubble.duration - elapsed
            if timeRemaining <= 1.0 then
                bubbleAlpha = math.max(0.0, timeRemaining)
            end

            if bubbleAlpha <= 0.01 then
                -- Skip rendering if fully transparent
            else
                -- Get other player handle and position
                local otherX, otherY, otherZ = 0, 0, 0
                local gotOther = false
                pcall(function()
                    if sampIsPlayerConnected(bubble.playerId) then
                        local result, handle = sampGetCharHandleBySampPlayerId(bubble.playerId)
                        if result and handle then
                            otherX, otherY, otherZ = getCharCoordinates(handle)
                            gotOther = true
                        end
                    end
                end)

                if gotOther then
                    -- Distance check (hide if > 10 but don't remove)
                    local dist = getDistance3D(myX, myY, myZ, otherX, otherY, otherZ)
                    if dist <= BUBBLE_MAX_DISTANCE then
                        -- Apply world offsets
                        local projX = otherX + 0.1
                        local projY = otherY
                        local projZ = otherZ + 1.3

                        -- Project to screen
                        local sx, sy, valid = projectWorldToScreen(projX, projY, projZ)

                        if valid then
                            -- Initialize stack offset for this player
                            if not playerStackOffset[bubble.playerId] then
                                playerStackOffset[bubble.playerId] = 0
                            end

                            local scale = DPI_SCALE
                            local pad = 8 * scale
                            local maxWidth = screenW * BUBBLE_MAX_WIDTH_RATIO
                            local rounding = 4 * scale

                            -- Wrap text
                            local lines = wrapBubbleText(bubble.text, maxWidth - pad * 2)

                            -- Measure text dimensions
                            local maxLineWidth = 0
                            local lineHeight = 0
                            for li = 1, #lines do
                                local ts = imgui.CalcTextSize(lines[li])
                                if ts.x > maxLineWidth then
                                    maxLineWidth = ts.x
                                end
                                if ts.y > lineHeight then
                                    lineHeight = ts.y
                                end
                            end

                            -- Player name measurement
                            local nameText = bubble.playerName
                            local nameSize = imgui.CalcTextSize(nameText)
                            local nameHeight = nameSize.y * 0.85  -- slightly smaller
                            if nameSize.x > maxLineWidth then
                                maxLineWidth = nameSize.x
                            end

                            -- Box dimensions
                            local boxW = maxLineWidth + pad * 2
                            local totalTextH = nameHeight + 2 * scale + lineHeight * #lines
                            local boxH = totalTextH + pad * 2

                            -- Anchor at bottom-center, box expands upward
                            local anchorX = sx
                            local anchorY = sy - playerStackOffset[bubble.playerId]

                            local boxX = anchorX - boxW * 0.5
                            local boxY = anchorY - boxH

                            -- Draw background rectangle
                            local bgColor = imgui.ColorConvertFloat4ToU32(
                                imgui.ImVec4(0.0, 0.0, 0.0, 0.85 * bubbleAlpha)
                            )
                            drawList:AddRectFilled(
                                imgui.ImVec2(boxX, boxY),
                                imgui.ImVec2(boxX + boxW, boxY + boxH),
                                bgColor,
                                rounding
                            )

                            -- Draw player name (colored, dimmer)
                            local nameX = boxX + pad
                            local nameY = boxY + pad
                            local nameColor = imgui.ColorConvertFloat4ToU32(
                                imgui.ImVec4(0.4, 0.8, 1.0, 0.7 * bubbleAlpha)
                            )
                            local nameShadowColor = imgui.ColorConvertFloat4ToU32(
                                imgui.ImVec4(0.0, 0.0, 0.0, 0.7 * bubbleAlpha)
                            )
                            -- Name shadow
                            drawList:AddText(
                                imgui.ImVec2(nameX + 1 * scale, nameY + 1 * scale),
                                nameShadowColor,
                                nameText
                            )
                            -- Name text
                            drawList:AddText(
                                imgui.ImVec2(nameX, nameY),
                                nameColor,
                                nameText
                            )

                            -- Draw message lines
                            local textStartY = nameY + nameHeight + 2 * scale
                            local textColor = imgui.ColorConvertFloat4ToU32(
                                imgui.ImVec4(1.0, 1.0, 1.0, bubbleAlpha)
                            )
                            local shadowColor = imgui.ColorConvertFloat4ToU32(
                                imgui.ImVec4(0.0, 0.0, 0.0, 0.8 * bubbleAlpha)
                            )

                            for li = 1, #lines do
                                local lineY = textStartY + (li - 1) * lineHeight
                                local lineX = boxX + pad

                                -- Shadow (1px offset)
                                drawList:AddText(
                                    imgui.ImVec2(lineX + 1 * scale, lineY + 1 * scale),
                                    shadowColor,
                                    lines[li]
                                )
                                -- Main text
                                drawList:AddText(
                                    imgui.ImVec2(lineX, lineY),
                                    textColor,
                                    lines[li]
                                )
                            end

                            -- Update stack offset for this player (next bubble renders above)
                            playerStackOffset[bubble.playerId] = playerStackOffset[bubble.playerId] + boxH + 4 * scale
                        end
                    end
                end
            end
        end
    end
)

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    -- Register /chatcfg command: open config panel
    sampRegisterChatCommand("chatcfg", function()
        showConfigWindow[0] = not showConfigWindow[0]
    end)

    -- Register /ceoff command: toggle interception on/off
    sampRegisterChatCommand("ceoff", function()
        chatInterceptEnabled = not chatInterceptEnabled
        cfgEnabled[0] = chatInterceptEnabled
        if chatInterceptEnabled then
            sampAddChatMessage("{00FFFF}[ChatEngine] {FFFFFF}Chat interception: {00FF00}ON", -1)
        else
            sampAddChatMessage("{00FFFF}[ChatEngine] {FFFFFF}Chat interception: {FF0000}OFF", -1)
        end
    end)

    -- Add startup message to custom chat buffer (not sampAddChatMessage)
    if chatlib then
        chatlib.addMessage("{00FFFF}[ChatEngine] {FFFFFF}Loaded! Use {FFFF00}/chatcfg{FFFFFF} to configure, {FFFF00}/ceoff{FFFFFF} to toggle.", -1)
    end

    -- Clear default chat after connecting (1 second delay)
    wait(1000)
    for i = 1, 15 do sampAddChatMessage("", -1) end

    -- Wait for spawn then clear again
    while not sampIsLocalPlayerSpawned() do wait(100) end
    wait(1000)
    for i = 1, 15 do sampAddChatMessage("", -1) end

    -- Keep script alive
    while true do wait(100) end
end
