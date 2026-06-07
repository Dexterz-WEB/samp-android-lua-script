-- ============================================================================
-- MINIMAP HUD v1.0
-- Custom minimap with full map overlay for SA-MP Android
-- ============================================================================

script_name("MinimapHUD")
script_author("OnlyDexterZ")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'
local inicfg = require 'inicfg'

-- ============================================================================
-- CONFIG
-- ============================================================================
local iniFileName = "MinimapHUDConfig.ini"

local defaultConfig = {
    Settings = {
        minimapEnabled = true,
        radarDisabled = true,
        posX = 20.0,
        posY = 500.0,
        size = 200.0,
        opacity = 0.85,
        arrowSize = 24.0,
        zoomLevel = 0.05,
    },
}

local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end
if not iniData.Settings then iniData.Settings = defaultConfig.Settings end
for k, v in pairs(defaultConfig.Settings) do
    if iniData.Settings[k] == nil then iniData.Settings[k] = v end
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local showConfigWindow = imgui.new.bool(false)
local fullMapMode = false

-- Textures
local mapTexture = nil
local arrowTexture = nil

-- Config sliders
local cfgEnabled = imgui.new.bool(iniData.Settings.minimapEnabled)
local cfgRadarOff = imgui.new.bool(iniData.Settings.radarDisabled)
local cfgPosX = imgui.new.float(iniData.Settings.posX)
local cfgPosY = imgui.new.float(iniData.Settings.posY)
local cfgSize = imgui.new.float(iniData.Settings.size)
local cfgOpacity = imgui.new.float(iniData.Settings.opacity)
local cfgArrowSize = imgui.new.float(iniData.Settings.arrowSize)
local cfgZoom = imgui.new.float(iniData.Settings.zoomLevel)

-- Full map state
local fullMapOffsetX = 0
local fullMapOffsetY = 0
local fullMapZoom = 1.0
local fullMapDragging = false
local fullMapLastX = 0
local fullMapLastY = 0
local fullMapOpenTime = 0

-- Pinch zoom state
local fullMapPinching = false
local fullMapPinchDist = 0

-- Focus player state
local fullMapFocusPlayer = false
local fullMapFocusBtnLastClick = 0

-- Player cached data
local cachedPlayerX = 0
local cachedPlayerY = 0
local cachedPlayerZ = 0
local cachedHeading = 0

-- ============================================================================
-- TEXTURE LOADING
-- ============================================================================
imgui.OnInitialize(function()
    pcall(function()
        mapTexture = imgui.CreateTextureFromFile("testing/map.png")
    end)
    pcall(function()
        arrowTexture = imgui.CreateTextureFromFile("testing/arrow.png")
    end)
end)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function getPlayerData()
    local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
    if ok and x then
        cachedPlayerX = x
        cachedPlayerY = y
        cachedPlayerZ = z
    end
    local ok2, h = pcall(getCharHeading, PLAYER_PED)
    if ok2 and h then
        cachedHeading = h
    end
end

local function worldToUV(wx, wy)
    local uvx = (wx + 3000) / 6000
    local uvy = 1.0 - (wy + 3000) / 6000
    return uvx, uvy
end

local function drawRotatedImage(draw_list, texture, cx, cy, size, angle, color)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    local half = size / 2
    local p1 = imgui.ImVec2(cx + (-half * cos_a - (-half) * sin_a), cy + (-half * sin_a + (-half) * cos_a))
    local p2 = imgui.ImVec2(cx + (half * cos_a - (-half) * sin_a), cy + (half * sin_a + (-half) * cos_a))
    local p3 = imgui.ImVec2(cx + (half * cos_a - half * sin_a), cy + (half * sin_a + half * cos_a))
    local p4 = imgui.ImVec2(cx + (-half * cos_a - half * sin_a), cy + (-half * sin_a + half * cos_a))
    draw_list:AddImageQuad(texture, p1, p2, p3, p4,
        imgui.ImVec2(0, 0), imgui.ImVec2(1, 0), imgui.ImVec2(1, 1), imgui.ImVec2(0, 1), color)
end

local function isPointInCircle(px, py, cx, cy, r)
    local dx = px - cx
    local dy = py - cy
    return (dx * dx + dy * dy) <= (r * r)
end

local function saveConfig()
    iniData.Settings.minimapEnabled = cfgEnabled[0]
    iniData.Settings.radarDisabled = cfgRadarOff[0]
    iniData.Settings.posX = cfgPosX[0]
    iniData.Settings.posY = cfgPosY[0]
    iniData.Settings.size = cfgSize[0]
    iniData.Settings.opacity = cfgOpacity[0]
    iniData.Settings.arrowSize = cfgArrowSize[0]
    iniData.Settings.zoomLevel = cfgZoom[0]
    if inicfg.save(iniData, iniFileName) then
        sampAddChatMessage("{00FF00}[MinimapHUD] {FFFFFF}Configuration saved!", -1)
    else
        sampAddChatMessage("{FF0000}[MinimapHUD] {FFFFFF}Failed to save config!", -1)
    end
