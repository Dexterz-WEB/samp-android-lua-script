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

-- Chat mode: "NEWEST" or "NEARBY"
local chatMode = "NEWEST"
local NEARBY_MAX_DISTANCE = 50

-- Nearby messages buffer (separate from main buffer)
local nearbyMessages = {}
local MAX_NEARBY_MESSAGES = 100

-- Debug mode
local cfgDebug = imgui.new.bool(false)

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

-- Detect nearby message type: "IC", "ACT" (/me), or "DO" (/do)
local function detectNearbyType(message, playerName)
    if not message or message == "" then return "IC" end
    if not playerName then return "IC" end

    -- /me format: "* PlayerName ..." (name at front after "* ")
    if message:sub(1, 2) == "* " then
        local afterStar = message:sub(3)
        if afterStar:sub(1, #playerName) == playerName then
            return "ACT"
        end
        -- /do format: "* ... PlayerName" (name at end)
        if afterStar:sub(-#playerName) == playerName then
            return "DO"
        end
        -- Starts with * but can't determine — default ACT
        return "ACT"
    end

    return "IC"
end

-- Nearby category colors
local nearbyPrefixes = {
    IC  = nil,           -- no prefix for normal chat
    ACT = "[ACT] ",
    ME  = "[ME] ",
    DO  = "[DO] "
}
local nearbyPrefixColors = {
    ACT = imgui.ImVec4(0.8, 0.4, 0.9, 1.0),    -- purple
    ME  = imgui.ImVec4(0.8, 0.4, 0.9, 1.0),    -- purple
    DO  = imgui.ImVec4(0.4, 0.8, 1.0, 1.0)      -- light blue
}

-- Add message to nearby buffer
local function addNearbyMessage(playerId, message, color)
    local playerName = nil
    pcall(function()
        playerName = sampGetPlayerNickname(playerId)
    end)

    local nearbyType = detectNearbyType(message, playerName)

    local formatted = ""
    if playerName then
        formatted = playerName .. " (" .. playerId .. "): " .. message
    else
        formatted = "ID " .. playerId .. ": " .. message
    end

    local timestamp = os.date('[%H:%M]')

    local entry = {
        text = formatted,
        timestamp = timestamp,
        color = color,
        playerId = playerId,
        playerName = playerName,
        nearbyType = nearbyType
    }

    nearbyMessages[#nearbyMessages + 1] = entry

    -- Limit buffer size
    if #nearbyMessages > MAX_NEARBY_MESSAGES then
        table.remove(nearbyMessages, 1)
    end

    if cfgDebug[0] then
        sampAddChatMessage("{00FF00}[CE Debug] Nearby [" .. nearbyType .. "]: " .. (playerName or "?") .. " (ID:" .. playerId .. "): " .. message:sub(1, 30), -1)
    end
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

-- Track nearby message count for auto-hide in NEARBY mode
local lastNearbyCount = 0

-- Check for new messages (respects active mode for auto-hide)
local function checkNewMessages()
    if not chatlib then return end

    local currentCount = chatlib.getInsertionCount()
    local currentNearbyCount = #nearbyMessages

    if chatMode == "NEWEST" then
        -- Auto-hide reacts to all messages
        if currentCount > lastInsertionCount then
            lastInsertionCount = currentCount
            shouldAutoScroll = true
            onNewMessage()
        end
    else
        -- NEARBY mode: auto-hide only reacts to nearby messages
        if currentNearbyCount > lastNearbyCount then
            shouldAutoScroll = true
            onNewMessage()
        end
        -- Still track main buffer (for scroll when switching back)
        lastInsertionCount = currentCount
    end

    lastNearbyCount = currentNearbyCount
end

-- ============================================================================
-- SAMP.EVENTS HOOKS
-- ============================================================================
if sampev_loaded then
    function sampev.onServerMessage(color, text)
        if chatInterceptEnabled and chatlib then
            chatlib.addMessage(text, color)

            -- Detect /me and /do messages → add to nearby buffer
            -- Server only sends these to nearby players, so no distance check needed
            local cleanText = text:gsub("{%x%x%x%x%x%x}", "")
            if cleanText:sub(1, 2) == "* " then
                local nearbyType = "ME"
                local afterStar = cleanText:sub(3)
                -- /do usually contains (( )) pattern
                if afterStar:find("%(%(") then
                    nearbyType = "DO"
                end

                local timestamp = os.date('[%H:%M]')
                nearbyMessages[#nearbyMessages + 1] = {
                    text = cleanText,
                    timestamp = timestamp,
                    color = color,
                    nearbyType = nearbyType
                }
                if #nearbyMessages > MAX_NEARBY_MESSAGES then
                    table.remove(nearbyMessages, 1)
                end

                if cfgDebug[0] then
                    sampAddChatMessage("{00FF00}[CE Debug] Nearby [" .. nearbyType .. "] from server: " .. cleanText:sub(1, 40), -1)
                end
            end

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
            return false
        end
    end

    -- Intercept chat bubble RPC — this gives us playerId + message + distance
    function sampev.onPlayerChatBubble(playerId, color, distance, duration, message)
        if chatInterceptEnabled then
            -- Add to nearby buffer
            addNearbyMessage(playerId, message, color)

            if cfgDebug[0] then
                sampAddChatMessage("{00FFFF}[CE Debug] onPlayerChatBubble ID:" .. playerId .. " dist:" .. string.format("%.0f", distance) .. " msg:" .. message:sub(1, 30), -1)
            end
        end
    end

    -- Intercept our own outgoing chat — add to nearby buffer too
    function sampev.onSendChat(message)
        if chatInterceptEnabled then
            local myId = nil
            local myName = nil
            pcall(function()
                local _, lid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                myId = lid
                myName = sampGetPlayerNickname(lid)
            end)
            addNearbyMessage(myId or 0, message, 0xFFFFFFFF)
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

        -- Header: "Chat Engine" text + mode indicator + separator
        imgui.TextColored(imgui.ImVec4(0.4, 0.7, 1.0, masterAlpha), "Chat Engine")
        imgui.SameLine()
        local modeIndicator = chatMode == "NEWEST" and "[NEWEST]" or "[NEARBY]"
        imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.3, masterAlpha), modeIndicator)
        imgui.Separator()

        -- Scrollable child region for messages
        imgui.BeginChild("##ChatScroll", imgui.ImVec2(0, -1), false, 0)

        -- Get messages and render
        if chatlib then
            local allMessages
            local totalMessages

            if chatMode == "NEARBY" then
                allMessages = nearbyMessages
                totalMessages = #nearbyMessages
            else
                allMessages = chatlib.getMessages()
                totalMessages = #allMessages
            end

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

                -- Category prefix (not for Server) / Nearby type prefix
                if msg.nearbyType and msg.nearbyType ~= "IC" then
                    -- Nearby mode prefix (ACT/DO)
                    local nPrefix = nearbyPrefixes[msg.nearbyType]
                    local nColor = nearbyPrefixColors[msg.nearbyType]
                    if nPrefix and nColor then
                        local pfxScreenPos = imgui.GetCursorScreenPos()
                        renderTextWithShadow(drawList, pfxScreenPos.x, pfxScreenPos.y, nPrefix, nColor.x, nColor.y, nColor.z, gradientAlpha)
                        imgui.TextColored(
                            imgui.ImVec4(nColor.x, nColor.y, nColor.z, gradientAlpha),
                            nPrefix
                        )
                        imgui.SameLine(0, 0)
                    end
                elseif msg.category and msg.category ~= "Server" then
                    -- Newest mode prefix (PM/OOC/IC/AD/ACT)
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
                    -- Fallback: plain text with shadow (used by nearby messages too)
                    local fbScreenPos = imgui.GetCursorScreenPos()
                    local displayText = msg.text or ""
                    renderTextWithShadow(drawList, fbScreenPos.x, fbScreenPos.y, displayText, 1, 1, 1, gradientAlpha)
                    imgui.TextColored(
                        imgui.ImVec4(1.0, 1.0, 1.0, gradientAlpha),
                        displayText
                    )
                end
            end

            -- Auto-scroll to bottom when new messages arrive
            if shouldAutoScroll then
                imgui.SetScrollHereY(1.0)
                shouldAutoScroll = false
            end
        end

        imgui.EndChild()

        -- Reset font scale
        imgui.SetWindowFontScale(1.0)

        imgui.End()
        imgui.PopStyleColor(5)
        imgui.PopStyleVar(3)
    end
)

