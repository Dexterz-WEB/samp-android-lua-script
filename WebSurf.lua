-- ============================================================================
-- WEBSURF v1.0
-- In-game Web Browser for SA-MP Android (MonetLoader)
-- Uses custom WebView library via JNI bridge
-- Author: OnlyDexterZ
-- ============================================================================

script_name("WebSurf")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local ffi = require 'ffi'
local imgui = require 'mimgui'
local jsoncfg = require 'jsoncfg'
local webview = require 'lib.webviews.init'

-- ============================================================================
-- DPI SCALING
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0

-- ============================================================================
-- CONFIG
-- ============================================================================
local defaultConfig = {
    homepage = "https://www.google.com",
    webWidth = 550,
    webHeight = 450,
    clickable = true,
    bookmarks = {
        { name = "Google", url = "https://www.google.com" },
        { name = "YouTube", url = "https://m.youtube.com" },
        { name = "Spotify", url = "https://open.spotify.com" },
        { name = "TikTok", url = "https://www.tiktok.com" },
        { name = "Reddit", url = "https://www.reddit.com" },
        { name = "Wikipedia", url = "https://id.m.wikipedia.org" },
    },
}

local config = jsoncfg.load(defaultConfig, "WebSurf")

local function saveConfig()
    jsoncfg.save(config, "WebSurf")
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local showPanel = false
local browserCreated = false
local browserID = "websurf_main"

-- Input buffers for imgui
local addressBuffer = imgui.new.char[512](config.homepage)
local widthFloat = imgui.new.float(config.webWidth)
local heightFloat = imgui.new.float(config.webHeight)

-- ============================================================================
-- BROWSER HELPERS
-- ============================================================================

local function ensureBrowserExists()
    if not browserCreated then
        local ok = webview.create(browserID, config.homepage)
        if ok then
            browserCreated = true
            webview.setSize(browserID, config.webWidth, config.webHeight)
            webview.setClickable(browserID, config.clickable)
        end
    end
end

local function navigateToUrl(url)
    -- Add https:// if no protocol specified
    if not url:match("^https?://") then
        url = "https://" .. url
    end
    ensureBrowserExists()
    webview.setUrl(browserID, url)
    -- Update address bar buffer
    ffi.copy(addressBuffer, url)
end

local function destroyBrowser()
    if browserCreated then
        webview.destroy(browserID)
        browserCreated = false
    end
end

