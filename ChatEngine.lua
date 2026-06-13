-- ============================================================================
-- CHAT ENGINE v1.0
-- Custom chat window with message filtering, auto-hide, and config panel
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
        opacity = 0.55,
        autoHideDelay = 10,
        showTimestamp = true
    }
}

local iniFileName = "ChatEngine.ini"
local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local chatInterceptEnabled = (iniData.Settings.enabled ~= false) -- Read from config at startup
local lastMessageTime = 0
local currentFilter = "All"
local showConfigWindow = imgui.new.bool(false)
local chatMinimized = false
local lastInsertionCount = 0 -- Track insertion count for auto-scroll (monotonic)
local chatForceVisible = false

-- Filter options
local filterOptions = {"All", "PM", "Server", "IC", "OOC"}

-- Config imgui bindings
local cfgFontSize = imgui.new.float(iniData.Settings.fontSize or 14)
local cfgOpacity = imgui.new.float(iniData.Settings.opacity or 0.55)
local cfgAutoHide = imgui.new.float(iniData.Settings.autoHideDelay or 10)
local cfgEnabled = imgui.new.bool(iniData.Settings.enabled ~= false)
local cfgTimestamp = imgui.new.bool(iniData.Settings.showTimestamp ~= false)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function saveConfig()
    iniData.Settings.enabled = cfgEnabled[0]
    iniData.Settings.fontSize = cfgFontSize[0]
    iniData.Settings.opacity = cfgOpacity[0]
    iniData.Settings.autoHideDelay = cfgAutoHide[0]
    iniData.Settings.showTimestamp = cfgTimestamp[0]
    -- Wire cfgEnabled toggle to runtime interception state
    chatInterceptEnabled = cfgEnabled[0]
    inicfg.save(iniData, iniFileName)
end

local function isChatVisible()
    if not chatInterceptEnabled then return false end
    -- Auto-hide disabled: chat always visible when intercept is on
    return true
end

local function calculateFadeAlpha()
    -- No fade, always full opacity
    return 1.0
end

-- Map filter name to chatlib category
-- Note: "IC" filter maps to "IC" category. Player chat from onChatMessage is
-- explicitly categorized as "IC". Ad messages appear only in "All" tab (Phase 1).
local function mapFilterToCategory(filter)
    if filter == "All" then return "All" end
    if filter == "IC" then return "IC" end
    return filter
end

-- ============================================================================
-- SAMP.EVENTS HOOKS
-- ============================================================================
if sampev_loaded then
    function sampev.onServerMessage(color, text)
        if chatInterceptEnabled and chatlib then
            chatlib.addMessage(text, color)
            lastMessageTime = os.clock()
            return false
        end
    end

    function sampev.onChatMessage(playerId, text)
        if chatInterceptEnabled and chatlib then
            -- Format player message with ID
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
            -- Pass explicit "IC" category to avoid misclassification from text patterns
            chatlib.addMessage(formatted, 0xFFFFFFFF, "IC")
            lastMessageTime = os.clock()
            return false
        end
    end
end