-- ============================================================================
-- MODE TOGGLE BUTTON (floating, bottom-right corner)
-- ============================================================================
imgui.OnFrame(
    function()
        return chatInterceptEnabled
    end,
    function(self)
        self.HideCursor = false

        local sw, sh = getScreenResolution()
        local btnW = 120 * DPI_SCALE
        local btnH = 40 * DPI_SCALE
        local margin = 10 * DPI_SCALE

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8 * DPI_SCALE)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(4 * DPI_SCALE, 4 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.09, 0.14, 0.9))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.2, 0.35, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.35, 0.55, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.4, 0.8, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2(sw - btnW - margin, sh - btnH - margin - 50 * DPI_SCALE), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(btnW, btnH))

        local flags = imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoScrollbar

        imgui.Begin("##ChatModeToggle", nil, flags)

        local modeLabel = chatMode == "NEWEST" and "NEWEST" or "NEARBY"
        if imgui.Button(modeLabel, imgui.ImVec2(-1, -1)) then
            if chatMode == "NEWEST" then
                chatMode = "NEARBY"
            else
                chatMode = "NEWEST"
            end
        end

        imgui.End()
        imgui.PopStyleColor(4)
        imgui.PopStyleVar(2)
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

        -- Debug
        imgui.TextColored(imgui.ImVec4(1, 0.5, 0.2, 1), "DEBUG")
        imgui.Spacing()

        local debugLabel = cfgDebug[0] and "[ON] Debug Nearby" or "[OFF] Debug Nearby"
        if imgui.Button(debugLabel, imgui.ImVec2(-1, 30 * DPI_SCALE)) then
            cfgDebug[0] = not cfgDebug[0]
        end

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