end

-- ============================================================================
-- MINIMAP RENDERING
-- ============================================================================
local function drawMinimap(draw_list)
    if not mapTexture then return end
    if not cfgEnabled[0] then return end

    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end

    getPlayerData()

    local mapSize = cfgSize[0]
    local posX = cfgPosX[0]
    local posY = cfgPosY[0]
    local opacity = cfgOpacity[0]
    local zoom = cfgZoom[0]
    local arrowSz = cfgArrowSize[0]

    local centerX = posX + mapSize / 2
    local centerY = posY + mapSize / 2
    local radius = mapSize / 2

    -- Calculate UV based on player position
    local uvCenterX, uvCenterY = worldToUV(cachedPlayerX, cachedPlayerY)

    -- UV crop area
    local uvHalf = zoom
    local uvMinX = clamp(uvCenterX - uvHalf, 0, 1)
    local uvMinY = clamp(uvCenterY - uvHalf, 0, 1)
    local uvMaxX = clamp(uvCenterX + uvHalf, 0, 1)
    local uvMaxY = clamp(uvCenterY + uvHalf, 0, 1)

    -- Draw circular minimap using AddImageRounded
    local colorU32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, opacity))
    local pMin = imgui.ImVec2(posX, posY)
    local pMax = imgui.ImVec2(posX + mapSize, posY + mapSize)
    local uvMin = imgui.ImVec2(uvMinX, uvMinY)
    local uvMax = imgui.ImVec2(uvMaxX, uvMaxY)

    draw_list:AddImageRounded(mapTexture, pMin, pMax, uvMin, uvMax, colorU32, radius, 15)

    -- Draw player arrow in center (rotated by heading)
    if arrowTexture then
        local headingRad = -math.rad(cachedHeading)
        local arrowColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, opacity))
        drawRotatedImage(draw_list, arrowTexture, centerX, centerY, arrowSz, headingRad, arrowColor)
    end

    -- Tap detection for opening full map
    local io = imgui.GetIO()
    if imgui.IsMouseClicked(0) then
        local mx = io.MousePos.x
        local my = io.MousePos.y
        if isPointInCircle(mx, my, centerX, centerY, radius) then
            fullMapMode = true
            fullMapOffsetX = 0
            fullMapOffsetY = 0
            fullMapZoom = 1.0
            fullMapDragging = false
            fullMapFocusPlayer = false
            fullMapOpenTime = os.clock()
        end
    end
end