-- ============================================================================
-- IMGUI CONTROL PANEL
-- ============================================================================
imgui.OnFrame(
    function() return showPanel end,
    function(self)
        self.HideCursor = false

        local io = imgui.GetIO()
        local screenW = io.DisplaySize.x
        local screenH = io.DisplaySize.y
        local winW = 360
        local winH = 520

        -- Push dark theme styles
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(14, 12))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.09, 0.96))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.13, 0.13, 0.18, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.18, 0.18, 0.26, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.26, 0.26, 0.4, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
        imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(0.4, 0.7, 1.0, 1.0))
        imgui.PushStyleColor(imgui.Col.Header, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0.3, 0.3, 0.45, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2((screenW - winW) / 2, (screenH - winH) / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))

        if imgui.Begin("WebSurf", nil,
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoCollapse +
            imgui.WindowFlags.NoSavedSettings) then

            -- ================================================================
            -- TITLE
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.2, 0.8, 1.0, 1.0), "WEBSURF")
            imgui.SameLine()
            imgui.TextDisabled("v1.0 Browser")
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- ================================================================
            -- ADDRESS BAR + GO BUTTON
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "ADDRESS")
            imgui.Spacing()

            imgui.SetNextItemWidth(imgui.GetContentRegionAvail().x - 55)
            imgui.InputText("##url", addressBuffer, ffi.sizeof(addressBuffer))
            imgui.SameLine()

            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1, 0.5, 0.8, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.6, 0.9, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.4, 0.7, 1.0))
            if imgui.Button("GO", imgui.ImVec2(45, 0)) then
                local url = ffi.string(addressBuffer)
                if url ~= "" then
                    navigateToUrl(url)
                end
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()

            -- ================================================================
            -- NAVIGATION BUTTONS
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "NAVIGATION")
            imgui.Spacing()

            local navBtnW = (imgui.GetContentRegionAvail().x - 24) / 4

            if imgui.Button("Back", imgui.ImVec2(navBtnW, 30)) then
                if browserCreated then
                    webview.goBack(browserID)
                end
            end
            imgui.SameLine()

            if imgui.Button("Forward", imgui.ImVec2(navBtnW, 30)) then
                if browserCreated then
                    webview.goForward(browserID)
                end
            end
            imgui.SameLine()

            if imgui.Button("Refresh", imgui.ImVec2(navBtnW, 30)) then
                if browserCreated then
                    webview.reload(browserID)
                end
            end
            imgui.SameLine()

            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1, 0.5, 0.3, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.6, 0.4, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.08, 0.4, 0.25, 1.0))
            if imgui.Button("Home", imgui.ImVec2(navBtnW, 30)) then
                navigateToUrl(config.homepage)
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- ================================================================
            -- QUICK LINKS GRID
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "QUICK LINKS")
            imgui.Spacing()

            local gridCols = 3
            local gridBtnW = (imgui.GetContentRegionAvail().x - (gridCols - 1) * 8) / gridCols

            for i, bookmark in ipairs(config.bookmarks) do
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.12, 0.12, 0.2, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.3, 0.5, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
                if imgui.Button(bookmark.name, imgui.ImVec2(gridBtnW, 32)) then
                    navigateToUrl(bookmark.url)
                end
                imgui.PopStyleColor(3)

                -- Add SameLine for grid layout (3 columns)
                if i % gridCols ~= 0 and i < #config.bookmarks then
                    imgui.SameLine()
                end
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- ================================================================
            -- SIZE CONTROLS
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "SIZE")
            imgui.Spacing()

            imgui.Text("Width:")
            imgui.SetNextItemWidth(-1)
            widthFloat[0] = config.webWidth
            if imgui.SliderFloat("##width", widthFloat, 200, 1200, "%.0f") then
                config.webWidth = math.floor(widthFloat[0])
                if browserCreated then
                    webview.setSize(browserID, config.webWidth, config.webHeight)
                end
            end

            imgui.Text("Height:")
            imgui.SetNextItemWidth(-1)
            heightFloat[0] = config.webHeight
            if imgui.SliderFloat("##height", heightFloat, 150, 900, "%.0f") then
                config.webHeight = math.floor(heightFloat[0])
                if browserCreated then
                    webview.setSize(browserID, config.webWidth, config.webHeight)
                end
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- ================================================================
            -- CLICKABLE TOGGLE (Button, not Checkbox)
            -- ================================================================
            imgui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "INTERACTION")
            imgui.Spacing()

            if config.clickable then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1, 0.6, 0.3, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.7, 0.4, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.1, 0.5, 0.25, 1.0))
                if imgui.Button("Touch: ENABLED", imgui.ImVec2(-1, 30)) then
                    config.clickable = false
                    saveConfig()
                    if browserCreated then
                        webview.setClickable(browserID, false)
                    end
                end
                imgui.PopStyleColor(3)
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.6, 0.15, 0.15, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.7, 0.2, 0.2, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0.1, 0.1, 1.0))
                if imgui.Button("Touch: DISABLED", imgui.ImVec2(-1, 30)) then
                    config.clickable = true
                    saveConfig()
                    if browserCreated then
                        webview.setClickable(browserID, true)
                    end
                end
                imgui.PopStyleColor(3)
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- ================================================================
            -- SAVE & CLOSE
            -- ================================================================
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.15, 0.15, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.6, 0.2, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.4, 0.1, 0.1, 1.0))
            if imgui.Button("CLOSE PANEL", imgui.ImVec2(-1, 35)) then
                saveConfig()
                showPanel = false
                -- Auto-hide webview when panel is closed
                if browserCreated then
                    webview.setVisible(browserID, false)
                end
            end
            imgui.PopStyleColor(3)
        end
        imgui.End()
        imgui.PopStyleColor(9)
        imgui.PopStyleVar(4)
    end
)

-- ============================================================================
-- COMMAND HANDLER
-- ============================================================================
local function handleCommand(args)
    if args == "" or args == nil then
        -- Toggle panel visibility
        showPanel = not showPanel
        if showPanel then
            -- Auto-show webview when panel opens
            if browserCreated then
                webview.setVisible(browserID, true)
            end
        else
            -- Auto-hide webview when panel closes
            if browserCreated then
                webview.setVisible(browserID, false)
            end
        end
    else
        -- Open specific URL
        showPanel = true
        navigateToUrl(args)
        if browserCreated then
            webview.setVisible(browserID, true)
        end
    end
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    -- Wait for SA-MP to be available
    while not isSampAvailable() do wait(100) end

    -- Register chat command
    sampRegisterChatCommand("web", handleCommand)

    -- Show loaded message
    sampAddChatMessage("{33CCFF}[WebSurf]{FFFFFF} v1.0 Loaded! Use /web to open browser panel", 0xFFFFFF)

    -- Main loop
    while true do
        wait(100)
    end
end
