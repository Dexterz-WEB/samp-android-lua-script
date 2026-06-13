-- ============================================================================
-- CHAT ENGINE v2.0 - Style 4: Bottom Fade Gradient + Auto-hide
-- Pure floating text with gradient opacity, colored accent bars, auto-hide
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

-- Max visible messages
local MAX_VISIBLE_MESSAGES = 15

-- Config panel state
local showConfigWindow = imgui.new.bool(false)

-- Config imgui bindings
local cfgFontSize = imgui.new.float(iniData.Settings.fontSize or 14)
local cfgAutoHide = imgui.new.float(iniData.Settings.autoHideDelay or 10)
local cfgEnabled = imgui.new.bool(iniData.Settings.enabled ~= false)
local cfgTimestamp = imgui.new.bool(iniData.Settings.showTimestamp ~= false)
local cfgAccentBar = imgui.new.bool(iniData.Settings.showAccentBar ~= false)

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
            return false
        end
    end
end

-- ============================================================================
-- CHAT WINDOW (imgui.OnFrame) - Style 4: Floating text with gradient
-- ============================================================================
imgui.OnFrame(
    function()
        -- Always run detection and state update every frame regardless of visibility.
        -- Returning true unconditionally ensures MonetLoader never skips evaluation,
        -- so messages arriving in HIDDEN state are never missed.
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

        local posX = 10 * DPI_SCALE
        local posY = 10 * DPI_SCALE

        -- Calculate window size based on screen width (responsive)
        local sw, _ = getScreenResolution()
        local lineHeight = (cfgFontSize[0] + 4) * DPI_SCALE
        local winW = sw * 0.5
        local winH = (MAX_VISIBLE_MESSAGES + 2) * lineHeight + 20 * DPI_SCALE

        -- Push invisible window styles (no background, no border)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(4 * DPI_SCALE, 4 * DPI_SCALE))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2 * DPI_SCALE, 2 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        local flags = imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoScrollbar
            + imgui.WindowFlags.NoInputs
            + imgui.WindowFlags.NoBackground

        imgui.Begin("##ChatEngineFloating", nil, flags)

        -- Apply font size scaling
        imgui.SetWindowFontScale(cfgFontSize[0] / 14.0)

        -- CE badge (tiny, semi-transparent)
        imgui.TextColored(imgui.ImVec4(0.5, 0.7, 0.9, 0.3 * masterAlpha), "CE")

        -- Get messages
        if chatlib then
            local allMessages = chatlib.getMessages()

            -- Get last MAX_VISIBLE_MESSAGES
            local startIdx = #allMessages - MAX_VISIBLE_MESSAGES + 1
            if startIdx < 1 then startIdx = 1 end
            local visibleMessages = {}
            for i = startIdx, #allMessages do
                visibleMessages[#visibleMessages + 1] = allMessages[i]
            end

            local totalVisible = #visibleMessages
            local drawList = imgui.GetWindowDrawList()
            local windowPos = imgui.GetWindowPos()

            for idx = 1, totalVisible do
                local msg = visibleMessages[idx]

                -- Gradient opacity: older (top) = transparent, newer (bottom) = solid
                -- Floor at 0.15 so oldest message remains readable (~15% minimum)
                local gradientAlpha = masterAlpha * math.max(0.15, idx / totalVisible)

                -- Get cursor position for this line
                local cursorPos = imgui.GetCursorPos()
                local screenX = windowPos.x + cursorPos.x
                local screenY = windowPos.y + cursorPos.y

                -- Draw accent bar (thin colored bar on the left)
                if cfgAccentBar[0] and msg.category then
                    local barColor = categoryColors[msg.category]
                    if barColor and msg.category ~= "Server" then
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
                imgui.SetCursorPosX(cursorPos.x + textOffsetX)

                -- Timestamp [HH:MM]
                if cfgTimestamp[0] and msg.timestamp then
                    imgui.TextColored(
                        imgui.ImVec4(0.5, 0.5, 0.6, gradientAlpha * 0.7),
                        msg.timestamp
                    )
                    imgui.SameLine(0, 4 * DPI_SCALE)
                end

                -- Category prefix
                if msg.category and msg.category ~= "Server" then
                    local catColor = categoryColors[msg.category]
                    local catPrefix = categoryPrefixes[msg.category]
                    if catColor and catPrefix then
                        imgui.TextColored(
                            imgui.ImVec4(catColor[1], catColor[2], catColor[3], gradientAlpha),
                            catPrefix
                        )
                        imgui.SameLine(0, 0)
                    end
                end

                -- Render message text with color segments
                if msg.parsed_segments and #msg.parsed_segments > 0 then
                    for j = 1, #msg.parsed_segments do
                        local seg = msg.parsed_segments[j]
                        if j > 1 then
                            imgui.SameLine(0, 0)
                        end
                        imgui.TextColored(
                            imgui.ImVec4(seg.r, seg.g, seg.b, gradientAlpha),
                            seg.text
                        )
                    end
                else
                    -- Fallback: plain text
                    imgui.TextColored(
                        imgui.ImVec4(0.9, 0.9, 0.9, gradientAlpha),
                        msg.text or ""
                    )
                end
            end
        end

        -- Reset font scale
        imgui.SetWindowFontScale(1.0)

        imgui.End()
        imgui.PopStyleColor(2)
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
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "v2.0")
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

    -- Add startup message to custom chat buffer
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