-- ============================================================================
-- CHAT WINDOW (imgui.OnFrame)
-- ============================================================================
imgui.OnFrame(
    function()
        return chatInterceptEnabled and isChatVisible()
    end,
    function(self)
        self.HideCursor = true

        local sw, sh = getScreenResolution()
        local opacity = cfgOpacity[0] * calculateFadeAlpha()
        if opacity <= 0.01 then return end

        local winW = sw * 0.45
        local winH = sh * 0.35
        local posX = 10 * DPI_SCALE
        local posY = 10 * DPI_SCALE

        -- Push styles
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8 * DPI_SCALE)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 4 * DPI_SCALE)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10 * DPI_SCALE, 8 * DPI_SCALE))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(6 * DPI_SCALE, 4 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.09, 0.14, 0.85))
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.06, 0.07, 0.11, 0.85))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.9, 0.9, 0.9, opacity))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.15, 0.2, opacity))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.35, opacity))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.4, 0.8, opacity))

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar
        imgui.Begin("##ChatEngineWindow", nil, flags)

        -- Apply font size scaling from config
        imgui.SetWindowFontScale(cfgFontSize[0] / 14.0)

        -- Header bar
        imgui.TextColored(imgui.ImVec4(0.2, 0.8, 0.9, 1.0), "Chat Engine")
        imgui.Spacing()
        imgui.Separator()

        -- Message area
        local headerHeight = imgui.GetCursorPosY()
        local childHeight = winH - headerHeight - 10 * DPI_SCALE
        if childHeight < 50 then childHeight = 50 end

        imgui.BeginChild("##chatmessages", imgui.ImVec2(-1, childHeight), false)

        if chatlib then
            local messages = chatlib.getMessages()

            for i = 1, #messages do
                local msg = messages[i]

                -- Timestamp
                if cfgTimestamp[0] and msg.timestamp then
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.6, opacity), msg.timestamp)
                    imgui.SameLine()
                end

                -- Category prefix with color
                if msg.category and msg.category ~= "Server" then
                    local prefixColors = {
                        PM = imgui.ImVec4(0.2, 0.9, 0.4, opacity),
                        OOC = imgui.ImVec4(0.6, 0.6, 0.6, opacity),
                        IC = imgui.ImVec4(0.9, 0.9, 1.0, opacity),
                        Ad = imgui.ImVec4(1.0, 0.85, 0.2, opacity),
                        Action = imgui.ImVec4(0.8, 0.4, 0.9, opacity)
                    }
                    local prefixLabels = {
                        PM = "[PM] ",
                        OOC = "[OOC] ",
                        IC = "[IC] ",
                        Ad = "[AD] ",
                        Action = "[ACT] "
                    }
                    local color = prefixColors[msg.category]
                    local label = prefixLabels[msg.category]
                    if color and label then
                        imgui.TextColored(color, label)
                        imgui.SameLine(0, 0)
                    end
                end

                -- Render color segments
                if msg.parsed_segments then
                    for j = 1, #msg.parsed_segments do
                        local seg = msg.parsed_segments[j]
                        if j > 1 then imgui.SameLine(0, 0) end
                        imgui.TextColored(
                            imgui.ImVec4(seg.r, seg.g, seg.b, opacity),
                            seg.text
                        )
                    end
                else
                    -- Fallback: plain text
                    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, opacity), msg.text or "")
                end
            end

            -- Bottom padding so last message isn't clipped
            imgui.Spacing()
            imgui.Spacing()
            imgui.Spacing()

            -- Auto-scroll to bottom on new messages (uses monotonic insertion count)
            local currentCount = chatlib.getInsertionCount()
            if currentCount > lastInsertionCount then
                imgui.SetScrollHereY(1.0)
                lastInsertionCount = currentCount
            end
        end

        imgui.EndChild()

        -- Reset font scale
        imgui.SetWindowFontScale(1.0)

        imgui.End()
        imgui.PopStyleColor(6)
        imgui.PopStyleVar(4)
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
        local winH = 360 * DPI_SCALE

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12 * DPI_SCALE)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6 * DPI_SCALE)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15 * DPI_SCALE, 12 * DPI_SCALE))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8 * DPI_SCALE, 6 * DPI_SCALE))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
        imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.2, 0.8, 0.4, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        imgui.Begin("ChatEngine Config", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

        -- Title
        imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.6, 1), "CHATENGINE SETTINGS")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "v1.0")
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- Toggle enabled (use Button instead of Checkbox for MonetLoader compat)
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

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- Sliders
        imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1, 1), "APPEARANCE")
        imgui.Spacing()

        imgui.Text("Font Size:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##fontSize", cfgFontSize, 10.0, 24.0, "%.0f")

        imgui.Text("Opacity:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##opacity", cfgOpacity, 0.3, 1.0, "%.2f")

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- Save button
        if imgui.Button("SAVE CONFIG", imgui.ImVec2(-1, 35 * DPI_SCALE)) then
            saveConfig()
            showConfigWindow[0] = false
        end

        imgui.End()
        imgui.PopStyleColor(8)
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

    -- Register /ceoff command: toggle interception (safety fallback)
    sampRegisterChatCommand("ceoff", function()
        chatInterceptEnabled = not chatInterceptEnabled
        if chatInterceptEnabled then
            sampAddChatMessage("{00FFFF}[ChatEngine] {FFFFFF}Chat interception: {00FF00}ON", -1)
        else
            sampAddChatMessage("{00FFFF}[ChatEngine] {FFFFFF}Chat interception: {FF0000}OFF", -1)
        end
    end)

    -- Startup message
    sampAddChatMessage("{00FFFF}[ChatEngine] {FFFFFF}Loaded! Use {FFFF00}/chatcfg{FFFFFF} to configure, {FFFF00}/ceoff{FFFFFF} to toggle.", -1)

    -- Initialize last message time
    lastMessageTime = os.clock()

    -- Keep script alive
    while true do wait(100) end
end