-- ============================================================================
-- FULL MAP RENDERING
-- ============================================================================
local function drawFullMap(draw_list)
    if not mapTexture then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = getScreenResolution() end)
    if sw == 0 or sh == 0 then sw, sh = 1280, 720 end

    -- Fullscreen window to block GTA SA camera/touch input
    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    imgui.Begin('##FullMapOverlay', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoBackground)
    imgui.End()

    local io = imgui.GetIO()
    local mx = io.MousePos.x
    local my = io.MousePos.y

    -- Background overlay
    draw_list:AddRectFilled(
        imgui.ImVec2(0, 0),
        imgui.ImVec2(sw, sh),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 0.7))
    )

    -- Get player UV position
    getPlayerData()
    local playerUVX, playerUVY = worldToUV(cachedPlayerX, cachedPlayerY)

    -- Calculate map display area (at zoom 1.0, map fits screen)
    local baseSize = math.min(sw, sh) * 0.9
    local mapDisplaySize = baseSize * fullMapZoom

    local mapX, mapY

    if fullMapFocusPlayer then
        -- Focus mode: center map on player position
        local playerScreenX = sw / 2 - playerUVX * mapDisplaySize
        local playerScreenY = sh / 2 - playerUVY * mapDisplaySize
        mapX = playerScreenX + fullMapOffsetX
        mapY = playerScreenY + fullMapOffsetY
    else
        -- Default centered mode: center map on screen, then apply drag offset
        mapX = (sw - mapDisplaySize) / 2 + fullMapOffsetX
        mapY = (sh - mapDisplaySize) / 2 + fullMapOffsetY
    end

    -- Drag limits: map edges cannot go past screen edges
    if mapDisplaySize <= sw then
        mapX = (sw - mapDisplaySize) / 2
        if not fullMapFocusPlayer then
            fullMapOffsetX = 0
        end
    else
        if mapX > 0 then
            mapX = 0
            if fullMapFocusPlayer then
                fullMapOffsetX = mapX - (sw / 2 - playerUVX * mapDisplaySize)
            else
                fullMapOffsetX = mapX - (sw - mapDisplaySize) / 2
            end
        end
        if mapX + mapDisplaySize < sw then
            mapX = sw - mapDisplaySize
            if fullMapFocusPlayer then
                fullMapOffsetX = mapX - (sw / 2 - playerUVX * mapDisplaySize)
            else
                fullMapOffsetX = mapX - (sw - mapDisplaySize) / 2
            end
        end
    end

    if mapDisplaySize <= sh then
        mapY = (sh - mapDisplaySize) / 2
        if not fullMapFocusPlayer then
            fullMapOffsetY = 0
        end
    else
        if mapY > 0 then
            mapY = 0
            if fullMapFocusPlayer then
                fullMapOffsetY = mapY - (sh / 2 - playerUVY * mapDisplaySize)
            else
                fullMapOffsetY = mapY - (sh - mapDisplaySize) / 2
            end
        end
        if mapY + mapDisplaySize < sh then
            mapY = sh - mapDisplaySize
            if fullMapFocusPlayer then
                fullMapOffsetY = mapY - (sh / 2 - playerUVY * mapDisplaySize)
            else
                fullMapOffsetY = mapY - (sh - mapDisplaySize) / 2
            end
        end
    end

    -- Draw the full map
    local pMin = imgui.ImVec2(mapX, mapY)
    local pMax = imgui.ImVec2(mapX + mapDisplaySize, mapY + mapDisplaySize)
    local colorU32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.95))
    draw_list:AddImage(mapTexture, pMin, pMax, imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), colorU32)

    -- Draw player arrow on full map
    if arrowTexture then
        local playerMapX = mapX + playerUVX * mapDisplaySize
        local playerMapY = mapY + playerUVY * mapDisplaySize
        local headingRad = -math.rad(cachedHeading)
        local arrowSz = 28
        local arrowColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1))
        drawRotatedImage(draw_list, arrowTexture, playerMapX, playerMapY, arrowSz, headingRad, arrowColor)
    end

    -- Handle drag (touch hold and move)
    if imgui.IsMouseDown(0) then
        if not fullMapDragging then
            fullMapDragging = true
            fullMapLastX = mx
            fullMapLastY = my
        else
            local dx = mx - fullMapLastX
            local dy = my - fullMapLastY
            fullMapOffsetX = fullMapOffsetX + dx
            fullMapOffsetY = fullMapOffsetY + dy
            fullMapLastX = mx
            fullMapLastY = my
        end
    else
        fullMapDragging = false
        -- In focus mode, reset offset every frame so map snaps back to player
        if fullMapFocusPlayer then
            fullMapOffsetX = 0
            fullMapOffsetY = 0
        end
    end

    -- Zoom controls (draw +/- buttons)
    local btnSize = 50
    local zoomInPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 - btnSize - 10)
    local zoomOutPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 + 10)

    -- Zoom In button
    draw_list:AddRectFilled(zoomInPos, imgui.ImVec2(zoomInPos.x + btnSize, zoomInPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local plusSize = imgui.CalcTextSize("+")
    draw_list:AddText(imgui.ImVec2(zoomInPos.x + (btnSize - plusSize.x) / 2, zoomInPos.y + (btnSize - plusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "+")

    -- Zoom Out button
    draw_list:AddRectFilled(zoomOutPos, imgui.ImVec2(zoomOutPos.x + btnSize, zoomOutPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local minusSize = imgui.CalcTextSize("-")
    draw_list:AddText(imgui.ImVec2(zoomOutPos.x + (btnSize - minusSize.x) / 2, zoomOutPos.y + (btnSize - minusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "-")

    -- Close button (top-right)
    local closeBtnPos = imgui.ImVec2(sw - btnSize - 20, 20)
    draw_list:AddRectFilled(closeBtnPos, imgui.ImVec2(closeBtnPos.x + btnSize, closeBtnPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.1, 0.1, 0.9)), 8)
    local xSize = imgui.CalcTextSize("X")
    draw_list:AddText(imgui.ImVec2(closeBtnPos.x + (btnSize - xSize.x) / 2, closeBtnPos.y + (btnSize - xSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "X")

    -- Focus Player button (below zoom buttons, right side)
    local focusBtnPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 + btnSize + 30)
    local focusBtnColor
    if fullMapFocusPlayer then
        focusBtnColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.7, 0.2, 0.9))
    else
        focusBtnColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.3, 0.3, 0.9))
    end
    draw_list:AddRectFilled(focusBtnPos, imgui.ImVec2(focusBtnPos.x + btnSize, focusBtnPos.y + btnSize),
        focusBtnColor, 8)
    local focusText = "F"
    local fSize = imgui.CalcTextSize(focusText)
    draw_list:AddText(imgui.ImVec2(focusBtnPos.x + (btnSize - fSize.x) / 2, focusBtnPos.y + (btnSize - fSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), focusText)

    -- Handle tap for buttons (X button, zoom, and focus)
    local mapCooldown = (os.clock() - fullMapOpenTime) > 0.3
    if imgui.IsMouseClicked(0) and mapCooldown then
        -- Focus Player button
        local focusCooldown = (os.clock() - fullMapFocusBtnLastClick) > 0.5
        if mx >= focusBtnPos.x and mx <= focusBtnPos.x + btnSize and my >= focusBtnPos.y and my <= focusBtnPos.y + btnSize and focusCooldown then
            fullMapFocusBtnLastClick = os.clock()
            fullMapFocusPlayer = not fullMapFocusPlayer
            if fullMapFocusPlayer then
                -- Activate focus mode: zoom to 2.0 and reset offset
                fullMapZoom = 2.0
                fullMapOffsetX = 0
                fullMapOffsetY = 0
            else
                -- Deactivate focus mode: keep current zoom, reset offset for centered mode
                fullMapOffsetX = 0
                fullMapOffsetY = 0
            end
            return
        end
        -- Zoom In
        if mx >= zoomInPos.x and mx <= zoomInPos.x + btnSize and my >= zoomInPos.y and my <= zoomInPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom + 0.3, 0.5, 5.0)
            return
        end
        -- Zoom Out
        if mx >= zoomOutPos.x and mx <= zoomOutPos.x + btnSize and my >= zoomOutPos.y and my <= zoomOutPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom - 0.3, 0.5, 5.0)
            return
        end
        -- Close button (X only)
        if mx >= closeBtnPos.x and mx <= closeBtnPos.x + btnSize and my >= closeBtnPos.y and my <= closeBtnPos.y + btnSize then
            fullMapMode = false
            return
        end
    end
end

-- ============================================================================
-- CONFIG WINDOW
-- ============================================================================
local function drawConfigWindow()
    if not showConfigWindow[0] then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = getScreenResolution() end)
    if sw == 0 or sh == 0 then sw, sh = 1280, 720 end

    local winW = 450
    local winH = 420

    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
    imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
    imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.3, 0.8, 0.4, 1.0))

    imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))
    imgui.Begin("MinimapHUD Config", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

    -- Title
    imgui.TextColored(imgui.ImVec4(0.3, 0.8, 1.0, 1.0), "MINIMAP HUD CONFIG")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Toggles
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "TOGGLES")
    imgui.Spacing()
    imgui.Checkbox("Enable Minimap", cfgEnabled)
    imgui.Checkbox("Disable Built-in Radar", cfgRadarOff)
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Position
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "POSITION")
    imgui.Spacing()
    imgui.Text("Position X:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##posX", cfgPosX, 0, sw - cfgSize[0], "%.0f")
    imgui.Text("Position Y:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##posY", cfgPosY, 0, sh - cfgSize[0], "%.0f")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Appearance
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "APPEARANCE")
    imgui.Spacing()
    imgui.Text("Minimap Size:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##size", cfgSize, 100, 400, "%.0f")
    imgui.Text("Opacity:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##opacity", cfgOpacity, 0.2, 1.0, "%.2f")
    imgui.Text("Arrow Size:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##arrowSize", cfgArrowSize, 12, 64, "%.0f")
    imgui.Text("Zoom Level:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##zoom", cfgZoom, 0.01, 0.2, "%.3f")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Buttons
    if imgui.Button("SAVE", imgui.ImVec2((winW - 40) / 2, 35)) then
        saveConfig()
        showConfigWindow[0] = false
    end
    imgui.SameLine()
    if imgui.Button("CLOSE", imgui.ImVec2((winW - 40) / 2, 35)) then
        showConfigWindow[0] = false
    end

    imgui.End()

    imgui.PopStyleColor(7)
    imgui.PopStyleVar(4)
end

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[MinimapHUD] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[MinimapHUD] {FFFFFF}Use {FFFF00}/mapcfg{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[MinimapHUD] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    -- Register config command
    sampRegisterChatCommand("mapcfg", function()
        showConfigWindow[0] = not showConfigWindow[0]
    end)

    -- Disable built-in radar if configured
    if cfgRadarOff[0] then
        pcall(function() displayRadar(false) end)
    end

    -- Main rendering frame
    imgui.OnFrame(function() return true end, function()
        local draw_list = imgui.GetBackgroundDrawList()

        -- Handle radar toggle
        if cfgRadarOff[0] then
            pcall(function() displayRadar(false) end)
        else
            pcall(function() displayRadar(true) end)
        end

        -- Render based on mode
        if fullMapMode then
            drawFullMap(draw_list)
        else
            drawMinimap(draw_list)
        end

        -- Config window
        drawConfigWindow()
    end)

    -- Keep script alive
    while true do
        wait(1000)
    end
end
