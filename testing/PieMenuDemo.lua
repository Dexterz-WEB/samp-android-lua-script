-- ============================================================================
-- PIE MENU DEMO
-- Demonstrates all unique libraries working together as a modern radial/pie menu
-- Standalone test - does NOT modify RadialMenu.lua
-- Libraries: mimgui_piemenu, notifications, ease, fAwesome6, modern styling
-- ============================================================================

script_name("Pie Menu Demo")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local ease_loaded = false
local ease = nil
pcall(function()
    ease = require 'ease'
    ease_loaded = true
end)

local fa_loaded = false
local faicons = nil
pcall(function()
    faicons = require 'fAwesome6'
    fa_loaded = true
end)

local notif_loaded = false
local Notifications = nil
pcall(function()
    require 'notifications'
    Notifications = _G.Notifications
    notif_loaded = true
end)

-- ============================================================================
-- STATE
-- ============================================================================
local showPieMenu = false
local menuOpenTime = 0
local menuScale = 0
local selectedSector = -1
local lastExecuted = ""

-- Pie menu items with FontAwesome icons
local menuItems = {
    {
        icon = fa_loaded and faicons('CAR') or "[V]",
        label = "Vehicle",
        cmd = "/veh",
        color = { 0.26, 0.71, 0.81, 1.0 }
    },
    {
        icon = fa_loaded and faicons('PERSON_RUNNING') or "[A]",
        label = "Anim",
        cmd = "/anim",
        color = { 0.54, 0.36, 0.76, 1.0 }
    },
    {
        icon = fa_loaded and faicons('HEART') or "[H]",
        label = "Heal",
        cmd = "/heal",
        color = { 0.91, 0.30, 0.40, 1.0 }
    },
    {
        icon = fa_loaded and faicons('LOCK') or "[L]",
        label = "Lock",
        cmd = "/lock",
        color = { 0.26, 0.81, 0.46, 1.0 }
    },
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function getEase(easeFunc, x)
    if ease_loaded and ease and ease[easeFunc] then
        return ease[easeFunc](x)
    end
    -- Fallback: simple linear
    return x
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function togglePieMenu()
    showPieMenu = not showPieMenu
    menuOpenTime = os.clock()
end

local function executeCommand(index)
    local item = menuItems[index]
    if not item then return end

    lastExecuted = item.label .. " (" .. item.cmd .. ")"

    -- Show toast notification
    if notif_loaded and Notifications then
        Notifications.Show("Executed: " .. item.cmd, Notifications.TYPE.OK, 3)
    else
        -- Fallback to chat message
        pcall(function()
            sampAddChatMessage("{00BFFF}[PieMenu] {FFFFFF}Executed: " .. item.cmd, 0x00BFFF)
        end)
    end

    -- Execute the command
    pcall(function()
        sampSendChat(item.cmd)
    end)

    -- Close menu after executing
    showPieMenu = false
    menuOpenTime = os.clock()
end

-- ============================================================================
-- PIE MENU RENDERING
-- ============================================================================
local showTrigger = imgui.new.bool(true)

imgui.OnFrame(function() return showTrigger[0] end, function(self)
    self.HideCursor = not showPieMenu

    local sw, sh = getScreenResolution()
    local centerX = sw / 2
    local centerY = sh / 2

    -- Calculate animation scale
    local elapsed = os.clock() - menuOpenTime
    local animDuration = 0.3

    if showPieMenu then
        local t = clamp(elapsed / animDuration, 0, 1.0)
        menuScale = getEase('outCubic', t)
    else
        local t = clamp(elapsed / animDuration, 0, 1.0)
        menuScale = 1.0 - getEase('inCubic', t)
    end

    -- Clamp scale
    menuScale = clamp(menuScale, 0, 1.0)

    -- ========================================================================
    -- TRIGGER BUTTON (always visible)
    -- ========================================================================
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 25)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.12, 0.12, 0.18, 0.9))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.3, 0.6, 0.9, 0.4))

    imgui.SetNextWindowPos(imgui.ImVec2(sw - 80, sh - 80), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(50, 50), imgui.Cond.Always)
    imgui.Begin('##PieTrigger', showTrigger, imgui.WindowFlags.NoTitleBar
        + imgui.WindowFlags.NoResize
        + imgui.WindowFlags.NoScrollbar)

    local triggerIcon = fa_loaded and faicons('CIRCLE_NODES') or "[M]"
    local triggerSize = imgui.CalcTextSize(triggerIcon)
    local winSize = imgui.GetWindowSize()
    imgui.SetCursorPos(imgui.ImVec2(
        (winSize.x - triggerSize.x) / 2,
        (winSize.y - triggerSize.y) / 2
    ))
    if imgui.InvisibleButton('##triggerBtn', winSize) then
        togglePieMenu()
    end
    imgui.SetCursorPos(imgui.ImVec2(
        (winSize.x - triggerSize.x) / 2,
        (winSize.y - triggerSize.y) / 2
    ))
    imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1.0, 1.0), triggerIcon)

    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(2)

    -- ========================================================================
    -- PIE MENU (only when animating or open)
    -- ========================================================================
    if menuScale <= 0.01 and not showPieMenu then return end

    -- Full screen overlay for pie menu
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * menuScale))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    imgui.Begin('##PieOverlay', showTrigger, imgui.WindowFlags.NoTitleBar
        + imgui.WindowFlags.NoResize
        + imgui.WindowFlags.NoMove
        + imgui.WindowFlags.NoScrollbar
        + imgui.WindowFlags.NoSavedSettings)

    local draw_list = imgui.GetWindowDrawList()
    local itemCount = #menuItems
    local baseRadius = 120 * menuScale
    local sectorAngle = (2 * math.pi) / itemCount
    local startAngle = -math.pi / 2  -- Start from top

    -- Detect which sector is hovered
    local mousePos = imgui.GetIO().MousePos
    local dx = mousePos.x - centerX
    local dy = mousePos.y - centerY
    local dist = math.sqrt(dx * dx + dy * dy)
    local mouseAngle = math.atan2(dy, dx)

    -- Normalize angle to match sector calculation
    local hoveredSector = -1
    if dist > 30 * menuScale and dist < (baseRadius + 50) * menuScale then
        local normAngle = mouseAngle - startAngle
        if normAngle < 0 then normAngle = normAngle + 2 * math.pi end
        hoveredSector = math.floor(normAngle / sectorAngle) + 1
        if hoveredSector > itemCount then hoveredSector = 1 end
    end
    selectedSector = hoveredSector

    -- Draw background circle
    local bgAlpha = 0.85 * menuScale
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        baseRadius + 40,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.12, bgAlpha)),
        64
    )

    -- Draw outer ring
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        baseRadius + 42,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * menuScale)),
        64,
        2
    )

    -- Draw sectors
    for i = 1, itemCount do
        local item = menuItems[i]
        local angle1 = startAngle + (i - 1) * sectorAngle
        local angle2 = startAngle + i * sectorAngle
        local midAngle = (angle1 + angle2) / 2

        -- Sector highlight
        local isHovered = (hoveredSector == i)
        local sectorAlpha = isHovered and (0.6 * menuScale) or (0.2 * menuScale)
        local col = item.color

        -- Draw filled arc segment (approximate with triangles)
        local arcSegments = 20
        local innerR = 35 * menuScale
        local outerR = (baseRadius + 35) * menuScale
        for seg = 0, arcSegments - 1 do
            local a1 = angle1 + (angle2 - angle1) * seg / arcSegments
            local a2 = angle1 + (angle2 - angle1) * (seg + 1) / arcSegments
            local p1 = imgui.ImVec2(centerX + math.cos(a1) * innerR, centerY + math.sin(a1) * innerR)
            local p2 = imgui.ImVec2(centerX + math.cos(a1) * outerR, centerY + math.sin(a1) * outerR)
            local p3 = imgui.ImVec2(centerX + math.cos(a2) * outerR, centerY + math.sin(a2) * outerR)
            local p4 = imgui.ImVec2(centerX + math.cos(a2) * innerR, centerY + math.sin(a2) * innerR)
            local fillColor = imgui.ColorConvertFloat4ToU32(
                imgui.ImVec4(col[1], col[2], col[3], sectorAlpha)
            )
            draw_list:AddQuadFilled(p1, p2, p3, p4, fillColor)
        end

        -- Draw sector divider lines
        local lineStart = imgui.ImVec2(
            centerX + math.cos(angle1) * innerR,
            centerY + math.sin(angle1) * innerR
        )
        local lineEnd = imgui.ImVec2(
            centerX + math.cos(angle1) * outerR,
            centerY + math.sin(angle1) * outerR
        )
        draw_list:AddLine(lineStart, lineEnd,
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * menuScale)),
            1.5
        )

        -- Draw icon and label at sector center
        local iconDist = (innerR + outerR) / 2
        local iconX = centerX + math.cos(midAngle) * iconDist
        local iconY = centerY + math.sin(midAngle) * iconDist

        -- Icon
        local iconText = item.icon
        local iconSize = imgui.CalcTextSize(iconText)
        draw_list:AddText(
            imgui.ImVec2(iconX - iconSize.x / 2, iconY - iconSize.y - 2),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, menuScale)),
            iconText
        )

        -- Label
        local labelSize = imgui.CalcTextSize(item.label)
        local labelAlpha = isHovered and menuScale or (0.7 * menuScale)
        draw_list:AddText(
            imgui.ImVec2(iconX - labelSize.x / 2, iconY + 4),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.9, 0.9, 0.9, labelAlpha)),
            item.label
        )
    end

    -- Draw center circle (close button)
    local centerR = 30 * menuScale
    local centerHovered = (dist < centerR)
    local centerAlpha = centerHovered and (0.9 * menuScale) or (0.6 * menuScale)
    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.22, centerAlpha)),
        32
    )
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        centerR,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.8, 0.5 * menuScale)),
        32,
        1.5
    )

    -- "X" in center
    local closeIcon = fa_loaded and faicons('XMARK') or "X"
    local closeSize = imgui.CalcTextSize(closeIcon)
    draw_list:AddText(
        imgui.ImVec2(centerX - closeSize.x / 2, centerY - closeSize.y / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 0.4, 0.4, menuScale)),
        closeIcon
    )

    -- Handle clicks
    if imgui.IsMouseClicked(0) then
        if centerHovered then
            -- Close menu
            showPieMenu = false
            menuOpenTime = os.clock()
        elseif hoveredSector >= 1 and hoveredSector <= itemCount then
            -- Execute command
            executeCommand(hoveredSector)
        end
    end

    -- Status text at bottom
    if lastExecuted ~= "" then
        local statusText = "Last: " .. lastExecuted
        local statusSize = imgui.CalcTextSize(statusText)
        draw_list:AddText(
            imgui.ImVec2(centerX - statusSize.x / 2, centerY + baseRadius + 70),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.8, 1.0, 0.7 * menuScale)),
            statusText
        )
    end

    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(2)
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    -- Wait for SAMP to initialize
    while not isSampAvailable() do wait(100) end
    wait(500)

    -- Register command
    sampRegisterChatCommand("pdemo", function()
        togglePieMenu()
    end)

    -- Startup notification
    if notif_loaded and Notifications then
        Notifications.Show("Pie Menu Demo loaded! Use /pdemo", Notifications.TYPE.INFO, 4)
    else
        pcall(function()
            sampAddChatMessage("{00BFFF}[PieMenu] {FFFFFF}Demo loaded! Use /pdemo to toggle.", 0x00BFFF)
        end)
    end

    -- Main loop
    while true do
        wait(0)
    end
end
